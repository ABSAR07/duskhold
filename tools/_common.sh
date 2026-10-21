#!/usr/bin/env bash
# Shared helpers for tools/*.sh. Sourced, never executed directly.
# The repo path contains a space ("Thronefall-like Game") — every expansion below is quoted,
# and every caller must quote every expansion of these variables too.

# Resolve the repo root from this script's own directory, not the caller's cwd.
_DUSKHOLD_COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
DUSKHOLD_ROOT="$(cd -- "${_DUSKHOLD_COMMON_DIR}/.." >/dev/null 2>&1 && pwd -P)"

# Native (Windows-style, forward-slash) path form for passing to the native Windows Godot
# binary from Git Bash / MSYS. On non-Windows platforms this is just DUSKHOLD_ROOT.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    DUSKHOLD_ROOT_NATIVE="$(cygpath -m "${DUSKHOLD_ROOT}")"
    ;;
  *)
    DUSKHOLD_ROOT_NATIVE="${DUSKHOLD_ROOT}"
    ;;
esac

# Single version pin, shared by local scripts, CI and tools/bootstrap.py. Strip CR (Windows
# checkouts) and LF so the value is safe to interpolate into paths and comparisons.
DUSKHOLD_GODOT_VERSION="$(tr -d '\r\n' < "${DUSKHOLD_ROOT}/tools/godot_version.txt")"

# Prints the path to the pinned Godot binary for the current platform. Does not check that it
# exists — callers (tools/godot.sh) do that.
duskhold_godot_bin() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      printf '%s/.tools/godot/%s/Godot_v%s_win64_console.exe' \
        "${DUSKHOLD_ROOT}" "${DUSKHOLD_GODOT_VERSION}" "${DUSKHOLD_GODOT_VERSION}"
      ;;
    *)
      printf '%s/.tools/godot/%s/Godot_v%s_linux.x86_64' \
        "${DUSKHOLD_ROOT}" "${DUSKHOLD_GODOT_VERSION}" "${DUSKHOLD_GODOT_VERSION}"
      ;;
  esac
}

# --- native library (PLAT-01 GDExtension) -------------------------------------------------------
# Every way of running the project needs addons/duskhold_sim/bin/libduskhold_sim.<platform>...
# built from the current native/ sources. A missing or stale library is a hard error everywhere
# (exit 3 with the build command), never a silent fallback. The stamp binds the sources AND the
# installed library bytes: <platform>.stamp holds two lines, the source stamp and the sha256 of the
# library file. It is computed by ONE function below (duskhold_native_stamp_for), used both by
# duskhold_native_install, which tools/native_build.sh installs through and which writes the stamp
# only after a checked copy, and by duskhold_require_native when it checks it, so the two cannot
# drift and a failed, changed or swapped library is refused (review CR-01).
DUSKHOLD_NATIVE_BIN_DIR="${DUSKHOLD_ROOT}/addons/duskhold_sim/bin"

# Prints the platform name of this host as the library file names spell it (windows or linux).
duskhold_native_host_platform() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) printf 'windows' ;;
    Linux) printf 'linux' ;;
    *) printf 'unsupported' ;;
  esac
}

# Prints the sha256 over the pin file, native/CMakeLists.txt and every file under native/src, in
# LC_ALL=C path order, each file hashed with CR stripped (a Windows checkout and a Linux one agree).
duskhold_native_stamp() {
  (
    cd "${DUSKHOLD_ROOT}" || exit 1
    {
      for f in tools/godot_cpp_pin.txt native/CMakeLists.txt; do
        printf '%s  %s\n' "$(tr -d '\r' <"${f}" | sha256sum | cut -d' ' -f1)" "${f}"
      done
      find native/src -type f | LC_ALL=C sort | while IFS= read -r f; do
        printf '%s  %s\n' "$(tr -d '\r' <"${f}" | sha256sum | cut -d' ' -f1)" "${f}"
      done
    } | sha256sum | cut -d' ' -f1
  )
}

# Prints the library path for a platform (windows or linux); prints nothing for any other name.
duskhold_native_lib() {
  case "${1:-}" in
    windows) printf '%s/libduskhold_sim.windows.x86_64.dll' "${DUSKHOLD_NATIVE_BIN_DIR}" ;;
    linux) printf '%s/libduskhold_sim.linux.x86_64.so' "${DUSKHOLD_NATIVE_BIN_DIR}" ;;
  esac
}

