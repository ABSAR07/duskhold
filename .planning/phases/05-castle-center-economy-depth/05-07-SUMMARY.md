---
phase: 05-castle-center-economy-depth
plan: 07
subsystem: simulation
tags: [godot, gdscript, economy, mill, field, build-requirement, dawn-payout, screenshot, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "requires_spot / requires_spot_tier, NEEDS_SPOT and CASTLE_TIER, the 'Needs a <building>' label line (05-05); BuildingDef FLAT payout through BuildingSystem.dawn_income_by_spot and the one merged dawn payout, the generic plot geometry rules and the four pin lists (05-06); ShotEconomyScenarios and ECONOMY_SHOTS (05-04)"
provides:
  - "Mill (data/buildings/mill.tres): three FLAT tiers cost 3 / 4 / 6 paying 1 / 2 / 3, health 15 / 20 / 25, tier III requires_castle_tier 2, the first shipped gated top tier (D-03)"
  - "Field (data/buildings/field.tres): one FLAT tier, cost 2, paying 1, health 8"
  - "Plots mill_1 (30, 0, 28), field_1 (25.5, 0, 30.5), field_2 (30, 0, 33), field_3 (34.5, 0, 30.5) appended as spots 17 to 20; every Field requires mill_1 at tier 1 from day 1 and reads 'Needs a Mill'"
  - "Four models (mill_t1 to t3, field_t1) composed from the logged Fantasy Town wall, wall-door and roof pieces plus engine boxes, registered in building_view_catalog.tres"
  - "test_field_independence: a fallen or rebuilt Mill never relocks or unpays its Fields, a Mill upgrade raises only the Mill (D-10, D-13)"
  - "field_locked screenshot (40th shot, closes ECONOMY_SHOTS)"
affects: [05-08 Harbor (append plot ids to the four pin lists; map is now 20 spots), 05-09 Shrine, 05-10 economy replay (Mill and Field are FLAT, nothing needed in IncomeState), 05-11 fit of Mill and Field numbers and the Field cost (edit test_economy_data_contract and re-check test_loop_tuning_contract), 05-12 verification and the field_locked review]

actuals:
  tokens: 19340
  tasks: 2
  commits: 3
plan_head_before: e0a2c3f24a8862a193a432f1a8a17dabb224f3a4
plan_head_after: 33591a77f57f300ef7e3f866b9e7fd26936d5356

tech-stack:
  added: []
  patterns:
    - "A building whose payout is a flat number needs no new state: Mill and Field ride BuildingSystem.dawn_income_by_spot and the requirement mechanism of plan 05-05, so the whole plan is data, plots, models and tests"
    - "The Field lock reads the Mill's tier (not whether it stands), so a Mill destroyed in the night or still down never relocks an unbuilt Field and a built Field never depends on it again"
    - "A new plot id goes into four pin lists (PHASE_FIVE_PLOT_IDS, PHASE_FIVE_PLOTS, ECONOMIC_PLOT_IDS, plot-kind count) and the map geometry rules cover it"

key-files:
  created:
    - data/buildings/mill.tres
    - data/buildings/field.tres
    - presentation/buildings/models/mill_t1.tscn
    - presentation/buildings/models/mill_t2.tscn
    - presentation/buildings/models/mill_t3.tscn
    - presentation/buildings/models/field_t1.tscn
    - tests/unit/test_mill_fields.gd
    - tests/e2e/test_mill_fields_scene.gd
    - tests/integration/test_field_independence.gd
  modified:
    - data/maps/prototype_map.tres
    - presentation/buildings/building_view_catalog.tres
    - tests/unit/test_prototype_map_economy.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_structure_decision_pins.gd
    - tests/unit/test_bot_defers_locked.gd
    - tests/unit/test_shot_list.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - tools/screenshot/shot_economy_scenarios.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh

key-decisions:
  - "Field cost is 2, not the plan's 1: test_loop_tuning_contract pins (UAT G-01-4, owner) that no shipped hold lasts under 0.5 s, and a 1 gold hold lasts 0.25 s. The Field still pays 1, so it repays in two nights; the number is an [ASSUMED] start for plan 05-11's fit, which must keep the cheapest tier at 2 gold or more (or the owner revisits the pin)"
  - "The Mill and the Field are FLAT, so they need nothing in IncomeState: BuildingSystem pays them in MapConfig order (mill_1, field_1, field_2, field_3) before the castle key"
  - "Marker colours were left alone: the Mill and Field plot discs use BuildingViews' fallback tan like the Mine, so on the field_locked shot the Mill plot reads as the fourth disc, told apart by position only (the colour switch is outside this plan's files)"
  - "test_bot_defers_locked's 'shipped data is ungated' pin was rewritten to what it really guards: no shipped build order buys a gated tier or a locked plot (plan 05-11 will change this when the bots buy the Mill and Fields)"

patterns-established:
  - "A gated top tier is tested through the real castle purchase (BuildIntent with the first tier II card id) rather than by editing the def, so the test follows shipped data"

requirements-completed: [ECON-04]

coverage:
  - id: D1
    description: "The player can build a Mill on the prototype map; three FLAT tiers each pay their own gold at dawn, and tier III needs castle II (the first shipped gated top tier)"
    requirement: ECON-04
    verification:
      - kind: unit
        ref: "tests/unit/test_mill_fields.gd#test_mill_three_needs_the_castle_at_tier_two_and_not_before"
        status: pass
      - kind: unit
        ref: "tests/unit/test_economy_data_contract.gd#test_the_mill_has_three_flat_tiers_that_pay_per_tier"
        status: pass
    human_judgment: false
  - id: D2
    description: "Three Field plots read 'Needs a Mill' and refuse the hold with the denied bump (needs_spot, nothing spent) until the Mill is at tier I; then each builds for its flat price and pays 1 at dawn"
    requirement: ECON-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_mill_fields_scene.gd#test_a_locked_field_reads_needs_a_mill_and_the_hold_is_denied_for_free"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_mill_fields_scene.gd#test_the_mill_opens_the_field_and_a_hold_builds_it_with_its_own_model"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_mill_fields_scene.gd#test_after_a_night_the_one_payout_lists_the_mill_and_the_field"
        status: pass
    human_judgment: false
  - id: D3
    description: "A built Field never depends on the Mill again: a fallen Mill is rebuilt free, pays nothing that morning and never relocks or unpays a Field; a fallen Field skips only its own morning; Mill II raises only the Mill's payout"
    requirement: ECON-04
    verification:
      - kind: integration
        ref: "tests/integration/test_field_independence.gd (8 tests; mutation probe: a relock-on-destroyed change in BuildRequirements fails 1 of 8)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The lock lifts exactly when the Mill reaches requires_spot_tier; empty, one-Field and map-order payout cases; a king equidistant from two plots focuses the earlier one"
    requirement: ECON-04
    verification:
      - kind: unit
        ref: "tests/unit/test_mill_fields.gd (11 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The prototype map has 20 spots; each Field is 4 to 8 m from the Mill, the new plots are 5 m or more from every other plot, every Phase 5 plot passes the road, wall, gap and content-box rules, NavGrid keeps its layout"
    requirement: ECON-04
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_economy.gd (19 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_nav_layout_pin.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "smoke, army and walls replay byte-identical and full_idle keeps digest 4385f569...: the bots never build a Mill or Field"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke|army|walls --twice --expect-file=...; --scenario=full_idle --twice"
        status: pass
    human_judgment: false
  - id: D7
    description: "The Mill (windmill tower with four sails, a storey per tier) and the Field (soil with golden crop boxes) models and the field_locked shot read well in the real game"
    verification:
      - kind: automated_ui
        ref: "screenshots/field_locked.png (executor review line below); scratch captures of Mill tier I and III"
        status: pass
    human_judgment: true
    rationale: "The executor looked at the PNGs, but whether the placeholder models and the 'Needs a Mill' label feel right is the owner's call at the phase UAT (plan 05-12 reviews field_locked again)"

duration: 90min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 07: Mill and Fields Summary

**A three-tier Mill (3 / 4 / 6 gold paying 1 / 2 / 3, tier III gated at castle II) opens three Field plots that are locked from day 1 by "Needs a Mill" and then pay a flat 1 gold each, independent of the Mill once built; all four replays byte-identical**

## Performance

- **Duration:** about 90 min (start about 18:50Z by the clock, estimated; the first full-suite run began 19:00:55Z)
- **Started:** 2026-10-21T18:50:00Z (approximate)
- **Completed:** 2026-10-21T20:19:34Z (last code commit 33591a7; docs commit follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 24 across the three code commits (9 created, 12 modified, 3 .uid)

## Accomplishments

- **Tracer (Task 1):** in the real prototype scene the king at `field_1` reads "Needs a Mill" with an empty coin row, a hold gives `hold_denied(field_1, needs_spot)` with the gold unchanged; he builds `mill_1` by holding and its model stands; back at `field_1` the price returns and a hold builds the Field and its model; after a night the one `dawn_payout` lists `mill_1` and `field_1` at their tier I incomes (`test_mill_fields_scene`, 3 tests).
- **Rules (11 unit tests):** NEEDS_SPOT is refused for free and announced; the lock lifts exactly at the required Mill tier (also with the tier raised to 2 on a deep copy); Mill, Fields pay in MapConfig order whatever the purchase order, before the castle key; only the Mill built means no Field key, one Field built means just that Field; Mill III is CASTLE_TIER at castle I and buyable after the real castle II purchase; a king exactly between two plots focuses the earlier in MapConfig order.
- **Independence (Task 2):** a Mill that falls is rebuilt free and skips only its own morning; it never relocks an unbuilt Field, even while it is down (the lock reads the Mill's tier); a fallen Field skips only itself; two nights without a standing Mill never stop the Fields; Mill II changes only the Mill's entry.
- **Map and pins:** 20 spots (mill_1 index 16, field_1 to field_3 index 17 to 19); each Field 4 to 8 m (5.0 to 5.15 m measured) from the Mill, the new plots 5 m or more from every other plot; the four pin lists and the plot-kind count extended; the data contract pins every Mill and Field number, the Field requirements, the plots and the catalog models.
- **Models and shot:** four models composed from the logged Fantasy Town pieces (no new asset, no new third-party entry); `field_locked` is the 40th shot and closes `ECONOMY_SHOTS`.

## Task Commits

1. **Task 1: Mill, Fields, plots, models, tracer tests** - `61e63c2` (feat)
2. **Task 2 RED: failing shot-list pins, independence and contract tests** - `317dd65` (test)
3. **Task 2 GREEN: field_locked screenshot** - `33591a7` (feat)

**Plan metadata:** the docs commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md follows.

## TDD Gate Compliance (Task 2)

- **RED** `317dd65` `test(05-07)`: `test_shot_list` 5 of 18 failing on assertions for the planned behaviour (39 where 40 is expected, `field_locked` not in `ALL_SHOTS`, the wrapper or the economy scenes, `ECONOMY_SHOTS` not closing on it). One extra "Unexpected Errors" line is the out-of-bounds read of the 40th shot. The test refers to `field_2` by literal so RED fails on assertions, not on a missing constant.
- **Unexpected GREEN investigated:** `test_field_independence` (8 of 8) and `test_economy_data_contract` (14 of 14) passed before any Task 2 code: the independence follows from Task 1's mechanism (the lock reads the Mill's tier and the dawn rebuild is a plain flag) and the contract pins what Task 1 shipped. So the tests could not fail by themselves, a mutation probe was run: changing `BuildRequirements.rejection` so a destroyed required plot relocks its Fields fails `test_field_independence` 1 of 8 ("the lock reads its tier", "a Field builds"); the file was restored and `git status` shows no change under `simulation/`.
- **GREEN** `33591a7` `feat(05-07)`: the shot, the lists, the wrapper. No REFACTOR commit (nothing to clean).
- `gsd_run check tdd-red-evidence` was not run: the plan is `type: execute` with a `tdd="true"` task, not a `type: tdd` plan.

## Verification

- **Full suite**, final state after Task 2, two runs, both exit 0: **261 scripts / 2479 tests / 58795 asserts** and **261 / 2479 / 58754** (assert totals vary by a few dozen between identical runs because of polling waits in e2e tests), about 12.7 minutes each. After Task 1: 260 / 2465 / 58572 (a first run had two failures, both fixed, see Deviations). Baseline at dispatch: 258 / 2447 / 57757. New: 3 scripts, 32 tests.
- **Replays (each --twice):** smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all matched their golden files); full_idle outcome=won ticks=6911 digest `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`, byte-identical to the RESEARCH E3 baseline; checked after Task 1 and after Task 2.
- **Gate stress:** `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93`.
- **Lint:** `bash tools/lint.sh` clean (427 files).
- **JUnit names present:** test_mill_fields (unit and scene), test_prototype_map_economy, test_nav_layout_pin, test_build_requirements, test_dawn_payout_economy, test_field_independence, test_economy_data_contract, test_shot_list, test_loop_tuning_contract.
- **field_locked review (real window, RTX 3060, Forward+, 1280x720):** the label reads "Field I / +1 gold at dawn / Needs a Mill" and is legible with no coin row; the three Field discs and the empty Mill plot are all in frame (the Mill plot is the top disc, the king stands on the bottom one); the label sits close to the king's hat and the Mill disc has the same tan as the Fields (fallback colour, see decisions), so it is told apart by position only. Scratch captures of the built models (not committed): Mill tier I reads as a stone windmill tower with four cream sails and a teal roof beside two Fields of dark soil with rows of golden crop boxes; tier III is a three-storey tower that overflows the top of the frame at this camera height.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Field cost 1 broke the owner's minimum-hold pin**
- **Found during:** Task 1 (first full suite)
- **Issue:** `test_loop_tuning_contract.test_shortest_shipped_hold_is_at_least_the_minimum` (UAT G-01-4: the owner judged a 0.4 s hold too short, so no shipped hold may be under 0.5 s) failed: a 1 gold Field holds for 0.25 s. The plan's "cost 1" is an [ASSUMED] starting number that nobody checked against that pin.
- **Fix:** Field cost is 2 (still pays 1, so it repays in two nights). The owner's pin was not touched. `test_economy_data_contract` pins cost 2 with the reason in a comment. Plan 05-11, which fits the numbers, must keep the cheapest tier at 2 gold or more or take the pin back to the owner.
- **Files modified:** data/buildings/field.tres, tests/unit/test_economy_data_contract.gd
- **Verification:** test_loop_tuning_contract 12 of 12; full suite green twice
- **Committed in:** 61e63c2 (data), 317dd65 (contract)

**2. [Rule 3 - Blocking] The "shipped data is ungated" pin met the first shipped gating**
- **Found during:** Task 1 (first full suite)
- **Issue:** `test_bot_defers_locked.test_a_shipped_strategy_on_the_shipped_map_never_defers` asserted no tier and no plot carries a requirement, true until plan 05-05's "gating waits for plan 05-11". Mill III and the Fields are gated by this plan's own design, so four assertions failed.
- **Fix:** the test now checks what it is meant to guard: for every shipped strategy's build order, each plot needs no other plot and each tier bought is ungated. No shipped bot buys a Mill or Field yet, so it passes unchanged in meaning; plan 05-11 must update it when the bots do.
- **Files modified:** tests/unit/test_bot_defers_locked.gd
- **Verification:** 8 of 8 pass
- **Committed in:** 61e63c2

**3. [Rule 3 - Blocking] Pin lists extended for the new plots** (the four places plan 05-06's SUMMARY listed, as expected, not a surprise): `PHASE_FIVE_PLOTS` (the Phase 4 structure worlds skip the new plots, no pin edited), `ECONOMIC_PLOT_IDS`, `PHASE_FIVE_PLOT_IDS` with the counts (20 spots, 19 buildable), and the plot-kind count in `test_upgrade_at_spot` (5 to 7: Mill and Field are kinds of their own). Committed in 61e63c2.

**4. [Plan shape] Task 2 RED was only partly real** - see TDD Gate Compliance (shot-list RED real, independence and contract green by design, mutation probe run).

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3) plus one TDD shape note
**Impact on plan:** the Field cost change is the one number that differs from the plan; all are within the plan's own [ASSUMED] flag and no owner pin or golden moved.

## Issues Encountered

- Python one-off edits on files with CRLF in the working copy (autocrlf) did not match multi-line strings; solved by reading with universal newlines and writing LF (the repo's eol=lf).
- One lint line-length slip per edited test header, fixed with `lint.sh --fix` plus manual wrapping.

## Known Stubs

None. No placeholder text or empty data source in any created or modified file. The Mill and Field plot discs wear the House-tan fallback colour (building_views.gd, outside this plan's files); that is a presentation gap left for the art pass or a later plan, not a stub.

## Threat Flags

None. T-05-15 (Field lock bypass through a BuildIntent) is mitigated and pinned: `validate_build` refuses NEEDS_SPOT before any spend (test_mill_fields, test_mill_fields_scene: gold unchanged, command_rejected announced), and BuildRequirementValidation (plan 05-05) covers a missing plot, itself and an impossible tier on the shipped map (`test_the_shipped_map_validates_clean`). T-05-SC: no packages; models compose the logged Fantasy Town pieces and engine primitives.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-08 (Harbor): append the Harbor plot id to `PHASE_FIVE_PLOT_IDS` (test_prototype_map_economy), `PHASE_FIVE_PLOTS` (test_structure_decision_pins), `ECONOMIC_PLOT_IDS` (test_prototype_map_data), raise `SPOT_COUNT`, `BUILDABLE_PLOT_COUNT`, the first Phase 5 index logic and the plot-kind count in `test_upgrade_at_spot` (now 7). `test_prototype_map_economy` has 19 tests (one short of the 20 cap): a Harbor test file of its own is needed rather than more tests there. `test_shot_list` has 18 tests.
- Plan 05-11: the Mill and Field numbers are [ASSUMED] starting points (edit `test_economy_data_contract` in the same commit); keep the cheapest tier at 2 gold or more (the 0.5 s hold pin), and update `test_bot_defers_locked`'s shipped-orders pin when the bots buy the Mill, Fields and gated tiers.
- ECON-04 is recorded in `requirements-completed` and may be ticked in REQUIREMENTS.md; no other plan of the phase declares it.
- No blockers.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*

## Self-Check: PASSED

All nine created files exist (mill.tres, field.tres, four models, three test scripts), commits `61e63c2`, `317dd65` and `33591a7` exist, and every acceptance criterion holds: `id = &"mill"` with three `dawn_income =` lines and `requires_castle_tier = 2`; `id = &"field"` with `dawn_income = 1`; `id = &"mill_1"` and three `requires_spot = &"mill_1"` in the map; the catalog references the four scenes; `ALL_SHOTS` in screenshot.sh contains `field_locked`; `const EXPECTED_SHOT_COUNT: int = 40`; full_idle digest `4385f569...`; the contract pins the Mill and Field numbers; the field_locked review line is above.
