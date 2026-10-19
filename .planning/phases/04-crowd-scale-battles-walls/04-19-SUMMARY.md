---
phase: 04-crowd-scale-battles-walls
plan: 19
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, enemy-step, enemy-store, determinism, traces, step-bench, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plans 04-15 (gd_math.h operation table, native Separation), 04-17 (NativeWalls), 04-18 (NativeRoute, NativeField, NativeGrid), 04-23 (NativeStructures, NativeWallDecision, the enemy trace oracle) and 04-12 (the held-for-target wall rule, ported as committed); plan 04-22 stale-library guard; plan 04-16 CI that builds the library from source
provides:
  - "NativeEnemies (native/src/native_enemies.*): the enemy store (id-ordered records, binary-search id lookup, def table, killer-free removal), the EnemyIndex grid ported exactly (CELL 8.0, REACH_MARGIN 0.01, occupied-cells fallback, ascending result), and the three-call step API (begin_step, walk_pass, separate_pass)"
  - "native/src/enemy_step.cpp: the whole enemy step in C++, a line-by-line port of _publish_wall_times, _choose_target (with _choose_base_target, _target_walls_in_the_way, _aim_at_walls, _release_held_wall, _breaks_to_targets, _can_see, _target_in_sight, _pick_nearest_structure), _advance_and_strike, _separate and _push_out_of_walls, calling NativeWalls, NativeRoute, NativeStructures, NativeWallDecision and the native Separation as C++ members"
  - "EnemySystem as a facade: the 18 public methods unchanged, Record and every private rule function deleted, EnemyIndex deleted, strikes enqueued and announced in ascending attacker id between the two native passes"
  - "tests/unit/test_enemy_store_native.gd: 14 facade-contract tests, committed green on the GDScript before any native enemy file existed"
  - "tests/fixtures/trace/enemy_step_refs.txt: the five ENEMY_TRACE_OK lines of the unchanged GDScript step, committed before native_enemies.cpp and never changed"
affects: [04-20, 04-21]

actuals:
  tokens: 31000
  tasks: 2
  commits: 2

plan_head_before: 2483384b36741df107e3a2c5f9640d31bfd27159
plan_head_after: 8b8a30d79042c90a9087212706fad49f3940102a

tech-stack:
  added: []
  patterns:
    - "Three-call native step so the GDScript facade keeps the event order: begin_step, walk_pass (answers the strikes), separate_pass; the facade enqueues and announces each strike in between"
    - "Facade refreshes a native def table from every registered EnemyDef at the start of each step, because the GDScript read EnemyDef numbers live from the resource"
    - "Kinds cross as small integers (EnemyTargetKind in native_enemies.h, EnemySystem.KIND_NAMES in GDScript); killer kinds stay a GDScript Dictionary by id"
    - "Trace-first port: reference traces from the unchanged step committed as five ENEMY_TRACE_OK lines before any native file; the port matched on its first run"

key-files:
  created:
    - native/src/native_enemies.h
    - native/src/native_enemies.cpp
    - native/src/enemy_step.cpp
    - tests/unit/test_enemy_store_native.gd
    - tests/fixtures/trace/enemy_step_refs.txt
  modified:
    - simulation/night/enemy_system.gd
    - native/src/native_walls.h
    - native/src/native_walls.cpp
    - native/src/register_types.cpp
    - tests/unit/test_melee_breaks_to_target.gd
    - tests/unit/test_separation.gd
  deleted:
    - simulation/night/enemy_index.gd
    - simulation/night/enemy_index.gd.uid

