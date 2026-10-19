#!/usr/bin/env bash
# Builds the Duskhold native simulation library (PLAT-01 GDExtension) from source: the one build
# entry point, used locally and by CI. Windows builds with MSVC (CMake and Ninja from Visual Studio
# Build Tools, found with vswhere), Linux with GCC. Nothing is installed system-wide.
# Usage: bash tools/native_build.sh [--fetch] [--clean]
#   --fetch  clone https://github.com/godotengine/godot-cpp.git into .tools/godot-cpp when absent
#            and check out the commit pinned in tools/godot_cpp_pin.txt
#   --clean  delete build/native/<platform> first (a full rebuild of every godot-cpp binding)
# Steps: (1) the godot-cpp checkout must be at the pin; (2) extension_api.json and
# gdextension_interface.json are dumped from the pinned Godot binary into build/native/api/ and
# must report this version with single precision; (3) CMake configure; (4) the compile commands
# must carry no fast-math, fused multiply-add, AVX or host-tuned switch; (5) build; (6) on Windows
# the DLL must import no VCRUNTIME or MSVCP library; (7) the library is copied to
# addons/duskhold_sim/bin/ with a source stamp (<platform>.stamp: the sha256 over the pin file,
# native/CMakeLists.txt and every file under native/src, in path order).
# Prints NATIVE_BUILD_OK platform=<p> lib=<file> godot_cpp=<sha> api=<version> on success.
# Exit status: 0 ok; 1 build failure; 3 toolchain, Godot or godot-cpp checkout missing or wrong;
# 64 usage error. The first build compiles every godot-cpp binding (10 to 30 minutes on MSVC);
# later builds are incremental. On Windows run it from Git Bash (PowerShell's `bash` is WSL).
set -u

# shellcheck source=tools/_common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"

GODOT_CPP_URL="https://github.com/godotengine/godot-cpp.git"
PIN_FILE="${DUSKHOLD_ROOT}/tools/godot_cpp_pin.txt"
GODOT_CPP_DIR="${DUSKHOLD_ROOT}/.tools/godot-cpp"
NATIVE_DIR="${DUSKHOLD_ROOT}/native"
OUT_DIR="${DUSKHOLD_ROOT}/addons/duskhold_sim/bin"
API_DIR="${DUSKHOLD_ROOT}/build/native/api"

DO_FETCH=0
DO_CLEAN=0
for arg in "$@"; do
  case "${arg}" in
    --fetch) DO_FETCH=1 ;;
    --clean) DO_CLEAN=1 ;;
    *)
      echo "usage: bash tools/native_build.sh [--fetch] [--clean]" >&2
      exit 64
      ;;
  esac
done

fail_toolchain() {
  echo "NATIVE_BUILD_FAIL: $1" >&2
  exit 3
}

# --- platform ---------------------------------------------------------------------------------
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows"; LIB_EXT="dll" ;;
  Linux) PLATFORM="linux"; LIB_EXT="so" ;;
  *) fail_toolchain "unsupported host $(uname -s); the extension builds on Windows and Linux" ;;
esac
LIB_NAME="libduskhold_sim.${PLATFORM}.x86_64.${LIB_EXT}"
BUILD_DIR="${DUSKHOLD_ROOT}/build/native/${PLATFORM}"

# --- 1. the pin and the godot-cpp checkout -----------------------------------------------------
[ -f "${PIN_FILE}" ] || fail_toolchain "tools/godot_cpp_pin.txt is missing"
PIN="$(head -n 1 "${PIN_FILE}" | tr -d '\r\n')"
if ! printf '%s' "${PIN}" | grep -Eq '^[0-9a-f]{40}$'; then
  fail_toolchain "the first line of tools/godot_cpp_pin.txt is not a 40-character commit SHA"
fi

if [ "${DO_FETCH}" -eq 1 ]; then
  if [ ! -d "${GODOT_CPP_DIR}/.git" ]; then
    echo "native_build: cloning ${GODOT_CPP_URL} into .tools/godot-cpp"
    mkdir -p "${DUSKHOLD_ROOT}/.tools"
    git clone "${GODOT_CPP_URL}" "${GODOT_CPP_DIR}" || fail_toolchain "git clone of godot-cpp failed"
  fi
  if [ "$(git -C "${GODOT_CPP_DIR}" rev-parse HEAD 2>/dev/null)" != "${PIN}" ]; then
    git -C "${GODOT_CPP_DIR}" cat-file -e "${PIN}^{commit}" 2>/dev/null \
      || git -C "${GODOT_CPP_DIR}" fetch origin || fail_toolchain "git fetch of godot-cpp failed"
    git -C "${GODOT_CPP_DIR}" checkout --detach "${PIN}" || fail_toolchain "cannot check out ${PIN}"
  fi
