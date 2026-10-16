---
phase: 04-crowd-scale-battles-walls
plan: 03
subsystem: simulation
tags: [godot, gdscript, spatial-grid, performance, determinism, separation, tdd, bench]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: CrowdBatch and the EnemyViews per-frame fill (plan 04-01), UnitViews batches and the headless MeshBaker rule (plan 04-02)
  - phase: 02-night-combat
    provides: EnemySystem, TargetQuery, Separation and the smoke, army and full_idle replays that prove the pass exact
provides:
  - StructureIndex, the exact-preserving grid behind EnemySystem._pick_nearest_structure (rebuilt once per step)
  - EnemyIndex behind TargetQuery.nearest_enemy through EnemySystem.living_within
  - Separation.displacements_bucketed, bit-identical to Separation.displacements, used by EnemySystem and UnitSystem
  - CrowdReadView and EnemySystem.read_view(), the packed ids and previous and current positions EnemyViews fills its batches from
  - tools/stress/step_bench.gd, the headless STEP_BENCH step-cost bench (parse_args allowlist, exit 64 on misuse)
affects: [04-04 wall data, 04-06 flow field (StructureIndex and EnemyIndex are its neighbours), 04-09 stress scene and frame report, 08 art pass]

actuals:
  tokens: 19900
  tasks: 2
  commits: 3

plan_head_before: eb5027f7f2e5fdfdc7852366d32323395932b0b3
plan_head_after: d1279abf94c0676b505eb63501e1a4c19c658532

tech-stack:
  added: []
  patterns:
    - "A uniform grid keyed by integer cell coordinates in a Dictionary of Array[int] buckets: only occupied cells exist, candidates are gathered from the cell block around the query point and sorted into the shipped scan order, and the caller applies the shipped exact test to them"
    - "Equivalence tests keep a verbatim reference copy of the shipped scan inside the test file and compare on seeded random worlds with ties"
    - "A read view versioned by a change counter: one shared object refilled only when the system changed, so an unchanged field costs nothing per frame"

key-files:
  created:
    - simulation/night/structure_index.gd
    - simulation/night/enemy_index.gd
    - simulation/night/crowd_read_view.gd
    - tools/stress/step_bench.gd
    - tests/unit/test_spatial_index.gd
    - tests/unit/test_separation_grid.gd
    - tests/unit/test_crowd_read_view.gd
    - tests/unit/test_stress_tool_args.gd
  modified:
    - simulation/night/enemy_system.gd
    - simulation/night/target_query.gd
    - simulation/squads/separation.gd
    - simulation/squads/unit_system.gd
    - presentation/enemies/enemy_views.gd

key-decisions:
  - "StructureIndex gathers a (aggro_range + largest radius + 0.01 m) block of 12 m cells and sorts the candidate indices, so the shipped test runs on them in the shipped order and a tie goes to the earlier candidate"
  - "Separation.displacements_bucketed derives its neighbourhood from the cell edge it is given (span = ceil(2 * largest radius / cell)), so a cell narrower than the callers' choice still finds every partner; the callers pass 2 * largest radius + 0.001"
  - "EnemySystem keeps its Dictionary-of-records storage and exposes read_view() only (RESEARCH Open Question 6); read_view() bumps a change counter on spawn, step, remove_dead (per removal) and clear, and damage does not bump it because ids, previous and current do not change"
  - "EnemyIndex falls back to visiting the occupied cells when the cell block of a query would be larger than the number of occupied cells, so an oversized reach cannot cost more than the old full scan"

