---
phase: 02-night-defense-playtest-gate
plan: 17
subsystem: castle-attack-tuning
tags: [godot, balance, castle, validation, gap-closure, g-02-13, wr-02, in-01]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-15 castle attack (reach, interval, arrow speed read live from the map), 02-16 round-2 balance and gate packet
provides:
  - The shipped castle reaches 22.0 m and shoots 27.0 m/s arrows (owner decision 2026-10-07, G-02-13), pinned by a shipped-data test
  - MapConfig.validate() reports non-finite castle range, interval and speed once and an attacking castle with an interval below SimClock.STEP (review WR-02)
  - CastleAttack.is_armed() refuses non-finite and sub-step numbers, so T-02-33's "never fires every tick" is true for unvalidated maps too
  - SimEvents.dawn_payout doc names MapConfig.CASTLE_PAYOUT_KEY (review IN-01)
affects: [02-19-difficulty-lever, phase-2-verification, owner-playtest-gate]

requirements-completed: [KING-03, LOOP-03]

actuals:
  tokens: 4100
  tasks: 2
  commits: 4

plan_head_before: 99e15218dbdb3b0d19f26a7a463c4c5fb52ecba5
plan_head_after: 34d709ac7bdf58003c657423070b93fc6e4aebb2

tech-stack:
  added: []
  patterns:
    - "A tuning decision from the owner is a data edit plus a shipped-data pin test written failing first, with a mutation probe on the data line"
    - "Defensive arming: the runtime guard (is_armed) and the data validator (validate) refuse the same bad numbers, so neither depends on the other having run"

key-files:
  created: []
  modified:
    - data/maps/prototype_map.tres
    - simulation/defs/map_config.gd
    - simulation/night/castle_attack.gd
    - simulation/events/sim_events.gd
    - tests/unit/test_map_validate_castle.gd
    - tests/unit/test_castle_attack.gd

key-decisions:
  - "Castle reach 22.0 m and arrow speed 27.0 m/s on the shipped map, exactly the owner's request; damage 2, interval 1.5 s, castle health 70 and every enemy and building number untouched (the difficulty lever is 02-19's)"
  - "is_armed() requires a finite range above 0 and a finite interval of at least SimClock.STEP; validate() reports the same values, using only the SimClock.STEP constant (no time scale read under simulation/)"

duration: 15 min
completed: 2026-10-07
---

# Phase 2 Plan 17: Castle reach 22 m, arrows 27 m/s, and non-finite/sub-step guards Summary

**The shipped castle now answers enemies from 22 m (double) with 27 m/s arrows (1.5x), pinned by a test written failing first, and both MapConfig.validate() and CastleAttack.is_armed() refuse INF, NaN and sub-step castle numbers (WR-02); every replay is unchanged.**

## Performance

- **Duration:** 15 min (2026-10-06T23:11:10Z to about 2026-10-06T23:27Z)
- **Tasks:** 2 (each RED then GREEN)
- **Files:** 6 modified, none created
- **Tests:** 821 passing in 94 scripts (817 baseline plus 4 new: 1 shipped-data pin, 3 validate), lint clean

## Commits

| Task | Gate | Commit | What |
|---|---|---|---|
| 1 | RED | de2be23 | `test_the_shipped_castle_reaches_22_m_and_its_arrows_fly_at_27_m_per_s` fails on 11.0 / 18.0 (range, speed and the 25-tick edge flight, which was 19) |
| 1 | GREEN | 4bcc492 | two data lines, test_castle_attack.gd on the shipped numbers, castle_attack.gd and map_config.gd docs |
| 2 | RED | 2af3194 | non-finite and sub-step validate tests; DISARMING rows for INF range, INF/NaN/0.001 interval |
| 2 | GREEN | 34d709a | `_validate_castle_attack` finite and one-step rules, hardened `is_armed`, IN-01 doc |

## The two-line data diff

`git diff de2be23^..HEAD -- data/maps/prototype_map.tres`:

```
-castle_attack_range = 11.0
+castle_attack_range = 22.0
-castle_projectile_speed = 18.0
+castle_projectile_speed = 27.0
```

`castle_attack_damage = 2`, `castle_attack_interval = 1.5` and `castle_max_health = 70` are unchanged (grep-verified). Nothing under tests/golden, tests/fixtures, data/buildings or data/enemies changed (`git log` over those paths for the plan range prints nothing).

## Replays

- smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`, equal to tests/golden/smoke.json (run after both tasks)
- full_idle (run after Task 1 and again after Task 2, `--twice` each): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435`, unchanged, as the diagnosis measured (the balanced bot never lets an enemy within 22 m)

## Mutation probes (each restored afterwards)

1. **Task 1, data line:** set `castle_projectile_speed` back to 18.0 in prototype_map.tres. `test_map_validate_castle.gd` failed on the new test ("18.0 expected to equal 27.0" and "37 expected to equal 25" for the edge flight; the other 9 tests passed). Restored from a `cp` backup; `git diff` again showed exactly the two intended lines.
2. **Task 2a, arming:** removed `and is_finite(_map.castle_attack_interval)` from `is_armed`. `test_castle_attack.gd` failed 2 tests: `test_the_castle_is_armed_only_with_numbers_it_can_use` ("castle_attack_interval at inf disarms it") and `test_an_unarmed_castle_never_fires` ("castle_attack_interval at inf: the castle never fires", 90 shots). Restored.
3. **Task 2b, validation:** replaced the one-step rule's `castle_attack_interval < SimClock.STEP` with `< 0.0`. `test_an_attacking_castle_with_an_interval_below_one_step_is_reported` failed for 0.001 s and for half a step (0 errors reported). Restored.

## What changed in behaviour

- On the shipped map an arrow at the edge of the castle's reach flies `flight_ticks(22.0, 27.0) = 25` ticks, under the 45-tick interval, so at most one castle arrow is in the air. 3 hits still kill a grunt (6 hp) and 2 a skirmisher.
- `validate()`: INF, -INF and NaN in castle_attack_range, castle_attack_interval or castle_projectile_speed each give exactly one error "<field> is not finite (<value>)" (-INF is no longer reported as negative); an attacking castle with an interval below one step gives "castle_attack_interval is below one simulation step"; an interval of exactly one step, a castle with damage 0, the shipped map and the smoke fixture stay clean.
- `is_armed()`: false for a non-finite range or interval and for an interval below one step. NaN already disarmed through failed comparisons; INF range, INF interval and 0.001 s interval were the live holes (they fired every tick or armed the castle with an infinite reach).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] gdformat reflow of the RED test**
- **Found during:** Task 1 verification (`bash tools/lint.sh`)
- **Issue:** the RED test's multi-line `assert_lt` call would be reformatted by gdformat, so lint failed.
- **Fix:** ran gdformat on the test file and included it in the GREEN commit (4bcc492); no assertion changed.
- **Files modified:** tests/unit/test_map_validate_castle.gd

**2. [Plan wording] `test_an_interval_of_one_step_or_no_damage_is_accepted` passed in RED**
- It documents acceptance cases that the old validator already satisfied, so it is green before and after (the plan lists it among the RED-commit tests, but only rejecting cases can fail). The two rejecting-case validate tests and the DISARMING rows were the genuine RED.

**Total deviations:** 1 auto-fixed (lint formatting), 1 note. **Impact:** none on scope or behaviour.

## Out of scope, left as is

- IN-02 (test_results_layout.gd pins the 11 px constant) stays open in 02-REVIEW-DISPOSITION.md, as the plan said.
- Docs outside the plan's files that still quote 11 m / 18 m/s (02-PLAYTEST-GATE.md, 02-BALANCE-REPORT.md Round 2, ROADMAP.md, STATE.md history) describe what the owner played in round 2; the round-3 gate plan (02-20) refreshes the packet.

## Known Stubs

None.

## Threat Flags

None. T-02-37 (non-finite / sub-step castle numbers) and T-02-38 (shipped numbers drifting) are mitigated by the tests above; no new endpoints, files or trust boundaries.

## Self-Check: PASSED

- Files modified carry the planned content: `castle_attack_range = 22.0` and `castle_projectile_speed = 27.0` in the .tres; `SimClock.STEP` and `is not finite` in map_config.gd; `is_finite` and `SimClock.STEP` in castle_attack.gd; `CASTLE_PAYOUT_KEY` in sim_events.gd; the named tests in both test files.
- Commits de2be23, 4bcc492, 2af3194 and 34d709a exist on gsd/phase-01-foundation-day-loop.
- `bash tools/test.sh` exit 0 (821/821 in 94 scripts, with test_map_validate_castle, test_castle_attack, test_sim_rules_guard, test_balance_acceptance and test_dawn_income present in the JUnit file); `bash tools/lint.sh` clean; smoke equals its golden; full_idle unchanged.
