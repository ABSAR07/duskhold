---
phase: 03-king-combat-troops
plan: 11
subsystem: testing
tags: [godot, gdscript, replay, golden-digest, playtest-bot, balance, night-retune, squads, ci]

requires:
  - phase: 03-king-combat-troops
    provides: "03-04 WeaponDef, the slam through ActivateAbilityIntent and king regeneration; 03-07 SquadOrderIntent point orders (move, attack_move, patrol), the Shift queue and the gate reasons; 03-01/03-02/03-06 squads, military data and follow/hold/rally orders; 03-08 control groups and selection (presentation only)"
provides:
  - "ReplayScenarios army: a frozen, self-contained fixture map and king (Barracks, Archery Range, slam, regeneration), a scripted bot, ARMY_MAX_TICKS 8000, and tests/golden/army.json (seed 1, digest f7a967ed...) checked by CI next to the unchanged smoke golden"
  - "PlaytestBot scripted_orders, night_orders and slam_min_enemies: squad orders and the slam through SquadOrderIntent and ActivateAbilityIntent only, no random function"
  - "Per-night kills_units and units_lost in ReplayDriver.Tally and the BalanceReport night tables (14-cell rows)"
  - "PlaytestStrategies army_balanced (Barracks within 3 entries, Archery Range within 6, follow and hold at each night start, slam at 3 enemies) and the sixth strategy in the CLI default"
  - "Nights 5 to 8 of the prototype map raised to 25, 31, 39, 39 enemies so army_balanced wins 8 of seeds 1 to 10; balance pins re-measured and re-pinned"
  - "03-BALANCE-REPORT.md: six-strategy tables before and after, per-night army numbers, old and new totals, what the bots cannot judge"
affects: [03-12]

actuals:
  tokens: 17400
  tasks: 2
  commits: 4

plan_head_before: 6b68a0575d7c7f004b5f0bde61cbf80d3d7f92e3
plan_head_after: 5dae9d1a354b23caeb454a4cdf4a95a2e530d105
commits: 4

tech-stack:
  added: []
  patterns:
    - "A replay scenario on frozen fixtures that inline every def (copies of shipped numbers) so a data retune never moves its golden; the smoke and army goldens guard the rules, the shipped-data runs guard only self-agreement"
    - "Bots command squads and the slam through the same intents a player produces, one decision per tick before ctx.step(), orders on fixed ticks or once per night, rejections ignored as returned values"
    - "Night retune by explicit group counts measured with the bots; each balance pin keeps its assertion shape and moves its value with old and new values in the header comment"

key-files:
  created:
    - tests/integration/test_army_replay_golden.gd
    - tests/fixtures/fixture_map_replay_army.tres
    - tests/fixtures/fixture_king_replay_army.tres
    - tests/golden/army.json
    - .planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md
  modified:
    - tools/replay/playtest_bot.gd
    - tools/replay/replay_scenarios.gd
    - tools/replay/replay_driver.gd
    - tools/replay/balance_report.gd
    - tools/replay/playtest_strategies.gd
    - tools/replay.sh
    - tools/playtest.sh
    - .github/workflows/ci.yml
    - data/maps/prototype_map.tres
    - tests/integration/test_replay_golden.gd
    - tests/integration/test_balance_report.gd
    - tests/integration/test_balance_acceptance.gd
    - tests/unit/test_replay_cli_args.gd
    - tests/unit/test_playtest_strategies.gd
    - tests/unit/test_night_data_contract.gd
    - tests/unit/test_military_data_contract.gd

