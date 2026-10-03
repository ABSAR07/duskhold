---
phase: 01-foundation-day-loop
fixed_at: 2026-10-03T07:40:46Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-10-03T07:40:46Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

Verification ran in the main checkout (no worktree; the pinned engine is in git-ignored `.tools/`). Final state: `bash tools/test.sh` 364/364 passing (363 plus the new WR-01 test), `bash tools/lint.sh` green (84 files, no problems). No Godot process left running.

## Fixed Issues

### WR-01: The "helper is uncapped" test cannot fail, so the cap guard in `flat_drip_tuning` is unpinned

**Files modified:** `tests/e2e/e2e_support.gd`, `tests/unit/test_e2e_support_tuning.gd`
**Commit:** c3d2411
**Applied fix:** `flat_drip_tuning` takes an optional `base: LoopTuning = null` (defaults to the shipped tuning). New test `test_a_long_hold_is_not_capped_even_from_a_capped_base` feeds a base with `max_build_hold_seconds = 1.0` and asserts the cap is cleared, the hold is the flat sum, and the base is left untouched.

### WR-02: A shipped-data test asserts a property the design deliberately does not hold at the floor

**Files modified:** `tests/unit/test_coin_drip_flight.gd`
**Commit:** bf554d0
**Applied fix:** The test (renamed `..._above_the_break_even_...`) only asserts flight < gap for gaps above `MIN_FLIGHT_SECONDS / FLIGHT_FRACTION_OF_INTERVAL`, counts checked gaps so it is not vacuous, and the file header now states that overlap at the floor is intended (the airborne-bound test covers it).

### IN-01: Tautological ceiling test, and a constant referenced only by tests (open from the previous IN-02)

**Files modified:** `tests/unit/test_coin_drip_flight.gd`
**Commit:** 40710e3
**Applied fix:** Added a literal `D05_CEILING_S = 0.27` (0.9 x 0.3 s). `test_the_ceiling_is_the_d05_number` and `test_a_huge_gap_flies_for_the_ceiling` both compare against that literal instead of the constant's own definition. `COIN_DRIP_INTERVAL_MIN_S` was left in place: it is the documented D-05 range bound read by the contract test, and removing it is outside the review's fix.

### IN-02: Delayed burst and refund coins sit visible and stacked before they launch (open from the previous IN-03)

**Files modified:** `presentation/vfx/coin_drip_vfx.gd`
**Commit:** 3a6825b
**Applied fix:** In `_fly`, when `delay > 0.0` the coin is hidden, then made visible by a `tween_callback` right after the interval. Delays, flight, coin counts and `live_coin_count()` are unchanged; the existing burst/refund tests stay green (full suite 364/364). Fixed: requires human verification of the look in a real window (not visually checked).

### IN-03: The sandbox's starting gold covers one plot's upgrade chain, but the map has five House plots

**Files modified:** `tools/sandbox/hold_pacing_sandbox.gd`, `tests/e2e/test_hold_pacing_sandbox.gd`
**Commit:** afc393b
**Applied fix:** New `HoldPacingSandbox.house_plot_count(config)`; starting gold is `chain_total * house_plot_count + GOLD_MARGIN`. The sandbox test derives the expected gold from the map's House spots and asserts several plots exist.

---

_Fixed: 2026-10-03T07:40:46Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
