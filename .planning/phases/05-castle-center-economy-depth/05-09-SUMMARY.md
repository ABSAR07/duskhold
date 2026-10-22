---
phase: 05-castle-center-economy-depth
plan: 09
subsystem: simulation
tags: [godot, gdscript, economy, shrine, awakened-curve, stat-stack, synergy, tower-loop, validation, debug-overlay, screenshot, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "StatStack with add_source replacing a source id whole and the shrine.damage / shrine.range ids registered with no consumer (05-01); IncomeState, dawn_payouts() and BuildingDef.pays_income (05-06); the BOATS branch and the event registration recipe (05-08); the four plot pin lists and the generic plot geometry rules (05-07); EconomyValidation and EconomyOverlaySections (05-06, 05-08)"
provides:
  - "BuildingTierDef.wake_radius, wake_threshold_hp and synergy_percent; BuildingDef.damage_stat and range_stat (towers keep tower.damage and tower.range)"
  - "IncomeState Shrine state: is_awake(), kill_credit(), awake_count(); every enemy_died credits the dead enemy's max health to each built Shrine within its wake radius (<=, any killer, standing or fallen); a credit >= the threshold wakes it for good and emits shrine_woke once; dawn income only while awake"
  - "SimEvents.shrine_woke(spot_id), registered in SimSignals.ALL and SimRecorder.HANDLED with its handler and connect"
  - "The awake gate inside TowerSystem's existing loop (a dormant Shrine never fires, before any target query); damage and reach read through the building's own stat ids; NightSim's trailing income parameter (10 arguments, the lint cap)"
  - "The mutual synergy as one replaced stack source shrine_synergy (PERCENT synergy_percent x (n - 1) on shrine.damage), updated once per death after every Shrine is credited"
  - "data/buildings/shrine.tres, the plots shrine_west (-46, 0, 30) and shrine_east (46, 0, 30) as spots 22 and 23 (23 spots, 22 buildable), the obelisk model with a hidden Glow orb, tests/fixtures/fixture_map_shrine.tres with an inline Shrine"
  - "EconomyValidation Shrine checks (MAX_WAKE_RADIUS 40.0, MAX_WAKE_THRESHOLD 100000, MAX_SYNERGY_PERCENT 100, attack numbers, wake fields on other curves, known and right-kind damage_stat / range_stat); Economy overlay rows 'asleep C of T' and 'awake C'; Shrine label line; the glow, violet plot disc and violet bolts; shrine_awake_night (42nd shot)"
affects: [05-10 economy replay (IncomeState now has all four curves; no bot builds a Shrine yet), 05-11 fit of Shrine cost, threshold, pay and damage (edit test_economy_data_contract in the same commit, keep every cost at 2 or more; the Shrine plots sit 12.5 m from the road so a reach of 9 m reaches only enemies that come for it, see Next Phase Readiness), 05-12 verification and the shrine_awake_night review]

actuals:
  tokens: 32643
  tasks: 2
  commits: 3
plan_head_before: 66da1118fdef8cd61cd4f784e5094e3cc167977f
plan_head_after: 2b04a5e2931f10b130e102fc30558803ec5a5ca1

tech-stack:
  added: []
  patterns:
    - "An awakened curve is one more IncomeState branch plus one gate in an existing loop: the Shrine reuses TowerSystem (no second attack loop, no new NightSim step) and asks IncomeState whether it has woken, failing closed when nobody can say"
    - "A modifier that depends on a count is one stack source replaced on every change, updated once after the event handler has finished crediting, so same-tick changes land once and repeated wakes never accumulate"
    - "A building names the stat ids its attack reads (BuildingDef.damage_stat / range_stat), so a modifier on one kind of attacker never touches another"

key-files:
  created:
    - data/buildings/shrine.tres
    - presentation/buildings/models/shrine_t1.tscn
    - tests/fixtures/fixture_map_shrine.tres
    - tests/unit/test_shrine.gd
    - tests/unit/test_shrine_plots.gd
    - tests/unit/test_shrine_synergy.gd
    - tests/unit/test_shrine_validation.gd
    - tests/integration/test_shrine_night.gd
    - tests/integration/test_shrine_destroyed.gd
    - tests/e2e/test_shrine_scene.gd
    - tests/e2e/test_shrine_look.gd
  modified:
    - simulation/defs/building_tier_def.gd
    - simulation/defs/building_def.gd
    - simulation/defs/economy_validation.gd
    - simulation/economy/income_state.gd
    - simulation/night/tower_system.gd
    - simulation/night/night_sim.gd
    - simulation/run/run_context.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - data/maps/prototype_map.tres
    - presentation/buildings/building_view_catalog.tres
    - presentation/buildings/building_views.gd
    - presentation/vfx/projectile_vfx.gd
    - ui/world/spot_label_model.gd
    - ui/overlay/economy_overlay_sections.gd
    - ui/overlay/stat_overlay_sections.gd
    - tools/screenshot/shot_economy_scenarios.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
    - docs/STAT_MODIFIERS.md
    - tests/unit/test_prototype_map_economy.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_structure_decision_pins.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_economy_overlay_sections.gd
    - tests/unit/test_shot_list.gd

key-decisions:
  - "A death exactly at wake_radius counts (squared distance compared with <=) and a credit exactly equal to the threshold wakes the Shrine (>=); credit comes from any killer, the Shrine included, and from a Shrine that lies in rubble (D-14, research A8)"
  - "The towers loop skips an AWAKENED building unless IncomeState.is_awake(spot) is true, before any target query or enqueue; a TowerSystem built without an IncomeState keeps every Shrine silent (fails closed)"
  - "shrine_synergy reads synergy_percent from the first awake Shrine's tier I in MapConfig order, caps the value at StatModifierDef.PERCENT_MAX, and is updated once per enemy_died after every Shrine has been credited, so two Shrines waking on one tick change the stack once"
  - "BuildingDef.damage_stat and range_stat default to the tower ids; EconomyValidation requires damage_stat to be a registered integer stat and range_stat a registered float stat on every building"
  - "The fixture's Shrine plot sits at (-14, 0, 8) with a second tower plot tower_2 at (-12, 0, -4) and night 1 sends 36 grunts at 0.8 s: at the planned (-16, 0, 6) the grunts killed the dormant Shrine before it woke"
  - "The Shrine plot disc has its own colour (violet), keyed on the AWAKENED curve rather than the building id"

patterns-established:
  - "Awakened curve footprint: one IncomeState branch, one validation branch, one overlay row, one event, one gate in the loop that already steps the attacker"

requirements-completed: [ECON-06]

coverage:
  - id: D1
    description: "A built Shrine is credited with the max health of every enemy that dies within its wake radius (a death exactly at the radius counts, 0.01 m outside does not; any killer; standing or fallen), wakes once when the credit reaches the threshold (equal wakes it), emits shrine_woke once, and a death inside two radii credits both in MapConfig order"
    requirement: ECON-06
    verification:
      - kind: unit
        ref: "tests/unit/test_shrine.gd (17 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A dormant Shrine never fires even with an enemy in reach; an awake standing one shoots the nearest enemy like a tower on the pending-hit queue, reading shrine.damage and shrine.range (never the tower stats); a fallen awake one fires nothing and fires again once rebuilt"
    requirement: ECON-06
    verification:
      - kind: integration
        ref: "tests/integration/test_shrine_night.gd (13 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "On the Shrine fixture in a whole night the Shrine stays silent while grunts are in its reach, wakes, fires, pays its dawn income, logs one shrine_woke before its first shot and replays to the same digest (another seed differs); in the real scene the king builds it by holding, it wakes within 60 s and a drawn bolt leaves its plot"
    requirement: ECON-06
    verification:
      - kind: integration
        ref: "tests/integration/test_shrine_night.gd#test_the_shrine_stays_silent_while_dormant_then_wakes_fires_and_pays"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_shrine_scene.gd (2 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "With n Shrines awake each gets +synergy_percent x (n - 1) percent attack damage through one replaced stack source (none below two awake, 3 x 1.2 rounds to 4, a Golden Age card adds in the same percent bucket, the stack changes once for a same-tick double wake, repeated wakes never pile up, tower stats untouched)"
    requirement: ECON-06
    verification:
      - kind: unit
        ref: "tests/unit/test_shrine_synergy.gd (10 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A destroyed Shrine keeps its credit and its awake state, keeps being credited, does not shoot while down, is rebuilt free at dawn, pays nothing that morning, carries the crossed coin awake or dormant, and shoots again next night; a dormant fallen one keeps its partial credit and wakes later"
    requirement: ECON-06
    verification:
      - kind: integration
        ref: "tests/integration/test_shrine_destroyed.gd (8 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_shrine_look.gd#test_a_rebuilt_dormant_shrine_wears_the_crossed_coin"
        status: pass
    human_judgment: false
  - id: D6
    description: "MapConfig.validate() reports a non-finite wake_radius or one outside (0, 40], a wake_threshold_hp outside 1..100000, a synergy_percent outside 0..100, an AWAKENED building without attack numbers, wake fields on a non-awakened building and an unknown or wrong-kind damage_stat / range_stat; the shipped map is clean"
    requirement: ECON-06
    verification:
      - kind: unit
        ref: "tests/unit/test_shrine_validation.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "The prototype map has 23 spots (22 buildable plus the castle plot) with shrine_west and shrine_east at indices 21 and 22, each within 15 m and at least 12 m from a spawn-to-castle road, 5 m from every other plot, with the nav layout pin unchanged; the Shrine's numbers, plots, model and stats are pinned"
    requirement: ECON-06
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_economy.gd, tests/unit/test_shrine_plots.gd, tests/unit/test_nav_layout_pin.gd, tests/unit/test_economy_data_contract.gd"
        status: pass
    human_judgment: false
  - id: D8
    description: "The Economy overlay lists 'asleep C of T' and 'awake C' per built Shrine and the label reads 'Asleep: C of T enemy health' then 'Awake'; the Glow orb shows when it wakes and again after a rebuild, the plot disc is violet and Shrine bolts fly violet while tower arrows stay gold"
    requirement: ECON-06
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_overlay_sections.gd (4 new tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_shrine_look.gd (7 tests)"
        status: pass
    human_judgment: false
  - id: D9
    description: "smoke, army and walls replay byte-identical, full_idle keeps digest 4385f569..., and the gate stress is unchanged: no bot builds a Shrine, unbuilt Shrines credit, wake and fire nothing, and towers read the same stats as before"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke|army|walls --twice --expect-file=...; --scenario=full_idle --twice; bash tools/gate_stress.sh --twice"
        status: pass
    human_judgment: false
  - id: D10
    description: "The shrine_awake_night screenshot shows a glowing awake Shrine firing a bolt at night, and the obelisk placeholder, orb and violet look feel right"
    verification:
      - kind: automated_ui
        ref: "screenshots/shrine_awake_night.png (executor review line below)"
        status: pass
    human_judgment: true
    rationale: "The executor looked at the PNG and the scene's own checks passed (awake, glowing, a Shrine bolt drawn), but whether the placeholder obelisk, the orb and the violet bolt feel right is the owner's call at the phase UAT (plan 05-12 reviews shrine_awake_night again)"

duration: 85min
completed: 2026-10-22
status: complete
---

# Phase 5 Plan 09: Shrines Summary

**An awakened Shrine: kill credit from any death in its 18 m radius, a one-way wake, a bolt in the existing tower loop that a dormant Shrine never fires, dawn income only when awake, a mutual +20% per other awake Shrine through one replaced stack source, validated data, overlay rows, a glow and violet bolts; all four replays and the gate stress byte-identical**

## Performance

- **Duration:** about 85 min (about 50 min of it full-suite runs)
- **Started:** 2026-10-21T22:42:52Z
- **Completed:** 2026-10-22T00:08:17Z (last code commit 2b04a5e; docs commit follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 47 across the three code commits (11 created, 28 modified, plus .uid files)

## Accomplishments

- **Tracer (Task 1):** on `fixture_map_shrine.tres` in a whole night the Shrine stays silent while grunts are inside its 9 m reach, wakes when the credited health passes the threshold, then fires and pays at dawn; in the real scene the king builds it by holding, it wakes within 60 s and the projectile layer draws a bolt that leaves its plot (`test_shrine_night`, `test_shrine_scene`).
- **Credit and wake (17 unit tests):** a grunt (6) dying exactly 18.0 m away credits 6, one at 18.01 m credits nothing; credits that sum exactly to the threshold wake it (one short does not); further deaths keep crediting and never emit again; a death inside both radii credits both in MapConfig order; deaths before the Shrine is built credit nothing.
- **Gate in the existing loop (research P4):** `TowerSystem` skips an AWAKENED building unless `IncomeState.is_awake`, before any target query, and reads damage and reach through `damage_stat` / `range_stat`; the night step order, the native enemy step and its inputs did not change, and towers read the same stats as before.
- **Synergy (Task 2):** `shrine_synergy` is a PERCENT modifier of `synergy_percent x (n - 1)` on `shrine.damage`, replaced on every count change and removed below two; two awake Shrines each hit for 4 (3 x 1.2 rounds half up); a Golden Age card (+25) adds in the same bucket (45).
- **D-14:** a destroyed Shrine keeps credit and awake state, is credited for deaths beside the rubble, does not shoot while down, is rebuilt free, pays nothing that morning, wears the crossed coin awake or dormant, and shoots again next night.
- **Data and map:** `shrine.tres` (cost 3, pays 1, damage 3, reach 9.0, interval 1.1, bolt 20.0, health 30, wake radius 18.0, threshold 100, synergy 20), `shrine_west` and `shrine_east` (23 spots, 22 buildable), the obelisk model from two logged Castle Kit pieces with a hidden `Glow` orb, the label line "Asleep: C of T enemy health" / "Awake".
- **Validation and overlay:** EconomyValidation reports bad Shrine data and stat ids (T-05-17); the Economy section lists `shrine_west: asleep 30 of 100` and `shrine_east: awake C` rows, read-only.
- **Look:** the Glow orb shows on `shrine_woke` and after a rebuild (`BuildingViews.is_shrine_glowing`), the plot disc is violet, Shrine bolts are violet `Color(0.7, 0.45, 1.0)` while tower arrows stay gold; `shrine_awake_night` is the 42nd shot.

## Task Commits

1. **Task 1: Shrine, credit, wake, gated attack, data, plots, model, fixture, tracer tests** - `b7c78dc` (feat)
2. **Task 2 RED: failing synergy, validation, glow and bolt look, overlay rows and 42-shot pins** - `25d101d` (test)
3. **Task 2 GREEN: synergy, validation, overlay rows, glow, violet bolts, shrine_awake_night** - `2b04a5e` (feat)

**Plan metadata:** the docs commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md follows.

## TDD Gate Compliance (Task 2)

- **RED** `25d101d` `test(05-09)`: 30 assertions-level failures on the planned behaviour: `test_shrine_synergy` 6 of 10 (`has_source` false, pct 0 where 20 is expected, hits 3 where 4), `test_shrine_validation` 11 of 12 (every new check missing), `test_shrine_look` 4 of 7 (no glow, House-tan disc, gold where violet is expected), `test_shot_list` 7 of 20 (41 where 42 is expected, `shrine_awake_night` missing from the wrapper, `ALL_SHOTS` and the economy scenes, plus the out-of-range read as an "Unexpected Errors" line), `test_economy_overlay_sections` 2 of 18 (`[<null>] expected to equal ["asleep 30 of 100"]`). The interface (EconomyValidation's three constants, `SHRINE_MARKER_COLOR`, `SHRINE_COLOR`, an `is_shrine_glowing` that returned false and the fixture path constant) was committed with the RED tests so the scripts load and fail on assertions, not on missing names.
- **Unexpected GREEN investigated:** `test_shrine_destroyed` (8 of 8) and the three new Shrine tests of `test_economy_data_contract` passed before any Task 2 code by design: the D-14 rules (credit ignores destruction, awake never clears, a fallen Shrine is absent from `standing_spot_ids`, the rebuilt dawn pays nothing, `pays_income` has no awake check) are consequences of Task 1's IncomeState and the plan 05-06 marker rule, which the plan says to "confirm by test"; the contract pins what Task 1 shipped.
- **GREEN** `2b04a5e` `feat(05-09)`: the synergy, the checks, the rows, the look, the shot. No REFACTOR commit (nothing to clean).
- `gsd_run check tdd-red-evidence` was not run: the plan is `type: execute` with a `tdd="true"` task, not a `type: tdd` plan.

## Verification

- **Full suite, Task 1 (one run, exit 0):** 268 scripts / 2559 tests / 59931 asserts. Baseline at dispatch: 264 / 2521 / 59165.
- **Full suite, final state after Task 2, two runs:** run 1 **272 scripts / 2604 tests / 60276 asserts, 1 failure** (`test_box_select#test_hover_rings_are_suppressed_while_the_box_is_up_and_return_after`, the known busy-machine hover flake: `expected archery_1, got ''`); `bash tools/test.sh -gselect=test_box_select` alone then passed 13 of 13 with no other Godot process alive; run 2 **272 / 2604 / 60270, all 2604 passing, exit 0**. New in the plan: 8 scripts (test_shrine, test_shrine_plots, test_shrine_night, test_shrine_scene, test_shrine_synergy, test_shrine_destroyed, test_shrine_validation, test_shrine_look) and 83 tests (76 in the new scripts, 7 added to test_economy_data_contract, test_economy_overlay_sections and test_shot_list).
- **Replays (each --twice, after Task 1 and again after Task 2):** smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all matched their golden files); full_idle outcome=won ticks=6911 digest `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`, byte-identical to the RESEARCH E3 baseline.
- **Gate stress (after Task 1 and Task 2):** `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93` (digest `e448ffdb...`).
- **Lint:** `bash tools/lint.sh` clean (439 files).
- **JUNIT names present:** test_shrine, test_shrine_night, test_shrine_scene, test_prototype_map_economy, test_nav_layout_pin, test_tower_combat, test_determinism, test_stat_tracer (Task 1); test_shrine_synergy, test_shrine_destroyed, test_economy_validation, test_economy_data_contract, test_economy_overlay_sections, test_shot_list, test_projectiles_visible (Task 2).
- **shrine_awake_night review (real window, RTX 3060, Forward+, 1280x720, `bash tools/screenshot.sh shrine_awake_night`):** the awake Shrine on its violet plot disc shows its pale-violet Glow orb floating above the blue-roofed obelisk, a light-violet bolt streak is in flight above it toward the grunts crowding the road at the top of the frame, gold tower arrows fly beside it, the king stands in front and the night banner reads "Night 1 of 2 - 19 enemies left"; the scene's own checks (Shrine awake, a drawn bolt leaving its plot, the orb showing) passed. The framing puts the Shrine left of centre (the camera follows the king, who stands 3 m beside it), which is readable but not a hero shot, and the grey-green ground does not read as night: the owner's call at the UAT.

## Edge coverage ledger

Copied verbatim from the plan's "Edge coverage ledger" section (acceptance criterion). This plan carries the last probe items.

### Edge coverage ledger (no-silent-drop equality, recorded here as the plan carrying the last probe items)

The spec-less probe report surfaced 26 items across the nine requirements. Disposition: 26 = 23 explicit `[edge ...]` truths + 0 backstop markers + 3 flagged assumptions.
- Explicit truths (23): BLDG-08 empty and ordering, UI-02 empty and ordering (plan 05-02); BLDG-08 adjacency, UI-02 encoding (plan 05-03); UI-02 adjacency (plan 05-04); ECON-03 boundary, adjacency, empty, ordering, precision (plan 05-06); ECON-04 adjacency, empty, ordering (plan 05-07); ECON-05 boundary, adjacency, empty, ordering, precision (plan 05-08); ECON-06 adjacency, empty, ordering (this plan).
- Flagged assumptions (3, the unclassified rows, each with an assumed contract written as `[assumed-contract ...]` truths): META-08 (plan 05-01), BLDG-05 (plan 05-02), BLDG-09 (plan 05-05).
- Owner feel items that only a human can judge are carried as backstop markers in plan 05-12; they are not probe items and are not counted above.

This plan's three items and where they are proved:

| Item | Truth | Proof |
|------|-------|-------|
| ECON-06 adjacency | a death exactly at wake_radius counts (<=), a credit exactly at the threshold wakes (>=), a death 0.01 m outside credits nothing | `test_shrine.gd`: exact radius, 0.01 m outside on both axes, threshold equal and one short |
| ECON-06 empty | no shrine_synergy source with none awake, none with exactly one awake (damage equals the base), deaths before a Shrine is built credit nothing | `test_shrine_synergy.gd` (none, one awake, zero synergy data), `test_shrine.gd` (deaths before built, empty and unknown plots) |
| ECON-06 ordering | a death in both radii credits both in MapConfig order; two Shrines waking on one tick emit shrine_woke west then east and the stack changes once to the final count | `test_shrine.gd` (both radii), `test_shrine_synergy.gd` (same-tick wake: two events in order, one `changed`) |

## Files Created/Modified

See the frontmatter `key-files`. Highlights: `simulation/economy/income_state.gd` (credit, wake, synergy), `simulation/night/tower_system.gd` (the gate and the stat ids), `data/buildings/shrine.tres` and the two plots in `data/maps/prototype_map.tres`, `tests/fixtures/fixture_map_shrine.tres`, `presentation/buildings/models/shrine_t1.tscn`.

## Decisions Made

See `key-decisions`. Numbers (cost 3, pays 1, damage 3, reach 9.0, interval 1.1, bolt 20.0, health 30, radius 18.0, threshold 100, synergy 20) are [ASSUMED] starting points that plan 05-11 fits; behaviour tests read the shipped .tres or set numbers on a deep copy, and only `test_economy_data_contract` pins the literals.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The fixture needed more than counts and intervals to wake its Shrine alive**
- **Found during:** Task 1 (first runs of `test_shrine_night` and `test_shrine_scene`)
- **Issue:** On the planned fixture (Shrine at (-16, 0, 6), 24 grunts at 0.4 s, one tower) the grunts, whose aggro range of 6 m reaches that plot, destroyed the dormant Shrine at tick 683 and only 36 health was credited before the run ended; with 24 grunts at 1.5 s it was still destroyed before it woke (it woke at 1049 as rubble).
- **Fix:** Shrine plot at (-14, 0, 8) (more than 6 m of edge distance from the road, so grunts leave it alone, yet inside its 9 m reach of the road), a second tower plot `tower_2` at (-12, 0, -4) bought by every test, night 1 of 36 grunts at 0.8 s (night 2 unchanged: 10 at 0.8 s). The Shrine wakes at tick 646 and fires 14 times in night 1. The plan allowed tuning only counts and intervals; the position and the second tower are the additional change and are recorded here.
- **Files modified:** tests/fixtures/fixture_map_shrine.tres, tests/integration/test_shrine_night.gd, tests/integration/test_shrine_destroyed.gd, tests/e2e/test_shrine_scene.gd
- **Verification:** 38 of 38 Shrine tests passed after the change; full suite green
- **Committed in:** b7c78dc

**2. [Rule 1 - Bug] The Stats overlay read a Shrine's base for the tower stats**
- **Found during:** Task 1 (reading every `attack_damage > 0` scan after the Shrine joined the map)
- **Issue:** `StatOverlaySections._first_standing_attacker_tier` took the first standing building with attack numbers; with only a Shrine standing it would print the Shrine's damage as the base of `tower.damage`.
- **Fix:** it skips a building whose `damage_stat` is not `tower.damage` (file outside the plan's `files_modified`).
- **Files modified:** ui/overlay/stat_overlay_sections.gd
- **Verification:** `test_stat_overlay_sections` and the full suite green
- **Committed in:** b7c78dc

**3. [Rule 3 - Blocking] Test-script and class caps put some tests in new scripts**
- **Found during:** Task 1 and Task 2
- **Issue:** `test_prototype_map_economy` is at the 20-test cap and `test_economy_validation` at 19 public methods; the real-scene look tests need their own scene setup.
- **Fix:** `test_shrine_plots.gd` (Shrine plot rules), `test_shrine_validation.gd` (all Shrine validation tests) and `test_shrine_look.gd` (glow, disc, bolt colour, crossed coin) are new scripts; `test_prototype_map_economy` only changed its id list and counts as planned, `test_economy_validation` is unchanged. `test_economy_data_contract`, `test_economy_overlay_sections` and `test_shot_list` gained 3, 4 and 1 tests as planned.
- **Committed in:** b7c78dc, 25d101d

**4. [Plan shape] Pre-existing assertions on the end of the shot list moved**
- `test_shot_list` asserted that `harbor_pond` closes the list and that `field_locked` is second last; they now say second last and third last, and the deep-copy loop skips the fixture-based shot (it has 3 spots, not 23). The plan listed the file; the content of these edits was not spelled out.

**5. [Plan shape] Task 1's replay chain ran once, Task 2's twice**
- Task 1's verify chain ran the full suite once (268 scripts, all passing) plus the replays and the gate stress; the final state ran the suite twice. Run 1 of the final state had one failure, the known `test_box_select` hover flake (rerun alone: 13 of 13 pass; run 2 all pass), cited above.

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 3 fixture), 1 Rule 3 cap note, 2 plan-shape notes
**Impact on plan:** no pin value, golden or owner pin moved; the fixture change only affects a test map.

## Issues Encountered

- Several multi-line comment blocks hit the 100-character lint cap one at a time; fixed by hand (no code affected).
- The first fixture attempts (see Deviation 1) took three probe runs with a scratch SceneTree script to find a layout in which the Shrine survives long enough to wake.

## Known Stubs

None. No placeholder text or empty data source in any created or modified file. The Shrine's obelisk and orb are placeholder art (two logged Castle Kit pieces and a primitive sphere), a presentation matter for the Phase 8 art pass, not a stub.

## Threat Flags

None. T-05-17 (wake radius, threshold, synergy and stat ids) is mitigated and pinned: EconomyValidation bounds `wake_radius` to (0, 40], `wake_threshold_hp` to 1..100000 and `synergy_percent` to 0..100, requires attack numbers on AWAKENED tiers and known stat ids of the right kind (`test_shrine_validation`); the death handler is one squared-distance test per Shrine (two shipped). T-05-18 (synergy stacking) is mitigated and pinned: one source id is replaced on every change and never appended, the value is capped at the stack's own percent bound, and `test_shrine_synergy` shows 20 deaths more and a golden-age card leave it at +20 / +45. T-05-SC: no packages; the model composes two logged Castle Kit pieces and a primitive sphere.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-10 (economy replay): IncomeState now carries all four income curves; no bot builds a Shrine yet, so the four replays and the gate stress did not move. The new `shrine_woke` line is in the recorder, so an `economy` golden that builds a Shrine will record it.
- Plan 05-11 (fit): the Shrine numbers are [ASSUMED] starting points (edit `test_economy_data_contract` in the same commit and keep every cost at 2 or more). The shipped plots sit 12.5 m from the roads: enemies dying in the 18 m corridor credit it (RESEARCH E4, about 100 health near night 3 on the west road), but a 9 m reach only reaches enemies that come for the Shrine itself (a grunt notices a building within 6 m of its edge, a skirmisher within 9 m), so the fit should check how often a shipped Shrine actually fires, and may move the radius, reach or threshold. The bots' `_is_tower_plot` and `Tally._role_of` classify anything that attacks as a tower: exclude the Shrine by curve when a bot starts buying it.
- Plan 05-12: review `shrine_awake_night` (placeholder obelisk, orb, violet bolt and framing) with the owner; the end-of-phase counts are 23 spots, 22 buildable plots and 42 shots.
- ECON-06 is recorded in `requirements-completed`; whether REQUIREMENTS.md is ticked follows the shared-ID gate (same precedent as ECON-04 and ECON-05).
- No blockers.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-22*

## Self-Check: PASSED

All created files exist (shrine.tres, shrine_t1.tscn, fixture_map_shrine.tres, the eight test scripts, screenshots/shrine_awake_night.png), commits `b7c78dc`, `25d101d` and `2b04a5e` exist, and every acceptance criterion holds: `var wake_radius: float = 0.0`, `var wake_threshold_hp: int = 0` and `var synergy_percent: int = 0`; `var damage_stat: StringName = &"tower.damage"`; `is_awake(` and `damage_stat` in tower_system.gd; `enemy_died.connect(` and `shrine_woke.emit(` in income_state.gd; `"shrine_woke"` in sim_signals.gd and sim_recorder.gd; `id = &"shrine"`, `wake_threshold_hp = 100` and `synergy_percent = 20` in shrine.tres; `id = &"shrine_west"` and `id = &"shrine_east"` in prototype_map.tres; full_idle digest `4385f569...`; `&"shrine_synergy"`, `add_source(` and `remove_source(` in income_state.gd; `const MAX_WAKE_RADIUS: float = 40.0` and `StatIds.is_known(` in economy_validation.gd; `func is_shrine_glowing(` in building_views.gd; `shrine_awake_night` in ALL_SHOTS of tools/screenshot.sh; `const EXPECTED_SHOT_COUNT: int = 42`; the shrine_awake_night review line and the edge coverage ledger are above.
