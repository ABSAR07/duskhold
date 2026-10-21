#!/usr/bin/env bash
# Captures the scripted screenshot scenes (DEV-04) into screenshots/*.png (git-ignored output).
# Usage: bash tools/screenshot.sh [shot ...]
#   Shots: day_overview spot_label build_in_progress night_banner dawn_payout overlay_on
#          king_behind_keep spawn_telegraph night_combat building_destroyed dawn_rebuilt
#          king_down_countdown results_victory results_defeat overlay_paths
#          the eighteen Phase 3 shots hud_* and cmd_*, the four Phase 4 shots walls_day,
#          walls_night_breach, overlay_field_gate and crowd_stress_night, and the Phase 5 shots
#          castle_cards and castle_tier_four, all listed in ALL_SHOTS below.
#   With no arguments, all thirty-nine are captured. The night shots fast-forward the simulation
#   with a named bot (tools/replay/playtest_strategies.gd) before the real-time capture. Every hud_
#   and cmd_ shot also fails when a visible HUD control sits in the clear centre (ShotRunner).
#   The window is 1280x720, 1920x1080 for a name ending _1080p and 1600x1000 for one ending _16x10.
#   Each shot's output is kept in build/screenshot-<shot>.log and a script error in it fails the shot
#   (a runtime script error still exits 0 in Godot, as tools/replay.sh and tools/playtest.sh note).
#
# Screenshots need a real renderer, so this never runs the capture under --headless (the dummy
# renderer would save blank images). The only headless call is the one-time --import warm-up.
#   Local (Windows GPU, Forward+):  bash tools/screenshot.sh
#   CI / no GPU: DUSKHOLD_SCREENSHOT_COMPAT=1 bash tools/screenshot.sh
#     -> Compatibility renderer (OpenGL 3); on Linux without a DISPLAY it runs under xvfb-run,
#        which needs: xvfb libgl1-mesa-dri libglx-mesa0.
# On Windows run it from Git Bash. PowerShell's `bash` is WSL (Linux), which cannot see the
# pinned Windows Godot binary.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

ALL_SHOTS=(day_overview spot_label build_in_progress night_banner dawn_payout overlay_on king_behind_keep
  spawn_telegraph night_combat building_destroyed dawn_rebuilt king_down_countdown results_victory
  results_defeat overlay_paths
  hud_day_squads hud_night_squad_down hud_drag_box hud_pad_cursor hud_king_down hud_ability_ready
  hud_long_toast hud_day_squads_1080p hud_night_squad_down_16x10 hud_day_counter_long hud_king_120
  hud_keycap_backspace cmd_queue_ten hud_rubble_squad cmd_box_select cmd_move_ping cmd_patrol
  cmd_slam walls_day walls_night_breach overlay_field_gate crowd_stress_night castle_cards
  castle_tier_four)
RUN_TIMEOUT_S=120
OUT_DIR="${DUSKHOLD_ROOT}/screenshots"
OUT_DIR_NATIVE="${DUSKHOLD_ROOT_NATIVE}/screenshots"

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

# A missing or stale native library is a hard error (exit 3), never a silent fallback.
duskhold_require_native || exit 3

if [ "$#" -gt 0 ]; then
  SHOTS=("$@")
else
  SHOTS=("${ALL_SHOTS[@]}")
fi
for shot in "${SHOTS[@]}"; do
  known=0
  for candidate in "${ALL_SHOTS[@]}"; do
    [ "${shot}" = "${candidate}" ] && known=1
  done
  if [ "${known}" -ne 1 ]; then
    echo "Unknown shot: ${shot} (known: ${ALL_SHOTS[*]})" >&2
    exit 64
  fi
done

IMPORT_LOG="${DUSKHOLD_ROOT}/build/screenshot-import.log"
mkdir -p "${OUT_DIR}" "${DUSKHOLD_ROOT}/build"

# The one headless call: warm the .godot import cache so the class_name scripts resolve.
# Its output is kept (like tools/export.sh) so a failed import can be diagnosed.
duskhold_seed_extension_list
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

renderer_args=()
if [ "${DUSKHOLD_SCREENSHOT_COMPAT:-0}" = "1" ]; then
  renderer_args=(--rendering-method gl_compatibility --rendering-driver opengl3)
fi

wrapper=()
if [ "$(uname -s)" = "Linux" ] && [ -z "${DISPLAY:-}" ]; then
  if ! command -v xvfb-run >/dev/null 2>&1; then
    echo "No DISPLAY and xvfb-run is not installed (apt-get install xvfb libgl1-mesa-dri libglx-mesa0)" >&2
    exit 3
  fi
  wrapper=(xvfb-run -a -s "-screen 0 1920x1080x24")
fi

# The window shape of a shot: the name's suffix picks 1920x1080 or 1600x1000, else 1280x720.
resolution_for() {
  case "$1" in
    *_1080p) echo "1920x1080" ;;
    *_16x10) echo "1600x1000" ;;
    *) echo "1280x720" ;;
  esac
}

fail=0
saved=()
for shot in "${SHOTS[@]}"; do
  rm -f "${OUT_DIR}/${shot}.png"
  echo "== ${shot}"
  shot_log="${DUSKHOLD_ROOT}/build/screenshot-${shot}.log"
  ${wrapper[@]+"${wrapper[@]}"} timeout "${RUN_TIMEOUT_S}" "${GODOT_BIN}" \
    --path "${DUSKHOLD_ROOT_NATIVE}" --resolution "$(resolution_for "${shot}")" \
    ${renderer_args[@]+"${renderer_args[@]}"} \
    res://tools/screenshot/shot_runner.tscn -- "--shot=${shot}" "--out=${OUT_DIR_NATIVE}" 2>&1 \
    | tee "${shot_log}"
  status="${PIPESTATUS[0]}"
  if [ "${status}" -ne 0 ]; then
    echo "FAIL: ${shot} exited with ${status}" >&2
    fail=1
    continue
  fi
  # A runtime script error in a HUD node still exits 0 and the frame still renders, so read the log
  # the way tools/replay.sh and tools/playtest.sh do.
  if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${shot_log}" | grep -v 'addons/gut' | grep -q .; then
    echo "FAIL: script errors while capturing ${shot}:" >&2
    grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${shot_log}" | grep -v 'addons/gut' >&2
    fail=1
    continue
  fi
  if [ ! -s "${OUT_DIR}/${shot}.png" ]; then
    echo "FAIL: ${shot}.png is missing or empty" >&2
    fail=1
    continue
  fi
  saved+=("${OUT_DIR}/${shot}.png")
done

echo "Saved ${#saved[@]} of ${#SHOTS[@]} screenshots:"
for file in ${saved[@]+"${saved[@]}"}; do
  echo "  ${file}"
done
exit "${fail}"
