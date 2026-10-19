---
phase: 04-crowd-scale-battles-walls
plan: 23
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, structure-index, wall-decision, enemy-trace, determinism, step-bench, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-17 NativeWalls mirror (first_blocking, segment health); plan 04-18 NativeGrid, NativeField and NativeRoute (the medians and command lines compared against); plan 04-15 gd_math.h operation table and the pins-first port style; plan 04-22 stale-library guard; plan 04-16 CI that builds the native library from source
provides:
  - "NativeStructures (native/src/native_structures.*): the structure index in C++ (12 m grid, strict ascending-index scan, nearest, nearest_visible, nearest_through_walls) over a snapshot StructureIndex.rebuild gathers, plus plain lookups (unit position and radius by id, building centre and radius by spot index, standing membership) for plan 04-19"
  - "NativeWallDecision (native/src/native_wall_decision.*): begin_tick, add_attacker, end_tick, ttd_of, evaluated_count over the NativeWalls health mirror, and static C++ twins of damage_per_300, ttd_ticks, walk_ticks, should_break and keep_breaking proven equal to the GDScript statics on a grid through NativeSim.probe_rules"
  - "tests/unit/test_structure_decision_pins.gd: 13 sha256 pins computed on the GDScript before any native structure code, never edited since"
  - "tests/unit/test_native_structures.gd: the rule twins on the pins' grid, bad ids and sizes, snapshot lookups, odd ranges (T-04-60)"
  - "tools/stress/enemy_trace.gd: the per-tick enemy trace tool (ENEMY_TRACE_OK with a sha256), the oracle plan 04-19 diffs the native enemy step against, with read-only on_tick hooks in ReplayDriver, ReplayScenarios and GateStress"
affects: [04-19, 04-20, 04-21]

actuals:
  tokens: 20836
  tasks: 2
  commits: 3

plan_head_before: de16d2d27516c6cfe4d89c5821cc92849f8ed177
plan_head_after: bf873e24c17d738af95b63fa61687984639e1f67

tech-stack:
  added: []
  patterns:
    - "Snapshot hand-over: the GDScript facade gathers packed arrays from the systems' public methods in the shipped order once per step and the native class owns grid and scan; queries delegate"
    - "Statics stay GDScript for GDScript callers, with native twins exposed as a probe (NativeSim.probe_rules) and proven equal on an exhaustive grid that the pin test exports as constants"
    - "Read-only trace hooks as a trailing optional Callable, so the digests cannot move and the replays and the gate prove it"

key-files:
  created:
    - native/src/native_structures.h
    - native/src/native_structures.cpp
    - native/src/native_wall_decision.h
    - native/src/native_wall_decision.cpp
    - tests/unit/test_structure_decision_pins.gd
    - tests/unit/test_native_structures.gd
    - tests/unit/test_enemy_trace.gd
    - tools/stress/enemy_trace.gd
  modified:
    - native/src/native_sim.h
    - native/src/native_sim.cpp
    - native/src/native_walls.h
    - native/src/native_walls.cpp
    - native/src/register_types.cpp
    - simulation/night/structure_index.gd
    - simulation/nav/wall_decision.gd
    - tools/replay/replay_driver.gd
    - tools/replay/replay_scenarios.gd
    - tools/stress/gate_stress.gd

key-decisions:
  - "The decision's static integer rules stay GDScript (EnemySystem.spawn and the overlay call them); the C++ twins are static members of NativeWallDecision, reachable from GDScript only through the NativeSim.probe_rules probe, and proven equal on a 9x10 / 25x88 / 13x9 / 6x4x11 / 6x4x11x4 grid including negative, MAX_TICKS and overflowing values (GDScript's wrapping int arithmetic and truncating division reproduced with unsigned wrapping operations)"
  - "A query whose block of grid cells would be larger than the grid itself tests every candidate in ascending order, which is exactly the unfiltered scan the grid replaces; so an infinite or enormous aggro range answers instead of hanging as the GDScript loop would (a superset over an exact strict-minimum test, exact_port_rules 5)"
  - "NaN range or position answers no candidate (no edge can pass `edge <= aggro_range`), the answer the GDScript's comparisons give"
  - "WallDecision keeps _hysteresis and _notice in GDScript for its two cheap getters (EnemySystem reads them every enemy every tick) and hands the same numbers to the native object for plan 04-19; cadence, span, the run arrays, the sums and the published times live only in C++"
  - "The trace tool records ticks up to its bound while a replay scenario runs to its own end (ReplayScenarios has fixed bounds and the hook is read-only by design); the gate run is genuinely bounded because GateStress.run takes seconds"
  - "StructureIndex gains native() (five public methods, not four) so plan 04-19's native step can take the NativeStructures object, exactly as WallDecision.native(), NavGrid.native() and FlowField.native() do"

