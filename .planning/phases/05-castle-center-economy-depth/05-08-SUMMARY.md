---
phase: 05-castle-center-economy-depth
plan: 08
subsystem: simulation
tags: [godot, gdscript, economy, harbor, boats, pond, income-curve, validation, debug-overlay, screenshot, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "IncomeState and the merged one-per-dawn payout, BuildingDef.IncomeCurve with pays_income and tier_effect_line, EconomyValidation, EconomyOverlaySections (05-06); the four pin lists, the generic plot geometry rules and the 40-shot list (05-07); the gated top tier mechanism requires_castle_tier (05-05); the SimEvents registration recipe (05-02)"
provides:
  - "BuildingTierDef.boat_cap and boat_income; the BOATS branch of IncomeState: one boat per standing, not-rebuilt dawn up to the tier's cap, each boat paying boat_income, boats_of(spot_id), next_payout for a Harbor"
  - "SimEvents.harbor_boats_changed(spot_id, boats), emitted only when the count changes, registered in SimSignals.ALL, SimRecorder.HANDLED and attach"
  - "data/buildings/fishing_harbor.tres (two BOATS tiers, tier II gated at castle II) and the harbor_1 plot at (0, 0, 20.5), spot 21"
  - "MapConfig.pond_center and pond_radius (0 = no pond): a visual-only pond at (0, 30) radius 8, never in NavGrid, no collision"
  - "PondView (run_bound Node3D in prototype_map.tscn): the water disc, boats as primitives at fixed positions, boat_count and boat_position"
  - "Two Harbor models from the logged Fantasy Town pieces plus engine boxes, catalog entries, and the top-tier label line 'Boats N of M, next dawn G gold'"
  - "EconomyValidation boat and pond checks (MAX_BOAT_CAP 20, MAX_POND_RADIUS 30.0, POND_ROAD_CLEARANCE 10.0); Economy overlay row 'harbor_1: boats N of M'; harbor_pond screenshot (41st shot)"
affects: [05-09 Shrine (adds AWAKENED to IncomeState, EconomyValidation, overlay rows, plots; map now has 21 spots and the pin lists include harbor_1), 05-10 economy replay, 05-11 fit of Harbor cost, cap and boat gold (edit test_economy_data_contract; keep every cost at 2 or more; bots do not buy the Harbor yet), 05-12 verification and the harbor_pond review]

actuals:
  tokens: 23140
  tasks: 2
  commits: 3
plan_head_before: 9087fc8ac636ee8f622f86617c6f8c18c58c63fd
plan_head_after: a59ccb1d58c7344bb0b3ec919335a5b7237a9096

tech-stack:
  added: []
  patterns:
    - "A view of per-plot economy state follows one event and is a pure function of the index: PondView draws boat i at the same place whatever else changes, so views are stable frame to frame and run to run"
    - "A curve's unused fields must stay 0: EconomyValidation._check_unused picks the unused field list from the curve, so a boat field on a House or a step on a Harbor is reported"
    - "A visual-only map feature is two data fields (0 = none), read only by its view and by validate(), so no simulation system, the nav grid or the gate stress can see it"

key-files:
  created:
    - data/buildings/fishing_harbor.tres
    - presentation/environment/pond_view.gd
    - presentation/buildings/models/fishing_harbor_t1.tscn
    - presentation/buildings/models/fishing_harbor_t2.tscn
    - tests/unit/test_fishing_harbor.gd
    - tests/e2e/test_harbor_scene.gd
    - tests/unit/test_pond_layout.gd
  modified:
    - simulation/defs/building_tier_def.gd
    - simulation/defs/building_def.gd
    - simulation/defs/map_config.gd
    - simulation/defs/economy_validation.gd
    - simulation/economy/income_state.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - data/maps/prototype_map.tres
    - presentation/map/prototype_map.tscn
    - presentation/buildings/building_view_catalog.tres
    - ui/world/spot_label_model.gd
    - ui/overlay/economy_overlay_sections.gd
    - tools/screenshot/shot_economy_scenarios.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
    - tests/unit/test_prototype_map_economy.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_structure_decision_pins.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - tests/unit/test_economy_validation.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_economy_overlay_sections.gd
    - tests/unit/test_shot_list.gd
    - tests/e2e/test_rebuilt_economy_marker.gd

key-decisions:
  - "A Harbor boat count never falls: after = maxi(before, mini(before + 1, cap)), so bad data (a cap below the count) can only stop growth, never take boats away (D-14)"
  - "Boat i sits at angle i * golden angle (2.399963 rad) at 0.6 of the pond radius; a second Harbor on the same pond would start a fixed 1.0 rad round the ring (slot offset). The plan's 'fixed step' is read as the golden angle so up to 20 boats spread without overlap"
  - "EconomyValidation reports a boat field set on a curve that does not use it, and the DECLINING step and floor on a BOATS tier, by one _check_unused that picks its field list from the curve (it now also runs for DECLINING buildings, for their boat fields)"
  - "The pond check is skipped when the radius is 0 (no pond) except for a non-finite centre; a pond is 'in the water' for a plot or spawn strictly inside the radius and clear of a road at pond_radius + 10 m or more"
  - "harbor_pond stages three timed nights through the real command intents and ctx.step() (the fast-forward way a replay runs), on a deep copy with no authored nights; the king stands on the pond (no collision) at plot + (-2.5, 0, 6.5) so the whole pond is centred in the frame"

patterns-established:
  - "A new economy curve is one IncomeState branch, one validation branch, one overlay row, one event: Harbor followed the Mine's footprint and the Shrine plan can copy it"

requirements-completed: [ECON-05]

coverage:
  - id: D1
    description: "A Fishing Harbor gains one boat at every dawn it stands up to its tier's cap and every boat pays the tier's gold; four dawns with cap 3 give 1, 2, 3, 3 boats paying 1, 2, 3, 3, and the fourth dawn emits no event; after the upgrade the next dawns give 4 and 5 and stop at 5"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_fishing_harbor.gd#test_four_standing_dawns_give_one_two_three_three_boats_paying_the_same"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fishing_harbor.gd#test_after_the_upgrade_the_next_dawns_give_four_and_five_boats_and_stop"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fishing_harbor.gd#test_the_event_is_emitted_for_each_new_count_and_never_at_the_cap"
        status: pass
    human_judgment: false
  - id: D2
    description: "A Harbor rebuilt this dawn gains no boat, pays nothing, emits no event and keeps every boat; a Harbor bought today has 0 boats; an unbuilt one never appears in the payouts; the Harbor is never paid by BuildingSystem"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_fishing_harbor.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "In the real prototype scene the pond is a flat water disc at (0, 30) of radius 8 with no collision, the king builds the Harbor by holding on its shore, no boat floats until the first dawn, and across two nights one boat arrives each dawn and pays through the one dawn_payout; boat 0 never moves"
    requirement: ECON-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_harbor_scene.gd (4 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "MapConfig.validate() reports boat_cap outside 1..20, boat_income outside 1..1000, boat fields on a curve that does not use them, a non-finite pond centre or radius, a radius above 30, a pond holding a plot or spawn point, and a pond within pond_radius + 10 m of a spawn-to-castle road; a radius of 0 passes"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_validation.gd (19 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_pond_layout.gd (13 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The prototype map has 21 spots (harbor_1 at (0, 0, 20.5), index 20), the pond holds no plot or spawn, every road keeps 18 m from its centre, the Harbor is within 3 m of the shore, every plot rule and the nav layout pin still pass, and the Harbor's numbers, plot, pond and models are pinned"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_economy.gd (20 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_nav_layout_pin.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_economy_data_contract.gd (17 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The Economy overlay lists 'harbor_1: boats N of M' for a standing Harbor; the top-tier label reads 'Boats N of M, next dawn G gold'"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_overlay_sections.gd (14 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_harbor_scene.gd#test_the_top_tier_label_reads_the_boats_and_the_next_dawn"
        status: pass
    human_judgment: false
  - id: D7
    description: "smoke, army and walls replay byte-identical and full_idle keeps digest 4385f569...; the gate stress stays at 300 crossed, 0 stuck: the bots never build the Harbor and the pond never reaches the nav grid"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke|army|walls --twice --expect-file=...; --scenario=full_idle --twice; bash tools/gate_stress.sh --twice"
        status: pass
    human_judgment: false
  - id: D8
    description: "The pond reads as water, the boats read as boats and the dock reaches the shore in the harbor_pond screenshot; the placeholder Harbor model and boats look right"
    verification:
      - kind: automated_ui
        ref: "screenshots/harbor_pond.png (executor review line below)"
        status: pass
    human_judgment: true
    rationale: "The executor looked at the PNG, but whether the primitive boats, the hut and the flat blue pond feel right is the owner's call at the phase UAT (plan 05-12 reviews harbor_pond again)"

duration: 105min
completed: 2026-10-22
status: complete
---

# Phase 5 Plan 08: Fishing Harbor and Pond Summary

**A Fishing Harbor on the shore of a visual-only pond that gains one paying boat per standing dawn up to an upgradeable cap (3 then 5, 1 gold each), with the boats drawn by PondView, boat and pond data validated, an overlay row and a harbor_pond screenshot; all four replays and the gate stress byte-identical**

## Performance

- **Duration:** about 105 min (about 65 min of it was full-suite runs)
- **Started:** 2026-10-21T20:40:44Z
- **Completed:** 2026-10-21T22:24:35Z (last code commit a59ccb1; docs commit follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 36 across the three code commits (7 created, 25 modified, 3 .uid)

## Accomplishments

- **Tracer (Task 1):** in the real prototype scene the pond is a flat water disc at (0, 30) radius 8 with no collision node, the king holds at `harbor_1`, the Harbor's model stands with 0 boats, and across two nights one boat arrives at each dawn and pays (1 then 2) through the one `dawn_payout`; `boat_position(harbor, 0)` is identical before and after the second boat and lies inside the pond (`test_harbor_scene`, 4 tests).
- **Rules (12 unit tests):** with cap 3 four dawns give 1, 2, 3, 3 boats paying 1, 2, 3, 3 and three events (1, 2, 3); the upgrade keeps the count, then 4 and 5 and a stop; a fallen or rebuilt-this-dawn Harbor gains nothing, pays nothing, emits nothing and keeps its boats; a bought-today Harbor has 0 boats; `next_payout` is what the dawn then pays; a cap of 0 never adds a boat; the Harbor is paid by IncomeState only.
- **Event and views:** `harbor_boats_changed` is in SimEvents, SimSignals.ALL and SimRecorder.HANDLED with its handler and connect in one task (test_determinism passes); PondView follows it with boats at deterministic positions (golden angle, 0.6 of the radius).
- **Data and map:** `fishing_harbor.tres` (cost 3 / 6, cap 3 / 5, 1 gold per boat, health 18 / 24, tier II `requires_castle_tier = 2`), `harbor_1` as spot 21, `pond_center (0, 30)`, `pond_radius 8.0`; two models and catalog entries; the four plot pin lists and the plot-kind count extended.
- **Task 2:** EconomyValidation reports bad boat and pond data (T-05-16), `test_pond_layout` pins the shipped layout and the validator (13 tests), the overlay row reads `harbor_1: boats 2 of 3`, the contract pins every Harbor number, and `harbor_pond` is the 41st shot.

## Task Commits

1. **Task 1: Harbor, pond, boats, event, models, tracer tests** - `91082a0` (feat)
2. **Task 2 RED: failing boat and pond validation, pond layout, overlay and 41-shot pins** - `3cfe9a4` (test)
3. **Task 2 GREEN: validation, overlay row, harbor_pond screenshot** - `a59ccb1` (feat)

**Plan metadata:** the docs commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md follows.

## TDD Gate Compliance (Task 2)

- **RED** `3cfe9a4` `test(05-08)`: failing on assertions for the planned behaviour: `test_economy_validation` 3 of 19 (the new boat tests; the cap, income and field checks missing), `test_pond_layout` 5 of 13 (non-finite centre and radius, plot, spawn and road reports), `test_economy_overlay_sections` 2 of 14 (the Harbor rows, `[<null>] expected to equal ["boats 0 of 3"]`), `test_shot_list` 6 of 19 (40 where 41 is expected, `harbor_pond` missing from the wrapper, the economy scenes and `ALL_SHOTS`, plus the out-of-range read as an "Unexpected Errors" line). `EconomyValidation`'s three constants were committed with the RED tests as interface so the scripts load and fail on assertions, not on a missing constant.
- **Unexpected GREEN investigated:** `test_economy_data_contract` (17 of 17) passed before any Task 2 code by design: it pins what Task 1 shipped (the Harbor numbers, plot, pond and models). The tests that carry the new Task 2 behaviour are the ones listed as failing above.
- **GREEN** `a59ccb1` `feat(05-08)`: the validation checks, the overlay row, the shot. No REFACTOR commit (nothing to clean).
- `gsd_run check tdd-red-evidence` was not run: the plan is `type: execute` with a `tdd="true"` task, not a `type: tdd` plan.

## Verification

- **Full suite, final state after Task 2, two runs, both exit 0:** **264 scripts / 2521 tests / 59170 asserts** and **264 / 2521 / 59159** (assert totals vary by a few across runs because of polling waits), each about 13 minutes. After Task 1: 263 scripts / 2496 tests / 59010 asserts, exit 0. Baseline at dispatch: 261 / 2479 / 58790. New: 3 scripts (test_fishing_harbor, test_harbor_scene, test_pond_layout), 42 tests. (A first Task 2 full run had one failure, see Deviations; the committed code passes both final runs.)
- **Replays (each --twice, after Task 1 and again after Task 2):** smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all matched their golden files); full_idle outcome=won ticks=6911 digest `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`, byte-identical to the RESEARCH E3 baseline.
- **Gate stress (after Task 1 and Task 2):** `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93`.
- **Lint:** `bash tools/lint.sh` clean (431 files).
- **JUnit names present:** test_fishing_harbor, test_harbor_scene, test_prototype_map_economy, test_nav_layout_pin, test_determinism, test_dawn_payout_economy (Task 1); test_economy_validation, test_pond_layout, test_economy_data_contract, test_economy_overlay_sections, test_shot_list (Task 2).
- **harbor_pond review (real window, RTX 3060, Forward+, 1280x720, `bash tools/screenshot.sh harbor_pond`):** the pond reads as a flat blue water disc in the middle of the frame, three boats (cream deck plate and a sail on a brown hull) float at different angles inside it, the dock of dark boards reaches from the teal-roofed hut on the north shore into the water, the king stands on the pond and the two neighbouring plot discs lie well clear of it with nothing on any road. The first capture showed the pond cut off and the sails invisible from the high camera, so the king's stand point was moved to the pond's middle and the boats got a pale deck plate; the "Hold N to start Night 4" banner covers the pond's bottom edge, which is the normal day HUD.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The rebuilt-marker test used a BOATS building the new validation rejects**
- **Found during:** Task 2 (first full run after the GREEN code)
- **Issue:** `test_rebuilt_economy_marker.test_the_marker_asks_the_building_not_the_raw_income_field` turned the Gold Mine into a BOATS building with `boat_income` 0 (plan 05-06's stand-in for "a curve that pays nothing yet") and expected it not to be marked. With the Harbor's fields real, validation reports `boat_income is 0, expected 1 to 1000` (an unexpected `push_error`), and a valid BOATS tier pays through its boats so it would be marked anyway.
- **Fix:** the test now builds a valid boats building (cap 1, 1 gold per boat, `dawn_income` 0) and asserts it is marked with the House, so it still proves the marker asks the building rather than the raw `dawn_income` field (the check discriminates in the other direction).
- **Files modified:** tests/e2e/test_rebuilt_economy_marker.gd
- **Verification:** 5 of 5 pass; full suite green twice
- **Committed in:** a59ccb1

**2. [Rule 3 - Blocking] Pin lists and counts for the new plot** (the four places plan 05-07's SUMMARY listed, as expected, not a surprise): `PHASE_FIVE_PLOT_IDS` (with `SPOT_COUNT` 21, `BUILDABLE_PLOT_COUNT` 20), `PHASE_FIVE_PLOTS`, `ECONOMIC_PLOT_IDS`, and the plot-kind count in `test_upgrade_at_spot` (7 to 8). Committed in 91082a0.

**3. [Plan shape] Task 2 RED was only partly real** - `test_economy_data_contract` is green by design (see TDD Gate Compliance).

**4. [Plan shape] Task 1's replay and gate chain run once, Task 2's twice:** the plan's verify chains run the full suite twice; the Task 1 code was proved by one green full run (263 scripts / 2496 tests) plus the replays and the stress, and the final state by two runs. No code changed between the Task 1 run and its commit.

---

**Total deviations:** 1 auto-fixed (Rule 1), 1 Rule 3 pin-list note, plus two shape notes
**Impact on plan:** the marker test change is the only test intent that moved; no pin value, golden or owner pin was touched.

## Issues Encountered

- Several `sed` line-range edits of comment blocks overwrote the wrong lines because the line numbers had shifted; each was caught on the next read and fixed by hand (no code was affected). One `sed` replacement with an unescaped `&` expanded the match into three test files; those three were restored with `git checkout` (they held only that edit) and redone with the escape.
- The first harbor_pond capture cut the pond and hid the sails (a quad sail is edge-on from the high camera): fixed with a deck plate on each boat and a better stand point.

## Known Stubs

None. No placeholder text or empty data source in any created or modified file. The Harbor plot disc wears the House-tan fallback colour (building_views.gd, outside this plan's files, same note as plans 05-06 and 05-07): a presentation gap for the art pass, not a stub.

## Threat Flags

None. T-05-16 (boat cap, boat gold and pond data) is mitigated and pinned: EconomyValidation bounds `boat_cap` to 1..20, `boat_income` to 1..1000, the radius to 0..30 m with finite numbers, and keeps plots, spawns and roads clear of the pond (`test_economy_validation`, `test_pond_layout`); the pond never enters NavGrid (`test_nav_layout_pin`, gate stress unchanged at 300 crossed, 0 stuck). T-05-SC: no packages; the models compose the logged Fantasy Town pieces and engine primitives, the boats are engine primitives.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-09 (Shrine): extend `IncomeState` (AWAKENED branch) and `EconomyValidation` the way the Harbor did; `EconomyOverlaySections.economy_rows` takes one more `elif`; append the Shrine plot ids to the four pin lists and the generic geometry rules cover them (`test_prototype_map_economy` now has 20 tests, at the cap: its new plot tests go in their own script). Spot count after this plan: 21 (spots 1 to 14 Phase 4, 15 castle, 16 to 21 the economy plots).
- Plan 05-11: the Harbor numbers (cost 3 / 6, cap 3 / 5, 1 gold per boat on both tiers, health 18 / 24) are [ASSUMED] starting points; edit `test_economy_data_contract` in the same commit and keep every cost at 2 or more; the bots do not buy the Harbor yet (it is paid only after a bot order adds it, and `test_bot_defers_locked`'s shipped-orders pin must be revisited then, Harbor II being gated at castle II).
- Plan 05-12 reviews `harbor_pond` with the owner (the primitive boats, the hut and the flat blue pond are placeholder art).
- ECON-05 is recorded in `requirements-completed` and left unticked in REQUIREMENTS.md if a later plan declares it (same precedent as ECON-04).
- No blockers.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-22*

## Self-Check: PASSED

All seven created files exist (fishing_harbor.tres, pond_view.gd, two models, three test scripts), commits `91082a0`, `3cfe9a4` and `a59ccb1` exist, and every acceptance criterion holds: `var boat_cap: int = 0` and `var boat_income: int = 0`; `var pond_center: Vector2` and `var pond_radius: float = 0.0`; `func boats_of(` and `harbor_boats_changed.emit(` in income_state.gd; `"harbor_boats_changed"` in sim_signals.gd and sim_recorder.gd; `id = &"fishing_harbor"` and `requires_castle_tier = 2`; `id = &"harbor_1"` and `pond_radius = 8.0`; a `PondView` node in prototype_map.tscn; full_idle digest `4385f569...`; `const MAX_BOAT_CAP: int = 20` and `const POND_ROAD_CLEARANCE: float = 10.0`; `harbor_pond` in ALL_SHOTS of tools/screenshot.sh; `const EXPECTED_SHOT_COUNT: int = 41`; the harbor_pond review line is above.
