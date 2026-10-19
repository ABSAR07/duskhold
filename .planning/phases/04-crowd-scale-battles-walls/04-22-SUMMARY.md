---
phase: 04-crowd-scale-battles-walls
plan: 22
subsystem: infra
tags: [gdextension, native, bash, export, boot-guard, stamp]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-14 native library, the source stamp format and the NativeSim class
provides:
  - "tools/_common.sh: duskhold_native_stamp (the one stamp implementation), duskhold_native_lib, duskhold_require_native, duskhold_native_host_platform, duskhold_seed_extension_list"
  - "Seven wrappers (test, replay, gate_stress, stress, playtest, screenshot, export) that exit 3 with 'native library missing or stale: run bash tools/native_build.sh'"
  - "tools/export.sh fails unless libduskhold_sim.windows.x86_64.dll sits next to Duskhold.exe; export_presets.cfg excludes native/*"
  - "MapRoot boot guard: no NativeSim class means push_error plus quit(1), no fallback"
affects: [04-15, 04-16, 04-17, 04-18, 04-19, 04-20, 04-21, 04-23]

actuals:
  tokens: 3200
  tasks: 2
  commits: 2

plan_head_before: b569621745a832be4c6af94f3b64b83783e504d6
plan_head_after: f1183cc23aa8022efbadca5888ef6964a7b5c903

tech-stack:
  added: []
  patterns:
    - "One stamp function sourced by both the writer (native_build.sh) and the checker (duskhold_require_native), so the two cannot drift"
    - "Guard line right after the Godot binary check in every wrapper except tools/godot.sh (native_build.sh dumps the API through it)"
    - "Export checks the windows library whatever the host (CI exports the Windows preset from Linux)"

key-files:
  created: []
  modified:
    - tools/_common.sh
    - tools/native_build.sh
    - tools/test.sh
    - tools/replay.sh
    - tools/gate_stress.sh
    - tools/stress.sh
    - tools/playtest.sh
    - tools/screenshot.sh
    - tools/export.sh
    - presentation/map/map_root.gd
    - export_presets.cfg

