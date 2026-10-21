#!/usr/bin/env bash
# Hermetic proof of the native stamp contract (review CR-01, WR-12, WR-13): a failed or stale install
# must never pass the guard. Ten cases run against fake libraries in one temporary directory:
#   install_missing_source, install_ok, changed_library, swapped_library, one_line_stamp,
#   missing_library, missing_stamp, changed_sources, install_refuses_moved_sources,
#   install_with_start_stamp.
# The last three run against a miniature copy of the repository root (the pin file,
# native/CMakeLists.txt and native/src), so the probe can change "the sources" without touching them.
# CI (lint job) and tools/prepush_check.sh run it; it needs no Godot and no build.
# Usage: bash tools/native_stamp_probe.sh
# No Godot process is started. The probe writes only under one `mktemp -d` directory, removed by a
# trap on exit, and never touches addons/duskhold_sim/bin (DUSKHOLD_NATIVE_BIN_DIR is pointed at the
# temporary directory after tools/_common.sh is sourced; the guard reads it at call time).
# Prints NATIVE_STAMP_PROBE_CASE <name> ok per case and NATIVE_STAMP_PROBE_OK cases=10 (exit 0); the
# first failure prints NATIVE_STAMP_PROBE_FAIL case=<name> and exits 1.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

PLATFORM="$(duskhold_native_host_platform)"
if [ "${PLATFORM}" = "unsupported" ]; then
  echo "NATIVE_STAMP_PROBE_FAIL case=platform (unsupported host)" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"
SRC="${TMP}/src"
mkdir -p "${BIN}" "${SRC}"
DUSKHOLD_NATIVE_BIN_DIR="${BIN}"

LIB="$(duskhold_native_lib "${PLATFORM}")"
LIB_NAME="$(basename -- "${LIB}")"
STAMP="${BIN}/${PLATFORM}.stamp"
BUILT="${SRC}/${LIB_NAME}"
CASES=0

fail() {
  echo "NATIVE_STAMP_PROBE_FAIL case=$1" >&2
  exit 1
}

pass() {
  CASES=$((CASES + 1))
  echo "NATIVE_STAMP_PROBE_CASE $1 ok"
}

# 4096 bytes of one letter; a different letter is a different library of the same size.
make_lib() {
  head -c 4096 /dev/zero | tr '\0' "$2" >"$1"
}

guard_code() {
  duskhold_require_native "${PLATFORM}" >/dev/null 2>&1
  echo $?
}

# (a) a failed install (the source is missing) leaves no stamp, even when a stale one was there.
printf 'stale\n' >"${STAMP}"
if duskhold_native_install "${TMP}/no_such_library" "${BIN}" "${PLATFORM}" 2>/dev/null; then
  fail install_missing_source
fi
[ ! -e "${STAMP}" ] || fail install_missing_source
pass install_missing_source

# (b) a good install returns 0, leaves a two-line stamp and the guard accepts it.
make_lib "${BUILT}" A
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail install_ok
[ "$(tr -d '\r' <"${STAMP}" | wc -l)" -eq 2 ] || fail install_ok
[ "$(guard_code)" -eq 0 ] || fail install_ok
pass install_ok

# (c) one byte appended to the installed copy is refused.
printf 'x' >>"${BIN}/${LIB_NAME}"
[ "$(guard_code)" -eq 3 ] || fail changed_library
pass changed_library

# (d) different bytes of the same size are refused.
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail swapped_library
[ "$(guard_code)" -eq 0 ] || fail swapped_library
make_lib "${BIN}/${LIB_NAME}" B
[ "$(guard_code)" -eq 3 ] || fail swapped_library
pass swapped_library

# (e) a stamp from before the library hash existed (the source line only) is refused.
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail one_line_stamp
duskhold_native_stamp >"${STAMP}"
[ "$(guard_code)" -eq 3 ] || fail one_line_stamp
pass one_line_stamp

# (f) a missing library is refused.
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail missing_library
rm -f "${BIN}/${LIB_NAME}"
[ "$(guard_code)" -eq 3 ] || fail missing_library
pass missing_library

# (g) a missing stamp is refused.
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail missing_stamp
rm -f "${STAMP}"
[ "$(guard_code)" -eq 3 ] || fail missing_stamp
pass missing_stamp

# The remaining cases use a miniature root: DUSKHOLD_ROOT is read by duskhold_native_stamp at call
# time, so pointing it at a copy lets the probe edit "the sources" without touching the real ones.
MINI="${TMP}/root"
mkdir -p "${MINI}/tools" "${MINI}/native"
cp "${_DUSKHOLD_COMMON_DIR}/godot_cpp_pin.txt" "${MINI}/tools/godot_cpp_pin.txt" || fail mini_root
cp "${DUSKHOLD_ROOT}/native/CMakeLists.txt" "${MINI}/native/CMakeLists.txt" || fail mini_root
cp -R "${DUSKHOLD_ROOT}/native/src" "${MINI}/native/src" || fail mini_root
DUSKHOLD_ROOT="${MINI}"
SOME_SOURCE="$(find "${MINI}/native/src" -type f | LC_ALL=C sort | head -n 1)"
[ -f "${SOME_SOURCE}" ] || fail mini_root

# (h) a source edited after the install makes the stamp stale.
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" || fail changed_sources
[ "$(guard_code)" -eq 0 ] || fail changed_sources
echo '// edited after the install' >>"${SOME_SOURCE}"
[ "$(guard_code)" -eq 3 ] || fail changed_sources
pass changed_sources

# (i) the sources moved between the start stamp and the install: the install refuses and leaves no stamp.
START_STAMP="$(duskhold_native_stamp)"
echo '// edited during the build' >>"${SOME_SOURCE}"
if duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" "${START_STAMP}" 2>/dev/null; then
  fail install_refuses_moved_sources
fi
[ ! -e "${STAMP}" ] || fail install_refuses_moved_sources
[ "$(guard_code)" -eq 3 ] || fail install_refuses_moved_sources
pass install_refuses_moved_sources

# (j) with unchanged sources the install given the start stamp succeeds and the guard accepts it.
START_STAMP="$(duskhold_native_stamp)"
duskhold_native_install "${BUILT}" "${BIN}" "${PLATFORM}" "${START_STAMP}" || fail install_with_start_stamp
[ "$(sed -n 1p "${STAMP}")" = "${START_STAMP}" ] || fail install_with_start_stamp
[ "$(guard_code)" -eq 0 ] || fail install_with_start_stamp
pass install_with_start_stamp

echo "NATIVE_STAMP_PROBE_OK cases=${CASES}"
