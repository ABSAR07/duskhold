---
phase: 02-night-defense-playtest-gate
fixed_at: 2026-10-06T05:13:06Z
review_path: .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-10-06T05:13:06Z
**Source review:** .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

Every fix was written test-first: the new or extended test was run and seen to fail for the right
reason before the code change. Verification ran in the main checkout (no worktree; `workflow.use_worktrees`
is unset and the task said to work on the main checkout), so the numbers are reproducible from the tree.
Full suite at the end: 86 scripts, 745 tests, 0 failures (was 738 before this pass). `bash tools/lint.sh`
is clean. The replay goldens are unchanged: `smoke` prints REPLAY_OK with digest 2599c7c2..., and
`full_idle` still wins in 6244 ticks with digest a25aa7fd....

## Fixed Issues

### WR-01: The input grace gates the release of a press, so a press started inside the window and held past it still restarts

**Files modified:** `ui/results/results_screen.gd`, `tests/e2e/test_results_screen.gd`
**Commit:** 81c300e
**Applied fix:** Both buttons now connect `button_down` to a handler that stamps `_down_ms`; the two
`pressed` handlers call `_press_counts()`, which requires `accepts_input()` and
`_down_ms >= _accept_from_ms`. A press that begins inside the window and is released after it does
nothing; a press that begins after the window works. New tests press down only inside the window, wait
until `accepts_input()` is true, release, assert no signal, then do a fresh press and release and assert
one signal, for keyboard (Space), gamepad (A) and mouse (button_down then pressed on Quit) on the Defeat
screen and for the keyboard on the Victory screen. Before the fix all four failed with the straddling
press restarting. Existing tests that called `pressed.emit()` directly now go through a `_click()` helper
that emits `button_down` and then `pressed`, which is what a real mouse click does, so they stay
meaningful as mouse-press checks instead of being kept on `accepts_input()` alone. The e2e file still
sets `handle_results_actions` false, so no test reloads or quits. Logic fix: requires human verification.

### WR-02: The new results-screen tests fail if the runner stalls longer than the grace window

**Files modified:** `tests/e2e/test_results_screen.gd`
**Commit:** 81c300e
**Applied fix:** The two existing grace tests and the new straddle tests use their own 3.0 s window
(`TEST_GRACE_S`, through the `_tuning_with_grace` override) instead of the shipped 0.6 s; the victory
test no longer reads the shipped value (the shipped-value check stays in
`tests/unit/test_loop_tuning_contract.gd`). "Ignored inside the window" is judged after the taps rather
than before: `accepts_input()` never goes back to false, so if it is still false after the last tap every
tap was inside the window. If the runner stalled past the window the test calls `pending()` instead of
failing. The brittle `assert_false(results.accepts_input())` at the top of the defeat test was removed.

### IN-01: `preview_counts` counts groups that `WaveSchedule` skips

**Files modified:** `simulation/night/wave_schedule.gd`, `tests/unit/test_wave_schedule.gd`
**Commit:** 21b8abb
**Applied fix:** `_allowances` lost its `needs_enemy` parameter and always skips a group with an unknown
enemy as well as one with an unknown spawn point, so the preview and the schedule skip the same groups and
spend the night budget identically. The comment that claimed they agree now says what is shared. New test
`test_the_preview_skips_an_unknown_enemy_group_like_the_schedule` puts an unknown-enemy group of the whole
night budget ahead of a valid 5-grunt group; it failed before (preview `{west: 300}`) and now gives
`{east: 5}`, equal to the schedule's total. Replay goldens unchanged. Logic fix: requires human
verification.

### IN-02: `MAX_GROUP_COUNT` is now a dead clamp

**Files modified:** `simulation/night/wave_schedule.gd`, `tests/unit/test_wave_schedule.gd`
**Commit:** 21b8abb
**Applied fix:** Removed `MAX_GROUP_COUNT` and the inner `mini`; the `_allowances` doc comment now
describes the night budget (`MapConfig.MAX_ENEMIES_PER_NIGHT`) alone. Because a dead-constant removal has
no behaviour for a test to see, `test_the_night_budget_is_the_only_cap_constant` asserts the script's
constant map has no `MAX_GROUP_COUNT`, so the second cap cannot quietly come back. Committed together
with IN-01 (same file, same function).

### IN-03: The "shipped grace is set in the data file" test cannot see the data file

**Files modified:** `tests/unit/test_loop_tuning_contract.gd`
**Commit:** 260ec31
**Applied fix:** The test now reads the text of `res://data/tuning/loop_tuning.tres` with
`FileAccess.get_file_as_string` and asserts it contains a line starting `results_input_grace_seconds = `.
Checked by mutation: with the line deleted from the data file the test fails, and with the file restored
it passes.

### IN-04: The grace value has no upper bound

**Files modified:** `ui/results/results_screen.gd`, `tests/e2e/test_results_screen.gd`
**Commit:** 81c300e
**Applied fix:** New constant `MAX_GRACE_S = 3.0` (with a comment giving the reason) and the grace is
`clampf(value, 0.0, MAX_GRACE_S)`, so it is clamped at both ends. New test
`test_a_huge_grace_value_is_capped_so_the_buttons_still_work` gives a 600 s grace, waits for
`accepts_input()` within `MAX_GRACE_S` plus slack and then taps the key and expects Play again to fire; it
failed before the clamp (the screen was still deaf after 3.5 s).

---

_Fixed: 2026-10-06T05:13:06Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
