---
phase: 02-night-defense-playtest-gate
plan: 16
subsystem: balance-and-playtest-gate
tags: [godot, balance, acceptance-test, playtest-gate, gap-closure, g-02-1]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-12 base dawn income, 02-13 sprint and night fast-forward, 02-14 results-screen spacing, 02-15 castle attack, 02-10 round-1 balance tuning and report
provides:
  - tests/integration/test_balance_acceptance.gd, the seeded (1 to 3) balance shape after the gap closure, 7 tests
  - 02-BALANCE-REPORT.md with a Round 2 section (measured on the new data, with the Kills castle column) beside the unchanged Round 1 tables
  - 02-PLAYTEST-GATE.md with a Round 2 owner packet (what changed per point, controls with Fast-forward, round-2 balance table, assumptions 12 to 15, round-2 decision prompt)
  - A fresh, launch-checked Windows export (build/windows/Duskhold.exe, 2026-10-06)
affects: [phase-2-verification, owner-playtest-gate]

requirements-completed: [LOOP-05, LOOP-07, DEV-05]

actuals:
  tokens: 6700
  tasks: 2
  commits: 2

plan_head_before: 25c2f02a8a92105ffcea2be2331ddb83bb45b566
plan_head_after: 4b091d11771c32bb9e3ae9d1ce6db89ef7d5fbe8

tech-stack:
  added: []
  patterns:
    - "A seeded acceptance test over BalanceReport.run pins the shape of every strategy, with the thresholds as named constants and a mutation probe (data fields zeroed) instead of a RED commit when the fix already landed"

key-files:
  created:
    - tests/integration/test_balance_acceptance.gd
    - tests/integration/test_balance_acceptance.gd.uid
  modified:
    - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
    - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md

key-decisions:
  - "No wave or castle-health change: the balanced bot won 10 of 10 on seeds 1 to 10, so the owner's rule (night-3 east 5 to 4, then castle 70 to 80, only if balanced loses) was never triggered; data/maps/prototype_map.tres and every other data file are untouched by this plan"
  - "Round 1 of the report and the packet are kept; Round 1 report headings sit one level deeper, and the packet says Round 2 wins where they disagree"

duration: 14 min
completed: 2026-10-06
---

# Phase 2 Plan 16: Re-measure balance and open the round-2 gate Summary

**After the base income, castle attack and sprint, the balanced bot wins 10 of 10 and the tower-first opening goes from 0 of 10 to 10 of 10, so no wave or castle number was touched; the shape is pinned by a seeded acceptance test, the report has Round 2 beside Round 1, and the owner has a fresh export and a round-2 packet to replay and decide on.**

## Performance

- **Duration:** 14 min (2026-10-06T13:54:17Z to about 2026-10-06T14:09Z)
- **Tasks:** 2
- **Files:** 4 (2 created including the .uid, 2 modified)
- **Tests:** 817 passing in 94 scripts (810 baseline plus 7 new), lint clean

## Levers applied

**None.** `bash tools/playtest.sh` (five strategies, seeds 1 to 10, `PLAYTEST_OK runs=50`) showed `balanced` winning every run, so under the owner's rule night-3 east stays 5 grunts, `castle_max_health` stays 70, and grunt `max_health` stays 6. Costs, House incomes, the base income and the starting gold were not touched either. `git diff` of `data/` for this plan is empty.

## Measured balance (seeds 1 to 10, round 2 against round 1)

| Strategy | Round 2 win rate | Round 2 nights (mean/min/max) | Median loss night | Gold earned (mean) | Round 1 win rate / gold |
|---|---:|---:|---:|---:|---|
| no_build | 0% | 0.3 / 0 / 1 | 1 | 0.3 | 0% / 0.0 |
| greedy_economy | 0% | 4.0 / 4 / 4 | 5 | 15.0 | 0% / 8.5 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 31.0 | 100% / 18.0 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 0% / 0.0 |
| balanced | 100% | 8.0 / 8 / 8 | - | 28.0 | 100% / 18.0 |

Balanced loses no buildings and is never knocked out (round 1: 4.8 buildings, 1.4 knockouts). The castle attack kills nothing for balanced (0 in every night of its table); it kills 3.8 of the 5 night-1 enemies for `no_build`, which still loses. For the owner this means the game is much easier for the bots; whether it is "a bit easier" or too easy for a human is flagged in the packet as the owner's call. The prohibitions forbid changing anything else here.

## Accomplishments

- Task 1: `test_balance_acceptance.gd` (seeds 1 to 3; balanced wins all; greedy_economy loses every run on a night from 3 to 6; no_build survives at most 2 nights; towers_first earns gold in every run and wins at least 2; grunt max_health 6), a regenerated `02-BALANCE-REPORT.md` with `## Round 2 (gap closure G-02-1, 2026-10-06)` above `## Round 1 (plan 02-10)`, including the acceptance table, round-2 summary, balanced and towers_first per-night tables with Kills castle.
- Task 2: all 15 screenshots saved on the new data and the shot-list guard passes (no scenario needed changing), a fresh export launch-checked, and the Round 2 section of `02-PLAYTEST-GATE.md` with the round-2 balance table copied verbatim from the report (checked by string comparison of the five rows).

