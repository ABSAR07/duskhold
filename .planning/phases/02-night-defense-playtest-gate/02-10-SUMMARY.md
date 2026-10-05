---
phase: 02-night-defense-playtest-gate
plan: 10
subsystem: testing
tags: [godot, gdscript, balance, playtest, bots, tuning, dev-05, loop-07]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: ReplayDriver, SimRecorder and PlaytestBot (02-07, 02-09), the night data contract and the Skirmisher (02-02, 02-05), run outcomes and stats (02-07), the replay CLI and wrapper (02-09)
provides:
  - PlaytestStrategies (no_build, greedy_economy, houses_first, towers_first, balanced), a defend-nearest-threat king and telegraphed tower ordering in PlaytestBot
  - ReplayDriver per_night metrics (enemies, kills by king and towers, buildings lost, knockouts, castle hp, night duration, gold at dawn, how the night ended)
  - BalanceReport (strategy by seed matrix, summaries, markdown) and tools/playtest.sh with its PLAYTEST_OK sentinel (D-18)
  - tuned king, castle, House and tower data meeting D-10 and D-04, two guard tests, and 02-BALANCE-REPORT.md for the playtest gate
affects: [02-11, playtest-gate, balance, ci]

actuals:
  tokens: 16600
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A balance claim is a measured number from a seeded matrix of full scripted runs, with the bots' limits stated beside it"
    - "ReplayDriver bookkeeping is a read-only event listener (Tally), so adding metrics never moves a digest"
    - "A tuning pass is judged by report acceptance (win rates and median loss night) read from build/playtest/report.json, not by hand"

key-files:
  created:
    - tools/replay/playtest_strategies.gd
    - tools/replay/balance_report.gd
    - tools/playtest/playtest_cli.gd
    - tools/playtest.sh
    - tests/unit/test_playtest_strategies.gd
    - tests/integration/test_balance_report.gd
    - tests/integration/test_king_sturdiness.gd
    - tests/integration/test_every_night_ends.gd
    - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
  modified:
    - tools/replay/playtest_bot.gd
    - tools/replay/replay_driver.gd
    - tools/replay/replay_cli.gd
    - tools/replay/replay_scenarios.gd
    - data/king/king.tres
    - data/maps/prototype_map.tres
    - data/buildings/house.tres
    - data/buildings/tower.tres

key-decisions:
  - "Tuned only combat data: king 30 to 50 hp and 5 damage per 0.7 s, castle 40 to 70, Houses 12/18/24 hp, tower I 50 hp / 3 damage / 0.8 s / range 9, tower II 70 hp / 6 damage / 0.7 s / range 10.5; enemies, waves, costs, incomes, starting gold and the 15 s respawn cap are untouched"
  - "The telegraph preference reorders only the first build of each unbuilt tower plot; moving upgrades ahead starved the north road and lost night 7"
  - "balanced opens with three Houses before any tower, because a tower-first opening spends the 4 starting gold and leaves the run with no income"
  - "The full_idle replay scenario keeps its name (CI uses it) but plays the balanced bot, since an idle king loses on night 1 (02-09 request)"
  - "A playtest run that ends in timeout fails the CLI (exit 1) after the report is written, matching RESEARCH Pitfall 7"

patterns-established:
  - "tools/playtest.sh copies tools/replay.sh's shape: import warm-up, timeout, tee, sentinel and script-error grep"
  - "TDD tasks commit a RED test commit with assertion-failing stubs, then a GREEN feat commit (continued)"

requirements-completed: [DEV-05, LOOP-07]

coverage:
  - id: D1
    description: "bash tools/playtest.sh runs the five named strategies over a seed set on the shipped data and writes report.json and report.md with per-run and per-night numbers"
    requirement: DEV-05
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_report.gd (16 tests: matrix, keys, JSON round trip, summaries, markdown, per-night sums, CLI allowlist)"
        status: pass
      - kind: other
        ref: "bash tools/playtest.sh --seeds=10 prints PLAYTEST_OK runs=50 and writes build/playtest/report.json and report.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "The strategies are deterministic and the bots stay inside the rules: a defending king moves at most a sprint step toward the enemy nearest the castle, the same strategy and seed give the same digest"
    requirement: DEV-05
    verification:
      - kind: unit
        ref: "tests/unit/test_playtest_strategies.gd (14 tests)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (digest 2599c7c2... unchanged)"
        status: pass
    human_judgment: false
  - id: D3
    description: "With the tuned data, over seeds 1 to 10 balanced wins at least 8 runs, greedy_economy at most 2 with a median loss night of 3 to 6, and no_build loses by night 3 (D-10)"
    requirement: LOOP-07
    verification:
      - kind: other
        ref: "bash tools/playtest.sh --seeds=10 then the Python assertion over build/playtest/report.json: balanced 10 of 10, greedy_economy 0 of 10 with median loss night 4, no_build lost night 1 on every seed"
        status: pass
    human_judgment: false
  - id: D4
    description: "The king is sturdy but mortal (D-04): alone he beats 3 grunts without a knockout, and in the shipped night-4 wave he is knocked out"
    requirement: LOOP-07
    verification:
      - kind: integration
        ref: "tests/integration/test_king_sturdiness.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every night that starts under balanced ends in DAWN, WON or LOST inside its tick budget on all 10 seeds and no run times out"
    requirement: DEV-05
    verification:
      - kind: integration
        ref: "tests/integration/test_every_night_ends.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "The balance table, the before and after value list and the bots' limits are published for the playtest gate"
    requirement: DEV-05
    verification:
      - kind: other
        ref: ".planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md exists with a summary table, a before/after list and a 'What the bots cannot tell you' section"
        status: pass
    human_judgment: true
    rationale: "Whether the measured curve feels fair and tense, and whether the numbers deserve sign-off, is the owner's call at the gate (D-18)"

