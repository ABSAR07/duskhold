---
phase: 02-night-defense-playtest-gate
plan: 02
subsystem: simulation
tags: [godot, gdscript, night-data, map-validation, test-migration, gut]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: Night data schema (SpawnPointDef, SpawnGroupDef, NightDef, EnemyDef), WaveSchedule.preview_counts, NightSim, the waveless-map fallback to the Phase 1 timed night
provides:
  - Three spawn points (west, east, north) and eight hand-authored grunt nights on the shipped prototype map
  - 180 m ground plane
  - E2eSupport.shipped_prototype_map() and waveless_prototype_map(); spawn_map with no map runs waveless
  - Every Phase 1 day and loop suite moved onto a waveless copy, plus ShotScenarios.needs_timed_night for the two timed-night screenshots
  - MapConfig night and enemy validation with MAX_ENEMIES_PER_NIGHT (300)
  - Contract tests pinning D-07, D-09 and D-10 on the shipped data
affects: [02-03, 02-04, 02-05, 02-06, 02-07, 02-08, 02-09, 02-10, 02-11]

actuals:
  tokens: 7500
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Phase 1 tests build from E2eSupport.waveless_prototype_map(); night tests pass shipped_prototype_map() explicitly"
    - "validate() reports one error per bad item; a night with zero total reports 'has no enemies' only when no finer error already explains it"
    - "Spawn points are authored on the castle-to-tower ray 1.2x beyond the plot so a straight march crosses a tower plot"

key-files:
  created:
    - tests/integration/test_prototype_nights.gd
    - tests/unit/test_map_validate_nights.gd
    - tests/unit/test_night_data_contract.gd
  modified:
    - data/maps/prototype_map.tres
    - presentation/map/prototype_map.tscn
    - simulation/defs/map_config.gd
    - tests/e2e/e2e_support.gd
    - tests/e2e/test_dawn_payout.gd
    - tests/e2e/test_start_night_hold.gd
    - tests/integration/test_loop_gold_carryover.gd
    - tests/support/overlay_test_support.gd
    - tests/unit/test_build_phase_guard.gd
    - tests/unit/test_dawn_income.gd
    - tests/unit/test_run_manager.gd
    - tools/screenshot/shot_runner.gd
    - tools/screenshot/shot_scenarios.gd

key-decisions:
  - "Night ramp is the RESEARCH starter (5, 8, 11, 14, 18, 22, 27, 33 enemies over 1, 1, 2, 2, 2, 3, 3, 3 spawn points); plan 02-10 retunes it against the balance report (D-10)"
  - "spawn_map(test) with no map now means the waveless prototype; Phase 2 night tests always pass a map explicitly"
  - "The validation cap (300) sits below WaveSchedule.MAX_GROUP_COUNT (500): the per-night cap is the data error, the per-group cap stays as the runtime backstop"

patterns-established:
  - "Contract tests pin structure (counts of nights and spawn points, ray placement, escalation), not tuning numbers, so retuning in 02-10 does not break them"
  - "RED commits carry the constant or helper stubs needed so the target tests fail on assertions, not parse errors"

requirements-completed: [LOOP-03, LOOP-07]

coverage:
  - id: D1
    description: "Starting night 1 on the shipped map spawns exactly the previewed west-road enemies and stays NIGHT until all are dead, then enters DAWN"
    requirement: LOOP-03
    verification:
      - kind: integration
        ref: "tests/integration/test_prototype_nights.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every Phase 1 day and loop suite proves its rule on a waveless copy while the shipped map keeps its eight nights"
    requirement: LOOP-03
    verification:
      - kind: integration
        ref: "tests/integration/test_prototype_nights.gd#test_the_waveless_copy_has_no_nights_and_leaves_the_shipped_map_untouched"
        status: pass
      - kind: other
        ref: "bash tools/test.sh (440 tests in 56 scripts, all passing)"
        status: pass
    human_judgment: false
  - id: D3
    description: "MapConfig.validate() reports bad night and enemy data without blocking, caps a night at 300 enemies, and a night past the list clears at once"
    requirement: LOOP-03
    verification:
      - kind: unit
        ref: "tests/unit/test_map_validate_nights.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "The shipped night data keeps D-07 (eight nights), D-09 (one spawn point on night 1, never fewer afterwards, three on night 8, each on a tower ray) and D-10 (never easier)"
    requirement: LOOP-07
    verification:
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "Whether the authored ramp and spawn directions feel right to play"
    requirement: LOOP-07
    verification: []
    human_judgment: true
    rationale: "Fun and pacing are judged at the Phase 2 playtest gate; plan 02-10 retunes the numbers against the balance report"

duration: 20min
completed: 2026-10-05
status: complete
plan_head_before: 784725c1026817e9d3a70734049561f484388adf
plan_head_after: fdab2a404e1052d4562d1db731a912a95c7a0258
commits: 4
---

# Phase 2 Plan 02: Eight Authored Nights and Night Data Validation Summary

**The prototype map now plays eight hand-authored grunt nights from three spawn points placed on the castle-to-tower rays, every Phase 1 suite proves its rule on a waveless copy, and bad night data is reported and capped at 300 enemies per night.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-10-05T06:57:48Z
- **Completed:** 2026-10-05T07:17:18Z
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 19 (including `.gd.uid` files)

## Accomplishments

