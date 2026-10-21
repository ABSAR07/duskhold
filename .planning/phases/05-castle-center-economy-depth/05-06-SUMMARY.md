---
phase: 05-castle-center-economy-depth
plan: 06
subsystem: simulation
tags: [godot, gdscript, economy, income-curve, gold-mine, dawn-payout, validation, debug-overlay, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "CastleState.base_income() and the StatStack (05-01); the castle plot, _is_plain and the 15-spot pin (05-02); the EconomyValidation helper shape from ChoiceValidation and CastleValidation (05-03); StatOverlaySections registration point (05-01); the requirement gate and locked label lines (05-05)"
provides:
  - "BuildingDef.IncomeCurve (FLAT, DECLINING, BOATS, AWAKENED), income_curve, pays_income(tier) and tier_effect_line(tier); BuildingTierDef.income_step and income_floor"
  - "IncomeState (simulation/economy/, sibling of BuildingSystem): dawn_payouts(), mine_paid_dawns(), next_payout(); the only payer of every non-FLAT curve; RunContext.income; RunManager's ninth parameter"
  - "One dawn payout merged by walking spot_ids(): FLAT from BuildingSystem.dawn_income_by_spot(), every other curve from IncomeState, castle key last, key for key identical to before when no non-flat plot is built"
  - "Gold Mine: data/buildings/gold_mine.tres (one DECLINING tier), the gold_mine_1 plot at (-30, 0, 30) as spot 16, its Castle Kit model, catalog entry, label lines ('Pays 3 gold, then 1 less each dawn, never below 1' before building, 'Next dawn: N gold' after)"
  - "DawnNoIncomeMarker asks pays_income(), so every paying curve gets the crossed coin when rebuilt"
  - "EconomyValidation (MAX_CURVE_VALUE 1000) appended to MapConfig.validate(); EconomyOverlaySections, the read-only Economy section registered after Stats"
  - "Generic Phase 5 plot geometry rules in test_prototype_map_economy (12 m from roads, 3 m from wall runs and gaps, inside the nav content box), keyed by PHASE_FIVE_PLOT_IDS"
affects: [05-07 Mill and Field (extend PHASE_FIVE_PLOT_IDS and the pin lists named under Next Phase Readiness), 05-08 Harbor (BOATS curve, IncomeState, EconomyValidation, overlay rows), 05-09 Shrine (AWAKENED curve, IncomeState, overlay rows), 05-11 fit of the Mine's cost and first payout (edit test_economy_data_contract), 05-12 verification]

actuals:
  tokens: 23460
  tasks: 2
  commits: 4
plan_head_before: b34da11d4eefad363c6711abec9e84a8d489b999
plan_head_after: 71207325bab7c7a50efb5a6737f0817d7b68f49a

tech-stack:
  added: []
  patterns:
    - "A non-flat income curve is data on the building (income_curve) and its state lives in a sibling of BuildingSystem (IncomeState), so BuildingSystem (at the 20-method cap) changes a body only"
    - "One dawn payout from two payers: FLAT from BuildingSystem, every other curve from IncomeState, merged by walking spot_ids() so map order and the castle-last rule survive"
    - "The decline counter advances only while the payout was above the floor (and only with a step of 1 or more), so it stops at ceil((start - floor) / step) and never grows without bound; a rebuilt-this-dawn plot skips with no progress"
    - "Behaviour tests set curve numbers on a deep copy of the map; only test_economy_data_contract pins the shipped numbers"

key-files:
  created:
    - simulation/economy/income_state.gd
    - simulation/defs/economy_validation.gd
    - ui/overlay/economy_overlay_sections.gd
    - data/buildings/gold_mine.tres
    - presentation/buildings/models/gold_mine_t1.tscn
    - tests/unit/test_gold_mine.gd
    - tests/integration/test_dawn_payout_economy.gd
    - tests/e2e/test_gold_mine_scene.gd
    - tests/e2e/test_rebuilt_economy_marker.gd
    - tests/unit/test_economy_validation.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_economy_overlay_sections.gd
  modified:
    - simulation/defs/building_def.gd
    - simulation/defs/building_tier_def.gd
    - simulation/buildings/building_system.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/defs/map_config.gd
    - data/maps/prototype_map.tres
    - presentation/buildings/building_view_catalog.tres
    - ui/world/spot_label_model.gd
    - ui/hud/dawn_no_income_marker.gd
    - ui/overlay/debug_overlay.gd
    - tests/unit/test_prototype_map_economy.gd
    - tests/unit/test_sim_rules_guard.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_structure_decision_pins.gd
    - tests/unit/test_debug_overlay_night_sections.gd
    - tests/e2e/test_upgrade_at_spot.gd

key-decisions:
  - "dawn_income is the Mine's first payout and the curve, not a zero, decides who pays: BuildingSystem.dawn_income_by_spot() lists FLAT buildings only, IncomeState lists every other curve (the plan's Flagged Assumption, a deliberate change from RESEARCH Pattern 5's 'special tiers carry dawn_income = 0')"
  - "paid_dawns advances only when the amount paid was above the floor AND income_step >= 1: with a bad step of 0 the payout never falls and the counter never counts, so no counter grows without bound even on data the validator would reject"
  - "IncomeState._init takes (map, buildings, events, stat_stack) as the interface says but this plan uses only buildings; the other three are underscore-named and kept for the Harbor and Shrine plans so their constructor call in RunContext does not change again"
  - "A built Mine's label reads 'Next dawn: N gold' (Claude's discretion in the plan) so the decline is readable before the coins fly; it refreshes on gold_changed and phase_changed, so it is current again as soon as the day starts"
  - "BOATS pays_income is false until plan 05-08 adds its per-boat field, so a rebuilt BOATS building is not marked yet; test_rebuilt_economy_marker pins that the marker asks the building rather than the raw dawn_income field"
  - "EconomyOverlaySections rows are [label, value] pairs ('castle' -> 'tier 2, picks Royal Training', 'gold_mine_1' -> 'paid 1, next 2') so the overlay prints 'castle: tier 2, picks ...'; a map with no castle plot says 'no tiers' and the section is never empty"

patterns-established:
  - "Plot-adding plans append their ids to PHASE_FIVE_PLOT_IDS in test_prototype_map_economy and the generic geometry rules cover them without new tests"
  - "A TDD task whose behaviour is already satisfied by data (the contract test) or by a coincidence of the old code (the marker on a DECLINING building) gets a discriminating test so RED is real"

requirements-completed: [ECON-03]

coverage:
  - id: D1
    description: "A player can build a Gold Mine on the prototype map (ride to gold_mine_1, hold), its model stands, and it pays its starting gold at its first dawn and 1 less at each later dawn it pays, down to a floor of 1, never 0"
    requirement: ECON-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_gold_mine_scene.gd#test_two_nights_pay_the_mine_three_then_two_through_the_one_payout"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_gold_mine_scene.gd#test_the_king_rides_to_the_plot_holds_and_the_mine_stands_up"
        status: pass
      - kind: unit
        ref: "tests/unit/test_gold_mine.gd#test_five_standing_dawns_pay_three_two_one_one_one"
        status: pass
    human_judgment: false
  - id: D2
    description: "FLAT curves are paid only by BuildingSystem and every other curve only by IncomeState; each dawn still emits exactly one dawn_payout with per_spot in MapConfig order, castle last, total equal to the sum"
    requirement: ECON-03
    verification:
      - kind: integration
        ref: "tests/integration/test_dawn_payout_economy.gd#test_the_first_dawn_lists_house_mine_and_castle_in_map_order_with_one_event"
        status: pass
      - kind: integration
        ref: "tests/integration/test_dawn_payout_economy.gd#test_every_dawn_sums_to_its_total_across_five_dawns"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=full_idle --twice (digest 4385f569... unchanged)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A Mine rebuilt this dawn pays nothing, makes no progress, and wears the crossed coin; the next dawn pays what the skipped dawn would have"
    requirement: ECON-03
    verification:
      - kind: unit
        ref: "tests/unit/test_gold_mine.gd#test_a_rebuilt_mine_pays_nothing_and_makes_no_progress"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_rebuilt_economy_marker.gd#test_a_rebuilt_mine_wears_the_crossed_coin_and_it_fades_at_day_start"
        status: pass
    human_judgment: false
  - id: D4
    description: "MapConfig.validate() reports bad curve data (step or floor below 1, first payout below the floor, any value above 1000, curve fields on a curve that does not use them); the shipped data is pinned by a contract test"
    requirement: ECON-03
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_validation.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_economy_data_contract.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "The prototype map has 16 spots with gold_mine_1 as spot 16; every Phase 5 plot is at least 12 m from every road, 3 m from every wall run and gap, and inside the nav content box; NavGrid keeps its layout"
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_economy.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_nav_layout_pin.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "The debug overlay's Economy section shows the castle tier with its picks and each standing Mine's paid dawns and next payout, read-only, after the Stats section"
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_overlay_sections.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "The Gold Mine model and its label read well in the real game (stone mine mouth with a dark doorway and a heap of gold boxes; 'Pays 3 gold, then 1 less each dawn, never below 1')"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_gold_mine_scene.gd#test_the_label_says_how_the_payout_falls_before_the_mine_is_built"
        status: pass
    human_judgment: true
    rationale: "A real-window capture was checked by the executor, but whether the placeholder model and the declining numbers feel right is the owner's call at the phase UAT (plan 05-11 refits cost and first payout)"

duration: 98min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 06: Gold Mine and IncomeState Summary

**A Gold Mine plot whose payout falls 3, 2, 1, 1... through a new IncomeState sibling merged into the single dawn payout, with a rebuilt-dawn skip, the crossed coin, curve validation and a read-only Economy overlay section, all four replays byte-identical**

## Performance

- **Duration:** 98 min
- **Started:** 2026-10-21T16:56:45Z
- **Completed:** 2026-10-21T18:35:36Z (last code commit; docs commit follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 39 across the four code commits (12 created, 17 modified, plus .uid files)

## Accomplishments

- **Tracer (Task 1):** in the real prototype scene the king rides to `gold_mine_1`, holds, the Mine's model stands up, and across two nights the one `dawn_payout` lists the Mine at 3 and then 2, the gold rising by exactly those totals (`test_gold_mine_scene`, 3 tests).
- **IncomeState:** a sibling of BuildingSystem keeps the Mine's paid-dawn count. Five standing dawns pay 3, 2, 1, 1, 1 with the count reading 1, 2, 2, 2, 2 (it stops at ceil((3 - 1) / 1) = 2); a Mine that fell and was rebuilt this dawn pays nothing and makes no progress, so the next standing dawn pays what the skipped one would have. All integer arithmetic.
- **Single payout, two payers:** `BuildingSystem.dawn_income_by_spot()` pays FLAT curves only, `IncomeState.dawn_payouts()` every other curve, and `RunManager._apply_dawn_payout` walks `spot_ids()` so per_spot lists house_1, gold_mine_1, then the castle key last; with no Mine built the dictionary is key for key the old one (full_idle digest unchanged).
- **Task 2:** the crossed coin now asks `pays_income(tier)`; `EconomyValidation` (cap 1000) is in `MapConfig.validate()`; the Economy overlay section lists `castle: tier 2, picks Royal Training` and `gold_mine_1: paid 1, next 2`.
- **Plot rules:** `test_prototype_map_economy` is at 16 spots and carries the generic geometry rules (12 m from roads, 3 m from wall runs and gaps, nav content box) that plans 05-07 to 05-09 reuse by appending their ids.

## Verification

- Full suite, final state (two green runs on the committed Task 2 code): **258 scripts / 2447 tests / 57705 asserts** and **258 / 2447 / 57731** (assert totals vary by a few across runs because of polling waits), all passing, exit 0, about 12 minutes each. The first Task 2 run had one failure (the overlay section-order test, fixed in the GREEN commit); the Task 1 run had four failures in three scripts (see Deviations), fixed before the Task 1 commit and re-run per script.
- Baseline before the plan: 251 scripts / 2379 tests / 57338 asserts. New: 7 scripts, 68 tests.
- Replays after Task 2: smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all `--twice --expect-file`), full_idle `--twice` outcome=won ticks=6911 digest `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`: byte-identical to the baseline. They were also run after Task 1 with the same results.
- `bash tools/gate_stress.sh --twice`: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93`.
- `bash tools/lint.sh`: clean (424 files).
- JUnit names present: test_gold_mine, test_dawn_payout_economy, test_gold_mine_scene, test_prototype_map_economy, test_nav_layout_pin, test_dawn_income, test_dawn_payout, test_sim_rules_guard, test_rebuilt_economy_marker, test_economy_validation, test_economy_data_contract, test_economy_overlay_sections, test_debug_overlay_readonly.
- Real-window capture (scratch script, not committed): the Mine reads as a stone mine mouth with a dark doorway and a heap of gold boxes in front, the king beside it.

## TDD Gate Compliance (Task 2)

- **RED** `28647ef` `test(05-06)`: 4 test scripts, 39 tests. Failing on assertions for the planned behaviour: **9 of 14** in `test_economy_validation`, **7 of 11** in `test_economy_overlay_sections`, **1 of 5** in `test_rebuilt_economy_marker`. `test_economy_data_contract` (9 tests) passes by design: it pins what Task 1 shipped. `EconomyValidation` and `EconomyOverlaySections` were committed as interface skeletons (returning nothing) so the tests fail on assertions, not on a missing class.
- **Unexpected GREEN investigated:** the first marker tests all passed before any change because a DECLINING Mine's `dawn_income` is its first payout, so the old raw `dawn_income > 0` test already marked it. A discriminating test was added (`test_the_marker_asks_the_building_not_the_raw_income_field`: a BOATS-curve building with `dawn_income` 3 must not be marked until its own plan adds its field) and that one fails RED on the old code.
- **GREEN** `33db240` `feat(05-06)`: marker, EconomyValidation, overlay section, registration, map_config append. No REFACTOR commit (nothing to clean).
- `gsd_run check tdd-red-evidence` was not run: the plan is `type: execute` with a `tdd="true"` task, not a `type: tdd` plan.

## Task Commits

1. **Task 1: Tracer, Gold Mine pays 3 then 2 through the one dawn payout** - `f07a2ff` (feat)
2. **Task 2 RED: failing marker, validation and overlay tests** - `28647ef` (test)
3. **Task 2 GREEN: crossed coin for every paying curve, EconomyValidation, Economy overlay** - `33db240` (feat)
4. **Model polish after the real-window capture** - `7120732` (fix)

**Plan metadata:** the docs commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md.

## Files Created/Modified

- `simulation/economy/income_state.gd` - the Mine's paid-dawn state and non-flat dawn payouts
- `simulation/defs/building_def.gd`, `building_tier_def.gd` - the curve enum, `pays_income`, `tier_effect_line`, `income_step`, `income_floor`
- `simulation/run/run_manager.gd`, `run_context.gd`, `simulation/buildings/building_system.gd` - the payout merge, the ninth RunManager parameter, FLAT-only flat payouts
- `data/buildings/gold_mine.tres`, `data/maps/prototype_map.tres`, `presentation/buildings/models/gold_mine_t1.tscn`, `building_view_catalog.tres` - the building, its plot, model and catalog entry
- `ui/world/spot_label_model.gd`, `ui/hud/dawn_no_income_marker.gd`, `ui/overlay/economy_overlay_sections.gd`, `ui/overlay/debug_overlay.gd` - labels, marker, overlay section
- `simulation/defs/economy_validation.gd`, `map_config.gd` - curve validation
- Tests: see key-files; seven new scripts plus edits to six existing ones

## Decisions Made

See `key-decisions` above. Shipped numbers (cost 4, first payout 3, step 1, floor 1, health 20) are the planner's starting numbers; step 1 and floor 1 are D-12's wording and plan 05-11 fits cost and first payout by editing `test_economy_data_contract` in the same commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The Phase 4 structure pins built the new plot into their worlds**
- **Found during:** Task 1 (full suite)
- **Issue:** `test_structure_decision_pins` builds every prototype-map plot in its "proto" and "walled" worlds. The Gold Mine became one more target in the structure index, so six pins (proto and walled nearest/visible/through) moved with no structure code changed.
- **Fix:** the two worlds skip the Phase 5 plots (`PHASE_FIVE_PLOTS`), so the pinned worlds stay the Phase 4 map. The pins themselves are untouched and still never edited; `test_native_structures` reads the same worlds and passes.
- **Files modified:** tests/unit/test_structure_decision_pins.gd
- **Verification:** 8 of 8 pass; test_native_structures 14 of 14
- **Committed in:** f07a2ff

**2. [Rule 3 - Blocking] Two tests assumed the map ends with military and castle plots**
- **Found during:** Task 1 (full suite)
- **Issue:** `test_prototype_map_data` required every plot after the originals to field a unit (except wall and castle plots); `test_upgrade_at_spot` pinned four kinds of plot marker.
- **Fix:** the first lists the economic plots (`ECONOMIC_PLOT_IDS`) as exempt; the second counts five kinds and asserts the Gold Mine is one of them.
- **Files modified:** tests/unit/test_prototype_map_data.gd, tests/e2e/test_upgrade_at_spot.gd
- **Committed in:** f07a2ff

**3. [Rule 3 - Blocking] The overlay section-order test did not know the Economy section**
- **Found during:** Task 2 (first full run)
- **Fix:** `test_debug_overlay_night_sections` now lists Economy between Stats and Walls.
- **Files modified:** tests/unit/test_debug_overlay_night_sections.gd
- **Committed in:** 33db240

**4. [Rule 1 - Bug] The first Gold Mine model was a solid slab**
- **Found during:** a real-window capture after Task 2
- **Issue:** the Castle Kit wall piece is a one metre cube, not a thin wall; three of them at 0.45 offsets overlapped into one block with no readable doorway or ore.
- **Fix:** two pillars under a lintel against a low hill, a dark doorway box and five gold boxes (non-uniform scales of the same logged wall piece, no new asset).
- **Files modified:** presentation/buildings/models/gold_mine_t1.tscn
- **Committed in:** 7120732

**5. [Plan shape] Task 2 RED needed skeleton classes and one extra test** - see TDD Gate Compliance. The skeletons were replaced by the real classes in the GREEN commit.

---

**Total deviations:** 4 auto-fixed (3 Rule 3, 1 Rule 1) plus one TDD shape note
**Impact on plan:** all necessary for correctness of existing pins or legibility; no scope creep and no pin value edited.

## Issues Encountered

- A test that read the Mine's label at dawn found it stale ("Next dawn: 2" instead of 1): the label is hidden outside the day and refreshes at day start, so the test now waits for the day. This is by design, not a bug.
- `EconomyValidation` correctly rejected the test's own synthetic BOATS Mine (step and floor still set); the test clears them.
- The Mine plot's ground marker still uses BuildingViews' fallback colour (the House tan), because that colour switch is outside this plan's files. Left for the art pass or a later plan.

## Known Stubs

None. `IncomeState._init` has three underscore-named parameters (`_map`, `_events`, `_stat_stack`) that this plan does not read; they are the interface the Harbor and Shrine plans will use, not a placeholder for missing behaviour. No hardcoded empty data flows to the UI.

## Threat Flags

None. T-05-13 (curve tampering) is mitigated by EconomyValidation (range cap 1000, misplaced fields) and the non-growing integer counter; T-05-14 (double or mis-ordered payout) by the FLAT-only/IncomeState-only split, one `dawn_payout` with total equal to the sum, `test_dawn_payout_economy`, and the unchanged full_idle digest. T-05-SC: no packages; the model composes the logged Castle Kit wall piece.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 05-07 (Mill and Field). To add a plot, append its id to `PHASE_FIVE_PLOT_IDS` in `tests/unit/test_prototype_map_economy.gd` (raises the geometry rules over it), to `PHASE_FIVE_PLOTS` in `tests/unit/test_structure_decision_pins.gd` (so the Phase 4 pinned worlds stay Phase 4) and to `ECONOMIC_PLOT_IDS` in `tests/unit/test_prototype_map_data.gd`, and raise `SPOT_COUNT`, `BUILDABLE_PLOT_COUNT` there and the plot-kind count in `tests/e2e/test_upgrade_at_spot.gd`.
- `IncomeState` and `EconomyValidation` extend by adding a curve branch; `EconomyOverlaySections.economy_rows` by adding rows. `BuildingDef.pays_income` returns false for BOATS until plan 05-08 adds its field.
- RunManager is at 9 of 10 `_init` parameters (the ninth is `income`); BuildingSystem was not given a public method.
- Plan 05-11 owns the fit of the Mine's cost and first payout (edit `test_economy_data_contract` in the same commit).
- No blockers.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*

## Self-Check: PASSED

All twelve created files exist, commits `f07a2ff`, `28647ef`, `33db240` and `7120732` exist, and every acceptance criterion of both tasks holds (grep checks for the enum, `pays_income(`, `tier_effect_line(`, `class_name IncomeState`, `dawn_payouts(`, `spot_ids()`, `var income: IncomeState`, `income_step = 1`, `id = &"gold_mine_1"`, `"res://simulation/economy"`, `MAX_CURVE_VALUE: int = 1000`, `EconomyValidation.problems(`, `EconomyOverlaySections.register(`; full_idle digest `4385f569...`).
