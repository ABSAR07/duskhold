#!/usr/bin/env bash
# gdformat --check + gdlint over first-party GDScript only (never addons/).
# Usage: bash tools/lint.sh [--fix]
#   --fix   run gdformat (rewriting files) before the checks.
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

FIX=0
for arg in "$@"; do
  case "${arg}" in
    --fix) FIX=1 ;;
    *)
      echo "Unknown argument: ${arg} (supported: --fix)" >&2
      exit 64
      ;;
  esac
done

# Resolve the linters from the local venv (Windows: Scripts/, Linux: bin/), falling back to PATH (CI).
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    VENV_BIN="${DUSKHOLD_ROOT}/.tools/venv/Scripts"
    EXT=".exe"
    ;;
  *)
    VENV_BIN="${DUSKHOLD_ROOT}/.tools/venv/bin"
    EXT=""
    ;;
esac

resolve_tool() {
  local name="$1"
  if [ -f "${VENV_BIN}/${name}${EXT}" ]; then
    printf '%s' "${VENV_BIN}/${name}${EXT}"
  elif command -v "${name}" >/dev/null 2>&1; then
    command -v "${name}"
  else
    echo "${name} not found: run python tools/bootstrap.py --lint-tools --yes, or install gdtoolkit==4.5.0" >&2
    return 1
  fi
}

GDFORMAT="$(resolve_tool gdformat)" || exit 3
GDLINT="$(resolve_tool gdlint)" || exit 3

cd "${DUSKHOLD_ROOT}" || exit 1

# First-party directories only. addons/ is never passed.
targets=()
for dir in simulation input presentation ui tests tools; do
  if [ -d "${dir}" ] && [ -n "$(find "${dir}" -name '*.gd' -print -quit)" ]; then
    targets+=("${dir}")
  fi
done

if [ "${#targets[@]}" -eq 0 ]; then
  echo "no first-party GDScript yet"
  exit 0
fi

if [ "${FIX}" -eq 1 ]; then
  "${GDFORMAT}" "${targets[@]}" || exit 1
fi

status=0
"${GDFORMAT}" --check "${targets[@]}" || status=1
"${GDLINT}" "${targets[@]}" || status=1
exit "${status}"
