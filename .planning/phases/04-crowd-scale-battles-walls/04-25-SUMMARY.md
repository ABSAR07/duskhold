---
phase: 04-crowd-scale-battles-walls
plan: 25
subsystem: presentation
tags: [gdextension, native, cpp, view-port, arrows, multimesh, pins-first, vector3, gap-closure]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-24 view_fill_bench.gd and its before-any-port baseline, the two-line stamp bound to the library bytes; plans 04-14/04-15/04-22 gd_math.h and the build script; plans 04-19/04-20 the enemy read view
provides:
  - "NativeArrows (native/src/native_arrows.h/.cpp): the 512-slot arrow ring, launch, the per-frame fill (clock, target re-read through the enemy read view, arrow pose, instance write) and the arc_height / arrow_transform statics, registered in register_types.cpp"
  - "native/src/gd_math.h: the Vector3 rows (length, length_squared, distance_to, normalized, cross, lerp) copied from Godot 4.7.2; native/src/native_mirror.h: the CrowdBatch layout reader and instance writer every later view fill reuses"
  - "CrowdBatch.mirror(), layout() and commit_buffer(): the general hand-out and hand-back (any batch, with or without colours) 04-26 and 04-27 copy"
  - "NativeSim.probe_vector3 / probe_double3 with OP_V3_* and OP_DBL3_* constants, and tests/unit/test_native_view_math_contract.gd: the ten Vector3 operations bit-equal to the engine on 20,000 seeded inputs each"
  - "tests/unit/test_projectile_fill_pins.gd: the arrow batch pinned on the GDScript flight (stress night, walls replay, army replay), one commit, never edited"
  - "ProjectileVfx delegating to NativeArrows with the GDScript flight deleted; arrows bench median 2280.07 us before, 74.44 us after (30.6x)"
affects: [04-26, 04-27, 04-28]

actuals:
  tokens: 250000
  tasks: 2
  commits: 5

plan_head_before: be15b74
plan_head_after: 57f7429

tech-stack:
  added: []
  patterns:
    - "Pins first: a digest over the batch mirror, counts and drawn launch points is computed on the GDScript and committed alone, then the C++ must reproduce it byte for byte"
    - "The native fill writes into the CrowdBatch mirror and the GDScript side calls commit_buffer(mirror, count); presentation reads, never writes simulation state"
    - "Every engine maths row in gd_math.h cites its Godot 4.7.2 source function and is proven bit-equal on 20,000 seeded inputs through a NativeSim probe"
    - "One implementation: the GDScript loop is deleted in the commit that switches to the native fill, after the gain is measured"

key-files:
  created:
    - native/src/native_arrows.h
    - native/src/native_arrows.cpp
    - native/src/native_mirror.h
    - tests/unit/test_projectile_fill_pins.gd
    - tests/unit/test_native_view_math_contract.gd
    - tests/unit/test_native_arrows.gd
  modified:
    - presentation/crowd/crowd_batch.gd
    - tests/unit/test_crowd_batch.gd
    - presentation/vfx/projectile_vfx.gd
    - native/src/gd_math.h
    - native/src/register_types.cpp
    - native/src/native_sim.h
    - native/src/native_sim.cpp

key-decisions:
  - "CrowdBatch's native hand-out is general (mirror(), layout(), commit_buffer() with size, count and built-state refusals), not arrow-specific, because 04-26 and 04-27 port the enemy and unit fills on the same shape"
  - "ProjectileVfx keeps its node, slashes, constants, attack_fired handler and public hooks; arc_height and arrow_transform delegate to NativeArrows' statics so the existing tests keep their API"
  - "The Vector3 contract lives in a sibling script (test_native_view_math_contract) because test_native_math_contract already held 19 of the 20 allowed tests"
  - "No runtime fallback: the GDScript flight, ring arrays and slot search were deleted in the switch commit af0a80b, after the pins, replays and gate held and the bench ratio was read"

patterns-established:
  - "Pins file is exactly one commit in git log and the first native_arrows.cpp commit is a later, different commit"
  - "Bench before and after use the same arguments and five one-at-a-time runs; both medians and the ratio are quoted, and drawn_max is the same on all ten lines"

