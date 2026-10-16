#!/usr/bin/env bash
# Bounded wrapper around the headless gate stress CLI (ENMY-04): warms the import cache, runs
# tools/stress/gate_stress_cli.gd under a timeout and passes only when the run really finished well.
# Usage: bash tools/gate_stress.sh [--seed=<int>] [--twice] [--max-seconds=<10..300>]
#          [--out=build/<dir>]
#   e.g. bash tools/gate_stress.sh --twice
# Environment: GATE_TIMEOUT_S (default 600) bounds the Godot run.
# Exit status: 0 pass; 1 a failed gate, no GATE_OK sentinel or a script error in the output; 3 Godot
# is not installed; 64 usage error; 124 the timeout fired.
# A script runtime error inside Godot still exits 0, so a pass needs the sentinel line and a clean
# log, not just the exit code. Output: build/stress/gate.log plus the CLI's build/stress/gate.json.
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

STRESS_DIR="${DUSKHOLD_ROOT}/build/stress"
IMPORT_LOG="${STRESS_DIR}/import.log"
GATE_LOG="${STRESS_DIR}/gate.log"
TIMEOUT_S="${GATE_TIMEOUT_S:-600}"

mkdir -p "${STRESS_DIR}"
rm -f "${GATE_LOG}"

# 1. Headless import pass (warms .godot/ so class_name scripts and resources resolve).
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

# 2. The gate stress, bounded by a timeout. The user arguments follow `--`.
timeout "${TIMEOUT_S}" "${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://tools/stress/gate_stress_cli.gd -- "$@" 2>&1 | tee "${GATE_LOG}"
gate_status="${PIPESTATUS[0]}"

fail=0
if [ "${gate_status}" -eq 124 ]; then
  echo "FAIL: the gate stress did not finish inside ${TIMEOUT_S}s (timeout)" >&2
  exit 124
fi
if [ "${gate_status}" -ne 0 ]; then
  echo "FAIL: gate stress CLI exited with ${gate_status}" >&2
  fail="${gate_status}"
fi
if ! grep -q '^GATE_OK ' "${GATE_LOG}"; then
  echo "FAIL: no GATE_OK line in the output" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi
# A script runtime or parse error can leave the exit status at 0.
if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${GATE_LOG}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: script errors in the gate stress output:" >&2
  grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${GATE_LOG}" | grep -v 'addons/gut' >&2
  [ "${fail}" -eq 0 ] && fail=1
fi

exit "${fail}"
