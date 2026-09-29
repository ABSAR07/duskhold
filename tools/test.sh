#!/usr/bin/env bash
# Headless import + GUT run. Writes build/test-results/gut-junit.xml.
# Usage: bash tools/test.sh [extra GUT args, e.g. -gselect=test_foo.gd]
# Exit status is non-zero if Godot fails, the JUnit XML is missing, or a first-party script
# has a parse/load error (GUT's own addon output is ignored for the parse guard).
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

RESULTS_DIR="${DUSKHOLD_ROOT}/build/test-results"
JUNIT_XML="${RESULTS_DIR}/gut-junit.xml"
IMPORT_LOG="${RESULTS_DIR}/import.log"
GUT_LOG="${RESULTS_DIR}/gut.log"

mkdir -p "${RESULTS_DIR}"
rm -f "${JUNIT_XML}"

# 1. Headless import pass (warms .godot/ so class_name scripts and resources resolve).
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" --import 2>&1 | tee "${IMPORT_LOG}"
import_status="${PIPESTATUS[0]}"
if [ "${import_status}" -ne 0 ]; then
  echo "FAIL: godot --import exited with ${import_status}" >&2
  exit "${import_status}"
fi

# 2. GUT run.
"${GODOT_BIN}" --headless --path "${DUSKHOLD_ROOT_NATIVE}" \
  -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit "$@" 2>&1 | tee "${GUT_LOG}"
gut_status="${PIPESTATUS[0]}"

fail=0
if [ "${gut_status}" -ne 0 ]; then
  echo "FAIL: godot/GUT exited with ${gut_status}" >&2
  fail=1
fi
if [ ! -f "${JUNIT_XML}" ]; then
  echo "FAIL: JUnit XML not written: ${JUNIT_XML}" >&2
  fail=1
fi
# Parse-error guard: a script that fails to compile can silently drop out of the run.
if grep -hE 'Parse Error|Failed to load script' "${IMPORT_LOG}" "${GUT_LOG}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: parse/load errors in first-party scripts:" >&2
  grep -hE 'Parse Error|Failed to load script' "${IMPORT_LOG}" "${GUT_LOG}" | grep -v 'addons/gut' >&2
  fail=1
fi

exit "${fail}"
