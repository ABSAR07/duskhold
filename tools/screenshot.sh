#!/usr/bin/env bash
# Captures the scripted screenshot scenes (DEV-04) into screenshots/*.png (git-ignored output).
# Usage: bash tools/screenshot.sh [shot ...]
#   Shots: day_overview spot_label build_in_progress night_banner dawn_payout overlay_on
#   With no arguments, all six are captured.
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

ALL_SHOTS=(day_overview spot_label build_in_progress night_banner dawn_payout overlay_on)
RUN_TIMEOUT_S=120
OUT_DIR="${DUSKHOLD_ROOT}/screenshots"
OUT_DIR_NATIVE="${DUSKHOLD_ROOT_NATIVE}/screenshots"

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

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

mkdir -p "${OUT_DIR}"

# The one headless call: warm the .godot import cache so the class_name scripts resolve.
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >/dev/null 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}" >&2
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
  wrapper=(xvfb-run -a -s "-screen 0 1280x720x24")
fi

fail=0
saved=()
for shot in "${SHOTS[@]}"; do
  rm -f "${OUT_DIR}/${shot}.png"
  echo "== ${shot}"
  "${wrapper[@]}" timeout "${RUN_TIMEOUT_S}" "${GODOT_BIN}" \
    --path "${DUSKHOLD_ROOT_NATIVE}" --resolution 1280x720 \
    "${renderer_args[@]}" \
    res://tools/screenshot/shot_runner.tscn -- "--shot=${shot}" "--out=${OUT_DIR_NATIVE}"
  status=$?
  if [ "${status}" -ne 0 ]; then
    echo "FAIL: ${shot} exited with ${status}" >&2
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
for file in "${saved[@]}"; do
  echo "  ${file}"
done
exit "${fail}"