requirements-completed: []

coverage:
  - id: D1
    description: "CrowdBatch hands out its mirror and layout and takes a filled buffer back, refusing a wrong size, a count outside the capacity and an unbuilt batch; every existing method behaves as before"
    verification:
      - kind: unit
        ref: "tests/unit/test_crowd_batch.gd (three new tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The arrow batch (counts, the whole Arrows mirror, drawn launch points) is pinned on the GDScript fill before any native view code, on the 300-enemy stress night (507 arrows, floor 200), the walls replay (2) and the army replay (9), and the native fill reproduces the pins byte for byte"
    verification:
      - kind: unit
        ref: "tests/unit/test_projectile_fill_pins.gd (4 tests; one commit 5c78be5, green on the GDScript, green again on NativeArrows)"
        status: pass
    human_judgment: false
  - id: D3
    description: "ProjectileVfx's per-frame arrow flight runs in C++ (NativeArrows) behind the unchanged API, and the GDScript flight is deleted"
    verification:
      - kind: unit
        ref: "tests/unit/test_native_arrows.gd (15 tests on bad input and the statics); tests/unit/test_projectile_fill_pins.gd"
        status: pass
      - kind: other
        ref: "build/bench/arrows_before.txt and arrows_after.txt: median mean_us 2280.07 -> 74.44, ratio 30.63 (bar 3.0), drawn_max 507 on all ten lines"
        status: pass
    human_judgment: false
  - id: D4
    description: "The ten Vector3 operations the flight uses are bit-equal to the engine on 20,000 seeded inputs each (native probes), and a reciprocal-multiply mutation of normalized turns the contract red"
    verification:
      - kind: unit
        ref: "tests/unit/test_native_view_math_contract.gd (11 tests; RED 10 of 11 failing before the probes existed; mutation run 10 of 11 failing, reverted, green)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Nothing the round is measured against moved: the four replays and the gate digest are unchanged"
    verification:
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls/full_idle --twice; bash tools/gate_stress.sh --twice -> GATE_OK enemies=300 crossed=300 stuck=0 digest=e448ffdb; final full suite 216 scripts, 2025 tests, 2025 passing"
        status: pass
    human_judgment: false
  - id: D6
    description: "The arrows look as they did after the port (crowd_stress_night and walls_night_breach compared before and after)"
    verification: []
    human_judgment: true
    rationale: "A visual comparison of real-window captures; headless Godot reads MultiMeshes back as zeros (RESEARCH F3), so the executor's by-eye review lines below stand in for the harvested human-check at the end of the phase"

duration: 64min
completed: 2026-10-20
status: complete
---

# Phase 4 Plan 25: Arrows in C++ (the view-port tracer) Summary

**ProjectileVfx's per-frame arrow flight now runs in C++ as NativeArrows behind the unchanged ProjectileVfx API, on pins computed on the GDScript first (stress night, walls and army replays byte for byte), with the arrows bench falling from a 2280.07 us median to 74.44 us (30.6x, bar 3.0) and the Vector3 maths proven bit-equal to the engine on 20,000 seeded inputs per operation; CrowdBatch's mirror()/layout()/commit_buffer() and native_mirror.h are the shape plans 04-26 and 04-27 copy.**

## Performance

- **Duration:** 64 min (execution to the final full-suite run; a rate-limit termination then cut off the executor before this SUMMARY, written by a continuation agent)
- **Started:** 2026-10-20T09:07:32Z
- **Completed:** 2026-10-20T11:51Z (SUMMARY written; last task commit 2026-10-20T10:01:41Z, full suite finished about 10:12Z)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 13 (6 created, 7 modified, plus 3 `.gd.uid`)

## Accomplishments