duration: 81min
completed: 2026-10-05
status: complete
plan_head_before: c544d24f566b48b018f2286354444156e8afc8d0
plan_head_after: 943b9c9832b32b831edf0beb3168b029a25f091d
---

# Phase 2 Plan 10: Scripted playthroughs, balance report and combat tuning Summary

**Five named bot strategies and a seeded balance report (`bash tools/playtest.sh`), then a data-only combat retune that makes the balanced build win 10 of 10 seeds, pure House greed lose on night 4 and a king alone mortal but sturdy**

## Performance

- **Duration:** 81 min
- **Started:** 2026-10-05T12:22:42Z
- **Completed:** 2026-10-05T13:43:57Z
- **Tasks:** 2
- **Files modified:** 17 (9 created, 8 modified; plus 4 `.uid` files)

## Accomplishments

- `bash tools/playtest.sh [--strategies=a,b] [--seeds=N] [--out=build/dir]` runs a strategy by seed matrix of full scripted runs on the shipped prototype map (50 runs in about 45 s) and writes `build/playtest/report.json` and `report.md`. Arguments are allowlisted (seeds 1 to 50, known strategies, output under build/), the wrapper is bounded by `timeout` and needs the `PLAYTEST_OK runs=<n>` sentinel and a clean log.
- ReplayDriver now returns `per_night` (enemies, kills by king and by towers, buildings lost, knockouts, castle hp at the end, duration, gold at dawn, how the night ended) from a read-only event listener; the digest is unchanged.
- The tuning pass (data only) took the matrix from "no run survives past night 4" to the acceptance values below; the evidence, the before and after values and the bots' limits are in `02-BALANCE-REPORT.md`.

## Final acceptance values (seeds 1 to 10, shipped data)

| Check | Required | Measured |
|-------|----------|----------|
| balanced win rate | at least 0.8 | 1.0 (10 of 10) |
| greedy_economy win rate | at most 0.2 | 0.0 |
| greedy_economy median loss night | 3 to 6 | 4 |
| no_build | max nights survived at most 2 | 0 (loses night 1 every seed) |
| houses_first / towers_first (informational) | none | 100% / 0% (towers_first starves: no income, dies night 6) |
| King alone vs 3 grunts | no knockout | 0 knockouts, 3 of 3 killed |
| King in the shipped night-4 wave | knocked out at least once | knocked out |
| Smoke golden | unchanged | `2599c7c2...` matches |
| full_idle (now the balanced bot) | two runs agree | REPLAY_OK, won, 6244 ticks, digest `a25aa7fd...` |

A 30-seed run of the final data gave 100% for balanced and houses_first, so the 10 of 10 is not a lucky sample. Seeds only move spawn scatter, so rates are close to all-or-nothing per strategy.

## Task Commits

1. **Task 1: Scripted strategies, per-night metrics and the balance report command**
   - RED `a4946f7` (test): failing tests for strategies, per-night metrics, report and CLI arguments (stubs fail on assertions)
   - GREEN `ab46b98` (feat): PlaytestStrategies, bot additions, ReplayDriver per_night, BalanceReport, playtest CLI and wrapper
2. **Task 2: Tune the shipped combat and wave data, guard it with tests, publish the balance report**
   - `f5e8f49` (fix): telegraph preference limited to first tower builds, balanced opens with Houses, full_idle plays the balanced bot
   - `943b9c9` (feat): tuned king, castle, House and tower data; test_king_sturdiness, test_every_night_ends; 02-BALANCE-REPORT.md

TDD note for Task 2: its RED evidence is the "before" matrix failing the same Python acceptance assertion (balanced win rate 0.0, `AssertionError`); the guard tests describe D-04 and Pitfall 7 and were written after the tuning they pin.

**Plan metadata:** recorded in the docs commit that carries this summary.

## Decisions Made

