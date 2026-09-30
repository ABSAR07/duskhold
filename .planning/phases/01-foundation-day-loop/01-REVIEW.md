---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/e2e/test_dawn_payout_hardening.gd.uid
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 6

## Summary

I read all six files in full and cross-checked them against `hud.gd`, `run_manager.gd`, `sim_events.gd`, `E2eSupport.wait_until` and the vendored GUT 9.7.1 error tracker. The prior review fixes hold up. Payout amounts are clamped before the int cast. Delay tweens are killed when a payout is superseded. Malformed `per_spot` entries are dropped one by one. Invalid overlay providers are warned about once and then dropped.

I found no crashes, security problems or data-loss risks. I checked the GUT semantics the tests rely on:
- `assert_push_warning_count` counts handled warnings, so it works after `assert_push_warning`.
- `push_warning` does not fail a test, so the tests that don't assert warnings are safe.
- `SIM_SIGNALS` matches the seven signals in `sim_events.gd` exactly.
- The `.uid` value is unique in the repo.
- `test_dawn_payout.gd` is at exactly 20 public methods, the `max-public-methods` limit in `.gdlintrc`.

One design edge and three minor items remain.

## Warnings

### WR-01: A tightened stagger leaves zero slack, so the last coin can land after dawn ends

**File:** `ui/hud/dawn_payout_vfx.gd:113-117`
**Issue:** `launch_stagger` returns `(dawn_seconds - TRIP_SECONDS) / (coin_total - 1)`, so the last coin is scheduled to land at exactly `dawn_seconds`. The test at `tests/e2e/test_dawn_payout.gd:286-290` even pins this with a +0.001 tolerance. The two clocks are not the same:
- Dawn ends in `RunManager.tick`, which advances by simulation steps.
- The coin delay tweens and flight run on the process clock.

Any frame-boundary skew therefore lets the final coin arrive after `phase_changed(DAWN -> DAY)`. The HUD backstop (`hud.gd:_on_phase_changed`) has already zeroed `_payout_pending` by then. The readout jumps to the full ledger amount before the last coin visibly lands, and "+X gold" appears during the day. The default tuning (12 coins at most, 2.0 s dawn) has about 0.5 s of slack, so it does not trigger today. It will once a later phase has more than 12 paying spots or a shorter dawn, which is the case the tightening exists for.

**Fix:** Reserve a margin when computing the stagger:
```gdscript
const DAWN_MARGIN_SECONDS: float = 0.15
var window: float = _ctx.tuning.dawn_seconds - TRIP_SECONDS - DAWN_MARGIN_SECONDS
return clampf(window / float(maxi(coin_total - 1, 1)), 0.0, STAGGER_SECONDS)
```
Update the two tests that assert the exact fill (`test_a_crowded_payout_tightens_the_stagger...` and `test_a_real_payout_schedules_its_last_coin...`) to include the margin.

## Info

### IN-01: `start_point` dereferences `_ctx` without the null guard `launch_stagger` has

**File:** `ui/hud/dawn_payout_vfx.gd:292-294`
**Issue:** `start_point` is public and documented as callable from tests. Before `bind_run` it hits `_ctx.buildings` on a null `_ctx` and raises a script error. `launch_stagger` handles the same unbound state and has a test for it (`test_launch_stagger_before_the_run_is_bound...`).
**Fix:** Add `if _ctx == null: return get_viewport_rect().size * 0.5` at the top of `start_point`.

### IN-02: `_warn_once` is keyed by title only, so a second, different failure of the same provider is silent

**File:** `ui/overlay/debug_overlay_model.gd:84-88`
**Issue:** A provider that returns a non-Array once, then rows, then a non-Array again gets one warning in total. This is harmless today because `_warned` is cleared only on replacement or drop. It would hide a flapping provider once Phase 2 registers real wave sections.
**Fix:** Key the warning by `title + reason`, or clear `_warned[title]` when the provider returns a valid Array.

### IN-03: Tests for skipped providers are inconsistent about asserting the warning

**File:** `tests/unit/test_debug_overlay_readonly.gd:124-135, 160-168`
**Issue:** `test_a_freed_section_provider_is_skipped...` and `test_a_provider_that_needs_an_argument...` trigger a `push_warning` but never assert it. Sibling tests do assert it. The tests pass, because GUT does not fail on warnings, but they don't pin the "skipped with a warning" behaviour they are named for.
**Fix:** Add `assert_push_warning("debug overlay section 'Ghost' skipped")` and `assert_push_warning("debug overlay section 'Needy' skipped")` respectively.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
