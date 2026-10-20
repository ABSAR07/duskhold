---
phase: 04-crowd-scale-battles-walls
plan: 24
subsystem: infra
tags: [gdextension, native, bash, stamp, sha256, profiling, view-ablation, bench, gap-closure]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-22 stamp contract (one shared stamp function, exit 3, the message text), plan 04-21 scratch view ablation and the frame report slice table
provides:
  - "tools/_common.sh: duskhold_native_stamp_for (two-line stamp: source stamp, then the library sha256) and duskhold_native_install (stamp removed first, copy checked by status and cmp, stamp written last through a temp file); duskhold_require_native recomputes both lines"
  - "tools/native_build.sh installs through the checked copy and exits 1 without a stamp on failure; the API-file copy is checked too"
  - "tools/native_stamp_probe.sh: seven hermetic refusal cases, NATIVE_STAMP_PROBE_OK cases=7"
  - "tools/stress/view_fill_bench.gd: headless per-view _process cost on the stress shape (arrows, enemies, units, puffs), one VIEW_FILL_BENCH line"
  - "tools/stress/view_ablation.gd: plan 04-21's real-window ablation, committed and rerunnable (ABLATION_SLICE, ABLATION_SAVED, VIEW_ABLATION_OK)"
  - "The before-any-port baseline (twelve bench lines, one two-trial ablation) recorded below for plan 04-28 to quote"
affects: [04-25, 04-26, 04-27, 04-28]

actuals:
  tokens: 8000
  tasks: 3
  commits: 3

plan_head_before: dc1cd80d738592bcab9c95da0ffd8f5cc96dc350
plan_head_after: 7a5488aee3c3321f14218a72b8881a352085cf48

tech-stack:
  added: []
  patterns:
    - "The stamp binds the sources AND the installed library bytes; writer (duskhold_native_install) and checker (duskhold_require_native) share duskhold_native_stamp_for"
    - "Install = remove stamp, checked copy (status + cmp), write stamp last: a failed copy can never leave a valid-looking stamp"
    - "Hermetic shell probe: DUSKHOLD_NATIVE_BIN_DIR pointed at mktemp -d after sourcing _common.sh, fake libraries, trap cleanup"
    - "Tools probes keep their arithmetic in static functions (slice_at, views_on, saved_of, check_duration, parse_args) so GUT tests run without a window"
    - "Ablation records each frame delta under the slice that was running during the previous frame, then switches"

key-files:
  created:
    - tools/native_stamp_probe.sh
    - tools/stress/view_fill_bench.gd
    - tools/stress/view_ablation.gd
    - tests/unit/test_view_fill_bench_args.gd
    - tests/unit/test_view_ablation.gd
  modified:
    - tools/_common.sh
    - tools/native_build.sh
    - .github/workflows/ci.yml

key-decisions:
  - "No global set -e in native_build.sh (Flagged Assumption): both copies CR-01 names are checked individually"
  - "The ablation attributes a frame's delta to the slice active while that frame ran (the delta is the previous frame's cost) and applies the next slice after recording; the first frame after the warm-up is not recorded, exactly as StressNight does"
  - "ABLATION_SAVED is the median over trials of (that trial's all_on mean minus the slice mean); for two trials that is the mean of the two gains"

requirements-completed: []

coverage:
  - id: D1
    description: "A failed, changed, swapped, one-line or missing native library/stamp can no longer pass the guard: the real build writes a two-line stamp bound to the DLL, a DLL with one byte appended makes replay.sh exit 3, the restored DLL passes"
    verification:
      - kind: integration
        ref: "bash tools/native_build.sh; windows.stamp has 2 lines, line 2 = DLL sha256; smoke+army replays REPLAY_OK against goldens; appended-byte DLL -> replay.sh exit 3 'native library missing or stale: run bash tools/native_build.sh'; restored -> duskhold_require_native rc 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "tools/native_stamp_probe.sh proves seven refusal cases hermetically without touching the installed library"
    verification:
      - kind: other
        ref: "bash tools/native_stamp_probe.sh -> NATIVE_STAMP_PROBE_OK cases=7 (7 case lines ok); installed DLL sha256 identical before and after"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two instruments exist, parse only allowlisted arguments and produce their lines; the baseline before any port is recorded"
    verification:
      - kind: unit
        ref: "tests/unit/test_view_fill_bench_args.gd (8 tests), tests/unit/test_view_ablation.gd (5 tests)"
        status: pass
      - kind: other
        ref: "build/bench/baseline.txt (12 VIEW_FILL_BENCH lines); build/stress/ablation/ablation.txt (12 ABLATION_SLICE, 4 ABLATION_SAVED, VIEW_ABLATION_OK trials=2 slice_s=5)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Nothing the round is measured against moved: four replays, gate digest, BUDGET_P95_MS, stress night, map, data"
    verification:
      - kind: integration
        ref: "REPLAY_OK smoke 2599c7c2 / army f7a967ed / walls bfb05fc7 / full_idle 4385f569 (twice); GATE_OK enemies=300 crossed=300 stuck=0 digest=e448ffdb; git diff c962bb7..HEAD empty for tools/stress/stress_night.gd, stress_map.tres, data/, frame_report.gd"
        status: pass
    human_judgment: false

