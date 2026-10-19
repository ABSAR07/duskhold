#!/usr/bin/env bash
# The frame-time budget run of PLAT-01 (D-12): the stress night in a REAL window, several times,
# then the headless report tool that picks the median run and writes build/stress/report.md.
# LOCAL ONLY. It never runs in CI and never headless: the stress scene exits 2 under a headless
# display server, and a frame time measured on the dummy renderer would mean nothing.
# Usage: bash tools/stress.sh [--runs=<1..9>] [--duration=<5..120>]
#   e.g. bash tools/stress.sh --runs=3 --duration=20
# Close other heavy programs first: run-to-run noise is real (RESEARCH Pitfall 13).
# Environment: STRESS_EXTRA_TIMEOUT_S (default 120) is added to warm-up plus duration as the time
# limit of one run.
# Exit status: 0 pass; 1 a failed run, a script error or no FRAME_REPORT_OK line; 3 Godot is not
# installed; 64 usage error; 124 a run timed out.
# Output: build/stress/stress.log (every run and the report line), run_<n>.json per run, and the
# report tool's report.json and report.md. On Windows run it from Git Bash. PowerShell's `bash` is
# WSL (Linux), which cannot see the pinned Windows Godot binary.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

RUNS=3
DURATION=20
WARMUP=10
for arg in "$@"; do
  case "${arg}" in
    --runs=[1-9]) RUNS="${arg#--runs=}" ;;
    --duration=*)
      DURATION="${arg#--duration=}"
      case "${DURATION}" in
        ''|*[!0-9]*) echo "usage: --duration must be a whole number of seconds (5..120)" >&2; exit 64 ;;
      esac
      if [ "${DURATION}" -lt 5 ] || [ "${DURATION}" -gt 120 ]; then
        echo "usage: --duration must be between 5 and 120" >&2
        exit 64
      fi
      ;;
    *) echo "usage: bash tools/stress.sh [--runs=<1..9>] [--duration=<5..120>]" >&2; exit 64 ;;
  esac
done

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

# A missing or stale native library is a hard error (exit 3), never a silent fallback.
duskhold_require_native || exit 3

STRESS_DIR="${DUSKHOLD_ROOT}/build/stress"
IMPORT_LOG="${STRESS_DIR}/import.log"
STRESS_LOG="${STRESS_DIR}/stress.log"
TIMEOUT_S=$((WARMUP + DURATION + ${STRESS_EXTRA_TIMEOUT_S:-120}))

mkdir -p "${STRESS_DIR}"
rm -f "${STRESS_LOG}" "${STRESS_DIR}"/run_*.json "${STRESS_DIR}/report.json" "${STRESS_DIR}/report.md"

# 1. Headless import pass (warms .godot/ so class_name scripts and resources resolve).
duskhold_seed_extension_list
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import >"${IMPORT_LOG}" 2>&1
import_status=$?
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}; see ${IMPORT_LOG}" >&2
  tail -n 20 "${IMPORT_LOG}" >&2
  exit "${import_status}"
fi

script_errors() {
  grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script|STRESS_FRAMING_FAILED|STRESS_FAILED' "$@" \
    | grep -v 'addons/gut'
}

# 2. The real-window runs, one after the other. The user arguments follow `--`.
for run in $(seq 1 "${RUNS}"); do
  echo "== stress run ${run} of ${RUNS}" | tee -a "${STRESS_LOG}"
  run_log="${STRESS_DIR}/run_${run}.log"
  timeout "${TIMEOUT_S}" "${GODOT_BIN}" --path "${DUSKHOLD_ROOT_NATIVE}" --resolution 1920x1080 \
    res://tools/stress/stress_night.tscn -- "--run=${run}" "--duration=${DURATION}" \
    "--warmup=${WARMUP}" "--out=build/stress" 2>&1 | tee "${run_log}" | tee -a "${STRESS_LOG}"
  status="${PIPESTATUS[0]}"
  if [ "${status}" -eq 124 ]; then
    echo "FAIL: stress run ${run} did not finish inside ${TIMEOUT_S}s (timeout)" >&2
    exit 124
  fi
  if [ "${status}" -ne 0 ]; then
    echo "FAIL: stress run ${run} exited with ${status}" >&2
    exit "${status}"
  fi
  if script_errors "${run_log}" | grep -q .; then
    echo "FAIL: errors in stress run ${run}:" >&2
    script_errors "${run_log}" >&2
    exit 1
  fi
  if [ ! -f "${STRESS_DIR}/run_${run}.json" ]; then
    echo "FAIL: stress run ${run} wrote no run_${run}.json" >&2
    exit 1
  fi
done

# 3. The report tool (headless: it only reads the JSON the runs wrote).
report_log="${STRESS_DIR}/report.log"
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://tools/stress/frame_report_cli.gd -- "--in=build/stress" "--runs=${RUNS}" \
  2>&1 | tee "${report_log}" | tee -a "${STRESS_LOG}"
report_status="${PIPESTATUS[0]}"

fail=0
if [ "${report_status}" -ne 0 ]; then
  echo "FAIL: the report tool exited with ${report_status}" >&2
  fail="${report_status}"
fi
if ! grep -q '^FRAME_REPORT_OK ' "${report_log}"; then
  echo "FAIL: no FRAME_REPORT_OK line in the report output" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi
if script_errors "${report_log}" | grep -q .; then
  echo "FAIL: script errors in the report output:" >&2
  script_errors "${report_log}" >&2
  [ "${fail}" -eq 0 ] && fail=1
fi

exit "${fail}"
