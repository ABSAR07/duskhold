---
phase: 02-night-defense-playtest-gate
plan: 06
subsystem: simulation
tags: [godot, gdscript, dawn, rebuild, repair, income, hud, gut, loop-04, loop-05]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: Building health, destroyed and rebuilt_this_dawn on BuildingInstance, RubbleView, CastleState.repair, KingState.restore_for_dawn, DawnPayoutVfx (plans 02-03 and 02-04)
provides:
  - Dawn rebuild (LOOP-04): every building that fell in the night stands again at the tier it had, at full health, for no gold
  - Dawn repair: every standing building, the castle and the king are whole again (RESEARCH Open Question 1, D-05)
  - Rebuilt-pays-nothing rule (LOOP-05): dawn_income_by_spot skips a building rebuilt this dawn; the marks clear when the next night starts
  - SimEvents.buildings_rebuilt(spot_ids), emitted once per dawn after the repairs and before the payout
  - BuildingViews swaps the rubble for the model at its tier (rise tween) and re-reads every health bar
  - DawnNoIncomeMarker, the crossed-out coin over each rebuilt House (D-14), faded at day start
affects: [02-07, 02-08, 02-09, 02-10, 02-11]

actuals:
  tokens: 12500
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Dawn order in RunManager._enter_dawn: DAWN, end_night, rebuild_destroyed, repair_standing, castle.repair, king.restore_for_dawn, buildings_rebuilt, then the payout; start_night clears the rebuilt marks"
    - "A presentation view that must show a state change nobody emitted a per-item event for (repair) re-reads the simulation on the one summary event (buildings_rebuilt), not on a timer"
    - "Shared HUD helpers are public statics on the view that owns them (DawnPayoutVfx.make_coin_texture, spot_screen_point)"
    - "A mark counts as live until its fade finishes, so a test of 'fades within 1 s' observes the fade, not the start of it"

key-files:
  created:
    - ui/hud/dawn_no_income_marker.gd
    - tests/unit/test_dawn_rebuild.gd
    - tests/e2e/test_dawn_rebuilt_marker.gd
  modified:
    - simulation/buildings/building_system.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - presentation/buildings/building_views.gd
    - presentation/vfx/rubble_view.gd
    - ui/hud/dawn_payout_vfx.gd
    - ui/hud/hud.tscn
    - ui/world/spot_label_model.gd
    - tests/integration/test_upgrade_flow.gd

key-decisions:
  - "BuildingSystem stays at gdlint's max-public-methods (20): next_tier_def became private (its two callers read building_def.tier_def(tier + 1)) and was_rebuilt_this_dawn was dropped (get_instance(spot).rebuilt_this_dawn answers it); the three planned methods rebuild_destroyed, repair_standing and clear_rebuilt_marks stay public on BuildingSystem"
  - "Full repair at dawn: survivors, the castle and the king return to full health (RESEARCH Open Question 1); listed for the owner at the playtest gate"
  - "buildings_rebuilt fires on every dawn, with an empty list when nothing fell, so the views always re-read their bars after the repair"
  - "A Tower rebuilt at dawn gets no crossed-out coin (it never pays); only buildings whose current tier has dawn_income > 0 are marked"
  - "The rebuilt marks live from dawn through the whole day and are cleared by start_night, so a rebuilt House pays nothing at its rebuild dawn and its full income at the next"

patterns-established:
  - "New SimEvents signals go into SimSignals.ALL and SimRecorder (handler plus HANDLED) in the same task (continued)"
  - "TDD tasks commit a RED test commit carrying only the stubs needed to fail on assertions, then a GREEN feat commit (continued)"

requirements-completed: [LOOP-04, LOOP-05]

coverage:
  - id: D1
    description: "At dawn every building destroyed in the night is rebuilt for free at the tier it had, standing at full health, listed in MapConfig order in buildings_rebuilt; gold never falls during the rebuild"
    requirement: LOOP-04
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_dawn_rebuilds_what_fell_for_free_and_pays_only_the_survivors"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_two_fallen_buildings_are_listed_in_map_order_whatever_fell_first"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_a_destroyed_house_keeps_its_top_tier_and_that_tiers_health"
        status: pass
    human_judgment: false
  - id: D2
    description: "Edge cases of the rebuild: a building lost on the tick the last enemy dies is rebuilt that dawn; an empty dawn reports an empty list; a second call in the same dawn changes nothing; a destroyed building stays down all night whatever hits arrive; a rebuilt tower fires again the next night"
    requirement: LOOP-04
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "Survivors, the castle and the king are back at full health at dawn"
    requirement: LOOP-04
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_a_survivor_the_castle_and_the_king_are_whole_again_at_dawn"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_dawn_rebuilt_marker.gd#test_a_hurt_survivor_and_the_castle_show_full_bars_after_dawn"
        status: pass
    human_judgment: false
  - id: D4
    description: "Only buildings that stood through the night pay at dawn: per_spot is in MapConfig order and omits rebuilt spots; a House rebuilt at dawn pays 0 then and its tier's income at the next dawn; when every House fell the dawn pays 0 and launches no coin"
    requirement: LOOP-05
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_a_rebuilt_house_pays_nothing_at_its_dawn_and_pays_at_the_next_one"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_the_payout_lists_survivors_in_map_order_and_omits_rebuilt_spots"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_rebuild.gd#test_when_every_house_fell_the_dawn_pays_nothing_and_rebuilds_them_all"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_dawn_rebuilt_marker.gd#test_with_every_house_down_no_coin_flies_and_only_houses_get_a_mark"
        status: pass
    human_judgment: false
  - id: D5
    description: "In the real scene the rubble is replaced by the model at its tier within 1 s of dawn, a crossed-out coin marks each rebuilt House (none over a Tower or a surviving House) while coins fly only from the survivors, and the marks fade within 1 s of the day starting"
    requirement: LOOP-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_dawn_rebuilt_marker.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether the rise animation, the crossed-out coin and its placement over the House read clearly on screen"
    requirement: LOOP-05
    verification: []
    human_judgment: true
    rationale: "Readability is a visual judgement; the tests prove state and counts, not looks. The screenshot tool needs a real renderer; the owner judges it at the playtest gate."