patterns-established:
  - "Pins first and never edited: a4308cb precedes the first commit that creates native_structures.cpp (c4c09ba); a mutation probe (tie rule `<` to `<=`, cadence posmod(-tick) to posmod(tick)) failed the ties pins and the shipped and ring decision pins, then was reverted and rebuilt"
  - "Trace line format documented once in tools/stress/enemy_trace.gd: `<tick> <id> <position hex> <previous hex> <health> <target_kind> <target_id>`"

requirements-completed: []

coverage:
  - id: D1
    description: "The structure index (rebuild snapshot, nearest, nearest_visible, nearest_through_walls) runs in C++ behind StructureIndex, byte-identical to 9 sha256 structure pins computed on the GDScript, with all five replay digests and the 300-enemy gate unchanged and the GDScript grid, arrays and scan deleted"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_structure_decision_pins.gd (8 tests), tests/unit/test_native_structures.gd (14 tests), test_spatial_index.gd, test_los_targets.gd, test_melee_breaks_to_target.gd"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests below), full suite 207 scripts / 1940 tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "The wall decision's per-tick state (begin_tick, add_attacker, end_tick, ttd_of, evaluated_count) runs in C++ behind WallDecision, byte-identical to 3 decision pins over 300 ticks each, with native twins of the five static rules equal to the GDScript on an exhaustive grid"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_structure_decision_pins.gd (decision and rules pins), tests/unit/test_native_structures.gd (rule twins), test_wall_decision.gd, test_debug_overlay_crowd_sections.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "The per-tick enemy trace tool writes a deterministic, documented trace for smoke, army, walls, full_idle and gate within each scenario's own derived bound, and the on_tick hooks leave every digest unchanged"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_trace.gd (9 tests: allowlist, derived bounds, line format, same text twice, hooked smoke replay equals the golden, hooked gate digest equals unhooked)"
        status: pass
      - kind: other
        ref: "ENEMY_TRACE_OK lines and byte-identical A/B file pairs for all five scenarios, listed below"
        status: pass
    human_judgment: false
  - id: D4
    description: "The stress-shape and prototype step medians are measured (five runs each plus an interleaved A/B); the 8.0 ms p95 frame budget is not yet met"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "PLAT-01 closes only when the whole enemy step runs natively and the stress night is re-measured against 8.0 ms (04-VERIFICATION.md gap G-04-5); plan 04-21 judges the frame budget"

duration: 47min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 23: Native Structure Index, Wall Decision State and the Enemy Trace Oracle Summary

**The structure index (rebuild, nearest, nearest_visible, nearest_through_walls) and the wall decision's per-tick state (begin_tick, add_attacker, end_tick, ttd_of, evaluated_count) now run in C++ behind their unchanged GDScript APIs, byte-identical to 13 sha256 pins computed on the GDScript first, with all five replay digests and the 300-enemy gate unchanged, the static integer rules proven equal to their native twins on an exhaustive grid, and `tools/stress/enemy_trace.gd` writing the per-tick enemy oracle plan 04-19 diffs against.**

## Performance

- **Duration:** about 47 min (2026-10-19T16:45Z to 17:33Z; the full suite is 14 min of it, the trace series, bench series and A/B about 20 min)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files:** 22 in the production commits (8 created plus 4 .uid files, 10 modified)
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; the whole chain passed end to end (pins, the named suites, rules guard, four replays, gate, lint) before Task 2 started, and Task 2's chain re-ran everything plus the full suite after the expansion: "Tracer verified end-to-end, expanding".

## Accomplishments

