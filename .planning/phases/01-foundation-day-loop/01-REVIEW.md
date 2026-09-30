---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - simulation/buildings/building_system.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/unit/test_building_system_data_errors.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the building system, the HUD and dawn-payout view, the debug overlay model and their unit and e2e tests. Cross-checked against `MapConfig.validate`, `RunContext`, `RunManager._apply_dawn_payout`, `SimEvents`, `hud.tscn`, `E2eSupport` and the GUT 9.7.1 error tracker.

No correctness bugs or security problems were found in the shipped logic. I traced these paths and found no defect:

- Coin share arithmetic: no modulo by zero, and a spot's shares always sum to its amount.
- HUD held-back gold accounting: `payout_started` assigns rather than adds, coin arrivals are clamped, and the phase-change backstop covers a dawn shorter than one coin trip.
- The generation guard on stale launches and arrivals.
- Empty and duplicate id handling in `BuildingSystem` against `validate()`.
- The GUT push-error and push-warning assertions: the count assertion includes already-handled entries, so `assert_push_warning` followed by `assert_push_warning_count(1)` passes.

The findings below are robustness gaps in the debug overlay's error reporting and test-reliability risks.

## Warnings

### WR-01: A provider that returns a non-Array is skipped silently, contradicting the "warn once" design

**File:** `ui/overlay/debug_overlay_model.gd:45-47`
**Issue:** `_warn_once` exists because "a section that silently never shows is hard to notice". Invalid callables and providers with parameters get a warning, but a provider that returns `null` or a `String` (`if rows is Array`) is dropped with no diagnostic. `test_a_provider_that_returns_a_non_array_is_skipped_instead_of_crashing` locks that silence in. A Phase 2 wave provider that returns `null` by mistake produces a missing section and no clue why.
**Fix:**
```gdscript
var rows: Variant = provider.call()
if rows is Array:
	sections.append(_section(entry["title"], _clean_rows(rows)))
else:
	_warn_once(entry["title"], "it returned %s, not an Array of rows" % type_string(typeof(rows)))
```
Add a `push_warning` assertion to the test.

### WR-02: `_warned` is never cleared when a provider is re-registered

**File:** `ui/overlay/debug_overlay_model.gd:23-28, 62-66`
**Issue:** `register_section` replaces the provider for an existing title but leaves `_warned[title]` set. If a broken provider is replaced by another broken one, or a fixed one later breaks, the new failure is never reported. The one-shot suppression is keyed by title, not by provider.
**Fix:** In the replace branch, add `_warned.erase(title)` before returning.

### WR-03: Wall-clock-dependent e2e assertions can flake on a slow or loaded runner

**File:** `tests/e2e/test_dawn_payout.gd:104-110`, `tests/e2e/test_start_night_hold.gd:100-104`
**Issue:**
- `test_coins_are_in_flight_and_the_counter_lags_early_in_dawn` says "no real-time wait, so no race", but it relies on the first coin (0.6 s trip) still being airborne after `wait_until` returns and one more frame. A hitch over 0.6 s, such as a first-frame shader compile or CI contention, lands the coin and fails `assert_lt(shown, gold)` and `assert_gte(live_coin_count, 1)`.
- `test_a_tap_fills_the_prompt_but_releasing_early_keeps_the_day` waits 30% of the hold in real time, then asserts the ratio is below 1.0. A stall of more than 70% of the hold time flips it.

**Fix:** Assert immediately after the phase change, with no extra frame wait, or drive the payout deterministically with a direct `ctx.events.dawn_payout.emit(...)` followed by an immediate check (other tests here already do this). For the hold test, hold a slower-tuned duplicate (`start_night_hold_seconds` at 5 s or more) so the 30% mark has wide margin.

## Info

### IN-01: `BuildingSystem.get_instance` hands out the live mutable instance, contradicting the "reads never mutate" contract

**File:** `simulation/buildings/building_system.gd:3-4, 50-52`
**Issue:** The header says only `apply_next_tier` mutates, and `DebugOverlayModel` is documented as strictly read-only. `get_instance` returns the stored `BuildingInstance`, whose `tier` is a plain public field. Any reader (an overlay section provider, a view) can bump it without emitting `building_built` or going through `CommandProcessor`. The same applies to the shared `BuildSpotDef` and `BuildingDef` resources. The read-only test cannot catch this, because it only exercises the model's own getters.
**Fix:** Have `get_instance` return a duplicate or a read-only snapshot, or document the caveat and give callers `current_tier()` and friends. If it stays as is, soften the "never mutate" wording.

### IN-02: `DawnPayoutVfx._on_dawn_payout` trusts untyped Dictionary values as `int`

**File:** `ui/hud/dawn_payout_vfx.gd:127-132, 140`
**Issue:** `per_spot` arrives as an untyped `Dictionary`. `for amount: int in per_spot.values()` and `var amount: int = per_spot[spot_id]` raise a runtime type error inside a signal handler if a value is a float or null. That would happen after `_reset_for_new_payout` has already run and after the Economy was credited. `RunManager` emits ints today, so this only matters if a later payout source (Phase 2 rebuild refunds) emits floats.
**Fix:** Coerce once, for example `var amount: int = int(per_spot[spot_id])`, or skip non-int values with a warning.

### IN-03: Redundant HUD refresh triggers and a test that emits synthetic phase transitions

**File:** `ui/hud/hud.gd:118-131`, `tests/e2e/test_dawn_payout.gd:382`
**Issue:**
- `_on_night_started` and `_on_day_started` only call `_refresh_loop()`, and `_on_phase_changed` already calls it for every transition, so the two extra connections do redundant work.
- `test_the_hud_releases_a_held_back_readout_when_dawn_ends` emits a fake `phase_changed(DAWN, DAY)` on the real `ctx.events` while the run is actually in DAY. Every other subscriber on that bus (lighting, controllers) also receives the bogus transition, so the test can pass or fail for reasons unrelated to the HUD.

**Fix:** Drop the two redundant handlers, or keep them and note why. In the test, call `hud._on_phase_changed(...)` directly, or drive a real dawn to day transition with `run_manager.tick`.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
