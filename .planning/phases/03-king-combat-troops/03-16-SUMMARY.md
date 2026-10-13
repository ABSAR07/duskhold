---
phase: 03-king-combat-troops
plan: 16
subsystem: testing
tags: [godot, gdscript, playtest-bot, balance-report, squad-value, gap-closure, tdd]
gap_closure: true
gap_ids: [G-03-11]

requires:
  - phase: 03-king-combat-troops
    provides: "03-11 army_balanced bot, per-night kills_units and kills_towers, the balance report and its Round 1 text; 03-CONTEXT D-26 (squad value bar 0.8) and D-27 (all four goals at once)"
provides:
  - "ReplayDriver.Tally.spent: gold spent by building role (military, towers, economy) from building_built at the tier's own price; the driver result key spent"
  - "BalanceReport run entries military_gold_spent, tower_gold_spent, economy_gold_spent, unit_kills, tower_kills; summary keys unit_kills_per_military_gold, tower_kills_per_tower_gold, squad_value_ratio (sums divided, 0.0 on a zero divisor); the 'Squad value per gold' markdown table; all in build/playtest/report.json"
  - "tests/integration/test_balance_value_metric.gd (5 tests)"
  - "03-BALANCE-REPORT.md 'Round 2 (G-03-11)': the four owner goals as numeric targets, the may-move and stays lists, and the baseline on today's data"
affects: [03-17, 03-18]

actuals:
  tokens: 6963
  tasks: 2
  commits: 3

plan_head_before: f85a95fc0ce0af09289623201ec589acecb750b2
plan_head_after: c2e265900df390ca97cdf288abf02005f97afd03
commits: 3

tech-stack:
  added: []
  patterns:
    - "A read-only Tally listener on SimEvents (building_built) that reads defs through ctx.buildings and never writes the simulation, so no golden digest moves"
    - "Per-gold summary values divide sums over a strategy's runs (never a mean of per-run ratios) and guard a zero divisor with 0.0"

key-files:
  created:
    - tests/integration/test_balance_value_metric.gd
    - tests/integration/test_balance_value_metric.gd.uid
  modified:
    - tools/replay/replay_driver.gd
    - tools/replay/balance_report.gd
    - tests/integration/test_balance_report.gd
    - .planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md

key-decisions:
  - "Role classification: a building with a unit_id is military; any other building with a tier whose attack_damage is above 0 is towers; the rest is economy. Read from the defs, so a retune that renames nothing needs no change here"
  - "The free dawn rebuild is not counted as spend (rebuild_destroyed charges nothing); only building_built, which fires for a build and an upgrade, adds gold"
  - "The ratio is measured on army_balanced alone (the only bot that buys squads) against its own tower spend, and the report says so"

patterns-established:
  - "Report columns that are pure event listeners are proved harmless by replaying both goldens unchanged and by the per-night bookkeeping digest test"

requirements-completed: [UNIT-04, UNIT-07]

coverage:
  - id: D1
    description: "A bot run reports the gold spent by building role, summed from building_built at the tier's own price; a refused build counts nothing"
    requirement: "UNIT-04"
    verification:
      - kind: unit
        ref: "tests/integration/test_balance_value_metric.gd#test_the_tally_adds_each_build_and_upgrade_cost_to_its_role"
        status: pass
      - kind: unit
        ref: "tests/integration/test_balance_value_metric.gd#test_a_refused_build_spends_nothing"
        status: pass
    human_judgment: false
  - id: D2
    description: "Run entries carry the five gold and kill totals; summaries carry unit_kills_per_military_gold, tower_kills_per_tower_gold and squad_value_ratio with zero guards"
    requirement: "UNIT-07"
    verification:
      - kind: unit
        ref: "tests/integration/test_balance_value_metric.gd#test_run_entries_carry_the_gold_and_kill_totals"
        status: pass
      - kind: unit
        ref: "tests/integration/test_balance_value_metric.gd#test_the_summary_divides_kills_by_gold_and_guards_zero"
        status: pass
      - kind: integration
        ref: "bash tools/playtest.sh --strategies=army_balanced --seeds=2 (report.json has squad_value_ratio and military_gold_spent above 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The markdown report lists a 'Squad value per gold' table with one row per strategy"
    verification:
      - kind: unit
        ref: "tests/integration/test_balance_value_metric.gd#test_the_markdown_lists_the_squad_value_table_with_one_row_per_strategy"
        status: pass
    human_judgment: false
  - id: D4
    description: "The bookkeeping is read-only: smoke golden 2599c7c2 and army golden f7a967ed replay to their recorded digests"
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json; bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
    human_judgment: false
  - id: D5
    description: "03-BALANCE-REPORT.md opens Round 2 with the four goals as measured targets, the may-move and stays lists and the baseline on today's data"
    verification: []
    human_judgment: true
    rationale: "A document the owner reads at the gate; the checks are grep presence of the section, the Baseline heading and the exact target line, not whether the targets and limits are the ones the owner wants."

