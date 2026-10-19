---
phase: 04-crowd-scale-battles-walls
plan: 20
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, target-query, stuck-tracker, read-view, step-attribution, ci, determinism, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-19 (NativeEnemies store, living_within grid, read_view and its refill), 04-17 (NativeWalls blocking_segment), 04-18 (NativeField, the castle field), 04-23 (the read-only on_tick hooks of ReplayScenarios and GateStress), 04-15 (gd_math.h table, the step_bench stress shape) and 04-16 (CI builds both libraries from source, option A)
provides:
  - "NativeEnemies.nearest_living and EnemySystem.nearest_living (19 of 20 public methods): every nearest-enemy question of the night (towers, castle, king, squads) is one native call through TargetQuery's unchanged API, with the wall line test in C++ for nearest_enemy_clear"
  - "NativeStuck (native/src/native_stuck.*): the read-only stuck tracker in C++ over the enemy read view and the castle field; StuckTracker keeps its API, loses its Entry class and its per-enemy Dictionary of target_of"
  - "CrowdReadView.targeted and CrowdReadView.living flags, filled from the native store with the other arrays"
  - "tools/stress/step_attribution.gd: the committed, rerunnable headless step attribution of the stress shape (VARIANT, PHASE and STEP_ATTRIBUTION_OK lines) that plan 04-21 quotes"
  - "tests/unit/test_target_query_pins.gd (7 tests) and tests/unit/test_stuck_pins.gd (4 tests), each committed green on the GDScript before any native code for it existed and never edited since; tests/unit/test_step_attribution.gd (14 tests)"
  - "CI run 39310876191 green on every job for b5a6f57 with REPLAY_OK and GATE_OK on Linux and Windows, first push of plans 04-17, 04-18, 04-23, 04-19 and 04-20 (GCC compiled the wall, field, structure, decision, enemy and stuck code under -Wall -Wextra -Werror on the first try)"
affects: [04-21]

actuals:
  tokens: 17400
  tasks: 3
  commits: 4

plan_head_before: 64704069075cfa8616b83575cf4de330867006a3
plan_head_after: b5a6f57b02c10538573996f281b09580a4df77af

tech-stack:
  added: []
  patterns:
    - "Pins first, own commit, never edited: the nearest-enemy digests and the stuck digests were computed on the GDScript and committed (7aba0b0, 5bf16da) before nearest_living and native_stuck.cpp existed; both ports matched them on the first run"
    - "A native reader of the enemy store takes the packed read view, not the store: StuckTracker hands view.ids, targeted, living and current plus the castle NativeField to NativeStuck, so no new EnemySystem or Pathing method was needed (both at their caps)"
    - "Ablation-delta attribution probe: four variants that differ only in which plots are bought, interleaved runs, median of per-run means, arithmetic in a static function the test calls"

key-files:
  created:
    - native/src/native_stuck.h
    - native/src/native_stuck.cpp
    - tests/unit/test_target_query_pins.gd
    - tests/unit/test_stuck_pins.gd
    - tests/unit/test_step_attribution.gd
    - tools/stress/step_attribution.gd
  modified:
    - native/src/native_enemies.h
    - native/src/native_enemies.cpp
    - native/src/register_types.cpp
    - simulation/night/enemy_system.gd
    - simulation/night/target_query.gd
    - simulation/night/crowd_read_view.gd
    - simulation/nav/stuck_tracker.gd
    - simulation/nav/pathing.gd
    - tests/unit/test_stuck_tracker.gd

key-decisions:
  - "The read view carries a second flag array, living (health above 0), next to targeted: the GDScript tracker skipped dead-but-not-yet-removed enemies through is_alive, and the view lists them, so the port needs the flag to stay exact (Rule 2); a lethal EnemySystem.damage now also marks the view stale, because that is the one change to living that did not already bump the change counter"
  - "StuckTracker's constructor gains the castle position as a third parameter with a default of Vector2.ZERO, so test_stuck_tracker's two-argument constructions are unchanged; Pathing._init passes the map's castle position (Pathing gains no method)"
  - "NativeStuck computes the three thresholds itself from NavTuning's raw numbers (configure), with SimClock.ticks as gd::sim_ticks and the two roundi expressions in the GDScript's operation order, so test_stuck_tracker's 90-tick threshold test covers it"
  - "living_within was split into a private collect_within (candidate ids into a vector) so nearest_living walks exactly the same grid, rebuild rule and ascending order as the GDScript loop did; no per-query array is allocated"
  - "The attribution probe's PHASE values are ablation deltas (the header says so); rest comes out at -0.02 ms, i.e. towers + squads + enemies account for the whole step within noise"