- `data/maps/prototype_map.tres` carries spawn points `west` (-66, 0, 24), `east` (66, 0, 24) and `north` (0, 0, -66), each 1.2x beyond its tower plot on the castle-to-plot ray, and eight NightDefs (night 1 west 5; night 2 west 8; night 3 west 6, east 5; night 4 west 7, east 7; night 5 west 9, east 9; night 6 west 8, east 7, north 7; night 7 west 9, east 9, north 9; night 8 west 11, east 11, north 11). Castle health 40, radius 3.5. The ground plane is 180 m square.
- `E2eSupport.shipped_prototype_map()` and `waveless_prototype_map()` (deep copies, DR-12) exist, and `spawn_map` with no map runs waveless. The seven Phase 1 places that reached DAWN through the timed night (run manager, dawn income, build-phase guard, gold carry-over, overlay support, dawn payout, start-night hold) build from the waveless copy with their assertions untouched. `ShotScenarios.needs_timed_night` keeps the `night_banner` and `dawn_payout` shots on the timed night; the other shots never start a night.
- `test_prototype_nights` proves night 1 spawns `preview_counts(map, 1)[west]` enemies within scatter of the west spawn point, stays NIGHT while any enemy lives or is pending, and enters DAWN with the last death.
- `MapConfig.validate()` reports each bad item exactly once with its name (null or duplicate enemy or spawn point, unknown ids, count <= 0, negative delay or interval, `max_health`, `move_speed` or `attack_interval` <= 0, `castle_max_health` <= 0, a night above `MAX_ENEMIES_PER_NIGHT`), and a night totalling zero is `night N has no enemies`. A night number past the authored list spawns nothing and `is_cleared()` is true at once (tested directly on NightSim).
- `test_night_data_contract` pins D-07, D-09 and D-10 structure on the shipped data.

## Task Commits

1. **Task 1 RED: failing tests for the nights and the waveless helpers** - `8054cd8` (test)
2. **Task 1 GREEN: eight nights, ground, migrated suites, screenshot gate** - `f37ce9a` (feat)
3. **Task 2 RED: failing validation tests and the data contract** - `2b611d5` (test)
4. **Task 2 GREEN: night and enemy validation with the cap** - `fdab2a4` (feat)

**Plan metadata:** recorded in the final docs commit.

## Files Created/Modified

See `key-files`. Notable: `tests/e2e/e2e_support.gd` (the two map helpers), `simulation/defs/map_config.gd` (rewritten night validation), `data/maps/prototype_map.tres` (generated once from a script, then checked by the contract tests).

## Decisions Made

- The ramp numbers are data and a starting point; the contract tests pin only structure so 02-10 can retune freely.
- `validate()` reports "has no enemies" only when no finer error already explains the empty night, so a zero-count group yields one error, not two.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Spec conflict] "Exactly one new error" versus a zero total**
- **Found during:** Task 2
- **Issue:** The behavior list wants exactly one error for a group with count 0, and also an error `night N has no enemies` when a night totals zero. On a one-group night those two rules both fire (the code from 02-01 reported both a bad-count and a no-enemy error).
- **Fix:** the no-enemies error is added only when the night has no other error (no groups, or none countable); a zero-count group on a single-group night therefore reports once, naming `night N group M`.
- **Files modified:** `simulation/defs/map_config.gd`
- **Verification:** `test_a_night_whose_groups_total_zero_has_one_error_not_two`
- **Committed in:** `fdab2a4`

### Interface details that differ from the plan's sketch (no behavior change)

- 02-01 had already added most of the night validation (and a 500-per-group runtime cap in `WaveSchedule`). Task 2 split its combined messages into one per rule, added the move_speed, attack_interval, per-night cap and group-numbered messages, and kept the rest. The RED commit carries the `MAX_ENEMIES_PER_NIGHT` constant so the new tests fail on assertions instead of a parse error.
- The migrated suites lost their now-unused `PROTOTYPE_MAP` constant.

---

**Total deviations:** 1 auto-fixed (Rule 1 spec conflict)
**Impact on plan:** none beyond the message wording; all behavior-list cases hold.

## Issues Encountered

None. One typo in the first helper (`PROTOTYPE_MAP` instead of `PROTOTYPE_MAP_PATH`) was caught by the first RED run before any commit.

## Known Stubs

None.

## Threat Flags

None. T-02-04 (night counts and ids from data) is mitigated by the new validation, the 300 cap and the clears-at-once night past the list; T-02-05 (Phase 1 tests weakened) is covered because only the map source changed in migrated tests and the full suite is green in the same change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The shipped map now has real nights; later plans (castle damage, enemy attack, ranged type, telegraph, results screen) build on `shipped_prototype_map()` for night tests.
- Plan 02-05 adds the ranged type to `enemies` and the D-08 rule to `test_night_data_contract.gd`; plan 02-10 retunes the ramp.
- The screenshot tool was not run (it needs a real renderer); `needs_timed_night` is pinned by a unit test.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present (three new test suites, SUMMARY); modified data, scene and helper files contain the plan's acceptance strings.
- Commits `8054cd8`, `f37ce9a`, `2b611d5`, `fdab2a4` exist; `git rev-list --count 784725c..HEAD` is 4.
- Full suite: 56 scripts, 440 tests, all passing; `bash tools/lint.sh` clean; test_prototype_nights, test_start_night_hold, test_loop_gold_carryover, test_map_validate_nights and test_night_data_contract all present in the JUnit XML.