fi

if [ ! -d "${GODOT_CPP_DIR}/.git" ]; then
  fail_toolchain "godot-cpp is not checked out at .tools/godot-cpp; run: bash tools/native_build.sh --fetch"
fi
ACTUAL_HEAD="$(git -C "${GODOT_CPP_DIR}" rev-parse HEAD 2>/dev/null)"
if [ "${ACTUAL_HEAD}" != "${PIN}" ]; then
  fail_toolchain "godot-cpp is at ${ACTUAL_HEAD}, the pin is ${PIN}; run: bash tools/native_build.sh --fetch"
fi

# --- 2. the API dumped from the pinned Godot binary --------------------------------------------
GODOT_BIN="$(duskhold_godot_bin)"
[ -f "${GODOT_BIN}" ] || fail_toolchain "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)"

# The dump goes to a scratch directory and replaces the files in API_DIR only when their content
# changed: rewriting identical files would make the binding generator regenerate and recompile
# every godot-cpp class, which is what makes a first build slow and a rebuild not.
DUMP_DIR="${DUSKHOLD_ROOT}/build/native/api-dump"
rm -rf "${DUMP_DIR}"
mkdir -p "${DUMP_DIR}" "${API_DIR}"
(cd "${DUMP_DIR}" && "${GODOT_BIN}" --headless --dump-extension-api --dump-gdextension-interface-json) \
  >"${DUMP_DIR}/dump.log" 2>&1
if [ ! -s "${DUMP_DIR}/extension_api.json" ] || [ ! -s "${DUMP_DIR}/gdextension_interface.json" ]; then
  tail -n 20 "${DUMP_DIR}/dump.log" >&2
  fail_toolchain "the Godot API dump produced no extension_api.json or gdextension_interface.json"
fi
for dumped in extension_api.json gdextension_interface.json; do
  if ! cmp -s "${DUMP_DIR}/${dumped}" "${API_DIR}/${dumped}"; then
    cp -f "${DUMP_DIR}/${dumped}" "${API_DIR}/${dumped}"
  fi
done

API_HEADER="$(head -n 12 "${API_DIR}/extension_api.json" | tr -d ' \t\r')"
api_field() {
  printf '%s\n' "${API_HEADER}" | sed -n "s/^\"$1\":\([0-9]*\),*\$/\1/p" | head -n 1
}
API_VERSION="$(api_field version_major).$(api_field version_minor).$(api_field version_patch)"
EXPECTED_API="${DUSKHOLD_GODOT_VERSION%-*}"
if [ "${API_VERSION}" != "${EXPECTED_API}" ]; then
  fail_toolchain "the dumped API reports ${API_VERSION}, tools/godot_version.txt pins ${EXPECTED_API}"
fi
if ! printf '%s\n' "${API_HEADER}" | grep -q '"precision":"single"'; then
  fail_toolchain "the dumped API is not single precision (real_t must be 4 bytes)"
fi
echo "native_build: API ${API_VERSION} single precision dumped from the pinned Godot binary"

# One-line comparison with the API that godot-cpp bundles (informational, for the SUMMARY).
PYTHON=""
for candidate in python python3; do
  if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" -c 'import sys' >/dev/null 2>&1; then
    PYTHON="${candidate}"
    break
  fi
done
BUNDLED_API="${GODOT_CPP_DIR}/gdextension/extension_api-4-7.json"
if [ -n "${PYTHON}" ] && [ -f "${BUNDLED_API}" ]; then
  cat >"${API_DIR}/api_diff.py" <<'PYEOF'
import json
import sys


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def index(doc):
    classes = {}
    for entry in doc.get("classes", []) + doc.get("builtin_classes", []):
        classes[entry["name"]] = {m["name"] for m in entry.get("methods", [])}
    return classes


bundled = load(sys.argv[1])
dumped = load(sys.argv[2])
b_header = bundled.pop("header")
d_header = dumped.pop("header")
label = "bundled %d.%d.%d, dumped %d.%d.%d" % (
    b_header["version_major"], b_header["version_minor"], b_header["version_patch"],
    d_header["version_major"], d_header["version_minor"], d_header["version_patch"],
)
if bundled == dumped:
    print("API diff: identical apart from the header (%s)" % label)