patterns-established:
  - "A packed array read out of a Dictionary is a copy: a probe that appends through `runs[key].append()` or `(runs[key] as PackedFloat64Array).append()` writes nothing; read into a local, append, write back (caught by the first probe run printing 0.00)"

requirements-completed: []

coverage:
  - id: D1
    description: "Every nearest-enemy question of the night is answered in C++ by EnemySystem.nearest_living through TargetQuery's unchanged API; the GDScript loops are deleted; EnemySystem has 19 public methods"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_target_query_pins.gd (7 tests, 21 sha256 pins on the GDScript query over 2,000 queries per crowd of 50, 300 and 1000, no wall, intact walls, broken handful), unchanged since 7aba0b0"
        status: pass
      - kind: integration
        ref: "test_los_targets, test_enemy_targeting, test_squad_point_orders, test_spatial_index, test_enemy_store_native, test_native_rules_guard; bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests unchanged)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The read-only stuck tracker runs in C++ from the read view (with the targeted and living flags) and the castle field, emitting nothing and writing nothing; its flags, streaks and longest streak are byte-identical and the gate still reports stuck=0 and longest_flag_s=3.37"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_stuck_pins.gd (4 tests, the walls replay and the gate stress through the on_tick hooks), unchanged since 5bf16da; test_stuck_tracker (11), test_debug_overlay_readonly, test_debug_overlay_crowd_sections, test_enemy_views, test_gate_stress in the full suite"
        status: pass
      - kind: integration
        ref: "bash tools/gate_stress.sh --twice -> GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdb..."
        status: pass
    human_judgment: false
  - id: D3
    description: "The whole port is proven on CI: run 39310876191 succeeded on every job for HEAD, REPLAY_OK for smoke, army, walls and full_idle with the golden digests and GATE_OK 300/300/0 on Linux and Windows, and the CI export launches and quits inside 90 s here"
    requirement: PLAT-01
    verification:
      - kind: integration
        ref: "gh run view 39310876191 --log > build/ci-run.log (two REPLAY_OK per scenario, two GATE_OK); timeout 90 build/ci-export/Duskhold.exe --headless --quit-after 120 -> exit 0; the Task 3 verify chain exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "tools/stress/step_attribution.gd attributes the stress-shape step headlessly by the variant method and prints VARIANT, PHASE and STEP_ATTRIBUTION_OK lines; it changes nothing under simulation/ or data/"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_step_attribution.gd (14 tests: defaults, every flag, bounds, multiples of four, unknown flag, path leaving build/, PHASE arithmetic, median, report lines, plots bought per variant)"
        status: pass
      - kind: other
        ref: "bash tools/godot.sh --headless --path . -s res://tools/stress/step_attribution.gd -- --runs=3 --out=build/bench/attribution.txt (lines below)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The stress-shape step falls from a median of 4.58 ms (04-19) to 2.18 ms and the prototype step from 2.07 ms to 1.08 ms; the 8.0 ms p95 frame budget on real hardware is not yet judged"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "ten step_bench lines below"
        status: pass
    human_judgment: true
    rationale: "PLAT-01 closes only when plan 04-21 re-measures the stress night against 8.0 ms in a real window (rendering, frame pacing and the host's load are outside the headless step); PLAT-01 stays Pending in REQUIREMENTS.md"

duration: 61min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 20: Native Nearest-Enemy Query, Native Stuck Tracker and the Port Proven on CI Summary

**One native `nearest_living` now answers every nearest-enemy question (towers, castle, king, squads) through TargetQuery's unchanged API, the read-only stuck tracker runs in C++ from the enemy read view and the castle field, both byte-identical to the GDScript on pins written first, all four goldens and the 300-enemy gate; the stress-shape step median fell from 4.58 ms to 2.18 ms, the committed `step_attribution.gd` probe prints where the rest goes, and one push put the whole port green on CI (Linux and Windows) with a launched export.**

## Performance

