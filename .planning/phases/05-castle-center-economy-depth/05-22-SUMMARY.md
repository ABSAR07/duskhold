---
phase: 05-castle-center-economy-depth
plan: 22
subsystem: economy-harbor
tags: [godot, gdscript, gut, fishing-harbor, pond, exposure, g-05-7, econ-05]

requires:
  - phase: 05-castle-center-economy-depth
    provides: plan 05-21 (cards recut, full_idle at cec3eb71), plan 05-14 (Harbor health at the x100 scale), plan 05-17 (test_economy_data_contract at x100)
provides:
  - harbor_1 and its visual-only pond at the exposed west-road spot (proposal A, pond pushed 1.5 m out)
  - the Harbor's health one step lower, 1400 / 2000
  - harbor_1's own 9 to 10.5 m road band and the dock-on-land footprint pin
  - tests/unit/test_harbor_exposure.gd, the exposure pinned from the shipped files (4 tests)
  - the exposure measurement of both bots and full_idle after each task, for plan 05-23's report
affects: [05-23, 05-24]

actuals:
  tokens: 5200
  tasks: 2
  commits: 2

plan_head_before: 669fbbfd6cf9a5aa0c3001b2366540473bc48e38
plan_head_after: 706b3ca1b1892aeddd7ed8da432c419f9b9d1055

tech-stack:
  added: []
  patterns:
    - "Exposure pin: a notice distance is aggro_range plus the target's body_radius, a reach is the tier range read through the card's StatStack float_value, every number from a shipped .tres"

key-files:
  created:
    - tests/unit/test_harbor_exposure.gd
    - tests/unit/test_harbor_exposure.gd.uid
  modified:
    - data/maps/prototype_map.tres
    - data/buildings/fishing_harbor.tres
    - tests/unit/test_prototype_map_economy.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_pond_layout.gd
    - tests/e2e/test_harbor_scene.gd

key-decisions:
  - "Built: proposal A. harbor_1 at (-39.93, 0, 25.48), pond centre (-37.71, 31.59) radius 4.5; no rule failed on the moved data, so fallback C was not used"
  - "The pond, not the Harbor, was pushed 1.5 m out along the road's normal from the debug session's centre, so the dock stands 6.5 m from the water's middle (2.0 m from its edge, 0.5 m clear of the 1.5 m body); the pond is visual only, so the debug session's bot numbers at A still hold (and the probe below reproduced them exactly)"
  - "harbor_1 alone is exempt from the 12 m road rule, by name, with a 9 to 10.5 m band and the owner's reason in the test header; every other Phase 5 plot keeps 12 m"
  - "Health 1400 / 2000 (the 14 / 20 the debug session measured, at the x100 scale); cost, boat caps, boat gold, gate and body_radius untouched"

requirements-completed: [ECON-05]

coverage:
  - id: D1
    description: "harbor_1 and the pond stand at proposal A with the dock on dry land, and every plot, pond and nav rule passes"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_pond_layout.gd#test_the_harbor_stands_within_three_metres_of_the_pond_edge"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_economy.gd#test_every_phase_five_plot_keeps_its_road_clearance"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_harbor_scene.gd#test_the_king_builds_the_harbor_and_no_boat_floats_until_the_first_dawn"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Harbor is noticed by skirmishers and not grunts, and no tower or keep arrow reaches it even through the two cards"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_harbor_exposure.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "Harbor health 1400 / 2000 with every other economy number unchanged"
    requirement: ECON-05
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_data_contract.gd#test_the_fishing_harbor_has_two_boats_tiers_gated_at_castle_two"
        status: pass
    human_judgment: false
  - id: D4
    description: "In bot play the Harbor is struck in 7 of the 9 balanced seeds in which it is built and destroyed 18 times"
    requirement: ECON-05
    verification:
      - kind: other
        ref: "scratch copy of the debug session's probe4.gd, --bot=balanced and --bot=army_balanced, seeds 1 to 10 (tables below)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Whether the Harbor now feels awkward but fair to defend (the bots never ride out to defend it)"
    verification: []
    human_judgment: true
    rationale: "Owner's UAT test 7 re-judgement: how awkward it is to defend is a play feel no test asserts"

duration: 23min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 22: The Exposed Harbor Summary

**Built: proposal A.** The Fishing Harbor and its visual-only pond moved beside the west road, harbor_1 at (-39.93, 0, 25.48) with the water centred at (-37.71, 31.59) radius 4.5, and its health dropped a step to 1400 / 2000; no pond, nav or plot rule failed on the moved data, so fallback C was not needed.

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-25T20:06:59Z
- **Completed:** 2026-10-25T20:30Z
- **Tasks:** 2
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- Moved harbor_1 and the pond (three lines in prototype_map.tres) and re-pinned every geometry and pond test; the king builds the Harbor on the new shore in the e2e test.
- Lowered the Harbor's health to 1400 / 2000 (two lines in fishing_harbor.tres) and re-pinned HARBOR_HEALTHS.
- Added test_harbor_exposure (4 tests) so a later edit of an aggro range, a tower range, a card or the plot cannot silently cover or hide the Harbor.
- Measured the exposure with the bots: the debug session's balanced numbers reproduced exactly (table below).
- The four goldens held byte-identical after both tasks; full_idle moved twice by design.