- **Pins first.** `tests/unit/test_projectile_fill_pins.gd` (4 tests, `5c78be5`) feeds the arrow batch after every frame of three runs and hashes (SHA-256) the arrow and live counts, the whole Arrows mirror and the drawn launch points: the 300-enemy stress night (2400 frames, six unequal frame deltas, reaches 507 arrows against a floor of 200), the walls replay (3922 frames, at most 2 arrows) and the army replay (2706 frames, at most 9). Computed on the GDScript flight, green twice, committed alone; `git log -- tests/unit/test_projectile_fill_pins.gd` is that one commit. Pins: stress `870f22e8c574d2a149f4aebbf88c883c50df310d3fcd26a45dd04b3a0dff0b57`, walls `6aa13d88b607e4bd3cb0ff82976f1bce4f94156b2f7e3c6f60359891366622dc`, army `0ded61ddad9e92a69c54b86eb16dccb9b8b1e14a79d9c7f2331d16f80010e6bc`.
- **The general native hand-out.** `CrowdBatch.mirror()`, `layout()` and `commit_buffer()` (`d5bb865`) give a native fill the batch's byte mirror and instance layout and take a filled buffer back; `commit_buffer` refuses a wrong size, a count outside the capacity and an unbuilt batch. Three tests in `test_crowd_batch`; no existing method changed.
- **NativeArrows** (`af0a80b`): the 512-slot ring, launch, the per-frame fill (clock, target re-read through the enemy read view, arrow pose, instance write) and the `arc_height` / `arrow_transform` statics; `gd_math.h` gained the Vector3 rows (length, length_squared, distance_to, normalized, cross, lerp, each citing its Godot 4.7.2 source function) and `native_mirror.h` the layout reader and instance writer. ProjectileVfx delegates and commits the native mirror; the GDScript slot loop, ring arrays, slot search and path helper are deleted in the same commit (one implementation, no fallback). The pins, the four replays and the gate digest held before the switch commit was made.
- **The gain.** Median mean_us of five arrows bench runs 2280.07 before and 74.44 after: 30.63x against the 3.0 bar, one drawn_max (507) on all ten lines.
- **The Vector3 proof** (`de08db7` RED, `57f7429` GREEN): `NativeSim.probe_vector3` (add, sub, scalar multiply, from doubles, normalized, cross, lerp) and `probe_double3` (length, length_squared, distance_to) with `OP_V3_*` / `OP_DBL3_*` constants; `test_native_view_math_contract` checks each operation on 20,000 seeded inputs against the engine, and `test_native_arrows` (15 tests) holds the native entry points to bad input.

## Task Commits

1. **Task 1 (tracer): the arrows' flight in C++**
   - `d5bb865` (feat) CrowdBatch hands out its mirror and layout and takes a filled buffer back
   - `5c78be5` (test) the arrow batch pinned on the GDScript flight before any native view code
   - `af0a80b` (feat) NativeArrows behind the unchanged ProjectileVfx API, the GDScript loop deleted
2. **Task 2 (tdd): the Vector3 contract and the native arrow entry tests**
   - `de08db7` (test, RED) the failing Vector3 contract and the native arrow entry tests
   - `57f7429` (feat, GREEN) NativeSim probes the Vector3 rows

**Plan metadata:** the docs commit that carries this file. `plan_head_before` be15b74, `plan_head_after` 57f7429; `git rev-list --count be15b74..57f7429` is 5.

## Bench: five runs before and five after, with 04-24's baseline beside them

Same arguments throughout (`view_fill_bench.gd --view=arrows`, default warm-up 1440, 720 timed frames), one run at a time, nothing else running. The files are git-ignored (`build/bench/`), so this table is their only record.

Before the switch (`build/bench/arrows_before.txt`):

```
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2180.69 p95_us=2816.00 max_us=5228.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2279.37 p95_us=3054.00 max_us=8783.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2342.88 p95_us=3550.00 max_us=10475.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2280.07 p95_us=3019.00 max_us=9695.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2599.97 p95_us=3771.00 max_us=7666.00 drawn_max=507
```

After the switch (`build/bench/arrows_after.txt`):

```
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=67.73 p95_us=106.00 max_us=178.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=74.44 p95_us=131.00 max_us=658.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=100.59 p95_us=168.00 max_us=5991.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=65.34 p95_us=105.00 max_us=195.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=85.86 p95_us=159.00 max_us=480.00 drawn_max=507
```