key-decisions:
  - "The army scenario runs a bot that starts the night at tick 0, so every scripted order (follow and hold at tick 1, a move with a queued attack-move at tick 120, a patrol at tick 150) lands inside night 1; the dawn restore, the second night and the regeneration are exercised by the same run"
  - "The army fixtures copy today's shipped numbers (footman, archer, grunt, skirmisher, tower, house, barracks, archery, sword 3/5/0.7 with slam 4/4/9, regeneration 1.0/0.1) and add waves large enough that squad units kill and die, so the golden covers units spawning, dying, killing, restoring, the slam and healing"
  - "The retune moves only nights 5 to 8, by group counts (5: 11/10 grunts; 6: 8/7/10 grunts and 3/3 ranged; 7: 10 grunts and 3 ranged on each road; 8: 10 grunts on each road), and leaves costs, income, starting gold, squad and unit numbers alone; counts reached the bar, so test_military_data_contract needed no re-pin"
  - "Night 8 stops at 39, equal to night 7: the totals must not decrease (D-10) and the tower opening falls on night 8 for every seed once that night nears 40 enemies"
  - "army_balanced is 8 of 10 (seeds 1 and 9 lost) and towers_first keeps 2 of the 3 pinned seeds (all 3 before); the balanced bot is unchanged at 9 of 10 and so stays one loss short of the owner's G-02-15 target of 2 or 3, which night counts alone cannot reach without breaking the early-night wall"
  - "army_balanced weaves the balanced order with the military plots and keeps prefer_telegraphed_towers on; test_only_balanced_prefers_telegraphed_towers became test_only_the_balanced_pair_prefers_telegraphed_towers"

patterns-established:
  - "RED with an inert skeleton (the kills_units and units_lost keys in the night record) so the target tests fail on assertions, then GREEN, for both TDD tasks"
  - "Heredocs with apostrophes break the shell, so multi-line edits with prose went through a scratch Python helper that preserves each file's CRLF or LF style"

requirements-completed: [UNIT-04, UNIT-07, UNIT-10, KING-04]

coverage:
  - id: D1
    description: "The army scenario replays twice to the digest in tests/golden/army.json and the log shows unit_spawned, unit_died, squad_ordered for follow, hold, move, attack_move and patrol, squad_restored, king_ability_used and king_healed; seed 2 differs; the fixtures reference nothing under res://data/"
    requirement: UNIT-04
    verification:
      - kind: integration
        ref: "tests/integration/test_army_replay_golden.gd (11 tests)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json (REPLAY_OK digest f7a967ed...)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The smoke golden 2599c7c2... is byte-identical; the CLI accepts army through the existing allowlist, refuses an unknown name with exit 64 and takes no path argument; CI checks the army replay on every push with permissions still contents: read"
    requirement: UNIT-07
    verification:
      - kind: unit
        ref: "tests/unit/test_replay_cli_args.gd#test_army_is_accepted_with_its_defaults"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json; bash tools/replay.sh --scenario=nope exits 64; yaml.safe_load finds the army step in ci.yml"
        status: pass
    human_judgment: false
  - id: D3
    description: "PlaytestBot commands squads and slams through intents only: scripted orders on a tick, night orders once per night start, slam when ready and slam_min_enemies are in reach; no random function"
    requirement: UNIT-07
    verification:
      - kind: integration
        ref: "tests/integration/test_army_replay_golden.gd#test_the_bot_uses_no_random_function and #test_the_log_shows_all_five_orders_the_script_gives"
        status: pass
    human_judgment: false
  - id: D4
    description: "Per-night metrics count enemies killed by units and units lost, and the report tables list them"
    requirement: UNIT-10
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_report.gd#test_the_tally_counts_enemies_killed_by_units_and_units_lost and #test_the_markdown_night_table_lists_the_unit_columns_with_a_value_per_row"
        status: pass
      - kind: integration
        ref: "tests/integration/test_army_replay_golden.gd#test_kills_and_units_lost_per_night_match_the_log"
        status: pass
    human_judgment: false
  - id: D5
    description: "army_balanced builds the Barracks and Archery Range early with upgrades beside Houses and towers, follows with the footmen and holds the archers at each night start, slams at three enemies; the five Phase 2 strategies are unchanged"
    requirement: UNIT-07
    verification:
      - kind: unit
        ref: "tests/unit/test_playtest_strategies.gd#test_army_balanced_builds_the_barracks_early_and_the_range_soon_after, #test_army_balanced_follows_with_the_footmen_and_holds_the_archers_each_night and #test_the_five_phase_two_strategies_give_no_orders_and_never_slam"
        status: pass
    human_judgment: false
  - id: D6
    description: "With nights 5 to 8 raised to 25, 31, 39, 39 enemies, army_balanced wins 8 of seeds 1 to 10 (the Phase 2 bar of 7 or 8) and every no-army pin is re-measured and re-pinned with its old and new value"
    requirement: KING-04
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_the_army_building_bot_wins_seven_or_eight_of_ten_seeds"
        status: pass
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_nights_six_to_eight_carry_the_squad_retune_counts and #test_the_per_night_totals_match_the_owner_s_wall"
        status: pass
      - kind: other
        ref: "bash tools/playtest.sh --seeds=10 then build/playtest/report.json army_balanced win_rate 0.8"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the retuned nights feel right with an army: the bots build instantly, react perfectly and cannot judge tension; under them squads are not stronger than towers per gold, and the balanced bot still loses 1 of 10, not the owner's 2 or 3"
    verification: []
    human_judgment: true
    rationale: "Bot win rates measure the data, not feel; the owner judges the nights at the gate (D-08, Phase 2 D-18)"