## Rule check of proposal A (Task 1 step 2, on the moved data before any test edit)

`bash tools/test.sh -gselect=test_pond_layout`: 13 tests, 12 passing, 1 failing, and the one failure was the literal pin the task updates: `the west road is 16.8 m away` expected >= 18.0 (the old radius 8 plus 10). `bash tools/test.sh -gselect=test_nav_layout_pin`: 6 of 6 passing (the pond never enters the nav grid). MapConfig.validate() and EconomyValidation reported nothing. Measured geometry (python, same numbers as the plan): Harbor 10.30 m from the west road (47.37 m from the north and east roads); pond centre 16.80 m from the west road (14.5 needed) and 49.19 m from the other two; Mine 7.87 m and shrine_west 8.44 m from the pond centre (radius 4.5); Harbor 6.50 m from the centre (2.00 m from the water's edge); tower_1 16.04 m, the keep 47.37 m, shrine_west 7.57 m and the Mine 10.91 m from the Harbor.

## Pins changed (old to new)

| File | Pin | Old | New |
|---|---|---|---|
| test_prototype_map_economy | HARBOR_AT | (0, 0, 20.5) | (-39.93, 0, 25.48) |
| test_prototype_map_economy | new HARBOR_ROAD_BAND_MIN_M / MAX_M | none (12 m rule) | 9.0 / 10.5 for harbor_1 only |
| test_prototype_map_economy | road test | test_every_phase_five_plot_is_twelve_metres_from_every_road | test_every_phase_five_plot_keeps_its_road_clearance; plus the UAT G-05-7 header paragraph; 20 tests stay 20 |
| test_economy_data_contract | Harbor plot / POND_CENTER / POND_RADIUS | (0, 0, 20.5) / (0, 30) / 8.0 | (-39.93, 0, 25.48) / (-37.71, 31.59) / 4.5 (new HARBOR_PLOT constant); 20 stay 20 |
| test_economy_data_contract | HARBOR_HEALTHS | [1800, 2400] | [1400, 2000] |
| test_pond_layout | road distance | literal MIN_ROAD_CENTRE_M 18.0 | `map.pond_radius + EconomyValidation.POND_ROAD_CLEARANCE` (14.5); test renamed ..._keeps_the_radius_plus_ten_metres_from_the_pond_centre; fourth shore assertion gap >= body_radius read from fishing_harbor.tres; header and the stale "radius of 8" comment updated; 13 stay 13 |
| test_harbor_scene | POND_CENTER / POND_RADIUS and messages | (0, 30) / 8 | (-37.71, 31.59) / 4.5 |
| fishing_harbor.tres | max_health tier I / II | 1800 / 2400 | 1400 / 2000 |

`git diff -U0 ce3fcea` on the two .tres files shows only the castle's two x100 lines (05-13), the Harbor's two health lines (05-14 then this plan) and the three plot and pond lines.

## Task Commits

1. **Task 1 (tracer): move the Harbor and its pond, re-pin geometry and pond tests** - `e656ed8` (feat)
2. **Task 2 (tdd): lower the health, pin the exposure, measure it** - `706b3ca` (feat)

**Plan metadata:** the docs commit that carries this file (docs 05-22).

## Test results (each from this run's own log under build/)

- Task 1 verify (build/exec0522_verify1.log): test_prototype_map 3 scripts / 56 tests passing (economy, data, walls all in the JUnit XML); test_pond_layout 13 / 13; test_economy 6 scripts / 79 tests; test_harbor_scene 4 / 4; test_nav_layout_pin 6 / 6; test_shrine_plots 6 / 6; test_fishing_harbor 12 / 12; lint clean.
- Task 2 verify (build/exec0522_verify2.log): test_harbor 2 scripts / 8 tests (exposure and scene); test_economy 6 scripts / 79 tests (contract and destroyed in the XML); test_fishing_harbor 12 / 12; test_card_resolution 8 / 8; lint clean (448 files). The full suite is plan 05-24's.

## Replay digests (D-08)

The four goldens replayed byte-identical (REPLAY_OK, `--twice`) after Task 1 and again after Task 2, and `git diff --quiet ce3fcea` over tests/golden and the replay fixtures was clean:

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97
```

full_idle (owner-sanctioned moves, never pinned; each pair of runs agreed):

| Point | Outcome | Ticks | Digest |
|---|---|---|---|
| Before this plan (plan 05-14 / 05-21) | won | 7000 | cec3eb7182baddc2d2215916f624759510c911bfec64ed249c4ef375189b40e9 |
| After the move (Task 1) | won | 6993 | 6fd6121e0822bda3605d91ef2539e28c0649072c97df96d694be6d9346f3b019 |
| After the health step (Task 2) | won | 6993 | c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441 |

(The round's starting point, before the rescale, was afc11cd0 at 7000 ticks.)

## TDD record (Task 2)

- **RED, health:** `bash tools/test.sh -gselect=test_economy_data_contract` with HARBOR_HEALTHS [1400, 2000] against the old 1800 / 2400: 20 tests, 19 passing, 1 failing, `[1800] expected to equal [1400]: tier 1 health` and `[2400] expected to equal [2000]: tier 2 health` (the target test, test_the_fishing_harbor_has_two_boats_tiers_gated_at_castle_two, on the planned assertion).
- **RED, exposure (mutation evidence):** test_harbor_exposure cannot fail against the moved map (Task 1 had already moved the plot, and the file pins the shipped numbers), so it first ran green, 4 of 4. To prove it is not vacuous I set harbor_1 back to (0, 0, 20.5) in prototype_map.tres (backed up and restored byte-identical, `git diff` empty afterwards) and re-ran: 1 passing, 3 failing: `19.27 m from a road is inside a skirmisher's 10.50 m`, `castle_plot is 16.30 m away, its reach is 25.30 m` (so no tower covers the Harbor), `the keep is 20.50 m away, its longest reach 27.50 m` (so the keep's arrow does not cover it).
- **GREEN:** the two max_health lines in fishing_harbor.tres. test_economy_data_contract 20 / 20; test_harbor 8 / 8.
- Task 2 is one commit (the plan and the project instructions ask for one commit per task), so RED and GREEN are recorded here rather than as separate test and feat commits.

