---
phase: 03-king-combat-troops
plan: 17
subsystem: testing
tags: [godot, gdscript, balance, retune, tower-data, night-data, gap-closure, tdd, playtest-bot]
gap_closure: true
gap_ids: [G-03-11]

requires:
  - phase: 03-king-combat-troops
    provides: "03-16 squad_value_ratio and the Round 2 targets and baseline; 03-11 army_balanced bot and the first night retune; 03-CONTEXT D-26 (bar 0.8) and D-27 (all four goals at once)"
provides:
  - "Outcome (a): a candidate inside the allowed levers meets all four owner goals at once and is pinned in the shipped data: tower tier 1 attack_interval 0.8 -> 0.9 s and the north road of night 8 11 grunts (was 10)"
  - "The four goals as tests: test_the_balanced_bot_wins_seven_or_eight_of_ten_seeds, test_squads_are_worth_their_gold_against_towers (SQUAD_VALUE_BAR 0.8, D-26), test_the_last_night_is_larger_than_the_night_before, test_nights_one_to_four_keep_the_phase_two_wall"
  - "The full search log (29 measured candidates plus the baseline), the levers ruled out, the full_idle digest before and after, for plan 03-18 to publish"
affects: [03-18]

requirements-completed: [UNIT-04, UNIT-07, KING-04, KING-05]

actuals:
  tokens: 4244
  tasks: 2
  commits: 2

plan_head_before: b9c0d3d89d81777357b8d2246a6db7398e313929
plan_head_after: ef56a1e697e1e5237a20e82751031467262c84b8
commits: 2

tech-stack:
  added: []
  patterns:
    - "Balance search by a scratch helper that runs each candidate in its own copy of the project (the repository's data files are never edited during the search)"
    - "A pin whose goal can no longer be met under the bots (towers_first wins) is re-pinned as nights survived with the old pin and the reason in the header comment, keeping the assertion shape"

key-files:
  created: []
  modified:
    - data/buildings/tower.tres
    - data/maps/prototype_map.tres
    - tests/integration/test_balance_acceptance.gd
    - tests/unit/test_night_data_contract.gd
    - tests/unit/test_military_data_contract.gd

key-decisions:
  - "Outcome (a): tower tier 1 interval 0.8 -> 0.9 s plus night 8 north grunts 10 -> 11 is the fewest-values candidate that meets all four goals (balanced 8, army_balanced 8, squad_value_ratio 0.915, night 8 = 40 above night 7 = 39)"
  - "SQUAD_VALUE_BAR stays the owner's 0.8 (D-26); no override exists, no amendment was written"
  - "towers_first no longer wins any pinned seed: its pin moved from 'wins at least two of three' to 'survives at least six nights on every seed' and the loss is reported as a finding for the owner"

patterns-established:
  - "Search rows are recorded in the SUMMARY because the scratch directory does not outlive the session"

coverage:
  - id: D1
    description: "The balanced (tower-heavy, no army) bot wins 7 or 8 of seeds 1 to 10 on the shipped data (8 now, seeds 3 and 9 lost)"
    requirement: "KING-05"
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_the_balanced_bot_wins_seven_or_eight_of_ten_seeds"
        status: pass
    human_judgment: false
  - id: D2
    description: "army_balanced keeps 7 or 8 wins (8) and its squad_value_ratio is 0.915, at least the owner's bar 0.8 (D-26)"
    requirement: "UNIT-07"
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_squads_are_worth_their_gold_against_towers"
        status: pass
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_the_army_building_bot_wins_seven_or_eight_of_ten_seeds"
        status: pass
    human_judgment: false
  - id: D3
    description: "Night 8 holds 40 enemies, above night 7's 39; totals never decrease; nights 1 to 4 keep the Phase 2 wall; MapConfig.validate() is clean"
    requirement: "UNIT-04"
    verification:
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_the_last_night_is_larger_than_the_night_before"
        status: pass
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_nights_one_to_four_keep_the_phase_two_wall"
        status: pass
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd#test_every_night_stays_under_the_per_night_enemy_cap_and_the_map_validates"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every number Round 2 moved is pinned old to new; the locked numbers (squad sizes, replacements, footman, king) are unchanged"
    requirement: "KING-04"
    verification:
      - kind: unit
        ref: "tests/unit/test_military_data_contract.gd#test_round_two_slowed_the_first_tower_tier_and_nothing_else_of_the_tower"
        status: pass
    human_judgment: false
  - id: D5
    description: "The smoke and army goldens are byte-identical and replay to their committed digests; full_idle replays twice to one digest"
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json; bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json; bash tools/replay.sh --scenario=full_idle --twice"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether the retuned data feels right: a tower route that no longer wins under the bot (towers_first 0 of 10, houses_first 9 -> 4 of 10) and tower tier 1 firing every 0.9 s"
    verification: []
    human_judgment: true
    rationale: "The bots measure the data, not feel (D-08, Phase 2 D-18); the owner judges whether the tower opening still feels rewarding at the gate (test 15)."

