---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T14:49:08Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - tests/e2e/test_debug_overlay_toggle.gd
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T14:49:08Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `tests/e2e/test_debug_overlay_toggle.gd` against `tests/e2e/e2e_support.gd`, `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay.tscn`. The file has six tests. I ran it three times with `-gselect=test_debug_overlay_toggle.gd`: 6/6 passed with 29 asserts each time, so I found no flakiness.

The paused-tree and time-scale tests are sound. The overlay root has `process_mode = 3` (ALWAYS), and the refresh clock uses `Time.get_ticks_usec()`. `after_each` restores pause, time scale and held actions, so a failing test cannot leak state into later suites. There are no correctness or security defects. The remaining weakness is that the cadence the header promises is not really asserted.

## Warnings

### WR-01: The "about 4 times/s" refresh cadence is documented but effectively untested

**File:** `tests/e2e/test_debug_overlay_toggle.gd:7`, `:88-91`, `:114-117`, `:139-142`
**Issue:** The header says the overlay "refreshes about 4 times/s" (`REFRESH_INTERVAL_S = 0.25`). Every refresh test only asserts that the text changes within `REFRESH_WINDOW_S = 1.0` s, which is 4x the interval. A regression to a 0.9 s interval, or to a refresh that fires only once a second, would still pass. The window was widened from a smaller value in commit 625a89d, which made this looser. Nothing checks that a hidden overlay does not refresh, either. `_advance_refresh` returns early when `not visible`, and no test covers it.
**Fix:** Either reword the header to say the tests check "refreshes within 1 s", or add one cadence test with the interval tied to the production constant. For example, count text changes over a fixed real-time span, or assert the elapsed time until "Buildings: 1" is at most `DebugOverlay.REFRESH_INTERVAL_S * 2 + slack`:

```gdscript
const CADENCE_WINDOW_S: float = DebugOverlay.REFRESH_INTERVAL_S * 2.0 + 0.15
...
var refreshed: bool = await E2eSupport.wait_until(
	self, func() -> bool: return overlay.get_text().contains("Buildings: 1"), CADENCE_WINDOW_S
)
```

Add a test that submits the build while the overlay is hidden and asserts the text is still stale after a window longer than the interval.

## Info

### IN-01: Required-field check is substring-only and does not check values

**File:** `tests/e2e/test_debug_overlay_toggle.gd:8-17`, `:66-67`
**Issue:** `"Gold"`, `"Units"`, `"Enemies"` and `"FPS"` are checked only as substrings of the whole text. A row with a wrong or empty value (for example `Gold: `) would pass, and so would a title that appears in some other row. Only `Phase: DAY`, `Day: 1` and `Night: 0` include values. `"Buildings: 1"` would also match `"Buildings: 10"`. That is harmless here, since the test builds exactly one.
**Fix:** Assert on `"  Gold: "` with the value (the label format is `"  %s: %s"`). Or parse the lines into a dictionary and check each key has a non-empty value.

### IN-02: Repeated overlay lookup and null-guard boilerplate

**File:** `tests/e2e/test_debug_overlay_toggle.gd:38-42`, `:47-51`, `:59-63`, `:71-75`, `:97-101`, `:127-131`
**Issue:** Every test repeats the same five lines: spawn the map, look up the overlay, `assert_not_null`, and `return` on null. The `_press_toggle` and build-then-wait-for-"Buildings: 1" sequences are also duplicated. This is maintainability only.
**Fix:** Add a helper such as `_spawn_with_overlay() -> Array` (or store `_map_root` and `_overlay` in `before_each`) and a `_wait_for_buildings(overlay, n)` helper.

---

_Reviewed: 2026-09-30T14:49:08Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