key-decisions:
  - "The store is an id-ordered std::vector of records with a binary-search id lookup (array of structs), not separate arrays per field: the records are small, the step touches most fields of each, and it keeps the port line-for-line; the plan's 'struct-of-arrays' wording is an implementation hint, not a tested contract"
  - "NativeRoute is taken from Pathing's private _route by the facade (_hand_over_world): Pathing is at its 20-method cap and the plan forbids a public method on it, so no accessor was added"
  - "remove_dead removes one enemy at a time (dead_ids, then position and def read, remove, emit enemy_died), so a listener of enemy_died sees the same field the GDScript showed it: later dead enemies still present"
  - "EnemyIndex is deleted; nothing but EnemySystem used it (TargetQuery keeps calling living_within until plan 04-20)"
  - "walls_solid is computed once per step by the facade (pathing.has_intact_walls()), as the GDScript's repeated _walls_are_solid() always answered the same inside one enemy phase"

patterns-established:
  - "A test that needs a private of the store reads the native object (tests/unit/test_melee_breaks_to_target.gd reads _enemies._native.behind_kind_of(id); test_separation.gd calls _enemies._native.separate_pass(false)), the way it read _records and _separate before"

requirements-completed: []

coverage:
  - id: D1
    description: "The whole enemy phase (previous copy, D-08 wall times, every target choice including the 04-12 held-for-target rule and the castle march's break-or-detour rule, the walk and strike, the push-apart and the push out of walls) runs in C++ behind EnemySystem's unchanged 18-method facade, with the GDScript Record, step and EnemyIndex deleted"
    requirement: PLAT-01
    verification:
      - kind: integration
        ref: "ENEMY_TRACE_OK lines of smoke, army, walls, full_idle and gate equal tests/fixtures/trace/enemy_step_refs.txt byte for byte, and cmp of every new trace against its reference is empty"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests unchanged, listed below)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_enemy_store_native.gd (14 tests), full suite 208 scripts / 1954 tests / 33826 asserts, including every pin of plans 04-15, 04-17, 04-18 and 04-23, test_melee_breaks_to_target and test_determinism"
        status: pass
    human_judgment: false
  - id: D2
    description: "The stress-shape step falls from a median of 17.88 ms (04-23) to 4.58 ms and the prototype step from 11.35 ms to 2.07 ms; the enemy phase is now about 0.6 to 0.85 ms of the stress step"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "ten step_bench lines and three coarse phase-attribution runs below; the coarse replica digests equal the plain run's"
        status: pass
    human_judgment: false
  - id: D3
    description: "The 8.0 ms p95 frame budget on real hardware is not yet judged"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "PLAT-01 closes only when plan 04-21 re-measures the stress night against 8.0 ms with the squads, towers and stuck tracker (still GDScript) taken into account"

duration: 58min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 19: The Native Enemy Store and Step Summary

