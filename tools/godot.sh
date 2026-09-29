#!/usr/bin/env bash
# Resolves the pinned Godot binary and execs it with all arguments passed through.
set -euo pipefail

_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
# shellcheck source=./_common.sh
source "${_SCRIPT_DIR}/_common.sh"

DUSKHOLD_GODOT_BIN="$(duskhold_godot_bin)"

if [ ! -x "${DUSKHOLD_GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi

exec "${DUSKHOLD_GODOT_BIN}" "$@"