patterns-established:
  - "Exact-preserving performance passes are proved by reference-copy equivalence tests plus the three unchanged replay digests, never by regenerating a golden"
  - "Stubs with the final signatures (empty or zero results) go in the RED commit so the new tests fail on assertions rather than on a missing symbol"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "A target-less enemy finds its nearest unit, standing building or castle through StructureIndex with exactly the shipped answers (order, tie rule, expressions)"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_spatial_index.gd#test_structure_index_matches_the_shipped_scan_at_aggro_range_6"
        status: pass
      - kind: unit
        ref: "tests/unit/test_spatial_index.gd#test_a_unit_wins_a_tie_with_a_building_at_the_same_edge"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "TargetQuery.nearest_enemy answers from the enemy grid with the shipped tie rule (lower id) and never returns a dead enemy"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_spatial_index.gd#test_nearest_enemy_matches_the_shipped_scan_at_reaches_2_7_10_5_and_22"
        status: pass
      - kind: unit
        ref: "tests/unit/test_spatial_index.gd#test_a_dead_enemy_that_is_not_removed_yet_is_never_returned"
        status: pass
    human_judgment: false
  - id: D3
    description: "Crowds push apart bit-identically through the bucketed pass (EnemySystem and UnitSystem), proved by PackedVector2Array equality and the army golden"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_separation_grid.gd#test_300_circles_clumped_within_12_m_push_apart_the_same"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
    human_judgment: false
  - id: D4
    description: "EnemyViews fills its batches from EnemySystem.read_view() packed arrays; the view agrees with the id API, versions on change and emits no signal"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_crowd_read_view.gd#test_reading_the_view_emits_no_signal"
        status: pass
      - kind: unit
        ref: "tests/unit/test_enemy_views.gd (existing suite, unchanged)"
        status: pass
    human_judgment: true
    rationale: "A MultiMesh reads back zeros on the dummy renderer, so that every enemy is still drawn where the simulation has it, smoothly, needs one look at a real-window night; the stress scene screenshots of plan 04-09 carry that look"
  - id: D5
    description: "The headless step bench prints STEP_BENCH for 300 marching grunts; the mean step cost fell from 25.6 ms to 8.4 to 9.2 ms on the dev machine (recorded evidence, not a gate)"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30"
        status: pass
    human_judgment: false

duration: 36min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 03: Exact-Preserving Crowd Step Summary

**A 300-enemy night step now costs 8.4 to 9.2 ms instead of 25.6 ms on the dev machine: a structure grid for target-less enemies, an enemy grid behind `TargetQuery.nearest_enemy`, a bit-identical bucketed push-apart and a packed read view for the enemy batches, with the smoke, army and full_idle digests unchanged**

## Performance

- **Duration:** 36 min
- **Started:** 2026-10-16T04:24:07Z
- **Completed:** 2026-10-16T05:01:00Z
- **Tasks:** 2 (Task 2 as RED, GREEN)
- **Files modified:** 21 (8 created sources and tests plus 5 modified sources, 8 new `.uid` files not counted)

## Accomplishments

- Marching enemies no longer rescan every unit and building each tick. `StructureIndex` is rebuilt once per `EnemySystem.step` and `_pick_nearest_structure` takes its answer from it; the rescan period is cached on the record at spawn. 0 mismatches against a verbatim copy of the shipped scan over 300 seeded positions at aggro ranges 6 and 10, with unit-versus-building and building-versus-building ties.
- `TargetQuery.nearest_enemy` (towers, castle, king, squads) tests only the enemies around the query point, through `EnemySystem.living_within`; 200 queries at reaches 2, 7, 10.5 and 22 m equal the shipped scan, the equidistant pair goes to the lower id, a dead-but-not-removed enemy is never returned, and the answers follow spawn, remove_dead, clear and 30 steps of movement.
- `Separation.displacements_bucketed` equals `Separation.displacements` (PackedVector2Array equality) for 100 and 300 circles spread over 60 m, 300 clumped within 12 m, mixed radii, coincident pairs of even and odd ids, and cell edges both wider and narrower than needed; `EnemySystem._separate` and `UnitSystem.separate` call it.
- `EnemySystem.read_view()` returns ascending ids with previous and current positions in packed arrays, rebuilt only after a change; `EnemyViews` fills its batches from it (RESEARCH F3: about 20 times cheaper than three id calls per enemy).
- `tools/stress/step_bench.gd` prints `STEP_BENCH enemies=<n> steps=<n> mean_ms=<x> p95_ms=<x> max_ms=<x>`; its arguments are an allowlist of two bounded integers (exit 64 otherwise).