# Prints the two stamp lines for an installed library: the source stamp, then the sha256 of the
# library file. The source stamp is duskhold_native_stamp evaluated now, or the optional second
# argument (the stamp taken before the build began, review WR-12). Prints nothing and returns 1
# when the file does not exist.
duskhold_native_stamp_for() {
  local lib="${1:-}" sources="${2:-}"
  local lib_sha
  [ -n "${lib}" ] && [ -f "${lib}" ] || return 1
  lib_sha="$(sha256sum "${lib}" | cut -d' ' -f1)" || return 1
  [ -n "${lib_sha}" ] || return 1
  if [ -z "${sources}" ]; then
    sources="$(duskhold_native_stamp)" || return 1
  fi
  printf '%s\n%s\n' "${sources}" "${lib_sha}"
}

# Installs a built library: duskhold_native_install <built library> <destination directory> <platform>
# [source stamp taken before the build began]. The old stamp is removed first, the copy is checked by
# exit status and by a byte comparison (a Godot process holding the installed DLL open makes the copy
# fail on Windows), and the new stamp is written through a temporary file only after the check. When
# the optional fourth argument is given the install is refused if the sources changed since that stamp
# was taken (the library was compiled from the old ones, review WR-12), and that stamp is the one
# written. On any failure it prints NATIVE_BUILD_FAIL to stderr, leaves NO stamp and returns 1.
duskhold_native_install() {
  local built="${1:-}" dest_dir="${2:-}" platform="${3:-}" sources_at_start="${4:-}"
  local name target stamp tmp
  name="$(basename -- "${built}")"
  target="${dest_dir}/${name}"
  stamp="${dest_dir}/${platform}.stamp"
  rm -f "${stamp}"
  if [ -n "${sources_at_start}" ] && [ "$(duskhold_native_stamp)" != "${sources_at_start}" ]; then
    echo "NATIVE_BUILD_FAIL: native sources changed during the build; rebuild" >&2
    return 1
  fi
  if ! cp -f "${built}" "${target}" || ! cmp -s "${built}" "${target}"; then
    echo "NATIVE_BUILD_FAIL: cannot install ${name} (a Godot process may hold it open; close it and rebuild)" >&2
    return 1
  fi
  tmp="${stamp}.tmp.$$"
  if ! duskhold_native_stamp_for "${target}" "${sources_at_start}" >"${tmp}" || ! mv -f "${tmp}" "${stamp}"; then
    rm -f "${tmp}" "${stamp}"
    echo "NATIVE_BUILD_FAIL: cannot write the stamp for ${name}" >&2
    return 1
  fi
  return 0
}

# Returns 0 when the library for the platform (default: this host) exists and its two-line stamp
# equals duskhold_native_stamp_for of the installed file (current sources and these exact bytes);
# otherwise prints one line naming the build command and returns 3. Callers write:
# duskhold_require_native [platform] || exit 3
duskhold_require_native() {
  local platform="${1:-$(duskhold_native_host_platform)}"
  local lib stamp_file expected
  lib="$(duskhold_native_lib "${platform}")"
  stamp_file="${DUSKHOLD_NATIVE_BIN_DIR}/${platform}.stamp"
  expected=""
  if [ -n "${lib}" ] && [ -f "${lib}" ]; then
    expected="$(duskhold_native_stamp_for "${lib}")" || expected=""
  fi
  if [ -z "${expected}" ] || [ ! -f "${stamp_file}" ]     || [ "$(tr -d '' <"${stamp_file}")" != "${expected}" ]; then
    echo "native library missing or stale: run bash tools/native_build.sh" >&2
    return 3
  fi
  return 0
}

# A first import in a project that has no .godot/extension_list.cfg has crashed Godot at editor
# teardown (exit 139) after writing everything (04-14 probe, minimal project only). Seeding the
# list with the one extension makes that first pass behave like every later one. No-op when the
# list exists. Call it right before the headless --import pass.
duskhold_seed_extension_list() {
  local list="${DUSKHOLD_ROOT}/.godot/extension_list.cfg"
  if [ ! -f "${list}" ]; then
    mkdir -p "${DUSKHOLD_ROOT}/.godot"
    printf 'res://addons/duskhold_sim/duskhold_sim.gdextension\n' >"${list}"
  fi
}
