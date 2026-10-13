#!/usr/bin/env bash
# Bounded wrapper around the headless contrast probe (plan 03-19, G-03-13): warms the import cache,
# runs tools/screenshot/contrast_probe.gd under a timeout and passes only when it really measured
# the text at or above the bar.
# Usage: bash tools/contrast_probe.sh --image=screenshots/<shot>.png --rect=x,y,w,h [--min=<ratio>]
#   e.g. the knocked-out king count on the real-window capture (the HealthLabel's rect at 1280x720):
#        bash tools/screenshot.sh hud_king_down
#        bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5
#   With no arguments it runs that command line.
# Environment: CONTRAST_TIMEOUT_S (default 60) bounds the Godot run.
# Exit status: 0 pass; 1 the ratio is below the bar, the text could not be measured, no CONTRAST_OK
# sentinel or a script error in the output; 3 Godot is not installed; 64 usage error; 124 the
# timeout fired.
# A script runtime error inside Godot still exits 0, so a pass needs the sentinel line and a clean
# log, not just the exit code. Output: build/contrast/contrast.log.
# On Windows run it from Git Bash. PowerShell's `bash` is WSL (Linux), which cannot see the pinned
# Windows Godot binary.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

CONTRAST_DIR="${DUSKHOLD_ROOT}/build/contrast"
IMPORT_LOG="${CONTRAST_DIR}/import.log"
CONTRAST_LOG="${CONTRAST_DIR}/contrast.log"
TIMEOUT_S="${CONTRAST_TIMEOUT_S:-60}"

if [ "$#" -eq 0 ]; then
  set -- --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5
fi

mkdir -p "${CONTRAST_DIR}"
rm -f "${CONTRAST_LOG}"

# 1. Headless import pass (warms .godot/ so the script and its classes resolve).
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

# 2. The probe, bounded by a timeout. The user arguments follow `--`.
timeout "${TIMEOUT_S}" "${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://tools/screenshot/contrast_probe.gd -- "$@" 2>&1 | tee "${CONTRAST_LOG}"
probe_status="${PIPESTATUS[0]}"

fail=0
if [ "${probe_status}" -eq 124 ]; then
  echo "FAIL: the probe did not finish inside ${TIMEOUT_S}s (timeout)" >&2
  exit 124
fi
if [ "${probe_status}" -ne 0 ]; then
  echo "FAIL: contrast probe exited with ${probe_status}" >&2
  fail="${probe_status}"
fi
if ! grep -q '^CONTRAST_OK ' "${CONTRAST_LOG}"; then
  echo "FAIL: no CONTRAST_OK line in the output" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi
# A script runtime or parse error can leave the exit status at 0.
if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${CONTRAST_LOG}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: script errors in the probe output:" >&2
  grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${CONTRAST_LOG}" | grep -v 'addons/gut' >&2
  [ "${fail}" -eq 0 ] && fail=1
fi

exit "${fail}"