else:
    b_idx = index(bundled)
    d_idx = index(dumped)
    only_dumped = sorted(set(d_idx) - set(b_idx))
    only_bundled = sorted(set(b_idx) - set(d_idx))
    added = removed = 0
    for name in set(b_idx) & set(d_idx):
        added += len(d_idx[name] - b_idx[name])
        removed += len(b_idx[name] - d_idx[name])
    print(
        "API diff (%s): classes only in dumped %d, only in bundled %d; methods only in dumped %d, "
        "only in bundled %d" % (label, len(only_dumped), len(only_bundled), added, removed)
    )
PYEOF
  "${PYTHON}" -I "${API_DIR}/api_diff.py" "${BUNDLED_API}" "${API_DIR}/extension_api.json" \
    || echo "native_build: API diff failed (informational)"
else
  echo "native_build: API diff skipped (no python or no bundled extension_api-4-7.json)"
fi

# --- 3. configure ------------------------------------------------------------------------------
if [ "${DO_CLEAN}" -eq 1 ]; then
  rm -rf "${BUILD_DIR}"
fi
mkdir -p "${BUILD_DIR}"

if [ "${PLATFORM}" = "windows" ]; then
  VSWHERE="C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
  VS_ROOT=""
  if [ -f "${VSWHERE}" ]; then
    VS_ROOT="$("${VSWHERE}" -products '*' -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
      -property installationPath 2>/dev/null | tr -d '\r' | head -n 1)"
  fi
  if [ -z "${VS_ROOT}" ]; then
    VS_ROOT="C:/Program Files (x86)/Microsoft Visual Studio/18/BuildTools"
  fi
  VCVARS="$(cygpath -u "${VS_ROOT}")/VC/Auxiliary/Build/vcvars64.bat"
  [ -f "${VCVARS}" ] || fail_toolchain "vcvars64.bat not found under ${VS_ROOT}; the MSVC toolset of Visual Studio Build Tools is required"

  BAT="${BUILD_DIR}/build.bat"
  {
    printf '%s\r\n' '@echo off'
    printf '%s\r\n' "call \"$(cygpath -w "${VCVARS}")\" >nul"
    printf '%s\r\n' 'if errorlevel 1 exit /b 3'
    printf '%s\r\n' 'if "%1"=="configure" goto configure'
    printf '%s\r\n' 'if "%1"=="build" goto build'
    printf '%s\r\n' 'if "%1"=="dumpbin" goto dumpbin'
    printf '%s\r\n' 'exit /b 64'
    printf '%s\r\n' ':configure'
    printf '%s\r\n' "cmake -S \"$(cygpath -m "${NATIVE_DIR}")\" -B \"$(cygpath -m "${BUILD_DIR}")\" -G Ninja -DCMAKE_BUILD_TYPE=Release \"-DGODOT_CPP_DIR=$(cygpath -m "${GODOT_CPP_DIR}")\" \"-DDUSKHOLD_API_DIR=$(cygpath -m "${API_DIR}")\" -DDUSKHOLD_PIN=${PIN} -DDUSKHOLD_API_VERSION=${API_VERSION} -DDUSKHOLD_PLATFORM=${PLATFORM}"
    printf '%s\r\n' 'exit /b %errorlevel%'
    printf '%s\r\n' ':build'
    printf '%s\r\n' "cmake --build \"$(cygpath -m "${BUILD_DIR}")\""
    printf '%s\r\n' 'exit /b %errorlevel%'
    printf '%s\r\n' ':dumpbin'
    printf '%s\r\n' "dumpbin /dependents \"$(cygpath -w "${BUILD_DIR}/out/${LIB_NAME}")\""
    printf '%s\r\n' 'exit /b %errorlevel%'
  } >"${BAT}"
  run_step() {
    cmd //c "$(cygpath -w "${BAT}")" "$1"
  }