duration: 61min
completed: 2026-10-13
status: complete
---

# Phase 3 Plan 17: Round 2 balance retune Summary

**Outcome (a): all four of the owner's balance goals are met inside the allowed levers by two changed numbers, tower tier 1 firing every 0.9 s (was 0.8 s) and 11 grunts on night 8's north road (was 10): the balanced bot wins 8 of 10, army_balanced wins 8 of 10 at a squad_value_ratio of 0.915 (bar 0.8, D-26), and night 8 holds 40 enemies against night 7's 39.**

G-03-11 closes only together with plan 03-18, which publishes Round 2 from this file. Outcome (b) was not needed; it would have been a successful execution of this plan, not a failure.

## Performance

- **Duration:** 61 min
- **Started:** 2026-10-13T17:57:00Z (approximate: no start stamp was taken; the first measured command ran at 18:01:59Z)
- **Completed:** 2026-10-13T18:58:00Z (SUMMARY commit follows the last task commit at 18:57Z)
- **Tasks:** 2
- **Files modified:** 5 (2 data, 3 tests)

## Outcome

**(a) all four targets met inside the allowed levers.** No locked value (D-01 squad sizes, D-05 replacements, D-07 footman, the king's numbers, starting gold or income) moved, so no owner decision hand-back and no D-26 amendment were needed. The squad-value bar used is **0.8, the owner's bar confirmed as D-26 on 2026-10-13** (no override exists in 03-CONTEXT.md).

Measured on the shipped data, seeds 1 to 10, by `bash tools/playtest.sh --seeds=10` (`PLAYTEST_OK runs=60`):

| Goal | Target | Before (03-16 baseline) | After |
|---|---|---|---|
| 1 Balanced bot loses 2 or 3 of 10 | 7 or 8 wins | 9 wins (seed 9 lost) | **8 wins** (seed 3 lost on night 8, seed 9 on night 3) |
| 2 Army bot loses 2 or 3 of 10 | 7 or 8 wins | 8 wins | **8 wins** (seed 1 lost on night 7, seed 9 on night 6) |
| 3 Night 8 larger than night 7 | strictly above | 39 and 39 | **40 and 39** |
| 4 Squad value | ratio at least 0.8 | 0.681 (4.04 / 5.93) | **0.915** (4.31 unit kills per military gold / 4.70 tower kills per tower gold) |

Six-strategy table after the retune (win rate, seeds 1 to 10): no_build 0%, greedy_economy 0%, houses_first 40% (was 90%), towers_first 0% (was 30%), balanced 80% (was 90%), army_balanced 80% (unchanged).

### Findings for the owner (plan 03-18 publishes them)

- **towers_first no longer wins any seed** (0 of 10; it was 3 of 10, and 2 of its 3 pinned seeds). It falls on night 7 on seeds 1 to 3 (6 nights survived) and on night 8 on seed 8. The pinned test moved from "wins at least two of three" to "survives at least six nights on every pinned seed". The plan allows this when the data cannot keep a win; 29 candidates were searched and none that met the four goals left the pure tower opening a win (see the search log: every tower-shot nerf that moved the balanced bot also moved towers_first to 0; the candidates that kept towers_first wins, c13, c20, c27, left the balanced bot at 9 or 10).
- **houses_first went from 9 wins to 4** (the same slower tier 1 hurts every tower-heavy route); balanced lost one seed as intended, houses_first lost five.
- The bots build without riding to plots and react perfectly; these are measurements of the data, not of feel (D-08).

## Accomplishments

- Task 1: the four goals as tests, red on today's data for the right reasons (three assertion failures: balanced 9 wins outside 7 to 8; ratio 0.681 under 0.8; night 8 39 not above 39) and the Phase 2 wall snapshot green.
- Task 2: a 29-candidate search over the allowed levers using a scratch helper that ran each candidate in a private copy of the project, five candidates in parallel per call; the winning candidate applied, every pin re-measured and moved on purpose, the full suite, both goldens and the lint green.

## Task Commits

1. **Task 1: the owner's four balance goals as failing tests** - `c935dcf` (test)
2. **Task 2: Round 2 balance retune for squads and towers** - `ef56a1e` (feat)

**Plan metadata:** the `docs(03-17): complete ...` commit that carries this file, STATE.md and ROADMAP.md.

## TDD Gate Compliance

- **RED** (`c935dcf`): `bash tools/test.sh -gselect=test_night_data_contract.gd` gave 15 of 16 passing; the failing test is `test_the_last_night_is_larger_than_the_night_before` ("expected to be > than [39]: night 8 (39 enemies) is larger than night 7 (39)"). `bash tools/test.sh -gselect=test_balance_acceptance.gd` gave 10 of 12 passing; the failing tests are `test_the_balanced_bot_wins_seven_or_eight_of_ten_seeds` ("[9] expected to be between [7] and [8] ... lost seeds [9]") and `test_squads_are_worth_their_gold_against_towers` ("[0.681] expected to be >= than [0.8] ... unit kills per military gold 4.04, tower kills per tower gold 5.93"). Today's data therefore did NOT already pass the squad bar. `test_nights_one_to_four_keep_the_phase_two_wall` passed on today's data and keeps passing. Every failure was an assertion, not a script error.
- **GREEN** (`ef56a1e`): all four goal tests pass; the suite is green (below). No REFACTOR commit was needed.

## The search

Every measured candidate is one row. Columns: wins of balanced, army_balanced and towers_first over seeds 1 to 10 (the number in brackets is towers_first's wins on its pinned seeds 1 to 3), army_balanced's squad_value_ratio (unit kills per military gold / tower kills per tower gold) and the night 5 to 8 totals. Every candidate is on top of the committed data; "T1" is tower tier 1, "T2" tower tier 2. Run time per batch of five: about 3.5 minutes.

| Row | Values changed (old to new) | bal | army | tf | ratio | Nights 5-8 |
|---|---|---:|---:|---:|---:|---|
| baseline | none (committed data) | 9 | 8 | 3 (2) | 0.681 (4.04/5.93) | 25 31 39 39 |
| c01 | footman attack_interval 0.6 to 0.5 | 9 | 9 | 3 (2) | 0.648 | 25 31 39 39 |
| c02 | footman attack_interval 0.6 to 0.5; archer attack_interval 0.9 to 0.75 | 9 | 9 | 3 (2) | 0.658 | 25 31 39 39 |
| c03 | Barracks and Archery Range tier 1 cost 4 to 3 | 9 | 10 | 3 (2) | 0.633 | 25 31 39 39 |
| c04 | archer attack_range 8.5 to 10.0 | 9 | 8 | 3 (2) | 0.679 | 25 31 39 39 |
| c05 | tower T1 cost 4 to 5 | 8 | 2 | 1 (1) | 0.978 | 25 31 39 39 |
| c06 | tower T2 cost 6 to 8 | 9 | 8 | 3 (2) | 0.681 | 25 31 39 39 |
| c07 | tower T2 attack_damage 6 to 5 | 9 | 8 | 3 (2) | 0.681 | 25 31 39 39 |
| c08 | tower T1 attack_interval 0.8 to 1.0 | 4 | 6 | 0 (0) | 1.202 | 25 31 39 39 |
| c09 | tower T1 cost 4 to 5; T2 cost 6 to 7 | 8 | 2 | 1 (1) | 0.978 | 25 31 39 39 |
| c10 | tower T1 attack_interval 0.8 to 0.9 | 8 | 8 | 0 (0) | 0.895 (4.21/4.70) | 25 31 39 39 |
| c11 | tower T1 attack_interval 0.8 to 0.85 | 9 | 8 | 0 (0) | 0.792 | 25 31 39 39 |
| c12 | tower T1 attack_interval 0.8 to 0.95 | 6 | 4 | 0 (0) | 1.183 | 25 31 39 39 |
| c13 | tower T1 attack_range 9.0 to 8.0 | 9 | 8 | 3 (1) | 0.668 | 25 31 39 39 |
| c14 | tower T1 max_health 50 to 40 | 9 | 7 | 0 (0) | 0.882 | 25 31 39 39 |
| **c15** | **tower T1 attack_interval 0.8 to 0.9; night 8 north grunts 10 to 11** | **8** | **8** | **0 (0)** | **0.915 (4.31/4.70)** | **25 31 39 40** |
| c16 | c10 and night 8 grunts 10 to 11 on west, east and north | 8 | 8 | 0 (0) | 0.954 | 25 31 39 42 |
| c17 | c10 and night 8 north ranged 3 to 4 | 8 | 8 | 0 (0) | 0.905 | 25 31 39 40 |
| c18 | c10 and tower T1 attack_range 9.0 to 10.0 | 9 | 7 | 0 (0) | 0.876 | 25 31 39 39 |
| c19 | c10 and night 7 north grunts 10 to 9 | 8 | 9 | 0 (0) | 0.868 | 25 31 38 39 |
| c20 | king regen_delay_seconds 1.0 to 1.5 | 9 | 8 | 3 (2) | 0.700 | 25 31 39 39 |
| c21 | king regen_fraction_per_second 0.1 to 0.07 | 9 | 9 | 2 (1) | 0.669 | 25 31 39 39 |
| c22 | king regen_delay_seconds 1.0 to 2.0 | 9 | 8 | 2 (1) | 0.693 | 25 31 39 39 |
| c23 | tower T1 attack_interval 0.8 to 0.85; T1 max_health 50 to 60 | 9 | 9 | 3 (2) | 0.607 | 25 31 39 39 |
| c24 | tower T1 attack_interval 0.8 to 0.9; T1 max_health 50 to 60 | 9 | 8 | 0 (0) | 0.697 | 25 31 39 39 |
| c25 | c15 and tower T1 projectile_speed 18 to 24 | 8 | 6 | 0 (0) | 1.013 | 25 31 39 40 |
| c26 | tower T1 attack_interval 0.8 to 0.88; night 8 north grunts 10 to 11 | 8 | 8 | 0 (0) | 0.915 | 25 31 39 40 |
| c27 | tower T1 attack_interval 0.8 to 0.9; T1 cost 4 to 3; night 8 north grunts 10 to 11 | 10 | 8 | 3 (0) | 0.710 | 25 31 39 40 |
| c28 | tower T1 attack_interval 0.8 to 1.0; T1 cost 4 to 3; night 8 north grunts 10 to 11 | 10 | 7 | 0 (0) | 0.838 | 25 31 39 40 |
| c29 | tower T1 attack_interval 0.8 to 0.9; T1 attack_range 9.0 to 9.5; night 8 north grunts 10 to 11 | 8 | 6 | 0 (0) | 0.984 | 25 31 39 40 |

29 measured candidates (c01 to c29) of the 30 allowed, plus the baseline sanity row (it matches the 03-16 baseline exactly: 9, 8, 3 (2), 0.681). c15 was chosen: it moves the fewest values (two numbers, one tower interval and one night count) of the rows that meet all four goals (c15, c16, c17, c26 meet them; c19 and c10 miss the night goal or the army band). Per-seed in c15 (and the final matrix): balanced lost seeds 3 and 9, army_balanced lost seeds 1 and 9.

### Levers tried and ruled out, and why

- **Squad speed and cost levers (c01, c02, c03, c04):** faster footman or archer shots and a cheaper tier 1 keep the army alive (army wins 9 and 10) and the ratio goes down, not up, because a surviving army buys every tier and the higher tiers earn fewer kills per gold; the archer's longer reach changed nothing measurable. Squad buffs cannot reach 0.8 on their own while the army must stay at 7 or 8 wins.
- **Tower tier 2 (c06, c07):** cost and damage changes gave a result identical to the baseline on every column. The tier 2 tower value does not influence any bot result, so it is not a lever.
- **Tower tier 1 cost 5 (c05, c09):** the army collapses to 2 of 10 wins; cost 3 (c27, c28) hands the balanced bot 10 of 10.
- **Tower tier 1 interval:** the lever is steep and quantised to 30 Hz steps (0.8 s is 24 steps, 0.9 s is 27, and 0.88 s rounds to the same 27, so c26 equals c15). 0.85 s is not enough (c11: balanced still 9), 0.95 s and 1.0 s are too much (c08, c12: balanced 4 and 6, army 6 and 4). 0.9 s is the window.
- **Tower tier 1 range, health, arrow speed (c13, c14, c18, c23, c24, c25, c29):** range 8 and health 60 do nothing for the goals; health 40, range 9.5 and 10 and arrow speed 24 move the army out of its 7 to 8 band or leave the balanced bot at 9.
- **King regeneration (c20, c21, c22):** the balanced bot stays at 9 wins and the ratio stays near 0.7, as plan 03-04 showed; regeneration does not move the goals.
- **Night counts alone (c16, c17, c19):** only the night 8 goal needs them. Raising night 8 further (c16, +3 grunts) or adding a ranged enemy (c17) also meets the goals; one grunt is the smallest change that makes night 8 larger than night 7. Lowering night 7 (c19) also made the army win 9.
- **Locked values:** none was needed. Squad sizes, replacement times, the footman's numbers and the king's numbers were never touched, and no owner unlock was requested.

## Values moved (old to new) and what allows each

| File | Value | Old | New | Allowed by |
|---|---|---:|---:|---|
| `data/buildings/tower.tres` | tier 1 `attack_interval` | 0.8 | 0.9 | "tower tier values" on the Round 2 may-move list (owner decision 2026-10-13, D-27) |
| `data/maps/prototype_map.tres` | `Resource_group_n8_north` (night 8, north road grunts) `count` | 10 | 11 | "group counts of nights 5 to 8" on the Round 2 may-move list (D-27); night 8 total 39 to 40 |

Nothing else under `data/` changed; nights 1 to 4, squad sizes (D-01), replacements (D-05), the footman (D-07), the archer, the king and every enemy are untouched.

## Re-pinned constants (old to new)

`tests/integration/test_balance_acceptance.gd` (header and constants carry the Round 2 old and new values):

- `BALANCED_LOST_SEEDS` [9] to [3, 9]; `BALANCED_FIRST_LOSS_NIGHT` 3 unchanged (seed 9 still falls on night 3; seed 3 falls on night 8).
- Added `BALANCED_MIN_WINS` 7, `BALANCED_MAX_WINS` 8, `SQUAD_VALUE_BAR` 0.8 (`# provisional, owner-set`, confirmed D-26), and the two goal tests.
- `test_balanced_wins_every_seed_it_is_not_pinned_to_lose`: its message now says 8 of 10 (the assertion is unchanged and derives its count from the lost-seed list).
- `test_balanced_loses_only_seed_nine_and_never_before_night_three` renamed `test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three` (same assertions).
- `TOWERS_FIRST_MIN_WINS` 2 replaced by `TOWERS_FIRST_MIN_NIGHTS_SURVIVED` 6, and `test_towers_first_wins_at_least_two_of_three` by `test_towers_first_survives_at_least_six_nights_on_every_pinned_seed` (the plan's step 6 route for a tower opening that wins none; flagged above as a finding).
- Unchanged and still passing: `GREEDY_FIRST_LOSS_NIGHT` 3 / `GREEDY_LAST_LOSS_NIGHT` 5 (greedy loss nights re-measured as 3 to 5), `NO_BUILD_MAX_NIGHTS_SURVIVED` 2, `ARMY_BALANCED_MIN_WINS` 7 / `MAX` 8, `GRUNT_MAX_HEALTH` 6.

`tests/unit/test_night_data_contract.gd`: `NIGHT_TOTALS` [5, 12, 21, 21, 25, 31, 39, 39] to [5, 12, 21, 21, 25, 31, 39, 40]; `SQUAD_RETUNE_COUNTS` night 8 north grunt 10 to 11; the totals message updated; added `PHASE_TWO_WALL` / `PHASE_TWO_WALL_TOTALS` and the two goal tests. Night 5 did not change, so `ROUND_THREE_COUNTS` still holds nights 2 to 5 unchanged.

`tests/unit/test_military_data_contract.gd`: header and a new `test_round_two_slowed_the_first_tower_tier_and_nothing_else_of_the_tower` pinning tier 1 interval 0.9 (was 0.8) and the rest of the tower unchanged; `COSTS`, `SQUAD_SIZES`, `RESPAWN_SECONDS`, `FOOTMAN_DAMAGE` and `KING_HEALTH_PER_FOOTMAN` untouched.

## Determinism and goldens

- Smoke golden: `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks) replays to `tests/golden/smoke.json`, unchanged.
- Army golden: `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) replays to `tests/golden/army.json`, unchanged. `git diff --quiet HEAD -- tests/golden/smoke.json tests/golden/army.json` exits 0 (both byte-identical; they run on frozen fixtures).
- **full_idle (shipped data, balanced bot), recorded for G-03-11's closure wording:**
  - before the first data edit: digest `ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a`, **6199 ticks**, won (matches the expected pair).
  - after the retune: digest `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064`, **6941 ticks**, won, two runs in one process agree (`REPLAY_OK scenario=full_idle`). It moves by design: the shipped tower data changed and full_idle has no golden.

## Verification Results

- `bash tools/test.sh` (own run, after the data commit's content): 150 scripts, 1397 tests, 1397 passing, 15563 asserts, 621.8 s, exit 0 (baseline 1392; plan adds 4 goal tests and 1 Round 2 pin test, and replaces 1 test with 1; net +5). The JUnit XML holds all four goal test names and `test_military_data_contract`.
- `bash tools/playtest.sh --seeds=10`: `PLAYTEST_OK runs=60`; the plan's verify script reads balanced 8 (7 to 8), army_balanced 8 (7 to 8), ratio 0.915 (at least 0.8).
- `bash tools/replay.sh --scenario=smoke ...` and `--scenario=army ...`: `REPLAY_OK` against the committed goldens; `--scenario=full_idle --twice`: `REPLAY_OK`, two equal digests.
- `bash tools/lint.sh`: 265 files unchanged, no problems.
- `MapConfig.validate()` on the shipped map is clean (`test_every_night_stays_under_the_per_night_enemy_cap_and_the_map_validates` passes; night 8 is 40, far under the 300 cap).
- Acceptance criteria: NIGHT_TOTALS starts 5, 12, 21, 21 and ends 40 above 39; `SQUAD_SIZES [4, 8, 14]`, `RESPAWN_SECONDS [10.0, 7.0, 4.0]`, `FOOTMAN_DAMAGE 1`, `KING_HEALTH_PER_FOOTMAN 5` still in the military contract; the Round 2 test lists tier 1 old to new; both goldens untouched.

## Decisions Made

- Fewest-values rule (the plan's tie-break): two numbers moved. The tower tier 1 interval is the one lever that moves the balanced bot, the army band and the ratio in the right direction together (a slower tower lowers the army bot's tower kills per tower gold, which raises the ratio, and costs the tower-heavy balanced bot a seed); the night 8 count then makes the last night larger.
- Searches ran each candidate in a private copy of the project (five in parallel) instead of editing and restoring the repository's data files; the repository's data was never touched during the search, which is strictly safer than the plan's restore-after-each-candidate procedure.

## Deviations from Plan

None - plan executed exactly as written, with these notes that are not deviations:

- The measurement helper ran candidates in worker copies of the project in the scratch directory rather than editing and restoring the repository's files per candidate. The plan asks for a throwaway helper in the scratch directory with the pristine files restored; this meets the intent (nothing in the repository was edited during the search) with less risk.
- The parked winning edit was kept as a patch file in the scratch directory and re-applied after the last batch, because the helper requires pristine repository data during a search.
- Renamed `test_balanced_loses_only_seed_nine_...` and replaced the towers_first pin (the plan's step 6 route) as listed above; no assertion was relaxed in shape, none deleted without a replacement.

**Total deviations:** 0 auto-fixed.

## Issues Encountered

None. The only unexpected result is the one reported as a finding: the tower-shot nerf that satisfies the goals leaves towers_first with no wins and houses_first with 4 of 10.

## Known Stubs

None. No placeholder values flow to any output.

## Threat Flags

None. No new input, endpoint, file access or trust boundary. T-03-27 holds (both moved values are pinned in contract tests, `MapConfig.validate()` stays clean, no unit health changed). T-03-28 holds (29 candidates, at most five per helper call, each run bounded by `BalanceReport.MAX_TICKS`). T-03-SC: no package was installed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-18 publishes Round 2 in `03-BALANCE-REPORT.md` from this file: the outcome (a), the search log above, the values-moved table, the full_idle digest before and after, and the two findings for the owner (towers_first 0 of 10, houses_first 4 of 10). G-03-11 stays open until 03-18 is done.
- The owner judges feel at the gate (test 15); the bots measure only.

## Self-Check: PASSED

- Modified files exist: `data/buildings/tower.tres`, `data/maps/prototype_map.tres`, the three test files.
- Commits exist: `c935dcf`, `ef56a1e` (`git log --oneline --grep="03-17"`).
- Acceptance criteria re-run: goal check script printed `goal check ok 8 8 0.915`; both goldens `git diff --quiet` clean; lint clean.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