04-24's three baseline arrow lines (from `04-24-SUMMARY.md`, taken on the unchanged views):

```
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2785.27 p95_us=4477.00 max_us=35283.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2736.99 p95_us=4563.00 max_us=36658.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=2353.61 p95_us=3739.00 max_us=7187.00 drawn_max=507
```

| Series | Median mean_us (sorted, third of five) |
|--------|----------------------------------------|
| 04-24 baseline (three runs, median) | 2736.99 |
| 04-25 before (five runs) | 2280.07 |
| 04-25 after (five runs) | 74.44 |

Ratio before/after = 2280.07 / 74.44 = **30.63** (bar 3.0): the stop rule did not trip, the pins and replays held, so the GDScript flight was deleted. One `drawn_max` (507) across all ten lines. As 04-24 noted, the headless arrows bench fills about 507 of the 512 slots, so it is a ceiling for the arrow loop and is compared only against itself; the real-window share was about 2.0 ms of the frame and plan 04-28's stress runs, not this ratio, judge the 8.0 ms budget.

## Task 2 RED evidence and the mutation check

- RED (`de08db7`, run by the previous executor with `bash tools/test.sh -gselect=test_native_view_math_contract`, exit 1): 11 tests in `test_native_view_math_contract`, **10 failing** (only `test_the_seeded_inputs_cover_the_edge_cases`, a GDScript-only check of the seeded inputs, passed). The ten failures were `NativeSim has no op constant OP_V3_ADD` and the like, and `NativeSim.probe_vector3 is missing; run: bash tools/native_build.sh`: the probes did not exist yet. The same commit adds `test_native_arrows` (15 tests of the entry points against bad input; NativeArrows already existed from `af0a80b`, so these are characterisation tests and I found no record of them failing).
- GREEN (`57f7429`): the probes added to `native_sim.h/.cpp`, the contract passes on 20,000 seeded inputs per operation.
- Mutation check (recorded in the `57f7429` message): a reciprocal multiply in the Vector3 `normalized` mirror turned the contract red (10 of 11), was reverted and the contract was green again.

## Screenshot review (real-window captures, before the port in `build/shots_before_04-25/`, after in `screenshots/`)

Both scenes opened with the Read tool, before against after:

- **crowd_stress_night:** the tower arrows (yellow dashes at the 16 tower tops) read as before in the same places, length, colour and tilt; the 300-enemy crowd, squad cards, HUD and king are unchanged. The only differences are a few arrows and enemies a pixel or two apart (the two real-window captures are taken at slightly different wall-clock frames), nothing missing, doubled or mis-oriented.
- **walls_night_breach:** no arrow is in flight in either frame; the breach, the two enemies, the wall segments, king and HUD are identical to the eye (the stray differences are sub-pixel shifts of the red enemies). The scene confirms the empty-ring case draws nothing.

I judge the arrows to read as before. A human-check of the same pair stays with the phase verifier (coverage D6).

## Replays and gate

The Task 1 verify ran them on the switched tree; `build/replay/*.json` (written 2026-10-20 about 09:42Z) and `build/stress/gate.log` hold the results, matching the owner-pinned digests:

