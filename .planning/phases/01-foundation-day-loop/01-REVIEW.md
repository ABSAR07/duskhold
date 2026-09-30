---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T10:32:57Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_debug_overlay_registration.gd.uid
  - tests/unit/test_debug_overlay_timed_phases.gd
  - tests/unit/test_debug_overlay_timed_phases.gd.uid
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T10:32:57Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

I reviewed the debug overlay (view and model), the dawn payout VFX, and the three test suites that cover them. I cross-checked them against `hud.gd`, `run_manager.gd`, `sim_events.gd`, `project.godot` and `debug_overlay.tscn`.

I found no crashes, security issues or data-loss bugs. The interplay between `payout_started`, `coin_landed` and the HUD's `_payout_pending` holds up. Superseded payouts are handled by the generation guard. `Hud._on_phase_changed` also resets `_payout_pending` when dawn ends. The overlay's pre-bind registration, owner-lifetime handling and default-title guard behave as documented. The `.uid` files are unique. All signal names in `SIM_SIGNALS` exist in `sim_events.gd`, and the `toggle_debug_overlay` action is defined in `project.godot`.

What remains is one inconsistency in the model's failure reporting, one silent-drop path in the VFX, and some minor quality and test-coverage gaps.

## Warnings

### WR-01: Malformed provider rows are dropped silently, unlike every other provider failure

**File:** `ui/overlay/debug_overlay_model.gd:117-122`
**Issue:** `_clean_rows` discards any row that is not an `Array` of at least 2 elements. A provider that returns `PackedStringArray` rows, a `Dictionary` row, or a 1-element row loses those rows with no message. This contradicts the model's own stated principle at lines 106-107: "A section that silently never shows is hard to notice". Every other provider fault (freed owner, invalid callable, wrong arity, non-Array return) goes through `_warn_once`. If every row is dropped, the section still renders as a bare title with no rows, which looks like a working but empty section.
**Fix:** Warn once when a row is dropped, reusing the existing throttle.
```gdscript
func _clean_rows(title: String, rows: Array) -> Array:
	var clean: Array = []
	var dropped: int = 0
	for row: Variant in rows:
		if row is Array and (row as Array).size() >= 2:
			clean.append([str(row[0]), str(row[1])])
		else:
			dropped += 1
	if dropped > 0:
		_warn_once(title, "%d malformed row(s) dropped; rows must be [label, value]" % dropped)
	return clean
```
Note that `collect` erases `_warned[title]` on every successful call at line 75. That erase would need to move so it does not re-arm the warning on every refresh. For example, re-arm only when `dropped == 0`.

### WR-02: A payout with a positive `total` but only bad or negative `per_spot` entries gives no "+X gold" total and no feedback beyond a warning

**File:** `ui/hud/dawn_payout_vfx.gd:151-194`
**Issue:** The early return for `total <= 0` (lines 151-153) skips `per_spot` entirely. It is silent even when `per_spot` holds positive amounts, whereas the mismatch case at line 183 warns. A `total <= 0` payout that still carries gold in `per_spot` is a claim/detail disagreement of the same kind, and it currently produces neither coins nor a warning. The reverse case (`total > 0`, `carried == 0`) correctly emits `payout_started(0)` and warns, but nothing is shown. In that case the Economy has already been credited and the HUD is not held back, so the counter jumps with no attribution. The comment at lines 193-194 acknowledges this as intentional. The test file does not exercise the `total > 0`, `carried == 0` path. `test_a_payout_with_no_coins_does_not_report_the_previous_payouts_total` uses `emit(0, {})`, which only covers the early return.
**Fix:** Warn in the `total <= 0` branch when `per_spot` is non-empty. Add an e2e case for `emit(5, {})` or `emit(5, {HOUSE_ONE: -3})`. It should assert `get_last_total() == 0`, that `payout_started` is emitted with 0, and that the HUD readout matches the ledger immediately.
```gdscript
if total <= 0:
	if not per_spot.is_empty():
		push_warning("dawn payout claims %d gold but lists per-spot amounts; nothing shown" % total)
	payout_started.emit(0)
	return
```

## Info

### IN-01: `_is_gone` and `_skip_reason` duplicate the owner/validity checks

**File:** `ui/overlay/debug_overlay_model.gd:84-103`
**Issue:** Both functions re-derive "owner freed" and "callable invalid". The rules can drift, for example if a third permanent-failure reason is added to one and not the other. `collect` calls both for every skipped entry.
**Fix:** Have `_skip_reason` return a reason and let `_is_gone` be derived from it. Alternatively return a small struct or tuple `{reason, permanent}` from one function.

### IN-02: The read-only assertion covers only part of the simulation state

**File:** `tests/unit/test_debug_overlay_timed_phases.gd:60-73`
**Issue:** `_assert_collecting_is_read_only` checks gold, phase, timer, elapsed and the events. The model also reads `buildings.current_tier`, `spot_ids`, `get_unit_count` and `get_enemy_count`. A regression that mutated building state, for example lazily initialising a spot's tier inside a getter, would go unnoticed.
**Fix:** Snapshot `_count_buildings()`-equivalent state before and after, such as `current_tier` for every spot id plus the unit and enemy counts, and assert them unchanged.

### IN-03: The registration tests bypass the toggle path, and the visible-refresh timing is wall-clock dependent

**File:** `tests/unit/test_debug_overlay_registration.gd:25-28`
**Issue:** `_shown_text` sets `overlay.visible = true` directly and waits 0.35 s for the 0.25 s refresh interval. This never exercises `_process`'s `toggle_debug_overlay` branch (which refreshes immediately on show). The 0.10 s margin also depends on frame deltas under CI load. The tests would be tighter, and independent of the interval, if they forced a refresh through the same path the player uses, for example with `Input.action_press` and `Input.action_release`.
**Fix:** Simulate the toggle input with `Input.parse_input_event` or `action_press` and then await one process frame. That gives an immediate `_refresh()` and no timing margin.

---

_Reviewed: 2026-09-30T10:32:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