key-decisions:
  - "Probe rule (i) from 04-14 holds, so no second import pass; instead every wrapper pre-seeds .godot/extension_list.cfg (one line) before its import pass when the file is absent"
  - "The shared stamp reproduces the 04-14 value exactly (dbe427d3...), so the stamp format did not change"
  - "duskhold_require_native returns 3 for an unknown platform name as well as for a missing or stale library"
  - "The boot guard is one ClassDB.class_exists(&\"NativeSim\") check, no fallback"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "A missing or stale library is a hard named error in the seven wrappers (exit 3) and the one stamp function is shared by writer and checker"
    requirement: "PLAT-01"
    verification:
      - kind: other
        ref: "bash -c 'source tools/_common.sh && duskhold_require_native' rc 0; with a corrupted windows.stamp, test.sh, replay.sh, gate_stress.sh, playtest.sh, stress.sh, screenshot.sh and export.sh all exit 3 with the one-line message; unknown platform rc 3; stamp equals native_build.sh output"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Windows export carries the DLL next to Duskhold.exe, excludes native/*, launches and quits inside 90 s, and the boot guard quits 1 when the DLL is removed"
    requirement: "PLAT-01"
    verification:
      - kind: other
        ref: "bash tools/export.sh (Export OK, DLL present, 31 s); timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 rc 0 (8 s); same build with the DLL moved away: push_error plus rc 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every digest is unchanged: smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569, gate e448ffdb"
    requirement: "PLAT-01"
    verification:
      - kind: other
        ref: "bash tools/replay.sh (four scenarios) and bash tools/gate_stress.sh --twice, run after both tasks"
        status: pass
    human_judgment: false

duration: 49min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 22: Native Library Guard Summary

**One shared sha256 source stamp (`duskhold_native_stamp`) written by native_build.sh and checked by `duskhold_require_native` in seven wrappers (exit 3, names `bash tools/native_build.sh`), an export that must carry the Windows DLL and excludes `native/*`, and a MapRoot boot guard that quits 1 without NativeSim; every digest unchanged.**

## Performance

- **Duration:** 49 min (dispatch 2026-10-19T11:17:40Z to 2026-10-19T12:06:27Z; two full-suite runs account for about 25 min)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 11

## Accomplishments

- tools/_common.sh now holds the stamp, library path, guard and extension-list seeding helpers; native_build.sh writes `<platform>.stamp` through `duskhold_native_stamp`. The value is byte-identical to 04-14's (`dbe427d32d91cd1b34546bb3fda86f79833ec441e7222f3ae903d96158193841`), so nothing about the stamp format moved.
- test, replay, gate_stress, stress, playtest, screenshot and export call `duskhold_require_native` straight after the Godot binary check (export passes `windows` whatever the host). tools/godot.sh is untouched. Exit codes and usage texts are unchanged; the new failure is exit 3.
- tools/export.sh removes a stale DLL before exporting and fails unless `build/windows/libduskhold_sim.windows.x86_64.dll` (294912 bytes) exists beside Duskhold.exe; export_presets.cfg excludes `native/*`. The export log has no `native/` line and the pck holds no native source path.
- MapRoot `_ready` quits the tree with 1 and a push_error naming the build command when `ClassDB.class_exists(&"NativeSim")` is false. Exercised for real: the exported build with the DLL moved away printed the GDExtension load errors plus `NativeSim missing: the native library did not load; run bash tools/native_build.sh` and exited 1; with the DLL back it exited 0.
- Probe-rule note: 04-14 recorded rule (i), so the rule-(ii) second import pass was skipped. For the first-import exit 139 hazard (minimal probe project only), all seven import passes are preceded by `duskhold_seed_extension_list`, which writes the single line `res://addons/duskhold_sim/duskhold_sim.gdextension` to `.godot/extension_list.cfg` when the file is absent. The hazard never showed in the real project: with the list deleted, `bash tools/replay.sh --scenario=smoke` imported, exited 0 and regenerated the one-line list.

## Task Commits

1. **Task 1 (tracer): shared stamp, duskhold_require_native, test.sh and replay.sh** - `398b266` (feat)
2. **Task 2: other wrappers, export DLL check and exclusion, boot guard** - `f1183cc` (feat)

## Verification results

- Task 1 verify chain, all green after a clean rebuild (native_build.sh took 25 s, incremental): guard accepts the fresh library (rc 0), refuses `nosuchplatform` and `linux` (rc 3), `duskhold_native_stamp` equals `windows.stamp`, `test_native_extension` 5/5, four replays and the gate exact, lint clean.
- Staleness check: with `windows.stamp` overwritten, test.sh and replay.sh, then (in Task 2) gate_stress.sh, playtest.sh, stress.sh, screenshot.sh and export.sh each exited 3 with the one-line message; the stamp was restored afterwards.
- Task 2 verify chain, all green: export (31 s) with the DLL, launch check rc 0 in 8 s, `grep -l duskhold_require_native tools/*.sh` lists 8 files (_common.sh plus the seven wrappers), `bash tools/screenshot.sh day_overview` wrote a 86560-byte PNG, `test_native_extension` 5/5, lint clean.
- Digests after both tasks (run after the full suite): smoke 2599c7c2 (703 ticks, matches tests/golden), army f7a967ed (1353), walls bfb05fc7 (1961), full_idle 4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf (6911), `GATE_OK enemies=300 crossed=300 stuck=0 ... digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`.
- Full suite, run twice: 196 scripts, 1830 tests, all passing, exit 0; asserts 30307 in the first run and 30296 in the second (04-14 recorded 30238). Scripts and tests match the baseline exactly. The assert total moves between identical runs of the same tree, so the 04-14 figure is not a regression marker for this metric; I did not chase which test varies.

## Deviations from Plan

None - plan executed exactly as written. (The plan's rule-(ii) branches were skipped because 04-14 recorded rule (i); the extension-list seeding is the hazard handling the dispatch brief asked for.)

## Issues Encountered

- A first attempt to run the Task 1 verify chain in a nested `&` background subshell kept running after its wrapper returned and clashed with the clean re-run (it deleted `build/replay/replay.log` under it). I stopped only the process IDs I had started, confirmed no Godot or replay process was left, and re-ran the whole chain in one foreground call; the results above are from that clean run.

## Known Stubs

None.

## Threat Flags

None. T-04-37 (stale library) and T-04-58 (native sources in the export) are mitigated as planned.

## Notes for the next plans

- After this plan the CI jobs refuse to run without a library: ci.yml is untouched and plan 04-16 supplies the Linux build before the next push (expected, as the plan states). The export check demands `windows.stamp` and the Windows DLL even on Linux CI, so 04-16 must also deliver those.
- Any native source edit makes the stamp stale: run `bash tools/native_build.sh` (about 25 to 40 s incremental) before test.sh or replay.sh.

## Self-Check: PASSED

- Modified files exist: tools/_common.sh, tools/native_build.sh, tools/test.sh, tools/replay.sh, tools/gate_stress.sh, tools/stress.sh, tools/playtest.sh, tools/screenshot.sh, tools/export.sh, presentation/map/map_root.gd, export_presets.cfg (all tracked, diff stat 11 files).
- Commits found in git log: 398b266, f1183cc; `git rev-list --count b569621..HEAD` = 2.