## Step bench (recorded evidence, not a gate)

300 grunts from the three spawn points of the prototype map (scatter 3 m, seed 1), every plot built at tier 1, 25 units standing, 30 timed steps, headless, dev machine (Intel i5-10500H):

| Moment | Line copied from the run |
|--------|--------------------------|
| Before (HEAD eb5027f) | `STEP_BENCH enemies=300 steps=30 mean_ms=25.56 p95_ms=32.77 max_ms=32.90` (three re-runs: mean 26.66, 27.04, 25.82) |
| After Task 1 (structure grid), committed run | `STEP_BENCH enemies=300 steps=30 mean_ms=9.42 p95_ms=10.57 max_ms=10.80` (three earlier runs: mean 9.35, 9.91, 10.23) |
| After Task 2 (enemy grid, bucketed push-apart, read view) | `STEP_BENCH enemies=300 steps=30 mean_ms=9.08 p95_ms=10.52 max_ms=11.82` (three earlier runs: mean 9.20, 8.43, 8.97) |

- The 10.0 ms expectation holds on the final change (8.4 to 9.2 ms across four runs). One Task 1 run read 10.23 ms; it was re-run as the plan asks (9.35 and 9.42 ms) and the committed line is the 9.42 one.
- The before line is 25.6 ms here, not the 50.1 ms of RESEARCH F1: the researcher's bench scattered the grunts over 6 m instead of 3 m and ran with towers and military plots at all three tiers. The cliff is the same one (per-enemy structure scan every tick); the structure grid alone removed about 16 ms of it. Task 2 moved the mean by a further 0.3 to 1.0 ms on this scene because the grunts march in three loose clumps; a scratch measurement put the bucketed push-apart at 3.3 ms of the 8.9 ms step. The remaining 5.6 ms is the per-enemy target choice and step in GDScript, which is the lever list of plan 04-09 (storage as struct-of-arrays), not a finding against this plan.

## Task Commits

1. **Task 1: Tracer, StructureIndex and the step bench** - `b52987e` (feat)
2. **Task 2 RED: failing tests for the enemy grid, bucketed push-apart and read view** - `36cb198` (test)
3. **Task 2 GREEN: nearest-enemy and push-apart queries from grids, enemy batches from the read view** - `d1279ab` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Files Created/Modified

- `simulation/night/structure_index.gd` - the structure grid (`rebuild`, `nearest`; kinds unit, building, castle; CELL 12 m)
- `simulation/night/enemy_index.gd` - the enemy grid (`rebuild`, `within`; CELL 8 m)
- `simulation/night/crowd_read_view.gd` - ids, previous, current, version
- `simulation/night/enemy_system.gd` - StructureIndex per step, cached rescan period, `living_within`, `read_view`, bucketed `_separate`; 18 public functions
- `simulation/night/target_query.gd` - `nearest_enemy` loops over `living_within`
- `simulation/squads/separation.gd` - `displacements_bucketed` (the O(n^2) `displacements` stays as the reference)
- `simulation/squads/unit_system.gd` - `separate()` body only (still 20 public methods)
- `presentation/enemies/enemy_views.gd` - the per-frame fill reads `read_view()`
- `tools/stress/step_bench.gd` - the headless step bench
- `tests/unit/test_spatial_index.gd` (12 tests), `test_separation_grid.gd` (7), `test_crowd_read_view.gd` (7), `test_stress_tool_args.gd` (6)

## Decisions Made

See `key-decisions` above. `export_presets.cfg`'s `exclude_filter="tests/*, addons/gut/*, tools/*"` already covers `tools/stress/`, so no pattern was added.