## Exposure measurement (probe4.gd copy with one no-override entry; the committed data; seeds 1 to 10; build/exec0522_probe_*.log)

Harbor "built" counts seeds in which harbor_1 stood at least once; "struck" is a seed with at least one hit on it.

| Bot | Wins | Lost seeds | Built in seeds | Struck in seeds | Destroyed in seeds | Destructions | Boat gold mean | Gold earned mean |
|---|---|---|---|---|---|---|---|---|
| balanced | 8 of 10 | 3, 9 | 1 to 8 and 10 (9 seeds; seed 9 lost on night 2 before building it) | 1, 3, 4, 5, 6, 7, 8 (7 of the 9 built; untouched in 2 and 10) | 3, 4, 5, 6, 7, 8 (6 seeds) | 18 | 3.5 | 26.4 |
| army_balanced | 8 of 10 | 1, 9 | 2, 3, 4 (3 seeds; the army bot rarely buys it) | 2, 3, 4 (all 3 built) | 2, 3, 4 (3 seeds) | 5 | 0.0 | 14.8 |

The balanced row reproduces the debug session at this position exactly (8 of 10, lost 3 and 9, 26.4 gold, 3.5 boat gold, 18 destructions over 10 runs). The stop rule passes: the Harbor is struck in 7 of the 9 balanced seeds in which it was built (at least half) and destroyed 18 times (at least once). The bots never ride out to defend it, so this is the worst case; how awkward it is to defend is the owner's call at the next UAT.

## Decisions Made

- Proposal A with the pond pushed out (see key-decisions); recorded here because the plan's Flagged Assumptions anticipated it and nothing contradicted it.
- test_harbor_exposure counts every plot whose building shoots through tower.damage and tower.range (the three towers and, conservatively, the castle plot, whose tier range 22 m reads as 25.3 m through Engineers) and checks each plot against its own building's longest reach, not a single tower constant; the Shrine names its own stats and is excluded, as the plan says only an awake Shrine covers part of the Harbor.

## Deviations from Plan

None - plan executed exactly as written.

Notes that are not deviations:
- test_pond_layout's renamed road test has a 101-character `func` line; `gdformat` (run by `bash tools/lint.sh --fix`) wraps the empty parameter list onto a second line, lint passes, and the plan's exact test name is kept.
- The exposure test's RED evidence is a mutation of the map rather than a failing first run (see the TDD record), because the data it pins was moved by Task 1.
- The planner's scratch diff for this plan was not consulted; the plan was unambiguous.

**Total deviations:** 0.

## Issues Encountered

None.

## Known Stubs

None. No hardcoded empty values, placeholders or unwired data in the files touched.

## Threat Flags

None. No new endpoints, file access or trust-boundary surface; the pond stays visual only (T-05-40 mitigations hold: validate() clean, test_pond_layout and test_nav_layout_pin green).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05-23 can now run the sweep, re-pin the balance bar and write the report using the full_idle table above, and re-aim and re-capture the harbor_pond and economy_day shots (tools/screenshot/shot_economy_scenarios.gd still aims at the old position). The orchestrator's gate after this plan expects 281 test scripts.

## Self-Check: PASSED

- Files: tests/unit/test_harbor_exposure.gd and .uid exist; prototype_map.tres holds the new plot and pond lines; fishing_harbor.tres holds 1400 / 2000.
- Commits: e656ed8 and 706b3ca are on the branch (`git log --grep="05-22"`).
- Acceptance criteria re-checked: map lines, HARBOR_ROAD_BAND_*, renamed tests, `POND_ROAD_CLEARANCE` and `body_radius` in test_pond_layout, 20 / 20 / 13 tests per script, `HARBOR_HEALTHS = [1400, 2000]`, `aggro_range` read in the exposure test through the enemy .tres files, the probe tables above.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
