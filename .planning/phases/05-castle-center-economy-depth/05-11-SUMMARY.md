---
phase: 05-castle-center-economy-depth
plan: 11
subsystem: testing
tags: [godot, gdscript, balance, playtest-bot, castle-gate, d-03, d-08, report, screenshots, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "the castle plot, tiers and cards (05-02 to 05-04), the build requirements and the bots' pending list (05-05), the four economic buildings (05-06 to 05-09), PlaytestBot.card_picks and the economy golden (05-10)"
provides:
  - "requires_castle_tier = 2 on the last tier of House, Tower, Barracks, Archery Range and Wall (D-03, BLDG-09 on the shipped map); test_gate_data_contract pins the whole gate table and D-01's trade-off"
  - "Castle-aware bots: balanced and army_balanced buy the castle with one deterministic card per tier and the four new economic buildings; the Phase 4 orders live on as balanced_no_castle and army_balanced_no_castle (ten names)"
  - "Tally roles castle and shrine; report columns castle_tier_reached, picks, castle_days, castle_gold_spent, shrine_gold_spent and a Castle and Shrine table"
  - "Measurement: balanced 8 of 10, army_balanced 8 of 10 (ratio 0.888), first castle upgrade day 6, no number fitted; test_balance_acceptance re-pinned with a Plan 05-11 header"
  - "05-BALANCE-REPORT.md, the D-08 outcome report (full_idle 6911 ticks 4385f569 became 7000 ticks afc11cd0; four goldens unmoved)"
  - "Two shots, castle_gate_locked and economy_day (44 in all)"
affects: [05-12 (the local pass, the push, CI and the owner packet), gap plan for three tests that repeat a gated tier]

actuals:
  tokens: 27000
  tasks: 3
  commits: 4
plan_head_before: 4a68ce9d5a6543943f91d5b319e5ab2ed2dea550
plan_head_after: 9fcb5cc5898db7cee492e5093e6c72788c18c92b

tech-stack:
  added: []
  patterns:
    - "A gate that a test setup must satisfy gets one shared helper (E2eSupport.raise_castle: grant the price, buy the tier with the first card) and the setup calls it only when validate_build reports castle_tier, so tests that never reach a top tier keep their castle numbers"
    - "A balance search that meets the bar on the first lever (the bot's order) ships no data change; scratch probes compare candidate orders in parallel and only the shipped candidate is measured with the official sweep"

key-files:
  created:
    - tests/unit/test_gate_data_contract.gd
    - tests/unit/test_playtest_strategies_castle.gd
    - tests/integration/test_balance_report_castle.gd
    - tests/unit/test_shot_list_gate.gd
    - .planning/phases/05-castle-center-economy-depth/05-BALANCE-REPORT.md
  modified:
    - data/buildings/house.tres
    - data/buildings/tower.tres
    - data/buildings/barracks.tres
    - data/buildings/archery_range.tres
    - data/buildings/wall.tres
    - tools/replay/playtest_bot.gd
    - tools/replay/playtest_strategies.gd
    - tools/replay/replay_driver.gd
    - tools/replay/balance_report.gd
    - tools/playtest.sh
    - tools/screenshot.sh
    - tools/screenshot/shot_economy_scenarios.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot/shot_crowd_scenarios.gd
    - tests/integration/test_balance_acceptance.gd
    - tests/unit/test_playtest_strategies.gd
    - tests/unit/test_bot_defers_locked.gd
    - tests/e2e/e2e_support.gd
    - tests/unit/test_shot_list.gd

key-decisions:
  - "Lever (a), the bots' orders, met the bar alone, so no castle, card, economy or night number was fitted; the shipped balanced order buys the Harbor right after the first tower and the castle right after the second"
  - "The Phase 4 orders became balanced_no_castle and army_balanced_no_castle and the castle-aware orders took the names balanced and army_balanced, so full_idle exercises the castle and the new buildings"
  - "The no-castle and no-walls twins are re-pinned to their gate-on results (balanced_no_castle 3 of 10, balanced_no_walls 4 of 10) rather than kept at 8: the gate is what costs a bot that never buys the castle its tower upgrades"
  - "The Shrine is left as shipped: in bot play it wakes in a minority of seeds and fires about never, reach 14 m and threshold 50 changed neither the wins nor the shots; handed to the owner as a feel item"

patterns-established:
  - "Declared-file discipline for a gate: tests outside the declared list that buy a gated tier are recorded for a gap plan, never edited"

requirements-completed: [BLDG-09, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06]

gaps:
  - "tests/unit/test_choice_validation.gd (2 asserts), tests/integration/test_build_flow.gd (8) and tests/e2e/test_building_models.gd (16) fail because House III and Tower II now need castle II; they are outside the declared edit list, so they are not edited (plan step 1b)"

coverage:
  - id: D1
    description: "The castle gate ships on the five Phase 4 buildings' top tiers and the gate table (Mill III and Harbor II already carried it) is pinned, with D-01's trade-off (castle II costs more than the starting gold plus the first dawn's base income)"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_gate_data_contract.gd (7 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The bots play the new day: castle-aware balanced and army_balanced with picks and the new buildings, the Phase 4 no-castle twins, Tally roles castle and shrine, and report columns for castle tier, picks, day of each upgrade and the castle and shrine spend"
    requirement: "BLDG-08"
    verification:
      - kind: unit
        ref: "tests/unit/test_playtest_strategies_castle.gd (8 tests), tests/unit/test_playtest_strategies.gd (19), tests/unit/test_bot_defers_locked.gd (8)"
        status: pass
      - kind: integration
        ref: "tests/integration/test_balance_report_castle.gd (9 tests), tests/integration/test_balance_report.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Phase 2 bar on the shipped 23-spot map with the gate: balanced 8 of 10 (lost seeds 3 and 9), army_balanced 8 of 10 (lost 1 and 9, ratio 0.888 above 0.8), first castle upgrade on day 6 at the earliest"
    requirement: "ECON-03"
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd (17 tests); bash tools/playtest.sh --seeds=10 (PLAYTEST_OK runs=100)"
        status: pass
    human_judgment: false
  - id: D4
    description: "05-BALANCE-REPORT.md, the D-08 outcome report: goldens decision, full_idle before and after, balanced bot, what the castle and the gate change, numbers fitted (none), the search log and the owner feel items"
    requirement: "ECON-04"
    verification:
      - kind: other
        ref: "report holds the before digest and the after digest of the final full_idle run (afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14); smoke, army, walls and economy replay to their goldens"
        status: pass
    human_judgment: false
  - id: D5
    description: "castle_gate_locked and economy_day screenshots read correctly and the shot list is 44"
    requirement: "ECON-05"
    verification:
      - kind: unit
        ref: "tests/unit/test_shot_list.gd (20), tests/unit/test_shot_list_gate.gd (3)"
        status: pass
      - kind: other
        ref: "bash tools/screenshot.sh castle_gate_locked economy_day; both PNGs read with the Read tool"
        status: pass
    human_judgment: true
    rationale: "Whether the label and the small buildings read well at the shipped camera is a look-and-feel call the owner confirms at the Phase 5 gate"
  - id: D6
    description: "Whole-suite health after the gate: every declared test fixed through E2eSupport.raise_castle with no gate removed and no assertion changed; three undeclared tests that repeat a gated tier remain red for a gap plan"
    requirement: "ECON-06"
    verification:
      - kind: other
        ref: "bash tools/test.sh: 279 scripts, 2653 tests, 2645 pass; failing: test_choice_validation, test_build_flow, test_building_models (undeclared, gate-caused) and one test_select_one_type box-select flake that passes alone"
        status: fail
    human_judgment: false

duration: about 3 h of work across two sessions (a rate limit cut the first session after the Task 2 gate lines)
started: 2026-10-22T01:39:13Z
completed: 2026-10-22T07:58:47Z
status: complete
---

# Phase 5 Plan 11: Castle gate, castle-aware bots and the D-08 outcome report Summary

**The castle gate ships on the five Phase 4 buildings' top tiers, the bots now buy the castle with deterministic card picks and the four new economic buildings, and the order lever alone holds the Phase 2 bar (balanced 8 of 10, army_balanced 8 of 10 at ratio 0.888, first castle upgrade on day 6) so no number was fitted; 05-BALANCE-REPORT.md records full_idle moving from 6911 ticks (4385f569) to 7000 ticks (afc11cd0) with every golden unmoved, and two new shots close the list at 44.**

## Performance

- **Duration:** about 3 h of work (a rate limit paused the run between the first Task 2 gate lines and the rest)
- **Started:** 2026-10-22T01:39:13Z
- **Completed:** 2026-10-22T07:58:47Z
- **Tasks:** 3 (Task 1 tracer, Task 2, Task 3)
- **Files modified:** 37 (5 created source files, the rest modified, plus generated .uid files)

## Accomplishments

- **Tracer (Task 1).** `PlaytestBot._is_tower_plot` excludes the castle plot and AWAKENED buildings; two castle-aware strategies with castle_plot entries, per-tier card picks and the new buildings; `ReplayDriver.Tally` classes the castle plot as `castle` and Shrines as `shrine` before the attack test and records picks and the day of each castle upgrade; `BalanceReport` rows, summaries and report.md gain the castle and Shrine columns.
- **Gate (Task 2).** `requires_castle_tier = 2` on House III, Tower II, Barracks III, Archery Range III and Wall III (that line only); `test_gate_data_contract` pins the table, the castle's exemption, the one-tier buildings and D-01 (castle II costs 6, above 4 starting gold plus 1 base income).
- **Measurement.** The Phase 4 orders alone fall to 3 of 10 under the gate; the castle-aware order (Harbor after the first tower, castle after the second, Tower II after it) holds 8 of 10, the same two lost seeds as before. The army bot never affords the castle (it earns about 15 gold) and so keeps its 8 of 10.
- **Report.** `05-BALANCE-REPORT.md` has the seven named sections, the before and after full_idle digests, the twins, the search log and the owner feel items (the Shrine fires about never; the Harbor dominates income; tiers III and IV are out of reach of bot play).
- **Shots (Task 3).** `castle_gate_locked` (a Tower I plot reading "Needs Castle II") and `economy_day` (the Mine, the Mill with two Fields, the Harbor with two boats and a Shrine across the south side); 44 shots.

## Task Commits

1. **Task 1: Tracer, castle-aware bots, Tally roles and report columns** - `6e31e51` (feat)
2. **Task 2: Gate, rename, measurement, re-pin and D-08 report** - `5d4a227` (feat)
3. **Task 3: castle_gate_locked and economy_day shots** - `96cdd06` (feat)
4. **Follow-up: walls_day needs castle II first** - `9fcb5cc` (fix)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Round 1 (Task 1, no data change)

`bash tools/playtest.sh --strategies=balanced_castle,army_castle --seeds=10` (`PLAYTEST_OK runs=20`), seeds 1 to 10, before the gate:

| Strategy | Wins | Lost (seed: night) | Castle tier (mean) | First upgrade | Picks | Gold earned (mean) | Spend by role (mean) |
|---|---:|---|---:|---:|---|---:|---|
| balanced_castle | 6 of 10 | 3: 8, 6: 7, 9: 3, 10: 7 | 1.40 | day 8 | masons (4 seeds) | 23.1 | towers 10.8, economy about 10.7, castle 2.4, shrine 0, military 0 |
| army_castle | 8 of 10 | 1: 7, 9: 6 | 1.00 | none | none | 15.0 | military 7.2, towers 3.6, economy about 7.2 |

The castle entry waited unaffordable behind a Harbor and a Mine and blocked the order; this is what lever (a) fixed. Round 2 (the shipped candidate, gate in the data, full sweep, `PLAYTEST_OK runs=100`): balanced 8 of 10 (lost 3: night 7, 9: night 3; castle tier 1.80; earliest first upgrade day 6; 30.0 gold earned; spend towers 14.6, economy 13.7, castle 4.8), army_balanced 8 of 10 (lost 1: 7, 9: 6; ratio 0.888; 15.0 gold). Two of the eight allowed rounds were used; about forty scratch candidates (same simulation, throwaway probe, listed in the report) chose the order.

## Numbers fitted (old to new)

None. Castle tiers II to IV, the four new buildings, the twelve cards and the night counts are unchanged. The only data change is the gate: `requires_castle_tier` 0 to 2 on the five last tiers.

## Re-pinned (test_balance_acceptance, with a Plan 05-11 header paragraph)

- `balanced` (now castle-aware): 8 of 10, lost seeds [3, 9], first loss night 3 (unchanged); earliest first castle upgrade day 6, never before day 2.
- `army_balanced`: 8 of 10, lost [1, 9]; ratio 0.888 pinned at or above 0.8 beside the unchanged 0.915 of `army_balanced_no_walls`.
- `balanced_no_castle` (the Phase 4 order, 8 of 10 before): 3 of 10, lost [2, 4, 5, 6, 8, 9, 10]. `balanced_no_walls`: 8 of 10 became 4 of 10, lost [1, 3, 4, 6, 9, 10]. `army_balanced_no_castle` and `army_balanced_no_walls`: unchanged at 8 of 10. The wall-spend floors: balanced pair 6 became 1 (measured), army pair stays 3.
- BALANCED_MIN_WINS 7 and BALANCED_MAX_WINS 8 are unchanged; greedy economy, no_build and towers_first keep their pins (the gate leaves greedy on nights 3 to 5, towers_first on nights 7 and 8).

## Declared-test fixes (step 1b)

Gate-caused failures fixed by buying castle II in the setup through the new `E2eSupport.raise_castle(ctx, tier)` (grants the price, buys each tier with the first card the tier offers): `test_build_denied`, `test_spot_label`, `test_upgrade_flow`, `test_wall_views`, `test_dawn_rebuild`, `test_spot_label_model` (the last four through their build helper, only when `validate_build` reports `castle_tier`), and `shot_crowd_scenarios.gd` (`walls_day`, its own small helper because tools/ must not read tests/). `test_upgrade_at_spot`, `test_wall_detour` and `test_building_damage` did not fail and were not edited. `test_castle_gate` needed no change. **No gate was removed and no assertion was changed.** `test_bot_defers_locked`'s last test was rewritten as the plan directs (the orders must meet their gates in sequence instead of never meeting one).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] test_shot_list is at the 20-test cap**
- **Found during:** Task 3
- **Issue:** The two new shots needed their own list checks, but `test_shot_list.gd` already held 20 tests (gdlint caps public methods at 20).
- **Fix:** The existing test script was updated for 44 shots (its "last" assertions moved to "n-th last") and the new shots' checks live in `tests/unit/test_shot_list_gate.gd` (3 tests). The same split was made for the strategy and report tests (`test_playtest_strategies_castle.gd`, `test_balance_report_castle.gd`, both named in the plan).
- **Files modified:** tests/unit/test_shot_list.gd, tests/unit/test_shot_list_gate.gd
- **Verification:** lint clean; 23 tests pass across the two scripts.
- **Committed in:** 96cdd06

**2. [Rule 1 - Bug] walls_day failed with castle_tier after the gate**
- **Found during:** Task 3 (full screenshot pass)
- **Issue:** The shot buys the reinforced north run (Wall III), now gated.
- **Fix:** `ShotCrowdScenarios._raise_castle` buys castle II first with the first card (the king's health bar reads 63 / 63 because that card is Royal Training).
- **Files modified:** tools/screenshot/shot_crowd_scenarios.gd (a declared shot file)
- **Verification:** `bash tools/screenshot.sh walls_day` saved and read.
- **Committed in:** 9fcb5cc

**3. [Rule 3 - Blocking, camera range] economy_day needs a wider zoom than the shipped rig allows**
- **Found during:** Task 3
- **Issue:** The Mine and the Shrines lie 92 m apart; the rig's maximum zoom frames about 43 m.
- **Fix:** The shot sets `CameraRig.zoom_max` to 3.4 for the capture only (a presentation property, nothing in the simulation).
- **Files modified:** tools/screenshot/shot_economy_scenarios.gd
- **Verification:** screenshot read (below).
- **Committed in:** 96cdd06

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking). **Impact on plan:** none on scope.

## Deferred Issues (gap plan required)

- **Three tests outside the declared edit list fail because House III and Tower II now need castle II** (plan step 1b: stop and report, never edit): `tests/unit/test_choice_validation.gd::test_a_castle_building_with_one_tier_is_reported` (2 asserts: the shipped House III now names an impossible requirement when the castle is cut to one tier, so `validate()` reports two errors where the test expects one), `tests/integration/test_build_flow.gd` (8 asserts: the third House tier is refused with `castle_tier`), `tests/e2e/test_building_models.gd` (16 asserts: the tier III House and tier II Tower models are never reached). Each needs `E2eSupport.raise_castle(ctx, 2)` in its setup (the first one needs the shipped House tier 3 requirement neutralised on its copy). The full suite is therefore red until a gap plan edits them.
- **`hud_drag_box` screenshot fails** ("the drag box is not showing"). The king stands at (0, 0, 4), on the castle plot, with gold for castle II, so the Phase 5 card row is up and probably takes the mouse press; it buys only tier I buildings and is independent of the gate and of this plan's changes. Not fixed (undeclared). Found by the full 44-shot pass; the other 43 shots saved.
- **Box-select flake:** `test_select_one_type` failed once in the final full run (2 asserts) and passes alone (`-gselect=test_select_one_type`: 2 of 2). Both runs cited.

## Screenshot review

- `castle_gate_locked`: the Tower plot's label reads "Tower II / Range 10.5 · Damage 6 / Needs Castle II" with no price; the king stands to the side so the line is fully legible. Readable.
- `economy_day`: the whole south side is in frame by day: the Gold Mine with its ore pile (left), shrine_west on its pad, the blue pond with two boats and the Harbor dock under the king, the Mill with two cropped Fields (right) and the empty third Field and east Shrine plots, the keep above. Each building is distinct, the pond and both boats are visible, but at this zoom they are small (about 40 px). Readable; whether the size is enough is a feel call for the owner.

## Verification

- Round 2 sweep: `PLAYTEST_OK runs=100`.
- Full suite after Task 1: 277 scripts, 2640 tests, 60495 asserts, all passing. After Task 2: 278 scripts, 2650 tests, 60609 of 60622 asserts, 2643 passing, 7 failing (the three gap tests). Final: 279 scripts, 2653 tests, 2645 passing, 8 failing (the same three plus one `test_select_one_type` flake that passes alone).
- Replays `--twice` after every step: economy `f4b98093` (1842), smoke `2599c7c2` (703), army `f7a967ed` (1353), walls `bfb05fc7` (1961) all byte-identical to their goldens; full_idle won, 7000 ticks, `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14` (before: won, 6911, `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`), and the digest is in the report. Gate stress `GATE_OK enemies=300 crossed=300 stuck=0`.
- `bash tools/lint.sh`: clean (446 files).

## Known Stubs

None.

## Threat Flags

None. T-05-21 holds: pins, data and the report landed in one commit (5d4a227), the after digest in the report is the one the run prints, the before digest is kept, the four goldens were re-checked after every step and the bar was not lowered. T-05-22: all outputs stay under build/ except the committed report.

## Next Phase Readiness

- 05-12 can run the local pass and push once a gap plan (or its own first task) fixes the three gated-tier tests and decides on `hud_drag_box`; the ci.yml comment lines are still one golden out of date (left for 05-12).
- Owner feel items are in the report: the card numbers, A10, the castle ladder's reach, the army bot's castle, the Harbor's dominance, the Shrine's near-silence, and what the gate feels like to a player who ignores the castle.

## Self-Check: PASSED

- Created files exist: `05-BALANCE-REPORT.md`, `test_gate_data_contract.gd`, `test_playtest_strategies_castle.gd`, `test_balance_report_castle.gd`, `test_shot_list_gate.gd` (FOUND).
- Commits exist: 6e31e51, 5d4a227, 96cdd06, 9fcb5cc (FOUND in git log).
- Acceptance criteria: the five Phase 4 building files each hold one `requires_castle_tier = 2` line on the last tier; `balanced_no_castle` and `army_balanced_no_castle` are in `playtest_strategies.gd`; the acceptance header has `Plan 05-11` with `BALANCED_MIN_WINS` 7 and `BALANCED_MAX_WINS` 8 unchanged; the report holds both full_idle digests and the seven headings; `ALL_SHOTS` lists both new shots and `EXPECTED_SHOT_COUNT` is 44. The plan's whole-suite verify does not pass (the three gap tests above), recorded as deferred.
