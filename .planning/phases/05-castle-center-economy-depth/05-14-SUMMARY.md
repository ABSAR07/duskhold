---
phase: 05-castle-center-economy-depth
plan: 14
subsystem: balance-data
tags: [x100-rescale, shipped-data, tres, gap-closure, G-05-2, balance-acceptance, full_idle, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plan 05-13: the ten fighter, tower, Shrine and castle files at x100; the owner's 2026-10-25 x100 decision on UAT G-05-2"
provides:
  - "The shipped data complete at the x100 health and damage scale: all 19 files (05-13's ten plus walls, Houses, Barracks, Archery Range, Field, Gold Mine, Mill, Fishing Harbor, Royal Training's flat king damage)"
  - "The Phase 2 bar re-measured on the scaled game with only GRUNT_MAX_HEALTH re-pinned (6 to 600)"
  - "full_idle of the scaled game: won, 7000 ticks, digest cec3eb71"
affects: [05-15, 05-16, 05-17, 05-18, 05-19, 05-20, 05-21, 05-22, 05-23, 05-24]

actuals:
  tokens: 1100
  tasks: 2
  commits: 2

plan_head_before: 75c8176d8bf1a7f256549d90cc2ae1258119ed3a
plan_head_after: 7c8a516c64eb5602861a97c0e7809da2949b90f1

tech-stack:
  added: []
  patterns:
    - "Exact-x100 check: rebuild each .tres from git show ce3fcea:<file> with only six field names multiplied (awk), diff against the working file; now run over eighteen files"

key-files:
  created: []
  modified:
    - data/buildings/wall.tres
    - data/buildings/house.tres
    - data/buildings/barracks.tres
    - data/buildings/archery_range.tres
    - data/buildings/field.tres
    - data/buildings/gold_mine.tres
    - data/buildings/mill.tres
    - data/buildings/fishing_harbor.tres
    - data/abilities/royal_training.tres
    - tests/integration/test_balance_acceptance.gd

key-decisions:
  - "Followed the owner's locked G-05-2 decision: every health and damage number x100, gold untouched, StatStack untouched (D-15); Royal Training's one flat value +1 became +100, its +25% king health and every percent or multiplier card unchanged"
  - "Only GRUNT_MAX_HEALTH moved in the balance test (6 to 600); the bar, lost seeds, earliest castle day and every other pin stand, and the bots met them on the first run"
  - "Task 1 tracer verify (exact-x100 over fifteen files, test_prototype_map_data 20 of 20) was automated-only, so the plan auto-continued into Task 2"

patterns-established:
  - "The scaled game replays deterministically: full_idle after the flip is cec3eb71, the planner's scratch-copy digest, and the four frozen goldens do not see the shipped numbers"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Walls, Houses, Barracks, Archery Range and Field at 100 times their ce3fcea health, every other line byte-identical, loaded through the shipped map"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild from git show ce3fcea:<file> over fifteen files (empty diff each)"
        status: pass
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_prototype_map_data (20 of 20)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Gold Mine, Mill and Fishing Harbor at x100 and Royal Training's flat king damage +100; the other eleven cards unchanged"
    requirement: "META-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild over eighteen files; git diff -U0 ce3fcea -- data/abilities/royal_training.tres is exactly -value = 1 / +value = 100; git diff --quiet on the eleven other cards"
        status: pass
    human_judgment: false
  - id: D3
    description: "The bots play the whole scaled game to the unchanged Phase 2 bar with only the grunt pin moved to 600"
    requirement: "META-08"
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd (17 of 17, 87 asserts)"
        status: pass
    human_judgment: false
  - id: D4
    description: "full_idle replays twice to won in 7000 ticks at the planner's digest and the four goldens replay byte-identical"
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=full_idle --twice; --scenario=smoke|army|walls|economy --twice --expect-file=tests/golden/<s>.json"
        status: pass
    human_judgment: false

duration: 8 min
completed: 2026-10-25
status: complete
---

# Phase 05 Plan 14: x100 flip completed and the scaled game proven end to end Summary

**The last nine shipped data files (walls, Houses, Barracks, Archery Range, Field, Gold Mine, Mill, Fishing Harbor and Royal Training's flat king damage) moved to the owner's x100 scale, and the whole scaled game then passed the unchanged Phase 2 bar with one health pin re-pinned (grunt 6 to 600), replayed full_idle to cec3eb71 and left all four frozen goldens byte-identical.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-25T11:51:48Z
- **Completed:** 2026-10-25T11:59:29Z (code), SUMMARY follows
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Task 1 (tracer): walls, Houses, Barracks, Archery Range and Fields at x100, checked line by line over fifteen data files and loaded through the shipped map (test_prototype_map_data 20 of 20).
- Task 2: Gold Mine, Mill, Fishing Harbor and Royal Training at x100; test_balance_acceptance re-pinned on GRUNT_MAX_HEALTH only and passing 17 of 17 on the first run; full_idle and the four goldens replayed.
- The shipped data is now complete at the x100 scale (all 19 files). The planner's 70 failing tests, which plans 05-15 to 05-20 fix, remain red by design (fixtures, stress data, other pins and HUD are not yet re-pinned); the full suite is plan 05-24's and was not run here.

## Numbers changed (old to new)

| File | Field | Old | New |
|------|-------|-----|-----|
| data/buildings/wall.tres | max_health (3 tiers) | 30 / 60 / 90 | 3000 / 6000 / 9000 |
| data/buildings/house.tres | max_health | 12 / 18 / 24 | 1200 / 1800 / 2400 |
| data/buildings/barracks.tres | max_health | 40 / 60 / 80 | 4000 / 6000 / 8000 |
| data/buildings/archery_range.tres | max_health | 40 / 60 / 80 | 4000 / 6000 / 8000 |
| data/buildings/field.tres | max_health | 8 | 800 |
| data/buildings/gold_mine.tres | max_health | 20 | 2000 |
| data/buildings/mill.tres | max_health | 15 / 20 / 25 | 1500 / 2000 / 2500 |
| data/buildings/fishing_harbor.tres | max_health | 18 / 24 | 1800 / 2400 (plan 05-22 lowers it later, not here) |
| data/abilities/royal_training.tres | king.attack_damage FLAT value | 1 | 100 (king.max_health PERCENT 25 stays) |
| tests/integration/test_balance_acceptance.gd | GRUNT_MAX_HEALTH | 6 | 600 |
| tests/integration/test_balance_acceptance.gd | test_the_grunt_still_has_six_hp | six hp, message "the owner ruled out 5 hp (one-shot by the king)" | test_the_grunt_still_has_six_hundred_hp, message "the owner ruled out 500 hp (one-shot by the king's 500)" |

No cost, income, squad size, respawn time, requirement, body radius, tier count, gold number, percent or multiplier card moved.

## Verification results

Exact-x100 check (the plan's awk rebuild from `git show ce3fcea:<file>`, carriage returns ignored), printed `EXACT_X100` with an empty diff for all eighteen files: data/king/king.tres, data/king/sword.tres, data/units/footman.tres, data/units/archer.tres, data/enemies/grunt.tres, data/enemies/ranged.tres, data/buildings/tower.tres, shrine.tres, castle_center.tres, data/maps/prototype_map.tres, wall.tres, house.tres, barracks.tres, archery_range.tres, field.tres, gold_mine.tres, mill.tres, fishing_harbor.tres (after Task 1 the first fifteen, after Task 2 all eighteen).

Royal Training: `git diff -U0 ce3fcea -- data/abilities/royal_training.tres` shows exactly `-value = 1` / `+value = 100` (line 16, the king.attack_damage FLAT modifier); `value = 25` on king.max_health stays. `git diff --quiet ce3fcea` over the eleven other cards (commander, masons, prosperity, headsmans_edge, engineers, war_horns, warded_mail, iron_discipline, arrow_storm, master_builders, golden_age) and over `simulation native presentation ui tools tests/golden tests/fixtures tests/unit tests/e2e` exits 0. The only test file changed is tests/integration/test_balance_acceptance.gd (14 insertions, 4 deletions).

`bash tools/test.sh -gselect=test_prototype_map_data`: 1 script, 20 tests, 20 passing, 113 asserts, exit 0 (after Task 1; suite present in the JUnit XML).

`bash tools/test.sh -gselect=test_balance_acceptance` (after Task 2, own run log build/exec05-14_balance.log): 1 script, 17 tests, 17 passing, 87 asserts, 132.5 s, exit 0; suite present in the JUnit XML. Because every pin passed, the bots measured the pre-round numbers on the scaled game: balanced 8 of 10 seeds with seeds 3 and 9 lost (BALANCED_LOST_SEEDS [3, 9], first loss night 3), army_balanced 8 of 10 with seeds 1 and 9 lost (ARMY_BALANCED_LOST_SEEDS [1, 9]), the shipped castle's earliest day 6 (SHIPPED_EARLIEST_CASTLE_DAY), the castle-aware bot never buying it before day 2, the no-castle and no-walls twins on their pinned lost seeds, greedy economy losing on nights 3 to 5, no_build surviving at most 2 nights, towers_first surviving at least 6 nights, and the squad value ratio above SQUAD_VALUE_BAR 0.8. The test prints no per-strategy numbers, so the exact figures (gold earned 30.0, ratio 0.88) are the planner's scratch-copy measurements, which the passing pins are consistent with; plan 05-23 re-measures with playtest.sh and reports them.

Replays (all `--twice`, exit 0):

- full_idle before the round (05-BALANCE-REPORT.md): outcome=won ticks=7000 digest=afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14
- full_idle after the flip: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=7000 digest=cec3eb7182baddc2d2215916f624759510c911bfec64ed249c4ef375189b40e9` (identical to the planner's scratch copy; no unexplained difference)
- smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- army: `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- walls: `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
- economy: `REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97`

The four goldens read 2599c7c2, f7a967ed, bfb05fc7 and f4b98093, unchanged (D-08 stop rule not triggered). `bash tools/lint.sh` exit 0 (446 files unchanged, no problems), run after the test edit and again after all replays. Per-task acceptance greps (max_health values per file, value = 100 and value = 25 on Royal Training, GRUNT_MAX_HEALTH: int = 600, test_the_grunt_still_has_six_hundred_hp, "Gap round G-05-2", every bar and lost-seed constant still at its old value) all hold; the constants list read back from the file shows BALANCED_MIN_WINS 7, BALANCED_MAX_WINS 8, ARMY_BALANCED_MIN_WINS 7, ARMY_BALANCED_MAX_WINS 8, SQUAD_VALUE_BAR 0.8, BALANCED_LOST_SEEDS [3, 9], ARMY_BALANCED_LOST_SEEDS [1, 9].

## Task Commits

1. **Task 1: walls, Houses, Barracks, Archery Range and Field at x100 (tracer)** - `4bf10e9` (feat)
2. **Task 2: economy buildings and Royal Training at x100, balance pin on the 600 hp grunt** - `7c8a516` (feat)

**Plan metadata:** recorded in the docs(05-14) commit that follows this summary.

## Files Created/Modified

- `data/buildings/wall.tres`, `house.tres`, `barracks.tres`, `archery_range.tres`, `field.tres` - health lines x100 (Task 1)
- `data/buildings/gold_mine.tres`, `mill.tres`, `fishing_harbor.tres` - health lines x100 (Task 2)
- `data/abilities/royal_training.tres` - flat king damage +1 became +100
- `tests/integration/test_balance_acceptance.gd` - GRUNT_MAX_HEALTH 600, renamed grunt test, one header sentence and the gap-round header paragraph

## Decisions Made

None beyond following the plan and the owner's locked G-05-2 decision.

## Deviations from Plan

None - plan executed exactly as written.

Note (not a deviation): the planner's 05-14.diff and this plan agree on every data line (the sorted changed lines of the nine data files and the GRUNT_MAX_HEALTH line match); the diff carries no header paragraph or test rename, which the plan adds, so the plan won there. The Task 1 tracer verify ran in automated-only mode, so no human stop occurred (human_verify_mode end-of-phase).

## Issues Encountered

None. The balance test did not print per-strategy numbers, so its figures are inferred from the passing pins (see Verification results).

## Known Stubs

None (data and one test pin only).

## Threat Flags

None (no new surface). T-05-27 is mitigated by recording full_idle before (afc11cd0) and after (cec3eb71) here and leaving the pins other than the grunt's untouched; T-05-28 by the exact-x100 check over all eighteen files, Royal Training's one-line diff and the eleven unchanged cards.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 05-15 and the later fix plans: the shipped data is at the x100 scale end to end, and the tests, fixtures and stress data outside this plan's file list are still at the old scale (red by design until plan 05-20). full_idle stays at cec3eb71 until plan 05-22 (the Harbor move) moves it again by design; plan 05-23 reports it.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*

## Self-Check: PASSED

All ten modified files exist with the x100 numbers; commits 4bf10e9 and 7c8a516 exist on gsd/phase-01-foundation-day-loop; plan commit count measured 2 from the ledger (75c8176 to 7c8a516).
