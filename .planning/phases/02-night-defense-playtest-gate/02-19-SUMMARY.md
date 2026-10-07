---
phase: 02-night-defense-playtest-gate
plan: 19
subsystem: balance-data
tags: [godot, gdscript, gut, night-data, balance, gap-closure, G-02-15]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: "02-17 castle tuning (22 m reach, 27 m/s) the lever was measured with; 02-16 round-2 balance pin this plan replaces"
provides:
  - "The owner's full wall in the shipped night data: night 2 opens the east road, nights 3 to 5 grow (totals 5, 12, 21, 21, 21, 22, 27, 33)"
  - "A night data contract that names every changed count of nights 2 to 5"
  - "Balance acceptance pins: balanced bot wins 7 or 8 of seeds 1 to 10, loses exactly seeds 3 and 9, never before night 3"
affects: [phase-02 gap closure, 02-20, playtest gate re-run]

actuals:
  tokens: 7000
  tasks: 2
  commits: 3
plan_head_before: e876e52841f5c1daafcbdb34f5c7d07c1264b797
plan_head_after: 7d2584ad1342e44db9deb7436905676ac562abfe

tech-stack:
  added: []
  patterns:
    - "Mutation probe in place of a RED commit when the data landed first (02-16 precedent)"

key-files:
  created: []
  modified:
    - data/maps/prototype_map.tres
    - tests/unit/test_night_data_contract.gd
    - tests/integration/test_balance_acceptance.gd

key-decisions:
  - "Wrote exactly the owner's measured k4pS5m edit and nothing else (grunt 6 hp, costs, incomes, castle numbers, skirmisher groups, nights 1 and 6 to 8 untouched)"
  - "Balanced bot is measured as its own ten-seed report so the other strategies keep their cheap seeds 1 to 3"

requirements-completed: [LOOP-02, LOOP-03, LOOP-07]

coverage:
  - id: D1
    description: "Shipped nights carry the owner's full-wall counts for nights 2 to 5 and per-night totals 5, 12, 21, 21, 21, 22, 27, 33"
    requirement: LOOP-02
    verification:
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_nights_two_to_five_carry_the_owner_s_round_three_counts"
        status: pass
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_the_per_night_totals_are_unchanged_by_the_ranged_type"
        status: pass
    human_judgment: false
  - id: D2
    description: "Balanced bot wins 7 or 8 of seeds 1 to 10 and loses exactly seeds 3 and 9 on night 3 or later; greedy, no_build, towers_first and grunt pins keep their D-10 shape"
    requirement: LOOP-07
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_balanced_wins_seven_or_eight_of_seeds_one_to_ten"
        status: pass
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three"
        status: pass
    human_judgment: false
  - id: D3
    description: "Whether the night-3 wall now feels like the right difficulty (the bots' numbers are not the owner's sign-off, D-18)"
    verification: []
    human_judgment: true
    rationale: "Difficulty feel is the owner's judgment; the bots only measure the data"

duration: 10min
completed: 2026-10-07
status: complete
---

# Phase 2 Plan 19: Round-3 Night Counts Summary

**Owner's full wall written into the shipped nights (night 2 gains an east grunt group of 4; nights 3 to 5 grow to 21 enemies), pinned by a counts contract and a balanced-bot acceptance test: 8 of 10 seeds won, seeds 3 and 9 lost on night 3.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-06T23:54:34Z
- **Completed:** 2026-10-07T00:04:58Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `data/maps/prototype_map.tres`: new `Resource_group_n2_east` (east grunt, count 4, start 2.0 s, interval 1.5 s) listed after the west group of night 2; counts n3 west 11 / east 10, n4 west 11 / east 7, n5 west 9 / east 8; `load_steps` 59 to 60. Nothing else changed (diff: 1 header line, one 7-line block plus blank line, one groups line, six count lines).
- `NIGHT_TOTALS` is now [5, 12, 21, 21, 21, 22, 27, 33]; new test `test_nights_two_to_five_carry_the_owner_s_round_three_counts` compares every (night, spawn point, enemy) sum with no missing and no extra pair and pins night 2's group order and the new group's timing. The file has 12 tests.
- `test_balanced_wins_every_run` is replaced by `test_balanced_wins_seven_or_eight_of_seeds_one_to_ten` and `test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three` (constants BALANCED_SEEDS, BALANCED_MIN_WINS 7, BALANCED_MAX_WINS 8, BALANCED_LOST_SEEDS [3, 9], BALANCED_FIRST_LOSS_NIGHT 3). The file has 8 tests.

## Measured result

- Balanced on seeds 1 to 10: 8 wins, lost seeds exactly [3, 9], each lost on night 3 or later (pin passes; the diagnosis measured night 3 for both). Matches the diagnosis.
- Greedy economy, no_build, towers_first (seeds 1 to 3) and the grunt 6 hp pin pass unchanged.
- Full suite: 829 tests in 95 scripts, all passing (827 before plus the new contract test and the second balanced test); lint clean (167 files).
- Smoke replay matches tests/golden/smoke.json: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`.
- full_idle (run with `--twice`): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`, exactly the diagnosis line.

## Mutation probes

1. Task 1: dropped `Resource_group_n2_east` from `Resource_night_2`'s groups (block left in place). Contract suite: 2 failing (totals `[5, 8, 21, ...]` vs `[5, 12, 21, ...]`; night 2 counts and group order), 10 passing. Restored; 12 of 12 pass.
2. Task 2: same drop. test_balance_acceptance: both balanced pins fail (10 wins outside 7 to 8; lost seeds `[]` vs `[3, 9]`), 6 pass. Restored byte-exact (`git diff --quiet`).

## Task Commits

1. **Task 1 RED:** `d9a1158` (test) - contract pins the round-three counts, failing on old data
2. **Task 1 GREEN:** `b89a40d` (feat) - the shipped nights carry the owner's full wall
3. **Task 2:** `7d2584a` (test) - balanced 7 or 8 of seeds 1 to 10, seeds 3 and 9, night 3 or later

**Plan metadata:** docs commit following this summary.

## Files Created/Modified
- `data/maps/prototype_map.tres` - the owner's full-wall night counts
- `tests/unit/test_night_data_contract.gd` - new totals, ROUND_THREE_COUNTS table and counts test
- `tests/integration/test_balance_acceptance.gd` - ten-seed balanced report and the two new balanced pins

## Decisions Made
- Exact owner edit only; no retune was needed because the measured shape equals the diagnosis.
- Balanced bot runs as a separate ten-seed report in `before_all` so the other strategies stay on seeds 1 to 3 (the acceptance suite still runs in about 14 s).

## Deviations from Plan

None - plan executed exactly as written. The working-tree test files were CRLF while the index is LF; edits were normalised to LF (the repo's `eol=lf` convention), no content effect.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- G-02-15 code and data side is closed; the owner's replay remains the real sign-off (D-18). Night 3 is a wall for House openings by the owner's choice.

## Self-Check: PASSED

- Modified files carry the changes (`Resource_group_n2_east`, `load_steps=60`, `BALANCED_LOST_SEEDS`, `[5, 12, 21, 21, 21, 22, 27, 33]`).
- Commits d9a1158, b89a40d, 7d2584a found in git log.
- `git log` over data/enemies, data/buildings, data/tuning, tests/golden, tests/fixtures since the RED commit prints nothing.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-07*
