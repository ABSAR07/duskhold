---
phase: 03-king-combat-troops
plan: 02
subsystem: simulation
tags: [godot, gdscript, squads, respawn, dawn-restore, map-validation, building-models]

requires:
  - phase: 03-king-combat-troops
    provides: "03-01 SquadSystem/UnitSystem/Squad on the fixed step, unit_* events, barracks_1 and archery_1 plots, squad fields on BuildingTierDef and MapConfig"
provides:
  - "Night trickle: one replacement per squad_respawn_seconds (10/7/4 s as whole ticks) at the building post while the building stands; frozen on rubble; cleared at the cap"
  - "SquadSystem.restore_for_dawn(): full health, every missing seat at its slot around the unmoved anchor, countdown dropped, squad_restored once per squad"
  - "SquadSystem.replacement_progress(): 0..1 toward the next replacement for the later HUD plans"
  - "SimEvents.squad_restored with SimSignals.ALL and SimRecorder entries; UnitViews refills bars on it"
  - "RunManager takes a trailing squads argument and restores squads after the rebuild and king heal, before the payout"
  - "MapConfig._validate_squads(): one readable error per bad unit or squad number (T-03-04, T-03-05)"
  - "test_military_data_contract pinning D-01, D-02, D-03, D-05, D-06, D-07"
  - "Six Barracks and Archery Range wrapper scenes and catalog entries"
affects: [03-04, 03-05, 03-06, 03-07, 03-09, 03-10, 03-11, 03-12]

actuals:
  tokens: 14400
  tasks: 2
  commits: 4

plan_head_before: abb8ad9164a53fbfbc4e3bc4ec9c6d77cd3a6f2f
plan_head_after: b3114113dbbcd195ce5fff8fa60e6220d5e3cf4c
commits: 4

tech-stack:
  added: []
  patterns:
    - "Countdown fields live on Squad (replacement_ticks_left / replacement_total_ticks); progress is derived, never stored"
    - "Wrapper scenes are generated from kept kit GLBs in the house/tower pattern (a Model node holds the scale)"

key-files:
  created:
    - tests/unit/test_squad_respawn.gd
    - tests/integration/test_squad_lifecycle.gd
    - tests/unit/test_map_validate_squads.gd
    - tests/unit/test_military_data_contract.gd
    - presentation/buildings/models/barracks_t1.tscn
    - presentation/buildings/models/barracks_t2.tscn
    - presentation/buildings/models/barracks_t3.tscn
    - presentation/buildings/models/archery_range_t1.tscn
    - presentation/buildings/models/archery_range_t2.tscn
    - presentation/buildings/models/archery_range_t3.tscn
  modified:
    - simulation/squads/squad_system.gd
    - simulation/squads/squad.gd
    - simulation/squads/unit_system.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - presentation/units/unit_views.gd
    - simulation/defs/map_config.gd
    - presentation/buildings/building_view_catalog.tres
    - tests/unit/test_spot_label_model.gd
    - tests/e2e/test_building_models.gd
    - tests/e2e/test_unit_views.gd

key-decisions:
  - "The countdown starts on the first night step that finds the squad short and a replacement arrives exactly SimClock.ticks(respawn_seconds) steps later; after a spawn the countdown is cleared and restarts next step, so the second replacement is one full interval after the first"
  - "A replacement is raised at squad.home (the post) in the lowest free slot and walks to the slot in the same step; the dawn restore raises at the slot around the current anchor"
  - "Dawn restore runs inside _enter_dawn after rebuild_destroyed and the king heal and before buildings_rebuilt is emitted, so the building state is already back when squad_restored fires"
  - "UnitSystem.heal_to_full is the 20th and last public method the gdlint cap allows; later plans that need a unit writer must start a new file"
  - "MapConfig validation: a non-finite unit float is reported once as that and its range checks are skipped (the enemy rule); attack_interval and squad_respawn_seconds share the castle bounds [SimClock.STEP, 3600 s]"
  - "Barracks wrappers stack Castle Kit wall/base blocks (lone blockhouse, 2x2 keep, keep with corner turrets); Archery Range wrappers use Fantasy Town Kit slabs and gables (lean-to, two bays with a door, two floors); placeholders for the Phase 8 art pass"

patterns-established:
  - "RED with an inert API skeleton: the signal, SimSignals and recorder entries and stub methods land with the failing tests so the tests compile and fail on assertions, not on parse errors"
  - "A test that needs a stationary live enemy sets the grunt move_speed to 0.001 on its own map copy, then kills it from inside a signal handler to end the night on a chosen step"

requirements-completed: [UNIT-07, UNIT-04]