- **Pins first.** `tests/unit/test_structure_decision_pins.gd` builds three seeded structure worlds (the prototype map with no wall bought, the prototype map with its four wall runs bought and some units dead, two buildings fallen and six segments broken, and a world of integer positions full of exact ties) and puts each through 2,000 queries of `nearest` (aggro 6, 10, 22), `nearest_through_walls`, and `nearest_visible` at radius 0.0 and 0.5 with ranged reach -1 and 7 (8,000 answers). It pins the three decision scenarios (shipped tuning on the prototype runs, a cadence of one tick with span four, the sealed ring) over 300 ticks each of `begin_tick`, 0 to 40 seeded `add_attacker` calls (segments -2 to count+1, damage -3 to 60), `end_tick`, with segment damage in between: every `ttd_of` from -1 to count and `evaluated_count` after every tick. And it pins the five static rules over a grid (health 0 to 120 by 7 plus negative, million, 2^40 and 2^60; sums 0 to 900 by 11 plus negative, 1, 899, 1000, 20000, 2^40; distances and speeds including 2^61; every combination of ttd, straight, detour and hysteresis including MAX_TICKS). 13 pins, identical on two GDScript runs, committed green on the GDScript in `a4308cb`, before `native_structures.cpp` existed, and not touched since. Coverage tests prove the walled world really hides candidates (the visible answer differs from the plain one on more than 20 queries and the castle is skipped through walls) and the tie world really ties.
- **Native structure index.** `NativeStructures` keeps the snapshot (candidates in the shipped order: living units by ascending id, standing buildings in spot order, the castle last) and the 12 m grid (a `std::map` keyed exactly like `_key`), and its scan takes `edge <= aggro_range and edge < best_edge` over the sorted block candidates with the distance computed as the real_t `distance_to` widened to double minus the double radius; only an improving candidate pays the `NativeWalls::blocking_segment` line test. `StructureIndex.rebuild` still gathers through the same GDScript calls in the same order and hands over packed arrays; the three queries and a new `native()` delegate; `_cells`, the five arrays, `_largest_radius`, `_scan`, `_seen`, `_insert`, `_key` and the four grid constants are deleted.
- **Native decision state.** `NativeWallDecision` ports the sums, the published times and the staggered cadence line by line (posmod for `_first_due`, `(tick + near) % cadence`, wrapping int64 arithmetic, health read from the new `NativeWalls::health_of`). `WallDecision` keeps its twelve public methods (statics unchanged, instance methods delegate) plus `native()`; `_walls`, `_cadence`, `_span`, `_ttd`, `_sums`, `_run_first`, `_run_last`, `_tick`, `_evaluated` and `_first_due` are deleted.
- **Static rules and their twins.** The five statics stay GDScript; their C++ twins are static members of `NativeWallDecision`, bound as `NativeSim.probe_rules(op, a, b, c, d)`. `test_native_structures.gd` compares every element of the pin test's grids (90 damage pairs, 25 by 88 ttd pairs, 117 walk pairs, 1,056 should_break / keep_breaking combinations) between the probe and the GDScript.
- **Mutation probe.** Changing the tie rule to `edge <= best_edge` and `_first_due` to `posmod(tick, cadence)` in one build failed `proto_through`, `ties_nearest`, `ties_visible`, `ties_through` and the shipped and ring decision pins (the cadence-one pin correctly stays green, because posmod by 1 is 0 either way); reverted, rebuilt, 8/8 again.
- **Enemy trace oracle.** `tools/stress/enemy_trace.gd` and three trailing `on_tick: Callable = Callable()` parameters (ReplayDriver.run now has 8 parameters, ReplayScenarios.run and its four runners, GateStress.run and `_march`) with the line format documented in the file header exactly as plan 04-19 reads it. Default bounds are `ReplayScenarios.max_ticks(name)` and `SimClock.ticks(GateStress.DEFAULT_MAX_SECONDS)`; `--ticks` only lowers them. Output goes only to a `.txt` under `build/` through `ReplayCli.safe_dir`.
- **One implementation.** The GDScript bodies are gone; no runtime fallback.

## Trace oracle (default bounds, seed = the scenario's default, every pair of runs byte-identical)

```
ENEMY_TRACE_OK scenario=smoke ticks=703 lines=1689 sha256=4ea94b101b642aab727a88099b1679332363f33a7b76136981eff203014e0d14
ENEMY_TRACE_OK scenario=army ticks=1353 lines=9862 sha256=5b0b801643ceb14ddccbca48a6b7345c75b5c27656bdcb464783e495d44c9744
ENEMY_TRACE_OK scenario=walls ticks=1961 lines=8726 sha256=77e5d492adc1bb2cc8f521c5c3c606e67633242afbac1f26d6e45e870c1c0232
ENEMY_TRACE_OK scenario=gate ticks=658 lines=143991 sha256=71d4ce27514fe2dacda5e13e0b7e4005d6f1b8791f553439c8076b8bd4124a03
ENEMY_TRACE_OK scenario=full_idle ticks=6911 lines=40301 sha256=7d3750248e67648434c47ea2de45e9b58ceb14944cbd4b01661f8713dbec4021
ENEMY_TRACE_OK scenario=walls ticks=400 lines=3789 sha256=f024544bc801bcd1d985b54345ce665597eb1afbbd5c8ce77acab6629afe3052
```