duration: 26min
completed: 2026-10-13
status: complete
---

# Phase 3 Plan 16: Squad value per gold in the balance report Summary

**The balance report now measures kills per gold by building role (military, towers, economy) through a read-only event tally, and 03-BALANCE-REPORT.md opens Round 2 with the owner's four goals as numeric targets and a measured baseline: balanced 9 of 10, army 8 of 10, night 8 equal to night 7, squad_value_ratio 0.68 against the 0.8 bar.**

G-03-11 closes only when plans 03-17 (the retune) and 03-18 (the publication) are done. This plan measures; it changed no shipped data, no simulation code, no bot and no golden.

## Performance

- **Duration:** 26 min
- **Started:** 2026-10-13T16:36:00Z (approximate: taken from the commit time of the preceding plan, since no start stamp was recorded)
- **Completed:** 2026-10-13T17:01:07Z (last task commit; the SUMMARY commit follows)
- **Tasks:** 2
- **Files modified:** 6 (4 modified, 2 created)

## Accomplishments

- `ReplayDriver.Tally` connects `building_built`, classifies the spot's `BuildingDef` and adds the built tier's own cost to `spent` (military, towers, economy); the driver returns it as `spent`. A refused build emits nothing and so adds nothing; the free dawn rebuild is not an event of this kind and adds nothing.
- `BalanceReport` run entries gain `military_gold_spent`, `tower_gold_spent`, `economy_gold_spent`, `unit_kills` and `tower_kills`; each strategy summary gains `unit_kills_per_military_gold`, `tower_kills_per_tower_gold` and `squad_value_ratio` (sums over the strategy's runs, zero guards); the markdown gains the "Squad value per gold" table. `build/playtest/report.json` carries all of it.
- Baseline measured on today's data (60 runs, seeds 1 to 10, `PLAYTEST_OK runs=60`):
  - balanced 90% (9 of 10), army_balanced 80% (8 of 10), night totals 5, 12, 21, 21, 25, 31, 39, 39 (night 8 equals night 7).
  - army_balanced: military gold mean 7.20, unit kills mean 29.10, 4.04 unit kills per military gold; tower gold mean 4.40, tower kills mean 26.10, 5.93 tower kills per tower gold; squad_value_ratio 0.68 (short of 0.8 by 0.12).
  - balanced: 7.28 tower kills per tower gold; houses_first 8.80; towers_first 12.86.
- The six-strategy win table is identical to the Round 1 "after the retune" table, as it must be with unchanged data and read-only columns.

## Task Commits

1. **Task 1 RED: failing tests for gold spent and kills per gold by role** - `2198d2b` (test)
2. **Task 1 GREEN: the balance report measures kills per gold by building role** - `77dadd2` (feat)
3. **Task 2: balance report Round 2 targets and baseline** - `c2e2659` (docs)

**Plan metadata:** the `docs(03-16): complete ...` commit that carries this file, STATE.md and ROADMAP.md.

## TDD Gate Compliance

RED: `2198d2b` carries 5 tests in `test_balance_value_metric.gd` over an inert skeleton (zeroed `spent`, summary keys at 0.0, run keys at 0). The run of `bash tools/test.sh -gselect=test_balance_value_metric.gd` gave 1 of 5 passing: the four target tests failed on assertions for the planned behaviour (role totals, kill totals, the 1.5 / 2.0 / 0.75 maths, the missing table); the one passing test is `test_a_refused_build_spends_nothing`, which holds on the zeroed skeleton by design and guards the green step. One further guard against a script error in the table test (an out-of-bounds read when the table was missing) was added before the commit, so every failure was an assertion. GREEN: `77dadd2`, 5 of 5 passing. No REFACTOR commit was needed.

## Files Created/Modified

- `tools/replay/replay_driver.gd` - `Tally.spent`, the `building_built` listener, the role classifier and the result key `spent`.
- `tools/replay/balance_report.gd` - run entry totals, the three summary keys, `_per_gold`, `_value_row`, the squad value table, class and method docs (including what the ratio cannot show).
- `tests/integration/test_balance_value_metric.gd` (+ `.uid`) - the five tests.
- `tests/integration/test_balance_report.gd` - RUN_KEYS and SUMMARY_KEYS extended; the summary-row test now counts only inside the "## Summary" section (see Deviations).
- `.planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md` - the Round 2 section above the Round 1 text, title extended to "plans 03-11 and 03-16".

## Decisions Made

- Roles are decided from the defs (a `unit_id` makes military, an attacking tier makes towers, the rest economy), not from building ids, so a data retune cannot silently misfile a building.
- Round 2's target 4 uses the exact phrase the plan asks for ("squad_value_ratio is at least 0.8 (provisional owner bar)") and also records that the owner confirmed 0.8 as D-26 in `03-CONTEXT.md` on 2026-10-13, so 03-17 reads it there.
- The ratio compares army_balanced's squads with army_balanced's own (small) tower spend; the report says plainly that the tower-first bots get more per tower gold (7.28 to 12.86) and that footmen shielding a tower earn no kill credit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The existing summary-row test counted rows of the new squad value table**
- **Found during:** Task 1 (GREEN, first run of `test_balance_report.gd`)
- **Issue:** `test_markdown_has_a_header_row_and_one_summary_row_per_strategy` counted every line starting `| Strategy |` or `| balanced |` in the whole markdown. The plan's required table repeats both, so the test saw 2 where it expected 1. The plan said "constants only" for this file and had not seen the clash.
- **Fix:** The test now counts only between the "## Summary" heading and the next "## " heading. The assertions and their messages are unchanged; no test function was added (the file stays at 19, one below the gdlint cap).
- **Files modified:** `tests/integration/test_balance_report.gd`
- **Verification:** `bash tools/test.sh -gselect=test_balance_report.gd` passed 19 of 19; the full suite passed.
- **Committed in:** `77dadd2`

---

**Total deviations:** 1 auto-fixed (1 bug in a dependent test)
**Impact on plan:** Necessary to keep the required table and the existing test compatible. No scope creep; the test asserts exactly what it did before.

## Issues Encountered

- The `playtest.sh` plan verify chains several steps; each was run and checked separately (metric suite, report suite, army_balanced `--seeds=2` with the JSON assertions, both golden replays, lint) and the full suite once at the end, rather than as one command. All passed.
- Checked, not changed: the free dawn rebuild is not counted as spend. If the owner wants rebuild value shown later, it would be a separate column.

## Verification Results

- `bash tools/test.sh` (own run): 150 scripts, 1389 tests, 1389 passing, 15576 asserts, exit 0, 538 s. Baseline was 149 scripts, 1384 tests; this plan adds 1 script and 5 tests. `test_balance_value_metric` and `test_balance_report` are both in the JUnit XML.
- `bash tools/lint.sh`: 264 files left unchanged, no problems (baseline 263 plus the new test).
- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`: `REPLAY_OK` digest `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`.
- `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json`: `REPLAY_OK` digest `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`.
- `bash tools/playtest.sh --strategies=army_balanced --seeds=2`: `PLAYTEST_OK runs=2`; report.json `squad_value_ratio` present, `unit_kills_per_military_gold` 3.0, run 1 `military_gold_spent` 4.
- `bash tools/playtest.sh --seeds=10`: `PLAYTEST_OK runs=60`, six summaries, army_balanced `squad_value_ratio` 0.68.
- `git diff --name-only f85a95f HEAD` shows nothing under `data/`, `simulation/` or `tests/golden/`.

## Known Stubs

None. No placeholder values flow to any output; zero values in the squad value table for bots that buy no squads are the documented zero guard, not a stub.

## Threat Flags

None. No new input, endpoint, file access or trust boundary: T-03-25 (the tally stays read-only) is proved by both goldens replaying unchanged, T-03-26 (no new CLI argument) holds, and no package was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-17 can retune against four numeric targets read from `03-BALANCE-REPORT.md` Round 2 and D-26 / D-27 in `03-CONTEXT.md`, with the bots reporting `squad_value_ratio` in `build/playtest/report.json`.
- Starting point for 03-17: balanced needs 2 to 3 more losses of 10 (9 wins now), army_balanced is in range (8) and must stay there, night 8 needs at least 40 enemies against night 7's 39 while towers_first already dies at about 40, and squad_value_ratio needs +0.12.
- Plan 03-18 publishes the result; G-03-11 stays open until both are done.

## Self-Check: PASSED

- Created files exist: `tests/integration/test_balance_value_metric.gd`, its `.uid`, and this SUMMARY.
- Commits exist: `2198d2b`, `77dadd2`, `c2e2659` (`git log --grep="03-16"`).
- Acceptance criteria: `building_built.connect` and `"spent"` in `tools/replay/replay_driver.gd`; `squad_value_ratio`, `unit_kills_per_military_gold`, `tower_kills_per_tower_gold` and `## Squad value per gold` in `tools/replay/balance_report.gd`; goldens unchanged; `## Round 2 (G-03-11)` above the Round 1 text, `### Baseline (today's data)`, and the line "squad_value_ratio is at least 0.8 (provisional owner bar)" in `03-BALANCE-REPORT.md`.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