duration: 31min
completed: 2026-10-20
status: complete
---

# Phase 4 Plan 24: Stamp bound to the library bytes, and the round's two instruments Summary

**The native stamp now binds the installed library's sha256 (review CR-01 closed: a failed copy leaves no stamp, a changed or swapped DLL exits 3 in every wrapper), proven by a seven-case hermetic probe, and the view-layer port has its committed instruments, a headless per-view fill bench and the real-window view ablation, with the before-any-port baseline recorded.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-10-20T08:37:07Z
- **Completed:** 2026-10-20T09:08:00Z
- **Tasks:** 3 (Task 1 tracer)
- **Files modified:** 12 (3 shell/CI files, 5 created GDScript/shell files plus 4 `.gd.uid`)

## Accomplishments

- **CR-01 closed.** `duskhold_native_install` removes `<platform>.stamp`, copies the built library, checks the copy by exit status and `cmp -s`, and only then writes the stamp (through a temp file and `mv -f`); on failure it prints `NATIVE_BUILD_FAIL: cannot install <name> (a Godot process may hold it open; close it and rebuild)` to stderr, returns 1 and leaves no stamp, and `native_build.sh` exits 1 before `NATIVE_BUILD_OK`. `duskhold_require_native` compares the whole stamp file (CR stripped) with `duskhold_native_stamp_for <lib>` (source stamp, then the library's sha256); the 04-22 message and return code 3 are unchanged. The step-2 API-file copy is now checked too (`fail_toolchain`).
- **Proven end to end and hermetically.** Real build: `windows.stamp` is two lines, line 2 `070a7ba4aa8d5719108a11675d58b5971273b18da4355d36368ab84ce6f26201` = the DLL's sha256; smoke and army replays pass; one byte appended to the DLL makes `bash tools/replay.sh --scenario=smoke` exit 3 with the stale message; the backup was copied back and `duskhold_require_native` returns 0 (DLL sha256 identical afterwards). `tools/native_stamp_probe.sh` prints seven `NATIVE_STAMP_PROBE_CASE <name> ok` lines (install_missing_source, install_ok, changed_library, swapped_library, one_line_stamp, missing_library, missing_stamp) and `NATIVE_STAMP_PROBE_OK cases=7`, never touching `addons/duskhold_sim/bin`.
- **CI comment corrected** (comment lines only): the stamp binds the sources and the installed library's sha256 and rides with the library between jobs.
- **Two instruments committed with tests**, local only and read-only on everything the round is measured against.

## Task Commits

1. **Task 1 (tracer): stamp bound to the library bytes** - `9ccc0d7` (fix; only `tools/_common.sh` and `tools/native_build.sh`)
2. **Task 2: hermetic stamp probe, checked API copy, CI comment** - `d888c74` (test)
3. **Task 3: fill bench and view ablation with tests** - `7a5488a` (feat)

**Plan metadata:** the docs commit that carries this file.

## Baseline before any port (for plan 04-28 to quote)

Taken on the unchanged views (HEAD `7a5488a`, no view file touched in this plan), native library fresh, nothing else running.

### Twelve VIEW_FILL_BENCH lines (headless, dummy renderer, script cost only, 1440 warm-up and 720 timed frames at 1/144 s; three runs per view)

```
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2785.27 p95_us=4477.00 max_us=35283.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2736.99 p95_us=4563.00 max_us=36658.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2353.61 p95_us=3739.00 max_us=7187.00 drawn_max=507
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=580.01 p95_us=744.00 max_us=2299.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=611.33 p95_us=786.00 max_us=1169.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=635.83 p95_us=1009.00 max_us=6791.00 drawn_max=300
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=177.25 p95_us=206.00 max_us=265.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=161.04 p95_us=188.00 max_us=270.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=187.48 p95_us=256.00 max_us=818.00 drawn_max=50
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=105.79 p95_us=125.00 max_us=166.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=97.76 p95_us=109.00 max_us=196.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=205.16 p95_us=257.00 max_us=9193.00 drawn_max=87
```

Reading notes for the port plans: the headless arrows bench fills 507 of the 512-arrow ring (the stress night in a window shows about 241 to 250 on screen), so its mean is a ceiling for the arrow loop, not a prediction of the 2.0 ms real-window share; compare the bench only against itself (same view, same arguments, before and after). The puffs bench is the spawn-plus-refresh pair on a warm ring of 87 standing puffs. The third puffs run (mean 205.16 us, max 9193 us) shows one slow outlier frame; use the median of the three runs.

### The view ablation (real window 1920x1080, vsync off, two 30 s trials after a 10 s warm-up, run once, nothing else running; whole `ablation.txt`)

```
ABLATION_SLICE trial=1 slice=all_on frames=659 p50_ms=7.14 p95_ms=12.39 mean_ms=7.59
ABLATION_SLICE trial=1 slice=enemy_views_off frames=842 p50_ms=5.56 p95_ms=9.09 mean_ms=5.94
ABLATION_SLICE trial=1 slice=unit_views_off frames=762 p50_ms=6.06 p95_ms=10.94 mean_ms=6.57
ABLATION_SLICE trial=1 slice=projectile_vfx_off frames=1047 p50_ms=4.55 p95_ms=7.58 mean_ms=4.77
ABLATION_SLICE trial=1 slice=all_off frames=1477 p50_ms=3.33 p95_ms=4.17 mean_ms=3.39
ABLATION_SLICE trial=1 slice=all_on_again frames=661 p50_ms=7.14 p95_ms=11.11 mean_ms=7.58
ABLATION_SLICE trial=2 slice=all_on frames=739 p50_ms=6.25 p95_ms=9.09 mean_ms=6.77
ABLATION_SLICE trial=2 slice=enemy_views_off frames=862 p50_ms=5.56 p95_ms=8.33 mean_ms=5.79
ABLATION_SLICE trial=2 slice=unit_views_off frames=719 p50_ms=6.25 p95_ms=10.74 mean_ms=6.95
ABLATION_SLICE trial=2 slice=projectile_vfx_off frames=938 p50_ms=5.00 p95_ms=8.33 mean_ms=5.33
ABLATION_SLICE trial=2 slice=all_off frames=1480 p50_ms=3.33 p95_ms=4.52 mean_ms=3.38
ABLATION_SLICE trial=2 slice=all_on_again frames=636 p50_ms=7.41 p95_ms=12.96 mean_ms=7.86
ABLATION_SAVED slice=enemy_views_off mean_ms=1.32
ABLATION_SAVED slice=unit_views_off mean_ms=0.42
ABLATION_SAVED slice=projectile_vfx_off mean_ms=2.13
ABLATION_SAVED slice=all_off mean_ms=3.80
VIEW_ABLATION_OK trials=2 slice_s=5
```

It reproduces 04-21's scratch table within the drift the report states: projectiles about 2.1 ms (04-21: 2.0), enemy views 1.3 (1.1), unit views 0.4 (0.5), all three off 3.8 (3.5) with a slice p95 of 4.17 and 4.52 ms (04-21: 4.55), all under the 8.0 ms budget. The all_on slices are noisy (p95 12.39 and 9.09 ms in the two trials; all_on_again 11.11 and 12.96), so a before/after of the full night needs the median-run p95 of plan 04-28's stress runs, not one ablation slice. The embedded stress night's own run line for this ablation run (run_9, 60 s, mixed slices) was `STRESS_RUN run=9 frames=10822 p50_ms=5.53 p95_ms=8.80 p99_ms=12.43 max_ms=23.85 enemies_min=300 units_min=50 arrows_min=241`; it is not a budget measurement (the views were switched off for a share of it).

## Files Created/Modified

- `tools/_common.sh` - `duskhold_native_stamp_for`, `duskhold_native_install`, `duskhold_require_native` over the two-line stamp; header block updated
- `tools/native_build.sh` - step 7 through `duskhold_native_install ... || exit 1`; step 2 API-file copy checked; header comment updated
- `tools/native_stamp_probe.sh` - the seven-case hermetic probe
- `.github/workflows/ci.yml` - header comment sentence only
- `tools/stress/view_fill_bench.gd` (+ `.gd.uid`) - the per-view fill bench
- `tools/stress/view_ablation.gd` (+ `.gd.uid`) - the committed real-window ablation
- `tests/unit/test_view_fill_bench_args.gd` (+ `.gd.uid`) - 8 tests on the allowlist
- `tests/unit/test_view_ablation.gd` (+ `.gd.uid`) - 5 tests on duration rule, slice clock, view plans and saved arithmetic

## Decisions Made

- No global `set -e` in `native_build.sh`; both unchecked copies named by CR-01 are checked individually (as the plan's Flagged Assumption says).
- The ablation attributes each frame's delta to the slice that was running during the previous frame and applies the next slice after recording it, so a slice's numbers are not mixed with the switch; the first frame after the warm-up is not recorded (StressNight's own rule), so the probe and StressNight accumulate the same measured time and the last slice always ends the frame before StressNight quits.
- The temp stamp file is `<platform>.stamp.tmp.<pid>` inside the destination, removed on any failure.

## Deviations from Plan

None - plan executed exactly as written.

(Not deviations, noted for the record: `bash tools/lint.sh --fix` reformatted the two new files once after the first lint run; the 100-character cap forced the bench's launch line onto two lines.)

## Issues Encountered

- **Full suite (run once on the final tree, 577.5 s):** 213 scripts, 1992 tests, 1991 passing, 1 failing, 34137 of 34142 asserts. The one failure was `tests/e2e/test_order_markers.gd::test_a_hovered_squad_never_changes_the_selected_squads_colour` (a mouse-driven e2e test: "the archers add theirs" got 0 and the hover alpha read 0). It is the known mouse e2e flake class from the baseline; nothing under `presentation/` changed in this plan, and the script reran 2 of 2 green in isolation (10 of 10 tests each time). Baseline was 1979 tests; this plan adds 13 (8 + 5). Lint clean (360 files).
- Three stale `~libduskhold_sim.windows.x86_64.dll~RF*.TMP` leftovers sit in the git-ignored `addons/duskhold_sim/bin/` (the exact CR-01 scenario); left in place, untracked, harmless.
- The first heredoc-based file write of the two GDScript files failed in the shell tool (quote parsing); the files were written with the Write tool instead. No effect on the result.

## Known Stubs

None.

## Threat Flags

None. The new surface is local tooling only (a shell probe in a temp directory, two export-excluded GDScript tools with allowlisted arguments and an `--out` restricted to `build/` by `StressNight.parse_args`). T-04-62, T-04-63 and T-04-64 are mitigated as the plan states; T-04-63's cross-job proof (Linux and Windows CI recomputing the same two lines) is plan 04-27's push.

## Next Phase Readiness

Ready for plan 04-25. The libraries are fresh with a two-line stamp, so every rebuild in 04-25 to 04-27 installs through the checked copy: a Godot process still holding the DLL now fails the build loudly (exit 1, no stamp) instead of passing the guard with stale code. Before each rebuild run `tasklist | grep -i godot` and stop only a process you started. The before numbers above are the only baseline for the port; the bench is the per-view check after each port, the ablation and plan 04-28's stress runs are the judges of the 8.0 ms budget (unchanged). `requirements-completed` stays `[]`: PLAT-01 is decided by plan 04-28 only.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-20*

## Self-Check: PASSED

- Files exist: tools/native_stamp_probe.sh, tools/stress/view_fill_bench.gd, tools/stress/view_ablation.gd, tests/unit/test_view_fill_bench_args.gd, tests/unit/test_view_ablation.gd (and their `.gd.uid`) all tracked at HEAD.
- Commits exist: 9ccc0d7, d888c74, 7a5488a (`git log --grep="04-24"` returns all three); `git rev-list --count dc1cd80..7a5488a` = 3.
- Task 1 commit lists only tools/_common.sh and tools/native_build.sh; ci.yml diff since c962bb7 is two comment lines replaced by comment lines; stress night, map, data and frame report unchanged since c962bb7.
- Acceptance and plan verification re-run: stamp two lines with the DLL sha256; appended byte -> exit 3, restored -> 0; probe 7/7; four replays and the gate digest unchanged; bench 12 lines; ablation 12 slice / 4 saved / OK lines; both suites green; lint clean.