duration: 45min
completed: 2026-10-05
status: complete
plan_head_before: 2cf063253a701d5b2f6c998fca65ef4f673a526d
plan_head_after: ea3541c477d0dd5c672bc6f671bececd03419e5e
commits: 5
---

# Phase 2 Plan 06: Dawn Rebuilds and Pays Survivors Summary

**Dawn now stands every fallen building back up for free at the tier it had, repairs the survivors, the castle and the king to full health, pays only the buildings that stood through the night, and hangs a crossed-out coin over each rebuilt House until the day starts.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-10-05T10:09:00Z
- **Completed:** 2026-10-05T10:55:00Z
- **Tasks:** 2 (5 commits: one preparatory refactor, then RED and GREEN for each task)
- **Files modified:** 15 (plus `.gd.uid` files)

## Accomplishments

- **BuildingSystem:** `rebuild_destroyed()` walks MapConfig order and stands each fallen building again at its own tier and that tier's full health, marks it `rebuilt_this_dawn`, never touches Economy, and returns the spot ids (a second call returns an empty array). `repair_standing()` restores every standing building; `clear_rebuilt_marks()` clears the flag everywhere. `dawn_income_by_spot()` skips rebuilt spots.
- **RunManager:** `_enter_dawn` runs rebuild, repair, `castle.repair()`, `king.restore_for_dawn()`, emits `buildings_rebuilt`, then the single payout. `start_night()` clears the marks first. `RunContext` passes the CastleState in as a trailing constructor argument.
- **Events:** `buildings_rebuilt(spot_ids: Array)` is in `SimEvents`, `SimSignals.ALL` and `SimRecorder` (handler plus `HANDLED`, one token per spot id, none when empty).
- **BuildingViews:** on `buildings_rebuilt` the rubble is replaced by the model at the tier it had (the same `_place_building` seam `building_built` uses, now shared) with a short rise tween, and every health bar, including the castle's, is read again so repaired buildings stop showing damage.
- **DawnNoIncomeMarker:** a HUD control (`run_bound`, mouse ignore) that makes one crossed-out coin (the payout coin plus a red `Line2D` bar) per rebuilt building whose tier pays income, in list order, placed each frame with the same projection the flying coins use (`DawnPayoutVfx.spot_screen_point`), faded over 0.5 s at `day_started`.

## Task Commits

1. **Preparatory refactor:** make `next_tier_def` private to free a public-method slot - `1243f00` (refactor)
2. **Task 1 RED:** failing tests for the dawn rebuild, repair and rebuilt-pays-nothing rule - `cc8cd07` (test)
3. **Task 1 GREEN:** dawn rebuilds what fell for free, repairs the rest, pays only survivors - `492b0bd` (feat)
4. **Task 2 RED:** failing tests for rubble rising back and the crossed-out coin - `2ea5ac7` (test)
5. **Task 2 GREEN:** rubble rises back into the model; rebuilt Houses wear a crossed-out coin - `ea3541c` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 2: 75 scripts, 631 tests, 0 failures (base 611 in 73 scripts); `bash tools/lint.sh` clean.
- `test_dawn_rebuild` (15 tests), `test_dawn_rebuilt_marker` (5), `test_dawn_income`, `test_loop_gold_carryover`, `test_determinism`, `test_dawn_payout` and `test_dawn_payout_hardening` are all present and passing in the JUnit XML.
- RED runs failed as planned (14 of 15 unit tests, 5 of 5 e2e tests; the one unit test that passed in RED guards "an empty list still reports").
- Mutation probes: removing the `rebuilt_this_dawn` skip in `dawn_income_by_spot` made 5 of the 15 unit tests fail; marking every rebuilt building regardless of income made 1 of 5 e2e tests fail (the Tower must not be marked). Both restored.
- Acceptance strings checked: `func rebuild_destroyed() -> Array[StringName]`, `func repair_standing()`, `func clear_rebuilt_marks()` in building_system.gd; `rebuild_destroyed()`, `repair_standing()`, `buildings_rebuilt.emit` in run_manager.gd; `"buildings_rebuilt"` in sim_signals.gd; `class_name DawnNoIncomeMarker`, `buildings_rebuilt.connect`, `day_started.connect` in the marker; `DawnNoIncomeMarker` in hud.tscn; `buildings_rebuilt.connect` in building_views.gd.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] BuildingSystem public-method limit**
- **Found during:** Task 1 (and flagged by the 02-04 summary)
- **Issue:** BuildingSystem held 18 public methods; the plan adds four (`rebuild_destroyed`, `repair_standing`, `clear_rebuilt_marks`, `was_rebuilt_this_dawn`), exceeding gdlint's `max-public-methods` of 20, which must not be raised or disabled.
- **Fix:** `next_tier_def` became private (`_next_tier_def`; its two outside callers, `spot_label_model.gd` and `test_upgrade_flow.gd`, now read `building_def.tier_def(tier + 1)`), and `was_rebuilt_this_dawn` was not added: `get_instance(spot_id).rebuilt_this_dawn` answers it from the snapshot. The three methods the key link needs stay public on BuildingSystem, so RunManager still calls `rebuild_destroyed` on it.
- **Files modified:** simulation/buildings/building_system.gd, ui/world/spot_label_model.gd, tests/integration/test_upgrade_flow.gd
- **Commit:** `1243f00`