## Task Commits

1. **Task 1:** `07414dd` - test(02-16): pin the seeded balance shape and add the round-2 balance report
2. **Task 2:** `4b091d1` - docs(02-16): open the round-2 playtest gate for the owner

(No RED commit for Task 1: the fixes it guards had already landed, so a mutation probe stands in, as the plan directs.)

## Mutation probe (Task 1)

With `base_dawn_income = 0` and `castle_attack_damage = 0` set in `data/maps/prototype_map.tres`, `bash tools/test.sh -gselect=test_balance_acceptance.gd` gave 5 of 7 passing; `test_towers_first_earns_gold_in_every_run` failed on all three seeds (`[0.0] expected to be > than [0.0]: towers_first earned gold on seed N`) and `test_towers_first_wins_at_least_two_of_three` failed (`[0] expected to be >= than [2]`). The file was restored with `git checkout -- data/maps/prototype_map.tres` and `git diff --quiet` confirmed it identical; the test then passed 7 of 7.

## Verification results

- `bash tools/playtest.sh`: `PLAYTEST_OK runs=50`.
- `bash tools/test.sh`: 817 tests, 94 scripts, all passing; `test_balance_acceptance`, `test_every_night_ends` and `test_king_sturdiness` are in `build/test-results/gut-junit.xml`.
- `bash tools/lint.sh`: 166 files unchanged, no problems.
- Smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`, equal to `tests/golden/smoke.json` (unchanged).
- **Final full_idle:** `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` (both runs agree; identical to the post-02-13 value, as expected since no data changed).
- `grep "max_health = 6" data/enemies/grunt.tres` matches.
- Screenshots: `rm -f screenshots/*.png && bash tools/screenshot.sh` saved 15 of 15 in a real window (RTX 3060, Forward+); `bash tools/test.sh -gselect=test_shot_list.gd` 5 of 5 passing.
- Export: `bash tools/export.sh` printed `Export OK: .../build/windows/Duskhold.exe` (exe and pck dated 2026-10-06); `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exited 0 in 1.7 s.

## Screenshot review (read with the Read tool)

- `results_victory`: "Victory", Nights survived 1 of 1, four stat rows, Play again (outlined) and Quit; the gap from the last stat row to the buttons looks even with the gaps between rows. Pass.
- `results_defeat`: "Defeat", Nights survived 0 of 8, same layout and even spacing, collapsed castle and grunts dimmed behind the panel. Pass.
- `night_combat`: Night 5 of 8, 16 enemies left, red grunts and violet skirmishers by the west tower, one arrow in flight, king beside the castle; no gold castle arrow in frame (nothing comes within 11 m under the shot's bot). Pass.
- `building_destroyed`: Night 3, 4 enemies left, a fallen House as dark slabs on its pale disc, grunts with health bars, the king's bar, "+14 gold" line. Pass.
- `dawn_payout`: Dawn, Gold 23, four gold coins in flight around the castle and the two House plots; a still frame cannot show which one is the castle's base coin (left to the owner's replay). Pass.

## Deviations from Plan

None - plan executed exactly as written. The data-lever branch and the tools/screenshot/shot_scenarios.gd branch were both conditional and neither triggered. One small judgment: the Round 1 report headings were demoted one level to nest under `## Round 1`, and the Round 1 export-date line in the packet was left as is with a note at the end of Round 2 that Round 2 wins where they disagree.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. T-02-35 (the disclaimer that bot numbers are not the owner's sign-off is kept in the report header and the packet; the decision is recorded only through /gsd-verify-work) and T-02-36 (no data change, grunt hp pinned at 6 by the new test) are mitigated.

## Open for the owner

The owner's round-2 replay and decision (ROADMAP success criterion 4, D-18) is the one open item; nothing here is their sign-off. Judge in particular whether the run is now too easy: the balanced bot loses nothing and is never knocked out, though a human plays worse than a bot.

## Next

Phase 2 gap-closure plans 02-12 to 02-16 are all done; ready for the owner's round-2 decision through `/gsd-verify-work`.

## Self-Check: PASSED

- `tests/integration/test_balance_acceptance.gd` and its `.uid` exist; `02-BALANCE-REPORT.md` contains `## Round 2`, `## Round 1`, `Kills castle`; `02-PLAYTEST-GATE.md` contains `## Round 2`, `Fast-forward`, `base income`, `Your decision (round 2)`.
- Commits `07414dd` and `4b091d1` are on `gsd/phase-01-foundation-day-loop`; `git rev-list --count 25c2f02..HEAD` was 2 at SUMMARY time.
- All acceptance criteria of both tasks re-run and passing as listed under Verification results.