**The enemy store and the whole enemy step (wall times, every target choice with the 04-12 held-for-target rule and the castle march's break-or-detour rule, walk and strike, push-apart, push out of walls) now run in C++ behind EnemySystem's unchanged 18-method facade, byte-identical to the GDScript step on five per-tick traces, all four goldens and the 300-enemy gate; the stress-shape step median fell from 17.88 ms to 4.58 ms.**

## Performance

- **Duration:** about 58 min (2026-10-19T17:37Z to 18:35Z; two full-suite runs of 9.5 min each and the trace, replay and gate chains are most of it)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files:** 5 created, 6 modified, 2 deleted (plus the SUMMARY)
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; the whole chain passed end to end (five traces, the named suites, four replays, gate, lint) before Task 2 started: "Tracer verified end-to-end, expanding".

## Accomplishments

- **References first.** The five traces of the unchanged GDScript step were written at `2483384` with `tools/stress/enemy_trace.gd` and their ENEMY_TRACE_OK lines (carriage returns stripped) committed in `tests/fixtures/trace/enemy_step_refs.txt` together with the green facade contract test in `27b82f8`, before `native_enemies.cpp` existed (`8b8a30d`); neither file has changed since. The lines equal the five 04-23 measured, so the oracle is stable across sessions.
- **Native store.** `NativeEnemies` keeps the records in an id-ordered vector (spawn appends, removal keeps the order, id lookup is a binary search), the def table, and the EnemyIndex grid ported exactly: cell 8.0, reach margin 0.01, floori in double, the occupied-cells fallback when the block would be wider than the cell count, result ascending, rebuilt lazily after spawn, begin_step, the passes, removal or clear (not after `damage`, as before).
- **Native step.** `enemy_step.cpp` ports the GDScript function by function, each named in a comment; it reads the castle, king, structure snapshot (units by id, buildings by spot index, the standing membership), `NativeWalls`, `NativeRoute` and `NativeWallDecision` through their plain C++ members and calls `duskhold::separation_displacements_bucketed` for the push-apart. `NativeWalls.half_thickness_of` was added (plain member) because the step needs the segment face.
- **Facade.** `EnemySystem` is 311 lines: the same 18 public methods, the def table (index by EnemyDef, refreshed in `step`), the killer Dictionary, the died count, the read view and change counter. `step()` does begin_step, the destroyed-castle return, `_structures.rebuild`, the native target-and-walk pass, each strike enqueued then announced (`attack_fired`) in ascending attacker id, then the native push-apart pass. `Record` and every private rule function are gone; `enemy_index.gd` is deleted.
- **First-run match.** The port matched all five traces on its first build: smoke, army, walls, full_idle and gate, each `cmp`-empty against its reference.

## Trace oracle (default bounds; native step against the unchanged GDScript step)

```
ENEMY_TRACE_OK scenario=smoke ticks=703 lines=1689 sha256=4ea94b101b642aab727a88099b1679332363f33a7b76136981eff203014e0d14
ENEMY_TRACE_OK scenario=army ticks=1353 lines=9862 sha256=5b0b801643ceb14ddccbca48a6b7345c75b5c27656bdcb464783e495d44c9744
ENEMY_TRACE_OK scenario=walls ticks=1961 lines=8726 sha256=77e5d492adc1bb2cc8f521c5c3c606e67633242afbac1f26d6e45e870c1c0232
ENEMY_TRACE_OK scenario=full_idle ticks=6911 lines=40301 sha256=7d3750248e67648434c47ea2de45e9b58ceb14944cbd4b01661f8713dbec4021
ENEMY_TRACE_OK scenario=gate ticks=658 lines=143991 sha256=71d4ce27514fe2dacda5e13e0b7e4005d6f1b8791f553439c8076b8bd4124a03
```

Identical to the committed fixture (checked by `diff` against `tests/fixtures/trace/enemy_step_refs.txt` after the first build and again after the final C++ change); the full traces (`build/trace/ref_*.txt` against `new_*.txt`) `cmp` empty for all five.

Replays and gate (unchanged, run twice each):

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a
```

Full suite after the final change: **208 scripts, 1954 tests, 33826 asserts, exit 0** (baseline 207 / 1940 / about 33730; this plan adds `test_enemy_store_native` with 14 tests). The first full run, before the two tests that read EnemySystem privates were repointed, failed 9 tests (all `_records` / `_separate` accesses) and 28 asserts; nothing in the simulation failed. Lint is clean.

## Measured results

All numbers are from this laptop, headless, one run at a time, nothing else running, `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...` (stress shape `--map=stress --enemies=300 --warmup=300 --steps=300`, prototype shape `--enemies=300 --steps=30`).

**After this plan** (code at `8b8a30d`, five runs each):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=6.45 p95_ms=11.26 max_ms=63.60
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=4.30 p95_ms=6.38 max_ms=9.84
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=4.15 p95_ms=5.41 max_ms=11.87
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=4.98 p95_ms=7.71 max_ms=21.88
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=4.58 p95_ms=7.60 max_ms=10.63
STEP_BENCH enemies=300 steps=30 mean_ms=1.91 p95_ms=2.44 max_ms=2.83
STEP_BENCH enemies=300 steps=30 mean_ms=1.98 p95_ms=2.78 max_ms=2.84
STEP_BENCH enemies=300 steps=30 mean_ms=2.13 p95_ms=2.60 max_ms=3.27
STEP_BENCH enemies=300 steps=30 mean_ms=7.82 p95_ms=28.34 max_ms=35.56
STEP_BENCH enemies=300 steps=30 mean_ms=2.07 p95_ms=2.61 max_ms=3.18
```

Four more stress-shape runs taken along the way (the plain mode of the probe and two repeat runs) read 4.27, 4.18, 4.46 and 4.11 ms.

**Before** (plan 04-23's ten lines, code at `c4c09ba`, the GDScript enemy step with the native structure index and decision underneath):

```
stress     22.69  17.88  19.97  16.80  14.46  (mean_ms; median 17.88)
prototype  12.41  14.47  10.25  10.55  11.35  (mean_ms; median 11.35)
```

| Shape | Before (04-23), median of 5 | After (this plan), median of 5 | Difference |
|-------|----------------------------|--------------------------------|------------|
| Stress, step mean | 17.88 ms | 4.58 ms | -13.30 ms |
| Prototype, step mean | 11.35 ms | 2.07 ms | -9.28 ms |

**Reading the figures honestly.** The "before" lines are from the preceding plan's session (the laptop drifts between sessions, and the stress series then read 14.5 to 22.7 ms), so the drop is an upper bound on what this plan alone did, but a factor of four is far outside that drift; the diagnosis measured the enemy phase alone at 16 to 17 ms of 22 to 24 ms and the whole step is now 4 to 5 ms. One prototype run (7.82 ms, p95 28 ms) and the first stress run (6.45 ms, max 63.6 ms) are the machine's known outlier episodes; the medians ignore them. An interleaved A/B (the GDScript `enemy_system.gd` and `enemy_index.gd` swapped back in against the new library) was attempted and abandoned: the swapped-in arm failed to compile against the stale global class cache (script errors, 580 to 850 ms per "step"), so it measured nothing; the working files were restored byte for byte (`cmp`) and `git status` was clean afterwards.

**Phase attribution of the remaining step** (`prof_coarse.gd`, a coarse replica of RunContext.step and NightSim.step with clock reads around each phase and the facade's own sequence timed inside the enemy phase; its event digest equals the plain run's, `06e60a5f...3142fc` stress and `7123784d...c99e8322` prototype, so it steps the same simulation). Stress shape, 300 enemies, 50 units, 26 intact segments, steps 301 to 600, ms per step (run 1 / runs 2 and 3 for the enemy rows):

| Phase | ms/step | Share of the 4.2 to 5.9 ms step |
|-------|---------|--------------------------------|
| N4 squads.step | 1.834 | largest |
| N5 towers.step | 1.407 | |
| N8 stuck.update | 1.289 | |
| N7 enemies.step (whole facade) | 0.845 / 0.642 / 0.726 | about 14 to 16 % |
| N9 resolve_hits | 0.407 | |
| N11 squads.remove_dead | 0.080 | |
| N3 king.step | 0.027 | |
| N1 spawn_due, N10 enemies.remove_dead, N6 castle_attack, N2 pathing.refresh | 0.013, 0.007, 0.006, 0.004 | |

Inside N7: E6 native separate_pass 0.325 (0.265, 0.292), E2 StructureIndex.rebuild 0.280 (0.220, 0.247) (the GDScript gather of 50 units and the buildings), E4 native walk_pass 0.138 (0.110, 0.129), E5 strikes enqueued and announced 0.073 (0.026, 0.032) for 1.9 strikes a tick, E3 defs and world hand-over 0.017, E1 begin_step 0.003. The probe's clock reads add about 1 ms to the replica (its STEP mean is 5.94 against 4.18 plain), so the shares are coarse. Prototype shape (300 enemies, 8 units): enemies.step 0.475, stuck.update 0.818, squads.step 0.265, castle_attack 0.187, towers 0.064, step total 1.89 against 1.83 plain. Where the budget goes now: squads (04-20), towers, the stuck tracker and hit resolution are all still GDScript and together are about 5 of the 5.9 ms probe step; the enemy phase is no longer the problem. The step is 4 to 5 ms at the stress load against the 5 to 6 ms the diagnosis said the 8.0 ms frame budget needs; plan 04-21 judges the budget.

## Task Commits

1. **Task 1 (tracer), the contract and the references first:** `27b82f8` (test) - `tests/unit/test_enemy_store_native.gd` green on the GDScript and the five ENEMY_TRACE_OK lines
2. **Task 1, the native store and step, the facade, the two repointed tests:** `8b8a30d` (feat)
3. **Task 2 (measure and document):** no separate code commit. The `enemy_system.gd` header (names `native/src/native_enemies.cpp` and `native/src/enemy_step.cpp`, what stays GDScript, the exact-port contract) and the `enemy_step.cpp` opening comment (step order, the 04-12 rule, the GDScript at `2483384`) were written together with the facade in `8b8a30d`, because the facade file was rewritten there; Task 2's verify chain (native build, bench line, four replays, gate, lint) was re-run on that tree and passed.

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md. PLAT-01 stays Pending in REQUIREMENTS.md (04-21 measures the budget).

## Files Created/Modified

- `native/src/native_enemies.h`, `native/src/native_enemies.cpp` - `NativeEnemies`: store, grid, def table, bound API
- `native/src/enemy_step.cpp` - the step (`walk_pass`, `separate_pass`) and its `Stepper`
- `native/src/native_walls.h`, `native/src/native_walls.cpp` - `half_thickness_of` (plain member)
- `native/src/register_types.cpp` - registers `NativeEnemies`
- `simulation/night/enemy_system.gd` - the facade (311 lines, 18 public methods)
- `simulation/night/enemy_index.gd` (+ `.uid`) - deleted
- `tests/unit/test_enemy_store_native.gd` (+ `.uid`), `tests/fixtures/trace/enemy_step_refs.txt` - the contract and the references
- `tests/unit/test_melee_breaks_to_target.gd`, `tests/unit/test_separation.gd` - repointed from EnemySystem privates to the native store

## Decisions Made

See key-decisions above. Notes beyond them: the facade still calls `StructureIndex.rebuild` in GDScript (0.22 to 0.28 ms at 50 units, the Flagged Assumption; UnitSystem and BuildingSystem are at the 20-method cap), the `walk_pass` returns strikes as a flat `PackedInt64Array` of six values each (arrival tick, attacker id, target kind, target id, damage, flight ticks), and `NativeEnemies.target_of` answers `[kind, id]` or an empty array.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Two tests read EnemySystem privates that no longer exist**
- **Found during:** Task 1, first full-suite run (9 failing tests, 28 failing asserts, all `Invalid access to property or key '_records'` or `Nonexistent function '_separate'`)
- **Issue:** `tests/unit/test_melee_breaks_to_target.gd` read `_enemies._records[id].behind_kind` and `tests/unit/test_separation.gd` called `enemies.call("_separate")`; neither file is in the plan's `files_modified`.
- **Fix:** added the bound `NativeEnemies.behind_kind_of(id)`; the first test reads `EnemySystem.KIND_NAMES[_enemies._native.behind_kind_of(id)]`, the second calls `_enemies._native.separate_pass(false)` (walls not solid, so only the push-apart runs). Expectations are untouched; only the seam moved.
- **Files modified:** `tests/unit/test_melee_breaks_to_target.gd`, `tests/unit/test_separation.gd`, `native/src/native_enemies.h`, `native/src/native_enemies.cpp`
- **Verification:** both suites green (10 and 24 tests); second full run 1954 / 1954
- **Commit:** `8b8a30d`

**2. [Rule 3 - Blocking] The step needs a wall's half thickness in C++**
- **Found during:** Task 1 (`_wall_edge` and the wall goal radius use `walls().half_thickness_of`, and `NativeWalls::half_` is private)
- **Fix:** `NativeWalls::half_thickness_of(segment)` as a plain member (0.0 for an index out of range, like `WallSystem.half_thickness_of`); not bound to GDScript
- **Files modified:** `native/src/native_walls.h`, `native/src/native_walls.cpp`
- **Commit:** `8b8a30d`

**Total deviations:** 2 auto-fixed (both Rule 3). **Impact:** none on behaviour; two test seams moved and one accessor added. Two plan-text points were implemented differently without a rule: the store is an array of structs rather than separate arrays per field (key-decisions), and the interleaved A/B was abandoned (above).

## Authentication Gates

None.

## Issues Encountered

- The A/B swap of the old GDScript step failed (stale global class cache after deleting `EnemyIndex`): each swapped-in run printed script errors and read 580 to 850 ms per step. I stopped the benchmark processes I had started by PID, restored the working files from my scratch copy and `cmp`-checked them, and confirmed `git status` clean and a normal 4.27 ms bench afterwards.
- No difference was ever found between a new trace and a reference trace; the stop rule did not apply.

## Notes for the later `/gsd-code-review 4 --fix` pass

- **IN-01 (hot-path allocations in the enemy phase):** gone with the GDScript. The per-enemy `Vector3i` results of `_wall_ticks`, the per-call Dictionaries of `target_of` in the loop, the `Array[Record]`, the PackedArrays of `_separate` and the `Variant` boxing no longer exist. What remains in the enemy phase is the three PackedArrays that `Stepper::separate` builds per step to feed `separation_displacements_bucketed`, the strike vector, and the facade's strike loop; none is per enemy.
- **WR-02 (no tangency epsilon in `first_blocking`):** lives in `NativeWalls::blocking_segment` (`native/src/native_walls.cpp`), which `enemy_step.cpp` calls for `first_blocking`; ported unchanged on purpose.
- **WR-03 (an enemy outside the nav grid counts as sealed):** lives in `NativeRoute::is_sealed` (`native/src/native_field.cpp`), which `Stepper::aim_at_walls` calls; ported unchanged on purpose.

## Known Stubs

None.

## Threat Flags

None. The native step opens no file, network, input or scene-tree surface; it reads only what the facade hands it (T-04-50 to T-04-52 are mitigated by the five byte-identical traces, the recorder digests of the four goldens and the gate, and `test_enemy_store_native`'s unknown-id answers).

## Next Phase Readiness

Ready for 04-20 (the squad system and `TargetQuery.nearest_enemy` over `NativeEnemies.living_within`) and 04-21 (the frame budget). The enemy phase costs about 0.6 to 0.85 ms of a 4.2 to 5.9 ms stress step; squads, towers, the stuck tracker and hit resolution are the rest. `NativeEnemies` exposes the plain C++ store for a native squad or tower step to read; the facade has no room for a further public method (18 of 18), so a native reader should take the store from the facade's private `_native` as the tests do or get a packed accessor on a different class. PLAT-01 stays Pending.

## Self-Check: PASSED

- Created files exist: `native/src/native_enemies.h`, `native/src/native_enemies.cpp`, `native/src/enemy_step.cpp`, `tests/unit/test_enemy_store_native.gd`, `tests/unit/test_enemy_store_native.gd.uid`, `tests/fixtures/trace/enemy_step_refs.txt` (all tracked); `simulation/night/enemy_index.gd` and its `.uid` are gone.
- Commits exist: `27b82f8` and `8b8a30d` (`git log --oneline --all`); the fixture's adding commit `27b82f8` is an ancestor of the commit adding `native_enemies.cpp` (`8b8a30d`), and `git log --format=%H -- tests/fixtures/trace/enemy_step_refs.txt` lists only `27b82f8`.
- Acceptance: five ENEMY_TRACE_OK lines in the fixture and equal to the five new ones; `cmp` of each `new_<s>.txt` against `ref_<s>.txt` empty; `enemy_system.gd` has 18 public functions and no `class Record`; `test_enemy_store_native` committed green on the GDScript first and passing unchanged; the four replays and the gate keep their digests; ten bench lines, both medians, the phase attribution and the review-finding note are above; the `enemy_system.gd` header names `native/src/native_enemies.cpp` and `native/src/enemy_step.cpp`.
