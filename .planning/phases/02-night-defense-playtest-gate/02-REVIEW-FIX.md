---
phase: 02-night-defense-playtest-gate
fixed_at: 2026-10-05T16:00:29Z
review_path: .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-10-05T16:00:29Z
**Source review:** .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

Scope was Critical and Warning only (WR-01 to WR-03); IN-01 to IN-06 were left alone.

## Fixed Issues

### WR-01: MapConfig.validate() cannot catch enemy data that makes a night impossible to end, and a real night has no clock

**Files modified:** `simulation/defs/map_config.gd`, `tests/unit/test_map_validate_enemies.gd`, `tests/unit/test_map_validate_enemies.gd.uid`
**Commit:** c6bb202
**Applied fix:** `validate()` now reports an enemy whose `aggro_range` is not above its `attack_range` (strict, because at equality float rounding in the stop position can leave the target edge a hair beyond aggro range), `leash_range` below `aggro_range`, non-positive `radius` or `retarget_interval_seconds`, negative `attack_range` or `projectile_speed`, a non-positive `castle_radius`, and per tower tier a negative `attack_range` or `projectile_speed` and a non-positive `attack_interval`. The enemy checks moved into a new private `_validate_enemy`, the tier checks into `_validate_tier_combat`. A new test file (12 tests, each bad value yields exactly one error naming the field) was written first and failed with 11 of 12 reporting no error; the 20-test cap on `test_map_validate_nights.gd` is why the tests live in a new file. Shipped data still validates clean and the replay goldens are unchanged. Not done: the optional per-night tick ceiling in `RunManager` (the review said "consider"); it would change run structure and the hang is now prevented at the data gate instead. Status: fixed, requires human verification (logic rule; the strict `>` is a judgement call).

### WR-02: The per-night enemy cap is advisory only; at runtime it is not enforced

**Files modified:** `simulation/night/wave_schedule.gd`, `tests/unit/test_wave_schedule.gd`
**Commit:** ef8ca58
**Applied fix:** A new static `_allowances(map, night, needs_enemy)` shares one `MapConfig.MAX_ENEMIES_PER_NIGHT` budget across a night's groups in group order. `WaveSchedule._init` and `preview_counts` both use it, so the telegraph agrees with the capped night. `MAX_GROUP_COUNT` is now derived from the map constant (it was 500 against a 300 night limit). Groups the schedule cannot play take nothing from the budget; `preview_counts` still does not look at the enemy id (`needs_enemy` is false there), so IN-01 behaviour is unchanged. Four tests were added (one group of 1500 gives 300, 20 groups of 500 give at most 300, the budget is shared in group order, preview equals schedule when capped); three failed first with 500, 10000 and 580 spawned. Status: fixed, requires human verification (scheduling logic). The smoke and full_idle replay digests are unchanged.

### WR-03: The action key is also the menu accept key, so mashing it at the end of a run restarts the game

**Files modified:** `ui/results/results_screen.gd`, `simulation/defs/loop_tuning.gd`, `data/tuning/loop_tuning.tres`, `tests/e2e/test_results_screen.gd`, `tests/unit/test_loop_tuning_contract.gd`
**Commit:** 6057fd1
**Applied fix:** New tuning field `LoopTuning.results_input_grace_seconds` (0.6 s in `loop_tuning.tres`, with the reason in its doc comment). `ResultsScreen` records a real-time deadline (`Time.get_ticks_msec`) when it shows, exposes `accepts_input()`, and both button handlers emit their signal only when it is true. Focus and the look of the screen are unchanged (no disabled buttons, no timers), so keyboard, gamepad and mouse all work once the window is over (D-16); inside the window a press from any device does nothing, including a mouse click. The window applies to Victory (shown at once) and Defeat (shown after the loss beat). Tests: a defeat test pins that A, Space, Enter and mouse presses on both buttons inside a 1 s window emit nothing and that Space after `accepts_input()` emits exactly once; a victory test uses the shipped 0.6 s and Space as the real collision; a contract test pins the field as stored, between 0.3 and 1.0 s. Before the gate existed the new tests failed with `play_again_pressed` emitted inside the window. The older button tests now use a tuning with grace 0 so they press at once; `handle_results_actions` stays false on MapRoot there. Status: fixed, requires human verification (input timing; the owner should tap the action key as Victory appears in a real run).

---

_Fixed: 2026-10-05T16:00:29Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

## Verification

Worked in the main checkout on `gsd/phase-01-foundation-day-loop`, no git worktree (per the dispatch instructions); all gates ran there, so they are reproducible from the tree. Each fix: test written first and seen to fail for the right reason, then fixed, `bash tools/lint.sh` clean before each commit.

- Full suite after the last commit: 86 scripts, 738 tests, 738 passing (was 719 in 85 scripts; +12 +4 +2 +1 tests, +1 script).
- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`: REPLAY_OK, digest 2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f, 703 ticks (unchanged), after WR-01, WR-02 and at the end.
- `bash tools/replay.sh --scenario=full_idle --twice`: REPLAY_OK, won in 6244 ticks, digest a25aa7fd20e3cba842165f4c9579660b0ce3dd4b30628dd17facf812f97c5b07 (unchanged).
- Not run: screenshot job, playtest tool, a real-window play-through of the results screen, gdUnit or mutation probes by script.