- **Duration:** about 61 min (2026-10-19T18:40Z to 19:41Z; one full suite of about 17 min, two verify chains, two bench passes and the 14-minute CI run are most of it)
- **Tasks:** 3 (Task 1 tracer, Task 2 auto, Task 3 auto)
- **Files:** 6 created, 9 modified (plus the SUMMARY); 4 plan commits
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; the whole chain (native build, the pins, five named suites, four replays, the gate, lint) passed end to end before Task 2 started: "Tracer verified end-to-end, expanding".

## Accomplishments

- **Pins first, twice.** `test_target_query_pins` (7 tests, 21 digests: `nearest_enemy` and `nearest_enemy_clear` radius 0.5 and 0.4 over crowds of 50, 300 and 1000 grunts on a half-metre lattice so ties are common, repeated positions, every 37th enemy dead and not removed, in three wall worlds) was committed green on the GDScript at `7aba0b0`; `test_stuck_pins` (the walls replay and the gate stress through the 04-23 on_tick hooks, hashing tick, stuck ids, count, longest streak and every living enemy's streak after every step) at `5bf16da`. Neither has changed since, and both native ports matched them on the first run.
- **Native nearest query.** `NativeEnemies.nearest_living(pos, reach, radius, walls)` walks `living_within`'s candidates (the same grid, rebuild rule and ascending order, now through a shared private `collect_within`), skips health 0, compares `d2 <= reach * reach and d2 < best_d2` with `d2` the single-precision `distance_squared_to` widened to double (lower id wins a tie) and calls `NativeWalls::blocking_segment` last, only for an improving candidate, when walls stand. `EnemySystem.nearest_living` (19 of 20) passes the wall mirror only when at least one segment is intact; `TargetQuery.nearest_enemy` and `nearest_enemy_clear` are one line each and the loops are deleted.
- **Native stuck tracker.** `NativeStuck` is a line-by-line port of `update`, `_observe` and `_forget_unseen` and the getters: an ordered `std::map` of entries by id, the two units (field cost and whole centimetres), the watermark and streak rules, the stamp-based forgetting (including the same-tick edge), thresholds computed from NavTuning's raw numbers. It reads only the arrays it is handed and the castle `NativeField`, holds no pointer to the store, emits nothing and writes nothing. `StuckTracker` keeps its eight public methods, delegates, and no longer defines `Entry`.
- **Read view flags.** `CrowdReadView` gains `targeted` and `living`, filled by `read_view()` from `NativeEnemies.view_targeted` and `view_living`.
- **Attribution probe.** `tools/stress/step_attribution.gd` builds the stress shape exactly as `step_bench --map=stress` does in four variants that differ only in which plots are bought, interleaves the runs, takes the median of per-run means and prints documented `VARIANT`, `PHASE` and `STEP_ATTRIBUTION_OK` lines (header: launch line, arguments, format, the statement that PHASE values are ablation deltas). Arithmetic lives in static `phases_of`, `median_of` and `report_lines`, tested.
- **CI.** One push (`c420bef..b5a6f57`, 22 commits: plans 04-17, 04-18, 04-23, 04-19, 04-20) went green on the first try: zero fix cycles.

## Measured results

All numbers are from this laptop, headless, one run at a time, nothing else running, code at `b5a6f57`.

**Ten bench lines** (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...`):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=2.10 p95_ms=2.44 max_ms=2.86
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=2.12 p95_ms=2.42 max_ms=2.89
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=2.23 p95_ms=3.43 max_ms=5.02
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=2.26 p95_ms=2.71 max_ms=3.98
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=2.18 p95_ms=3.00 max_ms=4.90
STEP_BENCH enemies=300 steps=30 mean_ms=1.24 p95_ms=1.45 max_ms=1.47
STEP_BENCH enemies=300 steps=30 mean_ms=1.07 p95_ms=1.46 max_ms=1.46
STEP_BENCH enemies=300 steps=30 mean_ms=0.94 p95_ms=1.03 max_ms=1.27
STEP_BENCH enemies=300 steps=30 mean_ms=1.43 p95_ms=1.72 max_ms=1.99
STEP_BENCH enemies=300 steps=30 mean_ms=1.08 p95_ms=1.26 max_ms=1.41
```

| Shape | 04-19 (median of 5) | This plan (median of 5) | Difference |
|-------|---------------------|-------------------------|------------|
| Stress, step mean | 4.58 ms | 2.18 ms | -2.40 ms |
| Prototype, step mean | 2.07 ms | 1.08 ms | -0.99 ms |

The stress runs are tight (2.10 to 2.26 ms, worst-step max 2.86 to 5.02 ms) where 04-19's session read 4.15 to 6.45 ms with a 63.6 ms outlier; the laptop drifts between sessions, so the drop is an upper bound on this plan alone, but the p95 of 2.4 to 3.4 ms against 5.4 to 11.3 ms is far outside that drift. No gain bar applied to this plan; plan 04-21 judges the 8.0 ms frame budget in a real window.

**Attribution probe** (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_attribution.gd -- --runs=3 --out=build/bench/attribution.txt`, default 300 enemies, 300 warm-up, 300 timed steps):

```
VARIANT full mean_ms=2.42
VARIANT no_towers mean_ms=1.97
VARIANT no_squads mean_ms=1.01
VARIANT enemies_only mean_ms=0.58
PHASE total ms=2.42
PHASE towers ms=0.45
PHASE squads ms=1.41
PHASE enemies ms=0.58
PHASE rest ms=-0.02
STEP_ATTRIBUTION_OK runs=3 enemies=300 warmup=300 steps=300
```

The squads are now the largest piece (about 1.4 ms of 2.4, 58 %), then the enemy step (0.58 ms, 24 %) and the towers (0.45 ms, 19 %); `rest` is -0.02 ms, so the three account for the whole step within noise. The stuck tracker and hit resolution are inside the 0.58 ms "enemies_only" floor. This is the number the Flagged Assumption promised: the squad per-unit residual (orders, slot walks, goal-field walks for 50 units) is 1.4 ms, which plan 04-21 can weigh against 8.0 ms with the measured frame.

## Verification evidence

Replays and gate after the final change (each run twice; unchanged):

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a
```

Full suite after the final change: **211 scripts, 1979 tests, 34047 asserts, exit 0** (04-19 baseline 208 / 1954 / 33826; this plan adds `test_target_query_pins` 7, `test_stuck_pins` 4 and `test_step_attribution` 14). Lint clean. The pin runs: `test_target_query_pins` and `test_stuck_pins` 7/7 and 4/4 on the GDScript (before) and on the native code (after), same digests.

**CI** (https://github.com/ABSAR07/duskhold/actions/runs/39310876191, head `b5a6f57`, conclusion success, zero fix cycles):

| Job | Duration | Notes |
|-----|----------|-------|
| lint | 25 s | |
| native-linux | 3 min 39 s | GCC, `-Wall -Wextra -Werror`, first time it compiled the wall, field, structure, decision, enemy and stuck code |
| native-windows | 9 min 44 s | MSVC, plus REPLAY_OK x4 and GATE_OK |
| test | 7 min 6 s | Linux: headless import and GUT, REPLAY_OK x4, GATE_OK |
| export | 25 s | Windows export |
| screenshots | 2 min 56 s | |

`build/ci-run.log` has two REPLAY_OK lines per scenario (Windows job and Linux `test` job, the same four goldens) and two GATE_OK lines, all with the local digests: smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569 and the gate e448ffdb with `stuck=0 longest_flag_s=3.37`. `gh run download 39310876191 -n duskhold-windows -D build/ci-export` gave `Duskhold.exe`, `Duskhold.pck` and `libduskhold_sim.windows.x86_64.dll`; `timeout 90 build/ci-export/Duskhold.exe --headless --quit-after 120` launched and quit with exit 0. `ci.yml` is unchanged (`permissions: contents: read`, every `uses:` pinned to a 40-character SHA).

Screenshots from the run (opened with the Read tool): `crowd_stress_night.png` shows the 300-strong purple crowd funnelling through the gate toward the parked king under the tower rows with the `Night 1 of 1 - 300 enemies left` banner and the King's 99882 / 100000 health; `overlay_field_gate.png` shows the field-arrow overlay with `Enemies: 300`, `Segments intact: 26`, `Reached cells: 1962`, `Stuck now: 0`, `Longest stuck: 1.0 s` (software rendering at 11 FPS in the runner, so the frame time there is not a measurement).

## Task Commits

1. **Task 1 (tracer), pins first:** `7aba0b0` (test) - `tests/unit/test_target_query_pins.gd`, green on the GDScript query
2. **Task 1, the native query and the delegating TargetQuery:** `5f6cd94` (feat)
3. **Task 2, pins first:** `5bf16da` (test) - `tests/unit/test_stuck_pins.gd`, green on the GDScript tracker
4. **Task 2, NativeStuck, the read view flags, StuckTracker delegating, the attribution probe and its test:** `b5a6f57` (feat)
5. **Task 3:** no code commit (the push and the evidence); `ci.yml` untouched

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md (made after the push, so it is not part of CI run 39310876191). PLAT-01 stays Pending in REQUIREMENTS.md (04-21 measures the budget).

## Files Created/Modified

- `native/src/native_stuck.h`, `native/src/native_stuck.cpp` - `NativeStuck`: the read-only stuck tracker
- `native/src/native_enemies.h`, `native/src/native_enemies.cpp` - `nearest_living`, `collect_within`, `view_targeted`, `view_living`
- `native/src/register_types.cpp` - registers `NativeStuck`
- `simulation/night/enemy_system.gd` - `nearest_living` (19 public methods), the view refill of the two new flags, a lethal `damage` marks the view stale
- `simulation/night/target_query.gd` - one-line delegations; loops deleted
- `simulation/night/crowd_read_view.gd` - `targeted` and `living`
- `simulation/nav/stuck_tracker.gd` - delegating tracker (8 public methods, no `Entry`), castle position in the constructor
- `simulation/nav/pathing.gd` - passes the castle position to `StuckTracker.new`
- `tests/unit/test_target_query_pins.gd`, `tests/unit/test_stuck_pins.gd`, `tests/unit/test_step_attribution.gd` (+ `.uid`) - pins and the probe test
- `tests/unit/test_stuck_tracker.gd` - its stand-in enemies answer `read_view()` too
- `tools/stress/step_attribution.gd` (+ `.uid`) - the probe

## Decisions Made

See key-decisions above. One further note: `NativeStuck.update` treats arrays of different sizes as an update with no enemies (the GDScript had no analog; it can only happen from a caller that hands mismatched arrays, never from `StuckTracker`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] The read view needs a liveness flag, and a lethal hit must mark it stale**
- **Found during:** Task 2 (porting `update`)
- **Issue:** The plan gives the view only a `targeted` flag. The GDScript tracker skipped dead enemies that have not been removed yet (`is_alive`), the view lists them (ids is every record), and `test_stuck_tracker` pins that a dead enemy drops out; a port reading only `targeted` would track and flag dead enemies. Also, `EnemySystem.damage()` did not bump the change counter, so a view read after a lethal hit could carry a stale liveness flag.
- **Fix:** `CrowdReadView.living` (1 where health is above 0) filled with the other arrays; `damage()` calls `_mark_changed()` when the hit leaves 0 (the counter only gates the view refill: no simulation state, event or digest depends on it).
- **Files modified:** `simulation/night/crowd_read_view.gd`, `simulation/night/enemy_system.gd`, `native/src/native_enemies.h`, `native/src/native_enemies.cpp`
- **Verification:** `test_stuck_tracker` (11), `test_crowd_read_view` (7), the stuck pins, four replays and the gate, all unchanged
- **Commit:** `b5a6f57`

**2. [Rule 3 - Blocking] test_stuck_tracker's stand-in enemies had no read view**
- **Found during:** Task 2 (the tracker now reads `enemies.read_view()`, as the plan says)
- **Issue:** `FakeEnemies` overrides `ids`, `is_alive`, `target_of` and `position_of`; its `read_view()` would come from the empty native store, so the tracker saw nobody. The file is not in the plan's `files_modified`.
- **Fix:** `FakeEnemies.read_view()` builds the packed view from the same dictionaries. No expectation changed; only the seam moved (the tests' reads are the tracker's inputs).
- **Files modified:** `tests/unit/test_stuck_tracker.gd`
- **Verification:** 11 / 11 green; its 90-tick threshold, creeping, target-reset and dead-enemy tests pass unchanged
- **Commit:** `b5a6f57`

**3. [Rule 1 - Bug] The probe's first version printed 0.00 for every variant**
- **Found during:** Task 2 (first run of the probe, before the commit)
- **Issue:** `(runs[variant] as PackedFloat64Array).append(mean_ms)` appended to a copy (packed arrays are copy-on-read from a Dictionary), so every median was over an empty array.
- **Fix:** read into a local, append, write back; the unit test for the median stays arithmetic-only and the probe was re-run on a small shape (non-zero, sensible variant ordering) before the commit.
- **Files modified:** `tools/stress/step_attribution.gd`
- **Commit:** `b5a6f57` (fixed before the commit)

**Total deviations:** 3 auto-fixed (1 Rule 1, 1 Rule 2, 1 Rule 3). **Impact:** none on behaviour or any digest; one extra view array, one test seam and one probe bug fixed before it shipped.

## Authentication Gates

None. `gh auth status` was already logged in as ABSAR07; the push used the credential-helper command of the plan.

## Issues Encountered

- **An overlapping verify chain.** My first Task 1 verify chain was started from a nested background subshell and, when I then started the same chain again with `run_in_background`, two copies ran at once and shared `build/` logs. I stopped both by PID (they were mine, `taskkill /PID .. /T`), checked the process list, and re-ran the chain once, cleanly; the numbers quoted are from that clean run. Nothing else on the machine was touched.
- **A hung pin-computation script.** A scratch `SceneTree` script of mine hit a parse error before `quit()`, so Godot stayed running; I stopped those two processes by PID. The cause was a static function name (`_summary`) in my draft `test_stuck_pins.gd`; renamed `summary_of` before the pins were computed and committed.
- **Probe test counts.** `standing_spot_ids()` does not list the gate wall (walls are segments), so the first draft of the variant-plots test expected one plot too many per variant; the test now asserts 22 / 2 / 20 / 0 spots and a standing wall in every variant.

## Notes for the later `/gsd-code-review 4 --fix` pass

- `NativeEnemies::nearest_living` calls `slot_of` (a binary search) per candidate; at the stress reach that is a few hundred searches per query. It is already fast enough (the towers are 0.45 ms), but a slot-indexed grid would remove it if a later profile asks.
- The stuck tracker's `std::map` is O(log n) per enemy per tick; a sorted vector merged against the ascending view would be O(n). Not worth it at 300 enemies (the whole enemy-only floor is 0.58 ms).

## Known Stubs

None.

## Threat Flags

None. The native query and tracker open no file, network, input or scene-tree surface; they read only what the facade hands them (T-04-53 and T-04-54 are mitigated by the two pin tests written first, the four replays, the gate digest and its longest flag, the CI replays on both platforms and the tracker's no-event, no-write contract; T-04-55 by `prepush_check`, the credential-helper command only and an unchanged `ci.yml`; T-04-61 by the probe's allowlisted bounded arguments and its `--out` confined to a `.txt` under `build/` through `ReplayCli.safe_dir`, tested).

## Next Phase Readiness

Ready for 04-21 (the frame budget). The headless stress-shape step is 2.18 ms (median of five) against the 5 to 6 ms the diagnosis said the 8.0 ms frame budget needs; the attribution probe splits it as squads 1.41, enemies 0.58, towers 0.45 ms and is rerunnable with the launch line above. If 04-21 meets 8.0 ms the squad residual is accepted as measured; if it misses and squads are the largest remaining phase, the squad per-unit port is the next gap plan for the owner to decide. PLAT-01 stays Pending.

## Self-Check: PASSED

- Created files exist: `native/src/native_stuck.h`, `native/src/native_stuck.cpp`, `tests/unit/test_target_query_pins.gd`, `tests/unit/test_stuck_pins.gd`, `tests/unit/test_step_attribution.gd`, `tools/stress/step_attribution.gd` and the `.gd.uid` of each GDScript file (all tracked).
- Commits exist: `7aba0b0`, `5f6cd94`, `5bf16da`, `b5a6f57` (`git log --oneline --all`); `git log --format=%H -- tests/unit/test_target_query_pins.gd tests/unit/test_stuck_pins.gd` lists only `7aba0b0` and `5bf16da`, both ancestors of the commits that add `nearest_living` and `native_stuck.cpp`.
- Acceptance: `target_query.gd` calls `nearest_living(`; `EnemySystem` has 19 public functions; `stuck_tracker.gd` keeps update, clear, is_stuck, stuck_count, stuck_ids, streak_of, longest_streak_ticks and threshold_ticks and has no `class Entry`; the probe and its test exist with `.gd.uid` and the probe changes nothing under `simulation/` or `data/`; the ten bench lines, both medians and the VARIANT and PHASE lines are above; the CI run URL, job durations, the two screenshot lines and zero fix cycles are above; `build/ci-export` holds `Duskhold.exe` and the DLL and the build launched and quit inside 90 s.
- `PLAT-01` is still `Pending` in `.planning/REQUIREMENTS.md`.