## Deviations from Plan

None - plan executed exactly as written. Three readings the plan leaves open, none a deviation:

- The RED commit carries signature-only stubs (empty candidate list, zero displacements, empty view) beside the new tests, so the tests fail on their assertions instead of on a missing symbol; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` for `test_300_circles_spread_over_60_m_push_apart_the_same`. The `nearest_enemy` equivalence tests pass in RED by design (the shipped path is the reference); the new `living_within` test is the one that fails there.
- `StructureIndex` receives units, buildings and castle at rebuild; a null `units` or `buildings` holds no candidates, as the shipped scan did.
- The "Task 1 verify" ran the full suite once with a defect in my own new `test_stress_tool_args` (a typed-array loop); it was fixed and that suite re-run alone before the Task 1 commit. Every other test of that 160-script run passed, and the final 162-script run below is fully green.

**Total deviations:** 0.

## Issues Encountered

- `null as Array[int]` is an invalid cast in GDScript (the grid's empty-cell lookup); the lookup now goes through a `Variant` and a null check.
- A first draft of the stress-args test used a typed-array `for` loop over untyped literals, which GDScript rejects at runtime; rewritten with plain strings.
- `gdformat` on this machine writes CRLF; git normalises it (eol=lf attributes) and the commits show only a warning.

## Verification (final state, HEAD d1279ab)

- `bash tools/test.sh`: 162 scripts, 1501 tests, 20592 asserts, exit 0 (the baseline at dispatch was 158 scripts, 1469 tests, 17376 asserts; +4 scripts, +32 tests). `test_spatial_index`, `test_separation_grid`, `test_crowd_read_view`, `test_stress_tool_args`, `test_separation`, `test_tower_combat`, `test_squad_guard`, `test_enemy_views`, `test_enemy_targeting`, `test_enemy_targets_units` are in the JUnit XML.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) both `REPLAY_OK` against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` at 6941 ticks (twice); no golden touched.
- `bash tools/lint.sh`: clean (gdformat and gdlint).
- Public functions in `enemy_system.gd`: 18 (cap 20).

## Known Stubs

None. The RED-commit stubs were replaced in the GREEN commit.

## Threat Flags

None. No new network, auth, file-access or schema surface: the bench reads two bounded integer flags and no path, and tools/ stays export-excluded (T-04-05, T-04-06 and T-04-07 mitigated as planned; the grids hold occupied cells only).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04-04 and the wall plans can rely on a cheap step: the wall decision pass and the flow field add to a step that now spends about 9 ms of its 33 ms period on 300 marching enemies.
- Plan 04-09 owns the frame-time gate. Its levers, if the real-window report misses: `EnemySystem` storage as struct-of-arrays (lever a), the remaining per-enemy GDScript cost, and a read view for `UnitViews` (kept on id calls because `UnitSystem` is at the 20-method cap and the stress night has 50 units).
- Open for the verifier (D4): one real-window look that the 300 stress enemies are drawn where the simulation has them; headless cannot read a MultiMesh back.

## Self-Check: PASSED

- Created files exist: structure_index.gd, enemy_index.gd, crowd_read_view.gd, step_bench.gd and the four test scripts, each with its `.uid`.
- Commits `b52987e`, `36cb198` and `d1279ab` are in `git log`.
- Acceptance criteria re-run: `class_name StructureIndex`, `func rebuild(`, `func nearest(`; `StructureIndex` in `enemy_system.gd` with the scan loops gone and the rebuild before the per-enemy loop; `static func parse_args(` and `STEP_BENCH` in the bench; `class_name EnemyIndex`, `class_name CrowdReadView`; `static func displacements_bucketed(` called from `unit_system.gd`; `living_within(` in `target_query.gd`; `read_view(` in `enemy_views.gd`; 18 public functions in `EnemySystem`.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