coverage:
  - id: D1
    description: "During the night a squad below its cap whose building stands gets one replacement per tier interval (10/7/4 s as whole ticks) at the post in the lowest free slot; a squad at its cap runs no countdown; progress rises 0..1"
    requirement: UNIT-07
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_respawn.gd (tier one, two, three pace; at cap; progress; post and slot; cap clears countdown; zero squad)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A fallen building freezes the countdown and spawns nothing; after the free rebuild it resumes where it stopped; replacements due on the same step go in squad creation order"
    requirement: UNIT-07
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_respawn.gd#test_a_fallen_building_freezes_the_countdown_and_spawns_nothing"
        status: pass
      - kind: unit
        ref: "tests/unit/test_squad_respawn.gd#test_replacements_due_on_the_same_step_follow_the_creation_order"
        status: pass
    human_judgment: false
  - id: D3
    description: "At dawn every squad is back to full numbers and health, missing units appear at their slots around the unmoved anchor, squad_restored fires once per squad before the dawn payout, no gold is charged, and an emptied squad with a fallen building is rebuilt and restored"
    requirement: UNIT-07
    verification:
      - kind: integration
        ref: "tests/integration/test_squad_lifecycle.gd (4 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_squad_respawn.gd (dawn restore tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A replacement due on the last step of a night spawns before the night ends and dawn restores the rest; by day an upgrade fills new seats in the same step and every unit stands at its slot"
    requirement: UNIT-07
    verification:
      - kind: integration
        ref: "tests/integration/test_squad_lifecycle.gd#test_a_replacement_due_on_the_last_step_of_the_night_spawns_before_dawn"
        status: pass
      - kind: integration
        ref: "tests/integration/test_squad_lifecycle.gd#test_during_the_next_day_every_unit_stands_at_its_slot"
        status: pass
    human_judgment: false
  - id: D5
    description: "MapConfig.validate() reports bad unit and squad data (empty/duplicate/unknown ids, non-finite and non-positive numbers, attack and respawn intervals outside one step to one hour, squad sizes, post distance) with one readable error each, and a RunContext still constructs on a bad copy"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_map_validate_squads.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The shipped military numbers are pinned (costs 4/8/16, squads 4/8/14 with the D-01 step shape, respawn 10/7/4 s, footman a fifth of the king, plots last, inside the tower ring and at least 5 m clear)"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_military_data_contract.gd (6 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "A military plot reads 'Squad of N' for its next tier, and each Barracks and Archery Range tier renders its own wrapper scene, no smaller than the tier below"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_spot_label_model.gd (2 new tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_building_models.gd (barracks and archery range tier tests)"
        status: pass
    human_judgment: false
  - id: D8
    description: "How the placeholder Barracks and Archery Range models read next to the House and Tower models, and whether the replacement trickle pace feels right"
    verification: []
    human_judgment: true
    rationale: "Look and feel are judged by the owner at the Phase 3 UAT; plan 03-11 retunes the numbers and the Phase 8 art pass may replace the models"

duration: 29min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 02: Squad Life Cycle, Validation and Models Summary

**Squads trickle back one unit per tier interval at night, are whole at dawn without moving, and their data is validated and pinned, with a model for every Barracks and Archery Range tier**

## Performance

- **Duration:** 29 min
- **Started:** 2026-10-10T09:31:09Z
- **Completed:** 2026-10-10T10:00:55Z (code); SUMMARY and tracking follow
- **Tasks:** 2 (both TDD: RED then GREEN each)
- **Files modified:** 28 (10 created, 18 modified, per `git diff --name-only abb8ad9 HEAD`)

## Accomplishments

- **UNIT-07 night trickle (D-05):** a squad below its cap whose building stands counts down `SimClock.ticks(squad_respawn_seconds)` night steps (300 / 210 / 120) and raises one unit at the post in the lowest free slot, then starts over; a squad at its cap clears its countdown; rubble freezes it where it is.
- **UNIT-07 dawn restore (D-14):** `restore_for_dawn()` heals survivors, raises every missing seat at its slot around the unmoved anchor, drops the countdown and emits `squad_restored` once per squad, called by `RunManager._enter_dawn` after the rebuild and king heal and before the payout. Free of charge.
- **Lifecycle edges proven:** replacement due on the last step of a night spawns before dawn (stationary-enemy trick), an emptied squad whose building fell comes back after the free rebuild, the squad stands at its post the next day, by-day upgrades fill new seats at once.
- **T-03-04 / T-03-05 validation:** `MapConfig._validate_squads()` gives one readable error per finding for unit ids, every unit float, ranges, attack and respawn seconds in [SimClock.STEP, 3600 s], squad size in 1..`MAX_UNITS_PER_SQUAD`, post distance and non-military tiers.
- **Pinned military data:** `test_military_data_contract` guards D-01/D-02/D-03/D-05/D-06/D-07 so plan 03-11's retune moves a number deliberately.
- **Models:** six wrapper scenes from kept kit pieces and six catalog entries; the Barracks and Archery Range no longer draw as the House-style box.
- Suite: 103 scripts / 888 tests at baseline to 107 scripts / 929 tests, all passing; smoke golden digest `2599c7c2...` unchanged; lint clean.

