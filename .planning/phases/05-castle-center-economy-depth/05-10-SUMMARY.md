---
phase: 05-castle-center-economy-depth
plan: 10
subsystem: testing
tags: [godot, gdscript, replay, golden, economy, playtest-bot, card-picks, ci, d-14, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "BuildIntent.choice_id, CHOICE_REQUIRED and the castle plot (05-02); the bot's pending list for locked entries (05-05); IncomeState DECLINING, BOATS and AWAKENED curves and their events (05-06 to 05-09); fixture_map_replay_walls.tres as the self-contained fixture shape"
provides:
  - "PlaytestBot.card_picks: at a CHOICE_REQUIRED entry the bot passes the first listed card the tier offers (BuildIntent.new(spot, pick)) and removes it from the list; with none acceptable the entry is deferred to the pending list like a locked one, so a bot never meets choice_required"
  - "tests/fixtures/fixture_map_replay_economy.tres: self-contained frozen fixture (inline castle with tier II and four cards, Gold Mine, Mill, Field, Fishing Harbor, Shrine, tower, grunt; scripts the only ext_resources; no res://data/ reference)"
  - "ReplayScenarios economy scenario: &economy in NAMES, ECONOMY_MAP, ECONOMY_MAX_TICKS 9000, ECONOMY_BUILD_ORDER, ECONOMY_CARD_PICKS, ECONOMY_HOLD_POINT, _run_economy; tools/replay.sh usage line gains economy"
  - "tests/golden/economy.json (seed 1, digest f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97): the one new golden of D-08"
  - "The economy replay line in the test job and the native-windows job of ci.yml (permissions: contents: read kept)"
  - "test_economy_destroyed: D-14 across the Mine, Mill, Field, Harbor and an awake Shrine falling in one night"
affects: [05-11 (retunes cannot move the economy golden; the full_idle before/after report is its job), 05-12 (pushes and watches the economy replay on GCC and MSVC)]

actuals:
  tokens: 10985
  tasks: 2
  commits: 2
plan_head_before: ea36a4a57a1f46336409b8808b5255b6dbdf440f
plan_head_after: 1ddaf9c05757e19dc61cdf800f1466c0203e4292

tech-stack:
  added: []
  patterns:
    - "A replay golden for a family of rules runs on an inline-copy fixture whose only ext_resources are scripts, so a retune of data/ can never move it; the fixture's grunt counts, spawn points and plot positions are tuned until the log shows every event family the golden must guard"
    - "A bot gate that needs a player choice reuses the deferral list of locked entries: one _try_buy helper submits the purchase (with the first acceptable card) or returns the gate's reason, and both the build loop and the retry loop read it"

key-files:
  created:
    - tests/fixtures/fixture_map_replay_economy.tres
    - tests/golden/economy.json
    - tests/integration/test_economy_replay_golden.gd
    - tests/integration/test_economy_destroyed.gd
    - tests/unit/test_bot_card_picks.gd
  modified:
    - tools/replay/playtest_bot.gd
    - tools/replay/replay_scenarios.gd
    - tools/replay.sh
    - tests/unit/test_replay_cli_args.gd
    - .github/workflows/ci.yml

key-decisions:
  - "The economy fixture has a west road for night 1 (24 grunts, which wake the Shrine and break the Mine) and a north-west road for nights 2 and 3 (10 grunts each, which hit the Shrine and tower_1 and leave the rebuilt Mine alone), so the Mine falls exactly once, is rebuilt free at dawn 1 and is paid at dawn 2: one log shows a destroyed building, a rebuild and a dawn_payout listing Mine, Mill, Field and Harbor"
  - "The fixture carries a second tower plot (tower_2) beside the plan's tower_1: with one tower and castle tier II (100 health) the 24-grunt crowd destroyed the castle in night 1"
  - "Task 2 asserts the Mine's next payout against next_payout() read before the fall, and does not assert a paid-dawns count after the floor: IncomeState counts only the dawns that lowered the payout, so a Mine at its floor keeps its count (documented behaviour of mine_paid_dawns, not a rule gap)"

patterns-established:
  - "Economy golden checks read the log by event name and by spot index (attack_fired source = the Shrine's index in MapConfig order), never by tick, so a retune of the fixture's timing changes the digest but not the family checks"

requirements-completed: [BLDG-05, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06]

coverage:
  - id: D1
    description: "PlaytestBot.card_picks passes the first listed card a branching tier offers, skips an unoffered card for the next listed one, keeps it for a later tier, and defers the entry like a locked one when none is acceptable"
    requirement: "BLDG-05"
    verification:
      - kind: unit
        ref: "tests/unit/test_bot_card_picks.gd (6 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The economy scenario on a frozen self-contained fixture replays twice to the same digest and to tests/golden/economy.json, seed 2 differs, and the log shows the card pick, all five new buildings built, a dawn paying Mine, Mill, Field and Harbor, harbor_boats_changed, shrine_woke, Shrine attack_fired, building_destroyed and buildings_rebuilt"
    requirement: "ECON-03"
    verification:
      - kind: integration
        ref: "tests/integration/test_economy_replay_golden.gd (9 tests); bash tools/replay.sh --scenario=economy --twice --expect-file=tests/golden/economy.json"
        status: pass
    human_judgment: false
  - id: D3
    description: "--scenario=economy is accepted by the replay CLI with its defaults and its golden path; the economy replay line is in both CI jobs and permissions: contents: read is kept"
    requirement: "ECON-06"
    verification:
      - kind: unit
        ref: "tests/unit/test_replay_cli_args.gd#test_economy_is_accepted_with_its_defaults_and_its_golden"
        status: pass
      - kind: other
        ref: "grep -c 'scenario=economy --twice --expect-file=tests/golden/economy.json' .github/workflows/ci.yml = 2; grep -c 'contents: read' = 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-14 holds across the four new buildings at once: a night that destroys Mine, Mill, Field, Harbor and an awake Shrine is followed by a free rebuild in MapConfig order, no pay for them that morning (castle and an untouched House still paid), unchanged Mine paid dawns, Harbor boats and Shrine credit and awake state, the crossed coin on all five, and the next amounts at the following dawn"
    requirement: "ECON-05"
    verification:
      - kind: integration
        ref: "tests/integration/test_economy_destroyed.gd (5 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "smoke, army and walls replay byte-identical to their goldens and full_idle to its digest after both tasks"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --twice for smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569 (REPLAY_OK, unchanged)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-10-22
status: complete
---

# Phase 5 Plan 10: Economy replay golden Summary

**A fifth replay golden (economy, f4b98093) on a frozen self-contained fixture pins the castle card pick, all four new income curves, a Shrine waking and a Mine lost and rebuilt, via a new PlaytestBot.card_picks; the economy replay joins both CI jobs, and a test-only D-14 test proves five economic buildings fall together and lose only that morning's pay.**

## Performance

- **Duration:** about 45 min
- **Started:** about 2026-10-22T00:35:00Z (the orchestrator's wave-8 gate finished 00:26:12Z; the exact start was not recorded)
- **Completed:** 2026-10-22T01:25:00Z
- **Tasks:** 2
- **Files modified:** 13 (5 created source files plus 3 generated .uid files, 5 modified)

## Accomplishments

- `PlaytestBot.card_picks` plus one `_try_buy` helper: a branching tier is bought with the first listed card it offers, and a bot with no acceptable card defers the entry to the plan 05-05 pending list instead of stalling or hitting `choice_required`.
- `fixture_map_replay_economy.tres` (inline copies of every def, numbers of today, scripts the only ext_resources) and the `economy` scenario. The run: tick 0 buys castle II (masons), Mine, Mill, Field, Harbor, Shrine and two towers; night 1 breaks the Mine (tick 413), wakes the Shrine (tick 657) and the Shrine then fires 23 times; dawn 1 (tick 795) rebuilds the Mine free and pays Mill, Field, Harbor 1 boat, Shrine and castle; dawn 2 (tick 1334) pays Mine 3, Mill 1, Field 1, Harbor 2 boats, Shrine 1, castle 2; outcome won at tick 1842, 399 log lines, 3 nights.
- `tests/golden/economy.json` written once from `--twice` and re-confirmed with `--expect-file`; the economy replay line is in the test job and the native-windows job.
- `test_economy_destroyed`: Mine, Mill, Field, Harbor and an awake Shrine all fall in the third night; the dawn rebuilds all five in map order, full health, zero gold, none paid that morning, mine_paid_dawns 2, boats 2, Shrine credit and awake state unchanged, crossed coin on all five, and the fourth dawn pays Mine its next amount, Harbor a third boat, Shrine its income.

## Task Commits

1. **Task 1: economy replay golden, bot card picks, CI lines (tracer)** - `061e51b` (feat). The commit message names tests/golden/economy.json as the D-08 golden.
2. **Task 2: D-14 across the four new buildings (tdd, test-only)** - `1ddaf9c` (test)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `tools/replay/playtest_bot.gd` - `card_picks`, `_try_buy`, CHOICE_REQUIRED deferral in `_build` and `_retry_pending`
- `tools/replay/replay_scenarios.gd` - economy name, constants, `_run_economy`, header doc
- `tools/replay.sh` - usage line gains `economy`
- `tests/fixtures/fixture_map_replay_economy.tres` - the frozen fixture (2 spawn points, 8 plots, 3 nights)
- `tests/golden/economy.json` - seed 1, digest f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97
- `tests/integration/test_economy_replay_golden.gd` (9 tests), `tests/unit/test_bot_card_picks.gd` (6), `tests/integration/test_economy_destroyed.gd` (5), `tests/unit/test_replay_cli_args.gd` (+1, now 14)
- `.github/workflows/ci.yml` - two economy replay lines, nothing else

## Decisions Made

See key-decisions: a second spawn point so the Mine falls once and is paid later, a second tower plot, and no paid-dawns assertion at the Mine's floor.

## TDD Gate Compliance

Task 2 is test-only (`tdd="true"` with no production code by design), so it has one `test(05-10)` commit and no `feat` commit. RED observation: the first run of the new script loaded and ran (no load or parse failure) and 4 of 5 tests passed immediately, as expected for a test of rules that already exist. The one failure was my own wrong assertion (`mine_paid_dawns` equal to 3 after the fourth dawn); `IncomeState.mine_paid_dawns` documents that it counts only dawns that lowered the payout, and the fourth dawn pays the floor, so the count stays 2. I removed that assertion; the Mine's amount is still pinned against `next_payout()` read before the fall. No rule gap between the four buildings was found and no simulation file changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] A second tower plot and a second spawn point in the economy fixture**
- **Found during:** Task 1 (fixture tuning)
- **Issue:** With the plan's single `tower_1`, castle tier II at 100 health lost night 1 to 36 and then 24 grunts. With only a west road, the Mine either fell every night (so no dawn ever paid it) or never fell.
- **Fix:** Added `tower_2` at (-12, 0, -4) and a `northwest` spawn point at (-38, 0, 6) used by nights 2 and 3 (10 grunts each); night 1 is 24 grunts from the west. The plan allows tuning the fixture's counts, intervals and plot positions until the log shows every family; adding one plot and one spawn point is a small extension of that, and the scenario's `ECONOMY_BUILD_ORDER` gained `tower_2` as its last entry.
- **Files modified:** tests/fixtures/fixture_map_replay_economy.tres, tools/replay/replay_scenarios.gd
- **Verification:** the log shows every required family; `--twice --expect-file` passes; the fixture validates and references nothing in `res://data/`.
- **Committed in:** 061e51b

**2. [Rule 2 - Missing critical] A branching entry with no acceptable card is deferred even for a bot with no `card_picks`**
- **Found during:** Task 1 (bot picks)
- **Issue:** Before this plan `_build` treated CHOICE_REQUIRED like any other unaffordable-style refusal (`return`, waiting in place), so a bot that meets a branching tier stalls its whole order. The plan's behaviour list asks that a bot with no card_picks defers the entry like a locked one.
- **Fix:** `_build` and `_retry_pending` both go through `_try_buy`, which returns CHOICE_REQUIRED when no listed card is acceptable; that reason joins CASTLE_TIER and NEEDS_SPOT in the deferral branch.
- **Files modified:** tools/replay/playtest_bot.gd
- **Verification:** `test_a_bot_with_no_card_defers_a_branching_entry_like_a_locked_one`; full_idle replays to 4385f569 with the same 6911 ticks (no shipped bot meets a branching tier).
- **Committed in:** 061e51b

---

**Total deviations:** 2 auto-fixed (1 blocking fixture extension, 1 behaviour the plan's behaviour list required). 
**Impact on plan:** None on scope: both stay inside the files the plan lists. The ci.yml comment lines that say "four goldens" and "smoke, army and walls" were deliberately left as they were (the plan says nothing else in ci.yml changes), so they are now one golden out of date.

## Issues Encountered

- Fixture tuning took about ten runs. Findings worth keeping for 05-11: a plot is only engaged by grunts when it sits within the grunt aggro range (6 m) of the road, and positions farther away give a byte-identical digest; castle tier II replaces the castle's health with its own 100, so the map's `castle_max_health` is irrelevant to this scenario.
- A background suite started with a nested `&` detaches from the Bash tool, so no completion notification arrives; waiting on the log's `EXIT` line works instead.

## Verification

- Full suite after Task 1: 274 scripts / 2620 tests / 60340 asserts, all passing, exit 0 (776 s).
- Full suite after Task 2: 275 scripts / 2625 tests / 60479 asserts, all passing, exit 0 (773 s). No box-select flake in either run.
- Replays after Task 2, each `--twice` (economy, smoke, army and walls with `--expect-file`): economy f4b98093 (1842 ticks, won), smoke 2599c7c2 (703), army f7a967ed (1353), walls bfb05fc7 (1961), full_idle 4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf (6911, won). The same five were also green after Task 1.
- `bash tools/lint.sh`: clean (442 files). ci.yml carries the economy line twice and `contents: read` once; the fixture has 0 `res://data/` references and 0 ext_resources outside `res://simulation/`.

## Known Stubs

None.

## Threat Flags

None. T-05-19 is mitigated as planned (economy.json written once, named as the D-08 golden in its commit; four goldens plus full_idle verified unchanged); T-05-20 holds (two replay lines added, `permissions: contents: read` kept, ReplayCli still accepts only names in `ReplayScenarios.NAMES`).

## Next Phase Readiness

- 05-11 can retune freely: the economy fixture copies today's shipped numbers inline, so a retune cannot move tests/golden/economy.json. A digest move of economy, smoke, army or walls from here on is a stop rule for the owner (D-08, Phase 4 D-14).
- 05-11 note: `PlaytestBot._is_tower_plot` and `Tally._role_of` still count the Shrine as a tower (it attacks); the economy scenario's order lives in `ReplayScenarios`, not in `PlaytestStrategies`, so `test_bot_defers_locked` is unaffected.
- 05-12 pushes once and watches the economy replay on GCC (test job) and MSVC (native-windows job); this plan ran only on Windows locally, so the cross-compiler agreement is unproven until then.
- Requirement marking: all six IDs are also declared by 05-11 and/or 05-12, so the shared-ID gate leaves them for the plan that finishes last.

## Self-Check: PASSED

- Created files exist: fixture, golden, three test scripts (FOUND).
- Task commits exist: 061e51b, 1ddaf9c (FOUND in git log).
- Acceptance criteria re-checked: economy.json holds `"scenario": "economy"` and a 64-hex digest; `&"economy"` in NAMES and `func _run_economy(`; `var card_picks: Array[StringName]`; two CI lines; fixture ext_resources all under `res://simulation/`.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-22*
