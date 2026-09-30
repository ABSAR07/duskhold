---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T09:30:10Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-09-30T09:30:10Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

**Verification environment:** every gate (`bash tools/lint.sh`, `bash tools/test.sh`) ran in the main checkout on branch `gsd/phase-01-foundation-day-loop` (workflow ran without a worktree, per orchestrator instruction), so the numbers are reproducible from the tree. Final state: lint clean, GUT 243/243 passing (baseline was 241; +2 new tests).

## Fixed Issues

### WR-01: A tightened stagger leaves zero slack, so the last coin can land after dawn ends

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** f1806f5
**Applied fix:** Added `DAWN_MARGIN_SECONDS = 0.15` and `launch_stagger` now computes its window as `dawn_seconds - TRIP_SECONDS - DAWN_MARGIN_SECONDS` (still clamped to `[0, STAGGER_SECONDS]`). Default tuning (2.0 s dawn, at most 12 coins) still gets the full 0.08 s stagger: (2.0 - 0.6 - 0.15) / 11 = 0.114 s, so it clamps to `STAGGER_SECONDS`. Both exact-fill tests were updated to the new formula (the first was renamed `..._to_fill_the_dawn_window_less_its_margin`; the second now asserts the last coin lands by `dawn_seconds - DAWN_MARGIN_SECONDS`). Logic-related change: requires human verification of the chosen margin value.

**Mutation probe (CR-01 guard):** replaced `stagger` with `STAGGER_SECONDS` in the coin schedule (`float(launches.size()) * STAGGER_SECONDS`) and ran `bash tools/test.sh -gselect=test_dawn_payout.gd`. Result: `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` FAILED (17 pass, 1 fail). Both the exact last-delay assertion (0.88 vs 0.25) and the new margin assertion (1.48 <= 0.851) failed independently. Source restored byte-for-byte from a backup; the file test ran 18/18 green afterwards.

### IN-01: `start_point` dereferences `_ctx` without the null guard `launch_stagger` has

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** edf7e62
**Applied fix:** `start_point` returns the middle of the viewport when `_ctx` is null. Added `test_start_point_before_the_run_is_bound_falls_back_to_mid_screen` to the hardening file (a bare `DawnPayoutVfx` with the two unique-name labels it needs, never bound; the main test file is at the 20-public-method cap).

**Mutation probe:** removed the guard and ran `-gselect=test_dawn_payout_hardening.gd`. The new test FAILED (returned (0,0) instead of (32,32), plus an unexpected script error); the other 3 passed. Guard restored from backup.

### IN-02: `_warn_once` is keyed by title only, so a second, different failure of the same provider is silent

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 532be7a
**Applied fix:** When a provider returns a valid Array, `collect` now clears `_warned[title]`, so a failure after recovery warns again (still once per failure streak, not per refresh). Doc comment on `_warn_once` updated. Added `test_a_flapping_provider_warns_again_after_it_recovers` (fail, fail, recover, fail, fail expects exactly 2 warnings).

**Mutation probe:** removed the new `_warned.erase` in `collect` and ran `-gselect=test_debug_overlay_readonly.gd`. The new test FAILED ("Expected 2 push_warning errors. Got 1"); the other 17 passed. Restored from backup.

### IN-03: Tests for skipped providers are inconsistent about asserting the warning

**Files modified:** `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** c3905c7
**Applied fix:** Added `assert_push_warning("debug overlay section 'Ghost' skipped")` to the freed-provider test and `assert_push_warning("debug overlay section 'Needy' skipped")` to the needs-an-argument test.

**Mutation probe:** replaced the `push_warning` call in `_warn_once` with `pass` and ran the overlay test file. Both `test_a_freed_section_provider_is_skipped_instead_of_crashing` and `test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing` FAILED (along with the other warning-asserting tests; 7 failures in all). Source restored from backup.

---

_Fixed: 2026-09-30T09:30:10Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
