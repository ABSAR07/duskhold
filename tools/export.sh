#!/usr/bin/env bash
# Command-line Windows export (preset "Windows Desktop" in export_presets.cfg).
# Usage: bash tools/export.sh
# Writes build/windows/Duskhold.exe + Duskhold.pck and build/export.log. Works from Git Bash on
# Windows and from bash on Linux CI (the Windows export needs no Wine: modify_resources=false).
# Exit status is non-zero unless Godot succeeds, the exe (> 1 MB) and pck exist, and the log has
# no missing-template or rcedit complaint.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --templates --yes (after owner approval)" >&2
  exit 3
fi

OUT_DIR="${DUSKHOLD_ROOT}/build/windows"
EXE="${OUT_DIR}/Duskhold.exe"
PCK="${OUT_DIR}/Duskhold.pck"
LOG="${DUSKHOLD_ROOT}/build/export.log"

mkdir -p "${OUT_DIR}"
rm -f "${EXE}" "${PCK}"

# Import pass first so a fresh checkout (CI) has .godot/ imported resources before exporting.
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >/dev/null 2>&1

"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  --export-release "Windows Desktop" "${DUSKHOLD_ROOT_NATIVE}/build/windows/Duskhold.exe" 2>&1 | tee "${LOG}"
export_status="${PIPESTATUS[0]}"

fail=0
if [ "${export_status}" -ne 0 ]; then
  echo "FAIL: godot --export-release exited with ${export_status}" >&2
  fail=1
fi
if [ ! -f "${EXE}" ]; then
  echo "FAIL: ${EXE} was not produced" >&2
  fail=1
elif [ "$(wc -c < "${EXE}")" -le 1048576 ]; then
  echo "FAIL: ${EXE} is not larger than 1 MB" >&2
  fail=1
fi
if [ ! -f "${PCK}" ]; then
  echo "FAIL: ${PCK} was not produced" >&2
  fail=1
fi
if grep -qE 'No export template found|rcedit' "${LOG}"; then
  echo "FAIL: export log mentions a missing template or rcedit:" >&2
  grep -E 'No export template found|rcedit' "${LOG}" >&2
  fail=1
fi

if [ "${fail}" -eq 0 ]; then
  echo "Export OK: ${EXE}"
fi
exit "${fail}"
