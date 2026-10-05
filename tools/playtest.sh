#!/usr/bin/env bash
# Bounded wrapper around the headless balance report CLI (D-18): warms the import cache, runs
# tools/playtest/playtest_cli.gd under a timeout and passes only when the report really finished.
# Usage: bash tools/playtest.sh [--strategies=<a,b,...>] [--seeds=<1..50>] [--out=build/<dir>]
#   e.g. bash tools/playtest.sh                                   (all strategies, seeds 1..10)
#        bash tools/playtest.sh --strategies=no_build --seeds=2
# Strategies: no_build, greedy_economy, houses_first, towers_first, balanced.
# Environment: PLAYTEST_TIMEOUT_S (default 1800) bounds the Godot run.
# Exit status: 0 pass; 1 a run timed out, no PLAYTEST_OK sentinel or a script error in the output;
# 3 Godot is not installed; 64 usage error; 124 the timeout fired.
# A script runtime error inside Godot still exits 0 (RESEARCH Pitfall 4), so a pass needs the
# sentinel line and a clean log, not just the exit code. Output: build/playtest/playtest.log plus
# the CLI's build/playtest/report.json and report.md.
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

PLAYTEST_DIR="${DUSKHOLD_ROOT}/build/playtest"
IMPORT_LOG="${PLAYTEST_DIR}/import.log"
PLAYTEST_LOG="${PLAYTEST_DIR}/playtest.log"
TIMEOUT_S="${PLAYTEST_TIMEOUT_S:-1800}"

mkdir -p "${PLAYTEST_DIR}"
rm -f "${PLAYTEST_LOG}"

# 1. Headless import pass (warms .godot/ so class_name scripts and resources resolve).
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

# 2. The balance report, bounded by a timeout. The user arguments follow `--`.
timeout "${TIMEOUT_S}" "${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://tools/playtest/playtest_cli.gd -- "$@" 2>&1 | tee "${PLAYTEST_LOG}"
run_status="${PIPESTATUS[0]}"

fail=0
if [ "${run_status}" -eq 124 ]; then
  echo "FAIL: the playtest did not finish inside ${TIMEOUT_S}s (timeout)" >&2
  exit 124
fi
if [ "${run_status}" -ne 0 ]; then
  echo "FAIL: playtest CLI exited with ${run_status}" >&2
  fail="${run_status}"
fi
if ! grep -q '^PLAYTEST_OK ' "${PLAYTEST_LOG}"; then
  echo "FAIL: no PLAYTEST_OK line in the output" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi
# A script runtime or parse error can leave the exit status at 0.
if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${PLAYTEST_LOG}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: script errors in the playtest output:" >&2
  grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${PLAYTEST_LOG}" | grep -v 'addons/gut' >&2
  [ "${fail}" -eq 0 ] && fail=1
fi

exit "${fail}"
