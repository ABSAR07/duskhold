---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T15:02:33Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T15:02:33Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

Verification ran in the main checkout (no isolated worktree; see the note at the end), so the numbers are reproducible from the tree as committed: `bash tools/lint.sh` clean (72 files unchanged), `bash tools/test.sh` 290/290 passing in 36 scripts (was 289; one new test), no Godot process left running.

## Fixed Issues

### WR-01: The "about 4 times/s" refresh cadence is documented but effectively untested

**Files modified:** `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** e720f2c
**Applied fix:** Took the reviewer's first option (reword) rather than a wall-clock cadence test, because the previous review flagged a tight wall-clock window in this file as flaky and `tests/unit/test_debug_overlay_registration.gd` already pins the cadence deterministically with synthetic deltas (`test_a_shown_overlay_refreshes_once_the_interval_has_passed_and_not_before`, `test_a_shown_overlay_refreshes_about_four_times_a_second_and_a_hidden_one_never`). The header no longer claims a cadence; it says what the e2e file proves (shown overlay refreshes within `REFRESH_WINDOW_S` of real time, hidden overlay does not refresh) and points at the unit test for the 4 times/s cadence. Added `test_hidden_overlay_does_not_refresh_until_it_is_shown_again`: show, hide, build through the command gate, wait `REFRESH_WINDOW_S` (several intervals), assert the Buildings row is still stale, then show again and assert it refreshes at once. It can only fail in the failing direction, so it adds no flake risk.
**Mutation probe:** With `if not visible: return` deleted from `DebugOverlay._advance_refresh` (`ui/overlay/debug_overlay.gd`), the new test failed ("a hidden overlay does not refresh", 6 pass / 1 fail); before the change no e2e test failed on that mutation. Source restored from a backup copy; `git status` showed only the test file and the unrelated `.planning/config.json`.

### IN-01: Required-field check is substring-only and does not check values

**Files modified:** `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** 2091193
**Applied fix:** Replaced the substring list `REQUIRED_FIELDS` with a `_rows_of(overlay)` helper that parses the `"  label: value"` lines into a dictionary. `Phase`/`Day`/`Night`/`Buildings` are compared exactly (`DAY`, `1`, `0`, `0`), and `FPS`/`Gold`/`Units`/`Enemies` must carry an integer (their values depend on tuning or frame rate). Section titles no longer satisfy a row check.
**Mutation probe:** With the Gold row in `ui/overlay/debug_overlay_model.gd` changed to `["Gold", ""]`, the test failed ("the Gold row has an integer value, not ''"); the old substring check would still have passed because the title `Gold` remained. Source restored from a backup copy.

### IN-02: Repeated overlay lookup and null-guard boilerplate

**Files modified:** `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** da45f5c
**Applied fix:** Added `_spawn_overlay()` (spawns the map, keeps `_map_root`, looks up the overlay and asserts non-null, so each test guard is three lines instead of five), `_buildings_shown()`, `_wait_for_buildings(overlay, count)` and `_build_first_plot_through_the_gate()`, and removed `_overlay_of`. Buildings checks now read the row as an exact value via `_rows_of`, so `"1"` no longer matches `"10"` (this also closes the substring gap IN-01 noted for that row). Test behaviour and assert count are unchanged (35 asserts, 7 tests). The `_press_toggle` helper was already shared and is unchanged.
**Mutation probe:** With the refresh gate `if _since_refresh >= REFRESH_INTERVAL_S:` replaced by `if false:` in `ui/overlay/debug_overlay.gd`, the three refresh-within-window tests still failed after the refactor (4 pass / 3 fail), so the helpers kept the tests' teeth. Source restored from a backup copy.

## Notes

- **Isolation:** The orchestrator brief directed edits, `tools/test.sh` and `tools/lint.sh` in the main checkout on the phase branch with explicit-path staging (a fresh hand-rolled worktree has no warmed `.godot/` cache, so class_name scripts would not resolve for the tests). No worktree, temp branch or recovery sentinel was created. `.planning/config.json` still carries its unrelated uncommitted change and was never staged.
- The working copy of the test file is CRLF (`core.autocrlf=true`); commits store LF. `gdformat` was applied through `bash tools/lint.sh --fix` before each commit.
- `tests/unit/test_debug_overlay_registration.gd` (20 public methods, at the gdlint cap) was not touched; all new code is in the e2e file (now 7 tests, under the cap).

---

_Fixed: 2026-09-30T15:02:33Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
