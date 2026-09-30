---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T15:09:37Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - tests/e2e/test_debug_overlay_toggle.gd
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T15:09:37Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** clean

## Summary

Reviewed `tests/e2e/test_debug_overlay_toggle.gd` against its collaborators (`ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd`, the overlay scene's `process_mode = 3` (ALWAYS), and `tests/e2e/e2e_support.gd`).

Points checked:

- **Row parsing:** `_rows_of` splits on `": "` with maxsplit 1 and skips un-indented section titles. It matches the overlay's `"  %s: %s"` format. A missing or empty label yields "" or null, so assertions fail and do not pass vacuously.
- **Expected values:** The exact rows (Phase, Day, Night, Buildings) are unconditional in `_loop_rows`. The integer rows (FPS, Gold, Units, Enemies) are unconditional in the Perf, loop and agent sections. Only the Timer row is phase-conditional, and the test does not depend on it.
- **Paused-tree test:** it exercises the overlay's `process_mode = ALWAYS` and its real-time refresh. The build goes through the command gate, so only the overlay's own refresh can update the label. `after_each` unpauses the tree and resets `Engine.time_scale` and held actions, so a failed assertion cannot leak state into later suites.
- **Time-scale-zero test:** it polls with `wait_until`, which uses `Time.get_ticks_msec`, and `wait_process_frames`. Neither depends on scaled time, so the test cannot hang on its own clock. It would fail if the overlay used scaled `delta`.
- **Hidden-overlay test:** it fails only in the direction of a real bug. A correct overlay stays at "0" however long the wait. The final "1" assertion also proves the model would have shown the new count, so the "0" is not a stale-label accident.
- **Widened refresh window:** `REFRESH_WINDOW_S` is 1.0 s against a 0.25 s interval, which gives 4x headroom. Cadence is pinned deterministically in the unit tests.
- **Flakiness:** the file ran 3 times in a row through `tools/test.sh -gselect=test_debug_overlay_toggle.gd`. Each run was 7/7 passing with 35 asserts.

No bugs, security issues, or quality defects were found. All reviewed files meet quality standards.

---

_Reviewed: 2026-09-30T15:09:37Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
