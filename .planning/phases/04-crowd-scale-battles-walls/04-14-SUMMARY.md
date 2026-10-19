---
phase: 04-crowd-scale-battles-walls
plan: 14
subsystem: infra
tags: [godot-cpp, gdextension, cmake, msvc, ninja, native, determinism, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-12 baseline (replay goldens, gate digest, suite totals) and the owner's PLAT-01 route of 2026-10-19
provides:
  - "tools/native_build.sh: the one build entry point for the native library (local and CI), pinned, with flag, runtime and stamp checks"
  - "tools/godot_cpp_pin.txt: godot-cpp pinned to one full commit SHA"
  - "native/: CMake build and the NativeSim class (version, godot_cpp_pin, api_version, real_t_bytes) loading in headless Godot 4.7.2"
  - "addons/duskhold_sim/duskhold_sim.gdextension (library git-ignored)"
  - "test_native_extension and test_native_rules_guard (the C++ determinism gate)"
  - "godot-cpp attribution (ASSETS.md and assets/attribution.json)"
  - "The recorded rule for how GDScript may name native classes: rule (i)"
affects: [04-15, 04-16, 04-17, 04-18, 04-19, 04-20, 04-21, 04-22, 04-23]

actuals:
  tokens: 36000
  tasks: 2
  commits: 2

plan_head_before: 9fedd60105d059d7387fc0c540cfafc3522b8325
plan_head_after: da112270849e3a00b6777a24844b8a281d38c715

tech-stack:
  added: [godot-cpp (pinned commit 2bb1acf, MIT, fetched to .tools/, never committed), CMake 4.2.3 and Ninja 1.13.2 from VS Build Tools 2026 (already on the machine), MSVC 19.51.36246]
  patterns:
    - "Native build: API dumped from the pinned Godot binary, godot-cpp as a CMake subdirectory, /fp:precise or -ffp-contract=off on the extension target only, static MSVC runtime"
    - "C++ determinism guard: table of [label, regex, offending sample], comments not exempt, build files checked for the precise floating-point model"

key-files:
  created:
    - tools/native_build.sh
    - tools/godot_cpp_pin.txt
    - native/CMakeLists.txt
    - native/.gdignore
    - native/src/register_types.h
    - native/src/register_types.cpp
    - native/src/native_sim.h
    - native/src/native_sim.cpp
    - addons/duskhold_sim/duskhold_sim.gdextension
    - addons/duskhold_sim/duskhold_sim.gdextension.uid
    - tests/unit/test_native_extension.gd
    - tests/unit/test_native_rules_guard.gd
  modified:
    - .gitignore
    - ASSETS.md
    - assets/attribution.json

key-decisions:
  - "godot-cpp pinned to master commit 2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec (2026-10-16): no godot-4.6 or godot-4.7 tag exists (newest tag godot-4.5-stable); the build uses the API dumped from the 4.7.2 binary, which differs from the bundled 4.7.0 API only in the header"
  - "Fresh-project probe settles rule (i): a native class name is usable as a GDScript type once the extension is in place; no second import pass is needed"
  - "One template_release library per platform serves the editor binary and the export (the editor loaded it without complaint, so no template_debug variant was added)"
  - "The attribution entry godot-cpp covers res://addons/duskhold_sim/ (the folder the library is built into); test_attribution_log needed no change"

requirements-completed: []

coverage:
  - id: D1
    description: "NativeSim built from source with MSVC against the pinned godot-cpp and the API dumped from Godot 4.7.2 loads in headless Godot and answers version, pin, API 4.7.2 and a 4-byte real_t"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_native_extension.gd (5 tests, all pass)"
        status: pass
      - kind: other
        ref: "bash tools/native_build.sh --fetch -> NATIVE_BUILD_OK platform=windows ... api=4.7.2"
        status: pass
    human_judgment: false
  - id: D2
    description: "tools/native_build.sh refuses a wrong godot-cpp HEAD, forbidden compile switches and a dynamic MSVC runtime, writes the source stamp and prints NATIVE_BUILD_OK"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "build/native/build1.log and build4.log: compile commands clean, dumpbin lists only KERNEL32.dll, stamp written"
        status: pass
    human_judgment: false
  - id: D3
    description: "C++ determinism guard over native/src and native/CMakeLists.txt, each pattern proven on an offending sample"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_native_rules_guard.gd (10 tests, all pass; 4 native sources scanned; mutation probe failed 2 tests as intended)"
        status: pass
    human_judgment: false
  - id: D4
    description: "godot-cpp (MIT) logged in ASSETS.md and attribution.json"
    verification:
      - kind: unit
        ref: "tests/unit/test_attribution_log.gd (17 tests, all pass)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No simulation change: smoke, army, walls, full_idle replays and the gate stress digest are byte-identical"
    verification:
      - kind: integration
        ref: "tools/replay.sh x4 --twice and tools/gate_stress.sh --twice (digests below)"
        status: pass
    human_judgment: false

duration: 89min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 14: Native Extension Scaffold Summary

**A pinned godot-cpp, a CMake/MSVC build (tools/native_build.sh), a NativeSim GDExtension that loads in headless Godot 4.7.2 and a C++ determinism guard, with no simulation change and every digest unchanged.**

## Performance

- **Duration:** about 89 min (the first full godot-cpp build was about 20 min, later builds 38 s)
- **Started:** 2026-10-19T09:46:00Z (approximate; first command of the run)
- **Completed:** 2026-10-19T11:15:00Z
- **Tasks:** 2
- **Files modified:** 15 (12 created, 3 modified)

## Accomplishments

- `tools/native_build.sh [--fetch] [--clean]`: checks the godot-cpp checkout is at the pin, dumps `extension_api.json` and `gdextension_interface.json` from the pinned Godot binary (refusing anything but 4.7.2 single precision), configures with Ninja under the MSVC toolset found with vswhere (Linux: GCC, Ninja when present), fails on any fast-math, FMA, AVX or host-tuned switch in `compile_commands.json`, builds, checks `dumpbin /dependents` (only KERNEL32.dll), copies the DLL to `addons/duskhold_sim/bin/` with `windows.stamp` and prints `NATIVE_BUILD_OK`.
- `NativeSim` (RefCounted, static methods `version()`, `godot_cpp_pin()`, `api_version()`, `real_t_bytes()`) registered at the scene level; the `.gdextension` maps the Windows DLL and Linux .so; `.gitignore` gains `/addons/duskhold_sim/bin/` and `/native/bin/`. No built binary is tracked.
- `test_native_extension` (5 tests) and `test_native_rules_guard` (10 tests) added; godot-cpp logged in ASSETS.md and attribution.json.

## Pin evidence

`git ls-remote https://github.com/godotengine/godot-cpp.git` (official godotengine organisation) showed:

```
2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec  HEAD
2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec  refs/heads/master
27d9dd23c83871e0619fca5dc2cddfbfd69e926a  refs/heads/4.5
e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77  refs/tags/godot-4.5-stable   (newest tag; no 4.6 or 4.7 tag)
```

Chosen: master `2bb1acf6...` (merge of PR #2068, 2026-10-16), whose bundled `gdextension/extension_api-4-7.json` header reports 4.7.0 stable. API diff line printed by the build: `API diff: identical apart from the header (bundled 4.7.0, dumped 4.7.2)`. The build nevertheless uses the API dumped from the 4.7.2 binary.

## Fresh-project probe: rule (i)

Probe project `build/native-probe/`: a `ProbeUser` class with `var sim: NativeSim = null` and `NativeSim.version()`, plus a SceneTree script. With no `.godot/` present, the first `--headless --path build/native-probe --import` logged no Parse Error and no ERROR line (global class `ProbeUser` registered), and the next run printed `NATIVE_PROBE_OK duskhold-native-0.1`. **Rule (i): a native class name is usable as a GDScript type (field type and static call) when the extension is in place and the first import logs no Parse Error; no second import pass is needed.** Plans 04-22 to 04-23 follow rule (i).

Caveat that plan 04-22 must handle: in the minimal probe project the first import (no `.godot/extension_list.cfg`) exits 139 (segmentation fault) at editor teardown, after "EditorSettings: Save OK!" and after everything is written; reproduced 5 of 5 times. The same import with `.godot/extension_list.cfg` pre-seeded (one line, `res://addons/duskhold_sim/duskhold_sim.gdextension`) or run a second time exits 0. The no-extension probe exits 0. The real project did not reproduce it: with extension_list.cfg deleted, and with `.godot/` moved away entirely, `--import` exited 0 with no Parse Error. The cause was not isolated (an editor-target library variant was considered and not built). Wrappers that treat a non-zero import exit as failure could trip on this in a project shaped like the probe, so 04-22 should either pre-seed the list or retry the import once.

## Task Commits

1. **Task 1: tracer, NativeSim built from pinned godot-cpp loads and answers** - `0f4dd57` (feat)
2. **Task 2: C++ determinism guard and godot-cpp attribution** - `da11227` (test)

**Plan metadata:** committed with this SUMMARY (docs).

## Verification results

- `bash tools/native_build.sh --fetch`: `NATIVE_BUILD_OK platform=windows lib=libduskhold_sim.windows.x86_64.dll godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2`; source stamp `dbe427d32d91cd1b34546bb3fda86f79833ec441e7222f3ae903d96158193841`.
- Replays (all `--twice`): smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all against their goldens), full_idle `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` 6911. Gate: `GATE_OK enemies=300 crossed=300 stuck=0 ... digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. All unchanged.
- Full suite (`bash tools/test.sh`): 196 scripts, 1830 tests, 30238 asserts, all passing, exit 0 (baseline 194 / 1815 / 30118). Lint clean.
- Mutation probe: a commented `std::pow` in native_sim.cpp and `-mfma` in CMakeLists.txt made test_native_rules_guard fail 2 tests; both files restored and the guard passes again.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] A rebuild recompiled all of godot-cpp**
- **Found during:** Task 1 (second run of the build script)
- **Issue:** the script deleted and re-dumped `build/native/api/` on every run; the new file timestamps made the binding generator regenerate and recompile all 1095 objects (about 20 min).
- **Fix:** dump into `build/native/api-dump/` and replace the files in `build/native/api/` only when `cmp` finds a difference. A rebuild now takes 38 s (`ninja: no work to do`).
- **Files modified:** tools/native_build.sh
- **Committed in:** 0f4dd57

**2. [Rule 1 - Bug] Lint line-length finding in the guard test**
- **Found during:** Task 1 verify (lint ran over the not yet committed Task 2 file)
- **Fix:** split the float-pragma regex over two lines; lint clean.
- **Committed in:** da11227

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug). **Impact on plan:** none on scope.

### Plan conformance notes (not deviations)

- godot-cpp master bundles a JSON interface file (`gdextension_interface.json`); the build points `GODOTCPP_GDEXTENSION_DIR` at the dump from the 4.7.2 binary together with `GODOTCPP_CUSTOM_API_FILE`, as the plan's port decisions allow.
- Running the real project's `--import` directly (twice, to test the first-import crash) was a read-only probe of the git-ignored `.godot/` cache; `.godot/` was restored.

## Issues Encountered

- CI (not touched here) has no library: `addons/duskhold_sim/bin/` is git-ignored, so `test_native_extension` fails on a fresh checkout until plan 04-16 decides where binaries come from and 04-22 adds the hard guards. Nothing was pushed.
- Godot prints a harmless `'vswhere.exe' is not recognized` line from vcvars64.bat inside the generated build.bat; the build is unaffected.
- godot-cpp creates an empty `native/bin/` directory (its PDB output path); it is git-ignored.

## Known Stubs

None. NativeSim only reports its build identity; the enemy and wall step arrives in later plans.

## Threat Flags

None beyond the plan's register (T-04-34 pin refused on mismatch, T-04-35 guard bans OS/Time/Engine singletons and the build uses warnings as errors, T-04-36 precise model required and fast-math/FMA/AVX refused in compile_commands.json and by the guard).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for plan 04-15. The owner's one-way decision on where the binaries come from (CI build, cross-compile or LFS) is asked at the start of plan 04-16. Plan 04-22 should read the probe heading above (rule (i) plus the first-import exit 139 caveat) and the `<platform>.stamp` format (sha256 over the sha256 lines of tools/godot_cpp_pin.txt, native/CMakeLists.txt and every file under native/src in `LC_ALL=C` path order, CR stripped).

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

All created files exist on disk; commits 0f4dd57 and da11227 exist; native_build.sh, the four replays, the gate, the full suite and lint were re-run after the last code change.