- smoke: outcome won, 703 ticks, digest `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- army: won, 1353 ticks, `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- walls: won, 1961 ticks, `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
- full_idle: won, 6911 ticks, `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`; `build/replay/replay.log` ends `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
- gate: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`

(replay.log keeps only the last scenario's line, so the per-scenario REPLAY_OK text is not on disk; the four JSON files and the golden-comparison tests in the full suite are the record. These were not rerun in this continuation.) The Task 2 commits touch only native probe code and tests, no simulation or view file.

## Full suite

Final run of this plan (`build/test-results/gut.log`, written 2026-10-20 about 10:12Z, 591 s): **216 scripts, 2025 tests, 2025 passing, 54016 asserts, all tests passed.** Baseline before this plan: 213 scripts, 1992 tests; this plan adds 33 tests (3 in `test_crowd_batch`, 4 pins, 15 `test_native_arrows`, 11 `test_native_view_math_contract`) in 3 new scripts. The suite was not rerun in this continuation.

## Files Created/Modified

- `native/src/native_arrows.h`, `native/src/native_arrows.cpp` - the arrow ring, launch, per-frame fill and the two statics
- `native/src/native_mirror.h` - CrowdBatch layout reader and instance writer for native fills
- `native/src/gd_math.h` - the Vector3 rows with their Godot 4.7.2 sources in the operation table
- `native/src/register_types.cpp` - `GDREGISTER_CLASS(NativeArrows)`
- `native/src/native_sim.h`, `native/src/native_sim.cpp` - `probe_vector3`, `probe_double3`, `OP_V3_*`, `OP_DBL3_*`
- `presentation/crowd/crowd_batch.gd` - `mirror()`, `layout()`, `commit_buffer()`
- `presentation/vfx/projectile_vfx.gd` - delegates to NativeArrows; the GDScript flight deleted
- `tests/unit/test_projectile_fill_pins.gd` (+ `.gd.uid`) - the three pins, one commit
- `tests/unit/test_native_view_math_contract.gd` (+ `.gd.uid`) - the Vector3 bit-equality contract
- `tests/unit/test_native_arrows.gd` (+ `.gd.uid`) - the native entry points against bad input
- `tests/unit/test_crowd_batch.gd` - three tests for the new accessors

## Decisions Made

- CrowdBatch's native accessors and `native_mirror.h` are general (any batch, with or without colours) so 04-26 and 04-27 copy them unchanged.
- The statics `arc_height` and `arrow_transform` stay on ProjectileVfx and delegate to NativeArrows, so every existing caller and test keeps its API.
- The Vector3 contract is a sibling test script (the existing one holds 19 of 20 tests).
- No runtime fallback and no second implementation: the GDScript flight went in the switch commit once the pins, replays, gate and the 30.6x ratio were in hand.

## Deviations from Plan

None - plan executed exactly as written. The previous executor's scratch notes (`note.txt`, `table_rows.txt`) hold nothing beyond an edit reminder; `red_record.json` is the RED record quoted above. The stale `build/red1.log`, `red_t1a/b.log` and `g2red*.log` files are from earlier plans' RED runs (dated 2026-10-19) and are not evidence for this plan.

## Issues Encountered

- The previous executor was terminated by an API rate limit after the last task commit and the full-suite run but before this SUMMARY and the tracking updates; this continuation agent wrote the SUMMARY, STATE.md and ROADMAP.md from the commits and the on-disk evidence, rerunning nothing.
- Stop rules: none tripped (pins, replays and gate unchanged; the ratio 30.63 is far above 3.0).

## Known Stubs

None.

## Threat Flags

None. NativeArrows is presentation-only (it reads the enemy read view and the king position, writes only its own ring and the batch mirror, no time, randomness, singleton or simulation write); the new native entry points are covered by `test_native_arrows` against bad input.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for plan 04-26 (the enemy and unit view fills): copy the shape proven here, pins first (a digest over the batch mirror on the stress shape and the replays), `CrowdBatch.mirror()/layout()/commit_buffer()`, `native_mirror.h`, and the Vector3 rows now proven bit-equal. Before any rebuild run `tasklist | grep -i godot`. `requirements-completed` stays `[]`: PLAT-01 is decided by plan 04-28 only, which re-measures the full frame against the unchanged 8.0 ms p95 budget. Nothing is pushed (the round pushes once, in plan 04-27).

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-20*

## Self-Check: PASSED

- Commits exist: d5bb865, 5c78be5, af0a80b, de08db7, 57f7429 (`git log` shows all five; `git rev-list --count be15b74..57f7429` = 5).
- Files tracked at HEAD: native/src/native_arrows.h, native/src/native_arrows.cpp, native/src/native_mirror.h, tests/unit/test_projectile_fill_pins.gd, tests/unit/test_native_view_math_contract.gd, tests/unit/test_native_arrows.gd.
- Bench arithmetic recomputed from the two files: medians 2280.07 and 74.44, ratio 30.63; one drawn_max (507) across ten lines.
- Suite totals read from `build/test-results/gut.log`: 216 scripts, 2025 tests, 2025 passing.