**2. [Rule 2 - Missing critical functionality] Repaired buildings and the castle kept showing damage**
- **Found during:** Task 2 design
- **Issue:** the dawn repair emits no damage event, so a hurt House's bar and the castle's bar would have stayed visible after they were repaired.
- **Fix:** `BuildingViews._on_buildings_rebuilt` re-reads every building bar and the castle bar from the simulation; covered by `test_a_hurt_survivor_and_the_castle_show_full_bars_after_dawn`.
- **Files modified:** presentation/buildings/building_views.gd
- **Commit:** `ea3541c`

### Interface details that differ from the plan's sketch (no behavior change)

- **Shared HUD helpers.** The marker needs the payout coin and the spot projection, so `DawnPayoutVfx._make_coin_texture` became the public static `make_coin_texture` and `start_point` now delegates to a new public static `spot_screen_point(ctx, viewport, spot_id)`; the flying coins behave exactly as before (`test_dawn_payout*` green).
- **`marked_spots()`** was added to DawnNoIncomeMarker (read-only) so the e2e tests can check mark order; the plan lists only `marker_count()`.
- **E2E setup.** The plan's e2e scene has grunts destroy house_2; the test takes house_2 down through `BuildingSystem.damage_building` right after the night starts while the king (parked in front of a short fixture night) finishes the night, which keeps the test fast and deterministic. The unit tests cover enemy-driven timing (a House falling on the tick the last grunt dies).
- **`marker_count()` counts fading marks** until their fade finishes, so the "fades within 1 s of the day starting" test observes the fade itself.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing functionality); 4 interface details above.
**Impact on plan:** none on behavior; every behavior-list case holds.

## Issues Encountered

- A first edit script was pointed at a scratchpad path with a space where the directory has hyphens and did not run; it was re-run from the correct path with no partial edits applied.
- gdformat reflowed the long doc comments in the new files; they were rewrapped to the 100-column limit by hand.

## Known Stubs

None. The RED-phase stubs (empty BuildingSystem methods, placeholder marker) were replaced by the GREEN commits.

## Threat Flags

None. T-02-12 (dawn payout and rebuild tampering) is mitigated as planned: `rebuild_destroyed` never calls Economy (`test_dawn_rebuild.gd` asserts every gold delta of a rebuilding dawn is positive and that an all-fallen dawn moves no gold), rebuilt spots are skipped in `dawn_income_by_spot`, and `_apply_dawn_payout` still runs once per DAWN entry (`test_dawn_income` and `test_loop_gold_carryover` green). T-02-SC: no packages installed.

## Flagged Assumptions for the Owner

- Full repair at dawn (survivors, castle, king) resolves RESEARCH Open Question 1; FEATURES.md lists a mutator that makes buildings heal only 25% each morning, which implies a full heal by default. To be confirmed at the playtest gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later plans can rely on: `SimEvents.buildings_rebuilt`; every dawn leaving all buildings, the castle and the king at full health; rebuilt marks lasting until the next `start_night`; `BuildingViews` re-reading its bars on that event. If a later plan lets the castle fall to end the run, `_enter_dawn`'s `castle.repair()` should be skipped for a lost run (the run-end plan decides; today a destroyed castle cannot reach a normal dawn on a seeded night).
- Not run: the screenshot tool (needs a real renderer), so the rise animation and the crossed-out coin are verified by state and count, not by eye; the owner judges readability at the playtest gate.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: dawn_no_income_marker.gd, test_dawn_rebuild.gd, test_dawn_rebuilt_marker.gd.
- Commits `1243f00`, `cc8cd07`, `492b0bd`, `2ea5ac7`, `ea3541c` exist; `git rev-list --count 2cf0632..HEAD` is 5.
- Full suite: 75 scripts, 631 tests, all passing; lint clean.
