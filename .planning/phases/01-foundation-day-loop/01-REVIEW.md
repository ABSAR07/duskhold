---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T11:01:16Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_debug_overlay_timed_phases.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T11:01:16Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the dawn payout VFX, the debug overlay model and their four test files. Cross-checked against `ui/hud/hud.gd` (payout_started / coin_landed consumers), `simulation/run/run_manager.gd` (dawn payout emission and phase clocks), `simulation/buildings/building_system.gd` (`dawn_income_by_spot`) and `simulation/events/sim_events.gd`.

I found no correctness or security defects in the production code. I traced these paths:

- coin-count and share arithmetic: no division by zero, since `_coin_share` is only reached for `coin_count >= 1`, and shares always sum to the spot amount.
- clamping against int overflow.
- generation guards against superseded payouts.
- the HUD held-back readout, which is reset by every `payout_started`, including the 0 case.
- the model's skip, drop and warn-once state machine, including the re-registration path.

The findings below are test-maintenance and quality issues, not shipping bugs.

## Warnings

### WR-01: `SIM_SIGNALS` is duplicated, and only one copy has a drift guard

**File:** `tests/unit/test_debug_overlay_timed_phases.gd:9-17` (copy of `tests/unit/test_debug_overlay_readonly.gd:8-16`)
**Issue:** The list of simulation signals is duplicated verbatim in two files. `test_debug_overlay_readonly.gd` guards its copy with `test_the_watched_signals_are_every_signal_the_simulation_declares` (line 299), which fails when `SimEvents` gains a signal. The copy in `test_debug_overlay_timed_phases.gd` has no such guard. When a new SimEvents signal is added, the readonly test fails and the developer updates that list. The timed-phases list then silently under-watches, so its night and dawn "collecting emits no events" checks stop covering the new signal while staying green. Those two tests are the only place the read-only guarantee is checked in NIGHT and DAWN.
**Fix:** Keep one source of truth and share it. For example, move the list to a small helper such as `tests/support/sim_signals.gd` (`const ALL: Array[String] = [...]`, next to `E2eSupport`). Reference it from both files, keep the drift-guard test with it, and delete the local `SIM_SIGNALS` constants. Alternatively, derive the list at runtime from `SimEvents.new().get_script().get_script_signal_list()` in both files, which removes the maintenance point entirely.

## Info

### IN-01: Control flow in `DebugOverlayModel` depends on free-text reason strings

**File:** `ui/overlay/debug_overlay_model.gd:96-111`
**Issue:** `_skip_reason` returns a human-readable message that `_is_gone` compares against two constants to decide whether to erase the entry. The same string is also used as warning text. A typo, a reworded message, or a new "permanent" reason added without updating `_is_gone` silently makes a permanent failure transient. The failed provider is then re-checked on every refresh instead of dropped. The comment on the constants acknowledges the coupling, but the design still relies on a comment.
**Fix:** Return a small enum or `StringName` code from `_skip_reason` (for example `SKIP_NONE`, `SKIP_OWNER_FREED`, `SKIP_CALLABLE_INVALID`, `SKIP_NEEDS_ARGS`) and map it to message text in one place, so `_is_gone` compares codes rather than prose.

### IN-02: Dead tuning setup in the hardening e2e test

**File:** `tests/e2e/test_dawn_payout_hardening.gd:8, 18`
**Issue:** `before_each` sets `_tuning.placeholder_night_seconds = FAST_NIGHT_S`, but no test in this file starts a night. Every test emits `dawn_payout` directly on the events bus. The constant and the assignment have no effect and imply a night-driven scenario that does not exist. Anyone changing dawn or night timing may assume this file depends on it.
**Fix:** Delete `FAST_NIGHT_S` and the assignment, keeping only the duplicated tuning. Or drop `_tuning` entirely and let `_spawn` pass the default resource duplicate.

### IN-03: Test name and message use "owner freed" for a case with no owner

**File:** `tests/unit/test_debug_overlay_readonly.gd:142-162`
**Issue:** `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning` registers `owner_node.get_children` without a `lifetime_owner`. The warning it asserts is "its callable is no longer valid", not "its owner was freed". "Owner" here means the method's target object. In the neighbouring test (line 165) "owner" means the `lifetime_owner` argument and produces the other reason string. The overloaded word makes it hard to see which of the two `REASON_*` paths each test pins. The scenario at line 128 (`test_a_freed_section_provider_is_skipped_instead_of_crashing`) also covers the same registration, which makes the overlap more confusing.
**Fix:** Rename to something like `test_a_provider_with_an_invalid_callable_is_dropped_after_its_one_warning`. Keep "owner freed" only for the `lifetime_owner` tests.

### IN-04: The clamp e2e test does not check what it claims about the amounts

**File:** `tests/e2e/test_dawn_payout_hardening.gd:74-96`
**Issue:** The test name says the amounts are clamped so the coin cap holds. It asserts that `payout_started` carries `2 * MAX_AMOUNT`, that the delay count is at most `MAX_COINS`, that the HUD settles, and that each spot sent at least one coin. It does not assert `vfx.get_last_total()` after the flight or the number of coins actually sent. The HUD-settled check only proves the landed shares sum to the announced total, and it can pass even if the cap were hit in a different way. The `<= MAX_COINS` check is also loose: with two spots at the clamped amount the plan is exactly 12 coins (6 per spot), so an assertion of equality would catch regressions in the proportional split.
**Fix:** After the wait, add `assert_eq(vfx.get_last_total(), clamped_total)` and assert `vfx.get_launch_delays().size() == DawnPayoutVfx.MAX_COINS`, or assert 6 spawned per spot.

---

_Reviewed: 2026-09-30T11:01:16Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