else
  command -v cmake >/dev/null 2>&1 || fail_toolchain "cmake is not on PATH"
  command -v g++ >/dev/null 2>&1 || fail_toolchain "g++ is not on PATH"
  GENERATOR=()
  if command -v ninja >/dev/null 2>&1; then
    GENERATOR=(-G Ninja)
  fi
  run_step() {
    case "$1" in
      configure)
        cmake -S "${NATIVE_DIR}" -B "${BUILD_DIR}" ${GENERATOR[@]+"${GENERATOR[@]}"} -DCMAKE_BUILD_TYPE=Release \
          "-DGODOT_CPP_DIR=${GODOT_CPP_DIR}" "-DDUSKHOLD_API_DIR=${API_DIR}" \
          "-DDUSKHOLD_PIN=${PIN}" "-DDUSKHOLD_API_VERSION=${API_VERSION}" \
          "-DDUSKHOLD_PLATFORM=${PLATFORM}"
        ;;
      # Parallel jobs by hand: without Ninja the generator is Unix Makefiles, which builds one file at a
      # time unless told otherwise, and the first build compiles every godot-cpp binding.
      build) cmake --build "${BUILD_DIR}" --parallel "$(nproc 2>/dev/null || echo 2)" ;;
      dumpbin) return 0 ;;
    esac
  }
fi

echo "native_build: configuring (${PLATFORM}, Release)"
if ! run_step configure; then
  echo "NATIVE_BUILD_FAIL: cmake configure failed" >&2
  exit 1
fi

# --- 4. the floating-point switches in the compile commands -----------------------------------
COMPILE_COMMANDS="${BUILD_DIR}/compile_commands.json"
[ -f "${COMPILE_COMMANDS}" ] || { echo "NATIVE_BUILD_FAIL: ${COMPILE_COMMANDS} was not written" >&2; exit 1; }
FORBIDDEN_SWITCHES='/fp:fast|/fp:contract|-ffast-math|-Ofast|-funsafe-math-optimizations|-ffinite-math-only|-fassociative-math|-freciprocal-math|-ffp-contract=(fast|on)|-mfma|-mavx|/arch:AVX|-march=|-mtune=|-mcpu=|-mf16c'
if grep -Eq -- "${FORBIDDEN_SWITCHES}" "${COMPILE_COMMANDS}"; then
  echo "NATIVE_BUILD_FAIL: compile_commands.json carries a forbidden floating-point or architecture switch:" >&2
  grep -Eo -- "${FORBIDDEN_SWITCHES}" "${COMPILE_COMMANDS}" | sort | uniq -c >&2
  exit 1
fi
if ! grep -Eq -- '/fp:precise|-ffp-contract=off' "${COMPILE_COMMANDS}"; then
  echo "NATIVE_BUILD_FAIL: compile_commands.json names neither /fp:precise nor -ffp-contract=off" >&2
  exit 1
fi
echo "native_build: compile commands are clean (precise floating point, no FMA, fast-math or AVX switch)"

# --- 5. build ----------------------------------------------------------------------------------
echo "native_build: building (the first build compiles every godot-cpp binding and is slow)"
if ! run_step build; then
  echo "NATIVE_BUILD_FAIL: cmake build failed" >&2
  exit 1
fi
if [ ! -f "${BUILD_DIR}/out/${LIB_NAME}" ]; then
  echo "NATIVE_BUILD_FAIL: ${BUILD_DIR}/out/${LIB_NAME} was not produced" >&2
  exit 1
fi

# --- 6. static runtime (Windows) ---------------------------------------------------------------
if [ "${PLATFORM}" = "windows" ]; then
  DEPENDENTS="$(run_step dumpbin 2>&1 | tr -d '\r')"
  printf '%s\n' "${DEPENDENTS}" >"${BUILD_DIR}/dependents.txt"
  if printf '%s\n' "${DEPENDENTS}" | grep -Eiq 'VCRUNTIME|MSVCP|MSVCR|CONCRT'; then
    echo "NATIVE_BUILD_FAIL: the DLL imports a Visual C++ runtime library (it must link the static runtime):" >&2
    printf '%s\n' "${DEPENDENTS}" | grep -Ei 'VCRUNTIME|MSVCP|MSVCR|CONCRT' >&2
    exit 1
  fi
  echo "native_build: dumpbin /dependents lists no VCRUNTIME or MSVCP library"
fi

# --- 7. install the library and the source stamp ----------------------------------------------
mkdir -p "${OUT_DIR}"
cp -f "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}/${LIB_NAME}"
# The stamp comes from the shared function in tools/_common.sh, the same one the guard checks with.
duskhold_native_stamp >"${OUT_DIR}/${PLATFORM}.stamp"

echo "NATIVE_BUILD_OK platform=${PLATFORM} lib=${LIB_NAME} godot_cpp=${PIN} api=${API_VERSION}"