See `key-decisions` above. The retune was found by running the matrix with in-memory overrides (a scratch tool, deleted before commit) and then writing the chosen values into the `.tres` files; the first measurement on the old data had every strategy dead by night 4.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Telegraph preference starved the north road**
- **Found during:** Task 2 (tuning matrix)
- **Issue:** Reordering every tower entry (including upgrades) by the coming night's roads moved tower upgrades ahead of tower 3's first build, so `balanced` reached night 6 without a north tower and lost night 7, while `houses_first` (same data) won.
- **Fix:** The telegraph preference reorders only the first build of each unbuilt tower plot; upgrade entries stay in place.
- **Files modified:** tools/replay/playtest_bot.gd
- **Verification:** `balanced` 10 of 10; test_playtest_strategies still passes
- **Committed in:** f5e8f49

**2. [Rule 1 - Bug] The first `balanced` order could never earn income**
- **Found during:** Task 2 (before-table review: gold at dawn stuck at 0)
- **Issue:** The order opened with a tower, which spends the 4 starting gold; with no House the run has no income, and the bot waits forever at the next unaffordable entry.
- **Fix:** `balanced` opens with three Houses, then the towers on the telegraphed roads, then alternates.
- **Files modified:** tools/replay/playtest_strategies.gd
- **Committed in:** f5e8f49

**3. [Rule 3 - Blocking] Reused the replay CLI's path rule**
- **Found during:** Task 1 (playtest CLI)
- **Issue:** The plan says to reuse the replay CLI's `--out` path rules, but they were `_safe_dir`, a private helper.
- **Fix:** Renamed it `safe_dir` in tools/replay/replay_cli.gd (two occurrences) and called it from the playtest CLI; no behaviour change, replay CLI tests pass.
- **Files modified:** tools/replay/replay_cli.gd
- **Committed in:** ab46b98

**4. [Rule 2 - Missing critical] full_idle replay scenario**
- **Found during:** Task 2 (02-09 asked this plan to revisit it)
- **Issue:** full_idle lost on night 1 with an idle king, so it exercised one night.
- **Fix:** It plays the balanced bot (name kept for CI). It now wins in 6244 ticks, covering all eight nights; the smoke golden is untouched.
- **Files modified:** tools/replay/replay_scenarios.gd
- **Committed in:** f5e8f49

---

**Total deviations:** 4 auto-fixed (2 bugs, 1 blocking, 1 missing critical)
**Impact on plan:** No scope change. Additions beyond the plan, all small: `BalanceReport.run_on(map, tuning, king, strategies, seeds)` (the data-taking form `run` delegates to), a `per_night` key `end` ("dawn", "won", "lost" or "" if cut short), and the CLI failing on a timeout run after writing the report.

Pinned tests: none of the existing suites pinned a number this pass changed (the respawn cap of 15 s, building costs and incomes, starting gold, night totals and the night data contract were all left as decided), so no older test was edited.

## Issues Encountered

- With the old numbers the first matrix had no run surviving past night 4 for any strategy; the economy leaves only about 18 gold over the run, so the tuning had to make the king carry nights 1 to 3 and make towers worth their cost from day 4.
- Night 8 is chaotic around the tower I health value (45 hp gave 90% over 30 seeds, 48 or more gave 100%); 50 hp was chosen for margin.

## Known Stubs

None. (The RED-commit stubs were replaced in `ab46b98`.)

## User Setup Required

None - no external service configuration required.

## Threat Surface

No new surface beyond the plan's threat model: `--seeds` capped at 50, strategies allowlisted, every run bounded by `MAX_TICKS`, the wrapper bounded by `timeout` and the sentinel (T-02-21); `--out` confined to build/ with `..` rejected (T-02-22); measured values, before/after data and the bots' limits recorded in 02-BALANCE-REPORT.md (T-02-23).

## Next Phase Readiness

- 02-BALANCE-REPORT.md and the screenshots are the delegated half of the D-18 gate; the owner plays one or two runs and signs off or names fixes through `/gsd-verify-work`.
- Open points for the owner are listed at the end of the report: whether night 3 (king alone against two roads) is the right first scare, whether nights 6 and 7 are too calm once three towers stand, and the dawn full-repair rule.
- Plan 02-11 pushes the branch; CI will run the smoke golden and the `full_idle` double check on the new data.

## Self-Check: PASSED

- Files exist: playtest_strategies.gd, balance_report.gd, playtest_cli.gd, tools/playtest.sh, the four new test scripts and 02-BALANCE-REPORT.md (checked with `[ -f ]`).
- Commits exist: a4946f7, ab46b98, f5e8f49, 943b9c9 (`git rev-list --count c544d24..HEAD` is 4).
- Plan-level verification: `bash tools/test.sh` 714 passing in 84 scripts with test_playtest_strategies, test_balance_report, test_every_night_ends and test_king_sturdiness in the JUnit XML; `bash tools/playtest.sh --seeds=10` exits 0 and the acceptance assertion passes; the smoke replay still prints REPLAY_OK with digest 2599c7c2...; `bash tools/replay.sh --scenario=full_idle --twice` passes; `bash tools/lint.sh` clean.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*