File sizes: smoke 86,516 bytes, army 502,952, walls 446,954, gate 8,153,537, full_idle 2,136,249. These were taken with the GDScript enemy step (the native structure index and decision state underneath), the code at `c4c09ba`/`bf873e2`; plan 04-19's native step must reproduce every line. The gate stops at tick 658 (all 300 crossed at 21.93 s), well inside its 1800-tick limit (the Flagged Assumption).

## Measured results

All numbers are from this laptop, headless, one run at a time, nothing else running (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...`; stress shape `--map=stress --enemies=300 --warmup=300 --steps=300`, prototype shape `--enemies=300 --steps=30`). The GDScript enemy step is otherwise unchanged.

**After this plan** (code at `c4c09ba`, five runs each, one at a time):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=22.69 p95_ms=42.27 max_ms=148.74
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=17.88 p95_ms=36.92 max_ms=61.00
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=19.97 p95_ms=36.17 max_ms=113.31
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=16.80 p95_ms=26.50 max_ms=107.50
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=14.46 p95_ms=19.94 max_ms=28.34
STEP_BENCH enemies=300 steps=30 mean_ms=12.41 p95_ms=15.59 max_ms=16.21
STEP_BENCH enemies=300 steps=30 mean_ms=14.47 p95_ms=19.39 max_ms=20.53
STEP_BENCH enemies=300 steps=30 mean_ms=10.25 p95_ms=12.48 max_ms=13.70
STEP_BENCH enemies=300 steps=30 mean_ms=10.55 p95_ms=13.83 max_ms=17.20
STEP_BENCH enemies=300 steps=30 mean_ms=11.35 p95_ms=17.92 max_ms=18.08
```

| Shape | 04-18 median (after) | This plan, median of 5 | Difference |
|-------|---------------------|------------------------|------------|
| Stress, step mean | 22.78 ms | 17.88 ms | -4.90 ms |
| Prototype, step mean | 22.80 ms | 11.35 ms | -11.45 ms |

**Reading the figures honestly.** The laptop drifts between sessions (04-18 saw the prototype series bimodal at about 15 or 25 to 38 ms), so the cross-session drop is an upper bound on what this plan did. The fair judge is the interleaved A/B on the same machine state: `structure_index.gd` and `wall_decision.gd` of `a4308cb` (the GDScript implementation) swapped in and out against the committed native facades, five pairs per shape, the order alternating, the working files restored and `cmp`-checked afterwards (`RESTORED_OK`), the native library the same in both arms:

```
stress     pair 1: gd=22.32 native=17.58   pair 2: native=19.76 gd=20.80   pair 3: gd=17.77 native=14.99
           pair 4: native=13.41 gd=15.95   pair 5: gd=16.31 native=14.20
prototype  pair 1: gd=10.92 native=8.44    pair 2: native=19.78 gd=17.89   pair 3: gd=12.73 native=9.42
           pair 4: native=8.59 gd=18.61    pair 5: gd=26.02 native=9.50
```

Stress: gains of gdscript minus native 4.74, 1.04, 2.78, 2.54 and 2.11 ms, every pair positive, median +2.54 ms (mean +2.64 ms); column medians 17.77 ms (GDScript) against 14.99 ms (native). Prototype: gains 2.48, -1.89, 3.31, 10.02 and 16.52 ms, median +3.31 ms; column medians 17.89 against 9.42 ms, with one outlier arm (26.02) inflating the means, so I trust the sign and not the size. The structure index and wall decision state take a reproducible 2 to 3 ms off the stress-shape step (consistent with the diagnosis: rebuild 0.4 to 0.5 ms and `nearest_visible` about 1.6 ms of the profile, plus the per-enemy `ttd_of` and attacker calls). The stress-shape step is still far from the 5 to 6 ms the 8.0 ms frame budget needs: the enemy step itself crosses in 04-19 and the budget is judged in 04-21. There is no gain bar in this plan.

## Task Commits

1. **Task 1 (tracer), pins on the GDScript:** `a4308cb` (test)
2. **Task 1, NativeStructures and NativeWallDecision, StructureIndex and WallDecision delegating, GDScript bodies deleted, probe and direct tests:** `c4c09ba` (feat)
3. **Task 2, the enemy trace tool, the three read-only hooks and the trace tests:** `bf873e2` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `native/src/native_structures.h`, `native/src/native_structures.cpp` - NativeStructures
- `native/src/native_wall_decision.h`, `native/src/native_wall_decision.cpp` - NativeWallDecision and the static twins
- `native/src/native_sim.h`, `native/src/native_sim.cpp` - `probe_rules` and the five `OP_RULE_*` constants
- `native/src/native_walls.h`, `native/src/native_walls.cpp` - `health_of` (bound and plain)
- `native/src/register_types.cpp` - registers the two classes
- `simulation/night/structure_index.gd` - snapshot gather, four queries and `native()`, grid deleted
- `simulation/nav/wall_decision.gd` - hands the run arrays and numbers over, per-tick state deleted, `native()`
- `tools/stress/enemy_trace.gd`, `tools/replay/replay_driver.gd`, `tools/replay/replay_scenarios.gd`, `tools/stress/gate_stress.gd` - the trace tool and the hooks
- `tests/unit/test_structure_decision_pins.gd`, `tests/unit/test_native_structures.gd`, `tests/unit/test_enemy_trace.gd` (with their .uid files)

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] A direct test of the native entry points**
- **Found during:** Task 1 (exact_port_rules 10 and threat T-04-60 require unknown ids, indices and sizes to answer what the GDScript answered, but the facades pass only well-formed values and the pins cover only good input)
- **Issue:** nothing exercised `NativeStructures` and `NativeWallDecision` directly for unknown unit ids and spot indices, mismatched snapshot arrays, an unsorted snapshot, NaN or infinite ranges and positions, a decision with no wall mirror or mismatched run arrays, or `health_of` outside the segments.
- **Fix:** added `tests/unit/test_native_structures.gd` (14 tests), which also holds the rule-twin comparison.
- **Files modified:** tests/unit/test_native_structures.gd (new, not in the plan's files_modified)
- **Committed in:** `c4c09ba`

**2. [Rule 3 - Blocking] `NativeWalls::health_of`**
- **Found during:** Task 1 (the decision's `end_tick` reads `walls.health_of(segment)`; the 04-17 mirror kept health but exposed only `is_intact`)
- **Issue:** the native decision had no way to read segment health without crossing back into GDScript.
- **Fix:** added `health_of` (bound and plain) to NativeWalls, answering 0 outside the segments as `WallSystem.health_of` does.
- **Files modified:** native/src/native_walls.h, native/src/native_walls.cpp (not in the plan's files_modified)
- **Committed in:** `c4c09ba`

### Plan conformance notes (not deviations)

- The plan's step order (swap, check, then delete the bodies, check again) collapsed to one step: the facades were rewritten with the old bodies already removed and the pins, named suites, replays and gate were run on that code. The old GDScript still exists as the `a4308cb` arm of the A/B.
- `StructureIndex` has five public methods (the four plus `native()`), WallDecision thirteen, Pathing and the others unchanged. The plan's "keeps its four public methods" is read as "keeps these four, unchanged"; `native()` is what 04-19 takes the object through.
- The executor rule about option C (committing the rebuilt DLL) does not apply: the owner chose option A at plan 04-16, nothing binary is committed and CI builds both libraries from source.
- The plan lists `ReplayScenarios.run(name, run_seed)` gaining the hook; `--ticks` below a replay's own bound therefore stops the recording, not the run (the run is read-only and finishes in seconds). The gate run is genuinely bounded.

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking). **Impact:** none on scope or numbers; both additions were needed for the plan's own contracts.

## Issues Encountered

- A bounded `bash` foreground command exceeded 120 s once (the eight-suite loop); it was moved to the background by the tool and finished normally.
- The local build is MSVC only (`/W4 /WX` clean). The C++ is written warning-free for GCC (`-Wall -Wextra -Werror`, no unused parameters or private fields, no signed/unsigned comparisons, no shadowing of member functions by parameters) but was not compiled with GCC here; the Linux CI job compiles it on the next push.

## Notes for plan 04-19 (the native enemy step)

- Take `StructureIndex.native()` and `WallDecision.native()` and keep a `Ref`. `NativeStructures::scan_nearest`, `scan_visible(pos, aggro, const NativeWalls*, radius, ranged_reach)` and `scan_through_walls` are the plain C++ queries; `unit_position`, `unit_radius`, `has_unit`, `building_centre`, `building_radius`, `is_standing` and `candidate_count` read the snapshot StructureIndex.rebuild takes once per step (the facade still calls `rebuild` in GDScript).
- `NativeWallDecision` has `begin_tick`, `add_attacker`, `end_tick`, `ttd_of`, `evaluated_count`, `hysteresis_ticks`, `notice_range` and the five statics (`damage_per_300`, `ttd_ticks`, `walk_ticks`, `should_break`, `keep_breaking`), all plain C++.
- The oracle: `bash tools/godot.sh --headless --path . -s res://tools/stress/enemy_trace.gd -- --scenario=<name> --out=build/trace/<name>.txt` and compare the file to the one the GDScript step wrote (hashes above), line format in the tool's header.

## Known Stubs

None.

## Threat Flags

None. T-04-49 is mitigated by the argument allowlist and `ReplayCli.safe_dir` (tested: `..`, `res://tests/`, a bare `build`, a non-.txt file and a sibling prefix are refused). T-04-59 by the pins on the GDScript first, never edited, plus the four replays and the gate digest in both verifies and the mutation probe above. T-04-60 by the native bounds checks (unknown id or index, mismatched sizes, NaN and infinite input) tested in `test_native_structures.gd`.

## Verification results

- Task 1 verify chain: `NATIVE_BUILD_OK`, test_structure_decision_pins 8/8, test_spatial_index 12/12, test_wall_decision 12/12, test_los_targets 11/11, test_melee_breaks_to_target 10/10, test_debug_overlay_crowd_sections 12/12, test_native_rules_guard 10/10, test_native_extension 5/5, test_native_walls 7/7, test_native_structures 14/14; four replays; gate; lint clean.
- Task 2 verify chain (`CHAIN2_DONE`, all exits 0): `NATIVE_BUILD_OK`, full suite `bash tools/test.sh`: 207 scripts, 1940 tests, 33733 asserts, all passing (baseline 204 / 1909 / about 31260; +3 scripts and +31 tests are test_structure_decision_pins 8, test_native_structures 14 and test_enemy_trace 9), the named suites present in the JUnit XML, two walls traces byte-identical, the default-bound gate trace OK, lint clean (352 files).
- Digests after Task 2: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks, against tests/golden), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353), walls `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (1961), full_idle `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911), `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. All unchanged.
- Acceptance: the pins file is in one commit (`a4308cb`) older than the first commit that creates `native_structures.cpp` (`c4c09ba`) and unchanged since; `structure_index.gd` has rebuild, nearest, nearest_visible, nearest_through_walls and `native()`; `wall_decision.gd` has its 12 public methods plus `native()`; `tools/stress/enemy_trace.gd` and its .uid exist, print ENEMY_TRACE_OK with the file's sha256 for all five scenario names, and contain no hard-coded tick count (the bounds come from `ReplayScenarios.max_ticks` and `GateStress.DEFAULT_MAX_SECONDS`); two runs of every scenario are byte-identical; ten bench lines and the A/B above.

## Next Phase Readiness

Ready for 04-19. Every helper the enemy step reads (the wall mirror, the grid, the field, the route, the structure index, the decision state) is native and bit-identical, and the step port has a per-tick oracle. PLAT-01 stays open until the whole step crosses and 04-21 re-measures the stress night against 8.0 ms.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

- Created files exist: native/src/native_structures.h, native/src/native_structures.cpp, native/src/native_wall_decision.h, native/src/native_wall_decision.cpp, tests/unit/test_structure_decision_pins.gd, tests/unit/test_native_structures.gd, tests/unit/test_enemy_trace.gd, tools/stress/enemy_trace.gd (all tracked).
- Commits found in git log: a4308cb, c4c09ba, bf873e2; `git rev-list --count de16d2d..HEAD` = 3 before this SUMMARY's own commit.
- Re-run after the last code change: the Task 2 verify chain including the full suite, the trace series, the bench series and the A/B (working files restored and `cmp`-checked), lint.
