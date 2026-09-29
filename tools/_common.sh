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
