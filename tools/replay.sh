#!/usr/bin/env bash
# Bounded wrapper around the headless replay CLI (DEV-05): warms the import cache, runs
# tools/replay/replay_cli.gd under a timeout and passes only when the run really finished well.
# Usage: bash tools/replay.sh --scenario=<smoke|full_idle> [--seed=<int>] [--twice]
#          [--expect-file=tests/golden/<scenario>.json] [--out=build/<dir>] [--write-golden]
#   e.g. bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json
#        bash tools/replay.sh --scenario=full_idle --twice
# Environment: REPLAY_TIMEOUT_S (default 300) bounds the Godot run.
# Exit status: 0 pass; 1 digest mismatch, timeout outcome, no REPLAY_OK sentinel or a script error
# in the output; 3 Godot is not installed; 64 usage error; 124 the timeout fired.
# A script runtime error inside Godot still exits 0 (RESEARCH Pitfall 4), so a pass needs the
# sentinel line and a clean log, not just the exit code. Output: build/replay/replay.log plus the
# CLI's build/replay/<scenario>.json and .log.
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

REPLAY_DIR="${DUSKHOLD_ROOT}/build/replay"
IMPORT_LOG="${REPLAY_DIR}/import.log"
REPLAY_LOG="${REPLAY_DIR}/replay.log"
TIMEOUT_S="${REPLAY_TIMEOUT_S:-300}"

mkdir -p "${REPLAY_DIR}"
rm -f "${REPLAY_LOG}"

# 1. Headless import pass (warms .godot/ so class_name scripts and resources resolve).
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

# 2. The replay, bounded by a timeout. The user arguments follow `--`.
timeout "${TIMEOUT_S}" "${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://tools/replay/replay_cli.gd -- "$@" 2>&1 | tee "${REPLAY_LOG}"
replay_status="${PIPESTATUS[0]}"

fail=0
if [ "${replay_status}" -eq 124 ]; then
  echo "FAIL: the replay did not finish inside ${TIMEOUT_S}s (timeout)" >&2
  exit 124
fi
if [ "${replay_status}" -ne 0 ]; then
  echo "FAIL: replay CLI exited with ${replay_status}" >&2
  fail="${replay_status}"
fi
if ! grep -q '^REPLAY_OK ' "${REPLAY_LOG}"; then
  echo "FAIL: no REPLAY_OK line in the output" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi
# A script runtime or parse error can leave the exit status at 0.
if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${REPLAY_LOG}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: script errors in the replay output:" >&2
  grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${IMPORT_LOG}" "${REPLAY_LOG}" | grep -v 'addons/gut' >&2
  [ "${fail}" -eq 0 ] && fail=1
fi

exit "${fail}"