duration: 90min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 11: Army Replay Golden and the Squad Night Retune Summary

**A scripted army run (Barracks, Archery Range, six squad orders, slam, regeneration) replays to a golden digest that CI re-checks on every push, and nights 5 to 8 were raised to 25, 31, 39, 39 enemies so the army-building bot wins 8 of 10 seeds**

## Performance

- **Duration:** 90 min
- **Started:** 2026-10-10T16:04:39Z
- **Completed:** 2026-10-10T17:36:00Z
- **Tasks:** 2 (both TDD: RED then GREEN each)
- **Files modified:** 22 (5 created, 17 modified)

## Accomplishments

- **Army golden.** `ReplayScenarios.army` runs frozen fixtures (inline footman, archer, grunt, skirmisher, tower, house, Barracks, Archery Range, sword with the slam, regeneration) with a bot that builds the four plots, orders follow and hold, then a move with a queued attack-move and a patrol, and slams at two enemies in reach. Seed 1 wins in 1353 ticks with digest `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`, 12 units spawned, 7 units lost, 39 enemies killed, 22 king heals. The smoke digest `2599c7c2...` did not move.
- **Bot commands.** `PlaytestBot` gained `scripted_orders`, `night_orders` and `slam_min_enemies`; everything goes through `SquadOrderIntent` and `ActivateAbilityIntent` before `ctx.step()` and a source scan pins that the bot calls no random function.
- **Metrics.** `kills_units` and `units_lost` are in the driver's night record and the report tables (14-cell rows).
- **Strategy and retune.** `army_balanced` measured 10 of 10 wins on the unchanged data (too soft), so nights 5 to 8 went from 21, 22, 27, 33 to 25, 31, 39, 39 enemies by group counts alone; it now wins 8 of 10 (seeds 1 and 9 lost). The balanced control is unchanged at 9 of 10, `towers_first` fell from 10 of 10 to 3 of 10 (2 of the 3 pinned seeds), `greedy_economy` loses on nights 3 to 5, `no_build` on night 2.
- **Report.** `03-BALANCE-REPORT.md` holds the before and after six-strategy tables, the per-night army table, old and new totals and the honest limits of the bots.

## Task Commits

1. **Task 1 RED: failing tests for the army replay, its golden and the unit metrics** - `24b52f8` (test)
2. **Task 1 GREEN: scripted army replay with a golden digest, bot orders and unit metrics** - `91b9031` (feat)
3. **Task 2 RED: failing tests for army_balanced and the 7-or-8-of-10 bar** - `c16ea34` (test)
4. **Task 2 GREEN: army_balanced bot and the night retune, pins and the balance report** - `5dae9d1` (feat)

**Plan metadata:** the docs commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md.

RED evidence: Task 1 RED had 10 of 11 army tests, 1 of 8 golden-lookup, 2 of 12 CLI and 2 of 19 balance-report tests failing on assertions (no script errors); Task 2 RED had 3 of 17 strategy tests and 2 of 10 acceptance tests failing on assertions. No REFACTOR commit was needed.

## Files Created/Modified

See `key-files` above. Notable: `tools/replay/playtest_bot.gd` (orders and slam), `tools/replay/replay_scenarios.gd` (army constants and `_run_army`), `tests/fixtures/fixture_map_replay_army.tres`, `data/maps/prototype_map.tres` (16 group counts).

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The bot starts the night at tick 0, so "orders before night 1" fall inside night 1**
- **Found during:** Task 1 (scenario design)
- **Issue:** the plan scripts follow and hold "before night 1", but the bot's StartNightIntent fires on the first think, so the first night opens on tick 0.
- **Fix:** the orders sit on ticks 1, 120 and 150, all inside night 1, after the squads exist; the dawn restore and night 2 still follow. No test or behaviour depends on the order being in the day.
- **Files modified:** `tools/replay/replay_scenarios.gd`
- **Committed in:** `91b9031`