## Task Commits

1. **Task 1 RED: failing tests + inert skeleton** - `950c9d6` (test)
2. **Task 1 GREEN: trickle, dawn restore, wiring** - `5fe0d0d` (feat)
3. **Task 2 RED: failing validation, contract, label and model tests** - `78de869` (test)
4. **Task 2 GREEN: `_validate_squads` and six models** - `b311411` (feat)

RED evidence for both tasks: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`) for `test_a_replacement_due_on_the_last_step_of_the_night_spawns_before_dawn` / `test_a_tier_one_squad_gets_a_replacement_every_ten_seconds_of_night` (Task 1) and `test_a_building_unit_id_that_does_not_resolve_is_reported` / `test_every_barracks_tier_uses_its_wrapper_scene_and_grows` (Task 2).

## TDD Gate Compliance

RED (`test(03-02)`) precedes GREEN (`feat(03-02)`) for both tasks. Task 1's RED commit carries an inert skeleton (the `squad_restored` signal with its SimSignals and recorder entries, the Squad fields, stub methods) so the tests compile and fail on assertions. In Task 2 RED, `test_military_data_contract` and the two `test_spot_label_model` tests passed immediately: they pin data and an `effect_line()` branch already shipped in 03-01, so they are guards rather than driven behaviour. No REFACTOR commit was needed.

## Files Created/Modified

See `key-files` above. Notable: `simulation/squads/squad_system.gd` (`_trickle`, `_raise_unit`, `restore_for_dawn`, `replacement_progress`), `simulation/defs/map_config.gd` (`_validate_squads` and helpers), `simulation/run/run_manager.gd` (squads argument and dawn call).

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing coverage] Bar refresh had no test**
- **Found during:** Task 1 (UnitViews wiring)
- **Issue:** the plan asks UnitViews to refill hurt-only bars on `squad_restored` but lists no test for it
- **Fix:** added `test_the_dawn_restore_hides_the_bars_of_a_healed_squad` to `tests/e2e/test_unit_views.gd` (outside the plan's `files_modified`)
- **Verification:** `test_unit_views` 3/3
- **Committed in:** `5fe0d0d`

**2. [Rule 1 - Bug] Lifecycle test asserted the wrong dawn ordering**
- **Found during:** Task 1 GREEN
- **Issue:** my first test required the `buildings_rebuilt` event before `squad_restored`; the plan puts the restore before that event is emitted (the rebuild itself already happened)
- **Fix:** the test now asserts the barracks stands when `squad_restored` fires
- **Files modified:** `tests/integration/test_squad_lifecycle.gd`
- **Committed in:** `5fe0d0d`

**3. [Observation] `BuildingTierDef.effect_line()` already had the "Squad of %d" branch**
- **Found during:** Task 2
- **Issue:** 03-01 already added the branch, so the plan's step 2 needed no code change; `building_tier_def.gd` is untouched and the new label tests pass from the start
- **Impact:** none; the tests are regression guards

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1) plus 1 observation
**Impact on plan:** no scope creep; one extra test file touched.

## Issues Encountered

- Bash heredocs containing apostrophes or very long bodies are rejected by the tool shell; the edit scripts and larger test files were written with the file tool instead.
- `gdformat` leaves working files CRLF while the index is LF (`core.autocrlf`); an edit helper preserved each file's endings and git normalised on commit.

## Known Stubs

- `UnitViews` puppets are still static bind-pose models (animation is Phase 8).
- The six military wrapper scenes are kit-piece placeholders that I could not view (headless dummy renderer); only their sizes and tier growth are asserted. The owner judges the look at the UAT.
- `replacement_progress()` has no HUD consumer yet; a later plan reads it for the "coming replacement" pip.

## Threat Flags

None. No new network endpoint, auth path or file access; T-03-04 and T-03-05 are mitigated by `_validate_squads()` and `test_map_validate_squads`; T-03-SC accepted (no packages installed).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 03-04 and later plans can read `replacement_progress()`, `squad_restored` and a squad whose numbers already behave. `UnitSystem` is at the 20-method lint cap, so a unit writer needs a new file.
- `ASSETS.md` and `attribution.json` still describe the kit GLBs as used by the House and tower tiers; the Barracks and Archery Range now also use them (no new file, no new licence), which a later asset-log pass may mention.
- Open for the owner at UAT: the pace and look of the trickle, the placeholder models.

## Self-Check: PASSED

- 10 created files present on disk (4 tests, 6 wrapper scenes); commits `950c9d6`, `5fe0d0d`, `78de869`, `b311411` exist
- full suite 929/929 passing, smoke replay `REPLAY_OK` with digest `2599c7c2...`, `bash tools/lint.sh` clean
