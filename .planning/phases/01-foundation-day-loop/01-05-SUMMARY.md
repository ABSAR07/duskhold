---
phase: 01-foundation-day-loop
plan: 05
subsystem: prototype-map-buildings
status: complete
tags: [godot, gdscript, gut, prototype-map, tower, upgrades, map-validation, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "Plan 01-02 skeleton: MapConfig/BuildSpotDef/BuildingDef/BuildingTierDef, BuildingSystem, CommandProcessor, RunContext, BuildingViews, E2eSupport"
provides:
  - "data/maps/prototype_map.tres: permanent 8-spot sandbox (house_1..5, tower_1..3), castle at origin, starting gold 4, is_sandbox true, 110 m span (22 s at walk speed)"
  - "data/buildings/tower.tres: basic tower, tier I (cost 4, range 8, damage 2) and tier II (cost 6, range 10, damage 4), no income; Phase 2 consumes the stats"
  - "MapConfig.validate() -> PackedStringArray, called by RunContext._init with push_error per error (T-01-10)"
  - "BuildingViews._make_visual(building_id, tier) -> Node3D visual seam, CastleCenter landmark, plot markers colour-coded by building type, view meta tier and building_id"
  - "Data-contract, BLDG-01 (tie, boundary, empty, unknown), BLDG-02 (affordability edge) and BLDG-04 (upgrade, max_tier) tests, plus fixture_map_empty and fixture_map_tie"
affects: [01-06, 01-07, 01-08, 01-09, 01-10, phase-02-combat]

actuals:
  tokens: 10100
  tasks: 2
  commits: 4
plan_head_before: c2007d05cf03faf3f9c16dc8d04c61d01047574d
plan_head_after: cf5e2fe78397847b116795aa677966eab6fdd292

tech-stack:
  added: []
  patterns:
    - "Data-contract tests derive every expected number from loaded .tres data; the only literals are the structural counts D-03/D-10 fix"
    - "Edge-case affordability tests build a RunContext from MapConfig.duplicate(true) with starting_gold overridden; Economy stays setter-free"
    - "One visual seam per building type: BuildingViews._make_visual, the place plan 01-07 swaps CC0 models in"

key-files:
  created:
    - data/buildings/tower.tres
    - tests/fixtures/fixture_map_empty.tres
    - tests/fixtures/fixture_map_tie.tres
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_build_spot.gd
    - tests/unit/test_build_spot_affordability.gd
    - tests/integration/test_upgrade_flow.gd
    - tests/e2e/test_upgrade_at_spot.gd
  modified:
    - data/maps/prototype_map.tres
    - simulation/defs/map_config.gd
    - simulation/run/run_context.gd
    - presentation/buildings/building_views.gd

key-decisions:
  - "Ride-time contract measures the farthest pair among all spots, castle_position and king_spawn; tower_1 to tower_2 is 110 m, 22 s at 5 m/s"
  - "MapConfig.validate() also checks duplicate building ids and negative starting_gold beyond the plan's minimum list; RunContext logs but never blocks, so a bad map is loud yet still constructible"
  - "Tower visual is a slate cylinder (radius 0.9, height 3+2t) and House a tan box, chosen inside _make_visual only; building_built stays the sole trigger for view changes"

patterns-established:
  - "BuildingViews owns all spawned world nodes under one parent (CastleCenter, Spot_<id>, Building_<spot_id>) so tests address them by path"
  - "Signal assertions that follow an earlier emission in the same test call clear_signal_watcher() before watch_signals"

requirements-completed: [BLDG-01, BLDG-02, BLDG-04]

coverage:
  - id: D1
    description: "Prototype map is the 8-spot sandbox (5 House plots, 3 tower plots, castle at the middle, is_sandbox) and validates clean"
    requirement: "BLDG-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_map_has_eight_spots_five_house_and_three_tower_plots"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_prototype_map_is_the_permanent_sandbox_and_validates_clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "Edge-to-edge ride takes 20 to 30 s at walk speed; starting gold buys two Houses or one tower but not both; tier data (House 3, tower 2) lives in .tres"
    requirement: "BLDG-02"
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_ride_across_the_map_takes_twenty_to_thirty_seconds"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_starting_gold_buys_two_houses_or_one_tower_but_not_both"
        status: pass
      - kind: unit
        ref: "tests/unit/test_build_spot_affordability.gd#test_starting_gold_pays_for_two_houses_or_one_tower"
        status: pass
    human_judgment: false
  - id: D3
    description: "Spot rules: nearer spot wins, exact tie goes to the earlier spot, distance == radius is in range, empty map yields no focus, unknown or empty id is unknown_spot"
    requirement: "BLDG-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_build_spot.gd#test_an_exact_distance_tie_goes_to_the_earlier_spot_every_time"
        status: pass
      - kind: unit
        ref: "tests/unit/test_build_spot.gd#test_a_king_exactly_at_the_radius_is_in_range_and_just_beyond_is_not"
        status: pass
      - kind: unit
        ref: "tests/unit/test_build_spot.gd#test_a_map_with_no_spots_yields_no_focus"
        status: pass
    human_judgment: false
  - id: D4
    description: "Holding at a built House or tower upgrades it tier by tier with each tier's cost; max tier is rejected with max_tier and gold unchanged"
    requirement: "BLDG-04"
    verification:
      - kind: integration
        ref: "tests/integration/test_upgrade_flow.gd#test_house_upgrades_through_all_three_tiers_then_hits_max_tier"
        status: pass
      - kind: integration
        ref: "tests/integration/test_upgrade_flow.gd#test_tower_upgrades_through_both_tiers_then_hits_max_tier"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_upgrade_at_spot.gd#test_hold_then_hold_again_upgrades_the_house_to_tier_two"
        status: pass
    human_judgment: false
  - id: D5
    description: "MapConfig.validate() rejects duplicate ids, dangling building ids, empty tier lists, non-positive costs, negative income and negative gold"
    requirement: "BLDG-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_validate_reports_a_duplicate_spot_id"
        status: pass
    human_judgment: false
  - id: D6
    description: "Plots read as tan House and slate-blue tower plots, buildings grow with tier, and a grey castle keep stands at the centre (structure asserted; look and ride feel are a human judgment)"
    requirement: "BLDG-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_upgrade_at_spot.gd#test_scene_has_a_castle_landmark_and_a_marker_for_every_spot"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_upgrade_at_spot.gd#test_markers_are_colour_coded_by_building_type"
        status: pass
    human_judgment: true
    rationale: "Run the game and ride the whole map: 5 tan House plots near the castle, 3 blue tower plots far out, keep at the centre, House grows to II on the second hold with gold falling by 2 then 3, far towers 10-15 s from the castle. Visual readability and ride feel are not asserted by any test."

duration: 25 min
completed: 2026-09-29
---

# Phase 1 Plan 05: Prototype Map, Tower and Upgrades Summary

**Permanent 8-spot prototype sandbox (5 House plots, 3 tower plots, castle landmark) with a 2-tier data-driven tower, MapConfig.validate() guarding the .tres data, and the House I-III / tower I-II upgrade path proven end to end with max-tier rejection.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-29
- **Tasks:** 2 (both TDD)
- **Files:** 12 created or modified in source and data, 8 of them new
- **Suite:** 80/80 GUT tests passing (was 47), lint clean

## Accomplishments

- Prototype map expanded from one House plot to the D-03 layout. Houses sit close to the castle, towers 55 m out. The farthest pair is tower_1 to tower_2 at 110 m, 22 s at walk speed. Starting gold 4 buys two Houses (2 each) or one tower (4), never both (D-09).
- `tower.tres` added with two tiers of range/damage data. It does nothing in Phase 1; Phase 2 reads the numbers.
- `MapConfig.validate()` returns readable errors for duplicate spot or building ids, unknown building ids, zero-tier buildings, non-positive costs, negative income and negative starting gold. `RunContext` logs each with `push_error`.
- `BuildingViews` now draws a CastleCenter keep and turret, tan and slate-blue plot markers by building type, and per-tier visuals through the single `_make_visual` seam. Views carry `tier` and `building_id` meta.
- 33 new tests lock the data contract, BLDG-01 edges (tie, boundary, empty, unknown), BLDG-02 affordability edges, and BLDG-04 upgrades in both headless and real-scene form.

## Task Commits

1. **Task 1 RED:** `c7034c1` test(01-05): failing tests for map data, spot rules and validation (includes `MapConfig.validate()` stub so failures are assertion failures)
2. **Task 1 GREEN:** `a5e02fc` feat(01-05): 8-spot prototype map, 2-tier tower and `MapConfig.validate`
3. **Task 2 RED:** `3baee08` test(01-05): upgrade flow, castle landmark and per-tier visual tests
4. **Task 2 GREEN:** `cf5e2fe` feat(01-05): per-tier building visuals, colour-coded plots and castle landmark

## TDD Gate Compliance

- **Task 1:** RED confirmed with 12 failing tests, every failure an assertion on the planned behaviour (spot counts, ride time, missing tower, validate() returning no errors). No parse or fixture errors. GREEN passes 73/73. No refactor commit needed.
- **Task 2:** RED confirmed with 5 failing tests on CastleCenter missing, identical marker colours, and tower view not a cylinder or lacking `building_id` meta. The three `test_upgrade_flow` tests passed at RED by design: `apply_next_tier` already increments generically (the plan expected this), so they are regression locks rather than driving tests. GREEN passes 80/80. One test-only tweak (a trailing frame wait to avoid a GUT orphan warning) rode in the GREEN commit.
- `gsd_run check tdd-red-evidence` was not run because the resolver shim is not available in this executor shell; RED evidence is the GUT output described above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Integration test signal watcher leaked earlier emissions**
- **Found during:** Task 2 RED run
- **Issue:** `assert_signal_not_emitted(ctx.events, "building_built")` failed because the GUT watcher kept the emissions recorded while climbing the tiers earlier in the same test.
- **Fix:** Call `clear_signal_watcher()` before `watch_signals` in `_assert_capped`. Test-only defect, no production change.
- **Files modified:** tests/integration/test_upgrade_flow.gd
- **Commit:** `3baee08` (fixed before the RED commit)

**2. [Rule 3 - Blocking] RED needed a `validate()` stub for valid RED**
- **Found during:** Task 1 RED
- **Issue:** Calling a method that does not exist on a typed `MapConfig` is a parse error, which would have been INVALID_RED for the whole file.
- **Fix:** Added an empty-returning `validate()` stub in the RED commit; GREEN replaced it with the real implementation.
- **Files modified:** simulation/defs/map_config.gd
- **Commit:** `c7034c1`

**3. [Rule 2 - Missing critical] Two extra validation rules**
- **Found during:** Task 1 GREEN
- **Issue:** The threat register calls for rejecting malformed data; a duplicate building id would silently shadow a definition in `BuildingSystem._defs`.
- **Fix:** `validate()` also reports duplicate building ids (the plan listed it in the action but not the behaviour list), with tests for it and for negative starting gold.
- **Commit:** `a5e02fc`

**Total deviations:** 3 auto-fixed (1 bug in a test, 1 blocking, 1 missing-critical). **Impact:** none on scope; all inside plan files.

## Issues Encountered

None. Human verification of the visual and ride-feel check (`<human-check>` in Task 2) is deferred to the end-of-phase UAT batch per `human_verify_mode`.

## Known Stubs

None. The castle is a deliberate landmark with no gameplay (D-03). The tower has stats but no behaviour until Phase 2, by plan design.

## Threat Flags

None. T-01-10 is mitigated by `MapConfig.validate()`, `RunContext` error reporting and `test_prototype_map_data.gd` asserting the prototype map validates clean.

## Next Phase Readiness

Ready for 01-06. The map, both building defs and the visual seam are in place for the HUD, build-prompt and dawn-income plans, and for 01-07's CC0 model swap at `_make_visual`.

## Self-Check: PASSED

- All created files exist on disk; the four commits `c7034c1`, `a5e02fc`, `3baee08`, `cf5e2fe` are in `git log`.
- Acceptance criteria re-run: `tower_3`, `house_5`, `starting_gold = 4`, `is_sandbox = true` present; `func validate() -> PackedStringArray` present; `grep -c "func set_gold"` prints 0; `_make_visual` and `CastleCenter` present; `max_tier` compared in the upgrade test.
- Plan verification re-run: `bash tools/test.sh` exits 0 (80/80) with all five testsuites in the JUnit XML; `bash tools/lint.sh` exits 0.