**2. [Rule 2 - Missing critical] Fixture waves enlarged so units die and kill**
- **Found during:** Task 1 (first golden run)
- **Issue:** with the smoke-sized waves and tier-2 squads no unit died and no unit killed, so `unit_died`, `kills_units` and `units_lost` would have been unguarded by the golden.
- **Fix:** the build order has no upgrades (tier-1 squads of 4) and the two nights bring 14 and 25 enemies; the golden test asserts units died and units killed.
- **Files modified:** `tests/fixtures/fixture_map_replay_army.tres`, `tools/replay/replay_scenarios.gd`
- **Committed in:** `91b9031`

**3. [Rule 3 - Blocking] Night 8 pinned equal to night 7**
- **Found during:** Task 2 (retune search)
- **Issue:** the retune that put army_balanced at 8 of 10 needed night 7 at 39 enemies, but the nights must not decrease (D-10) and a night 8 near 40 ends the tower opening on every seed.
- **Fix:** nights 7 and 8 both carry 39; recorded in the contract test and the report.
- **Files modified:** `data/maps/prototype_map.tres`, `tests/unit/test_night_data_contract.gd`
- **Committed in:** `5dae9d1`

**4. [Minor scope additions]** `tools/replay.sh` and `tools/playtest.sh` usage comments name the new scenario and strategy (files not in the plan's list); `test_night_data_contract.gd` gained a cap-and-validate test and a retune-counts test beyond the plan's behaviour list; the balance-report markdown pin moved from "Kills towers | Kills castle | Buildings lost" to the 14-cell form because the two new columns sit beside the kill and loss columns.

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 missing critical) plus minor additions
**Impact on plan:** none on scope or the owner's decisions; the plan's prohibition held (no economy, cost, starting gold or squad number moved).

## Issues Encountered

- Squads are not stronger than towers per gold under these bots. Raising the late nights costs `army_balanced` runs faster than `balanced` (at +40 % on nights 4 to 8 it won 6 of 10 against 8), and the army bot loses far more buildings (16.4 per run against 5.8). Recorded in the report for the owner; the retune stayed inside the plan (counts only).
- The balanced bot stays at 1 loss in 10, one short of the owner's G-02-15 target of 2 or 3. Raising early nights to cost it a run breaks the Phase 2 wall (a x1.5 raise lost every seed on night 3), and the late nights it wins easily do not move it. The owner chooses which bar the nights serve.
- `towers_first` dropped from 10 of 10 wins to 3 of 10 (seeds 1, 2 and 7), so `TOWERS_FIRST_MIN_WINS` stays 2 of the three pinned seeds but is now at its margin.
- Full-suite wall time: 351 s for 1243 tests after Task 1 and 417 s for 1250 tests after Task 2 (RESEARCH A13: the army matrix and bigger late nights add about 66 s).
- `full_idle` (no golden) moved by design: old digest `91db5112b2041975d04ab464667528b33f5e04e8b486dad0a8687ce620f6efdc` (5140 ticks), new `ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a` (6199 ticks).

## Known Stubs

None.

## Threat Flags

None. T-03-18 holds: `army` joined the existing NAMES allowlist, no path argument was added, an unknown name still exits 64 (test and verify command). T-03-19 holds: the army run is bounded by ARMY_MAX_TICKS (8000) and balance runs by BalanceReport.MAX_TICKS; the playtest seed cap of 50 is unchanged. T-03-SC (accept): no packages; the CI change adds one run line and keeps `contents: read` and every pinned action SHA.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 03-12 (the owner gate packet): the balance report, the army golden and the six-strategy numbers are in place. Items for the packet: squads vs towers per gold, the balanced bot's 1 loss in 10 against the owner's 2 or 3, night 8 equal to night 7, and the high buildings-lost figure for the army bot.
- The full suite passes (1250/1250), lint is clean, the smoke golden is unchanged and the army golden is checked in CI.

## Self-Check: PASSED

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
