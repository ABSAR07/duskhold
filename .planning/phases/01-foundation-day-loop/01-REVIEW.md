---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - simulation/buildings/building_system.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/unit/test_build_spot.gd
  - tests/unit/test_building_system_data_errors.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the building system, HUD, dawn payout VFX, debug overlay model, and the six test files that cover them. Cross-checked against `run_manager.gd`, `economy.gd`, `command_processor.gd`, `map_config.gd`, `map_root.gd`, `hud.tscn`, `prototype_map.tscn` and `e2e_support.gd`.

No crash, security, or data-loss defects were found. The signal wiring is sound: the HUD sits in `run_bound` ahead of its child `DawnPayoutVfx`, so the HUD's `_payout_pending` is set before any coin can land. `bind_run` is idempotent. Coin shares always sum to the per-spot amount. The HUD lag clamps prevent a permanently short readout for the malformed payouts the tests cover.

The remaining issues are robustness gaps in the hardening added this phase, an implicit HUD/VFX invariant, and several tests that claim more than they prove.

## Warnings

### WR-01: Start-night hint reports "(unbound)" for bindings that work

**File:** `ui/hud/hud.gd:154-167`
**Issue:** `_start_night_hint` only recognises `InputEventKey` and `InputEventJoypadButton`. If a runtime rebind maps `start_night` to a trigger (`InputEventJoypadMotion`) or a mouse button, the action fires but the prompt reads "Hold (unbound) to start Night N". A key event with both `physical_keycode` and `keycode` equal to `KEY_NONE` (for example a `key_label`-only event) appends an empty string, which yields a stray " / " or a blank hint. Modifiers on a key event (Ctrl+N) are silently dropped, so the prompt names a key that will not trigger the action.
**Fix:** Handle the other event types, and use `event.as_text()` as the fallback for anything not specially named. Skip empty strings.
```gdscript
for event: InputEvent in InputMap.action_get_events(&"start_night"):
	if event is InputEventJoypadButton:
		pad.append("(%s)" % PAD_BUTTON_NAMES.get((event as InputEventJoypadButton).button_index, event.as_text()))
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadMotion:
		var text: String = event.as_text()
		if not text.is_empty():
			(pad if event is InputEventJoypadMotion else keys).append(text)
```

### WR-02: HUD readout lag is derived independently of the VFX, so it holds only by an unenforced invariant

**File:** `ui/hud/hud.gd:94-101`, `ui/hud/dawn_payout_vfx.gd:99-121`
**Issue:** `Hud._on_dawn_payout` assumes the VFX will land coins carrying exactly `sum(max(amount, 0))` of the payout, and it re-derives that sum on its own. Nothing ties the two together. If a later change makes the VFX skip a spot (an unknown spot, an off-screen spot, a per-frame launch budget), or the VFX is not bound or is freed mid-flight, the HUD holds gold back and never releases it. The `min(total, carried)` clamp only bounds the over-hold, it does not remove it. `coin_landed` is also the only release path: if a coin tween is killed, for example by a node `process_mode` change or a reparent, the readout stays short until the next payout.
**Fix:** Let the VFX be the single source of truth. Have it emit `payout_started(carried_total)` once, after it has computed its coin shares, and have the HUD set `_payout_pending` from that signal rather than from `dawn_payout`. Also clear `_payout_pending` when the phase leaves DAWN or on `day_started`, as a backstop.

### WR-03: The coin cap and the "fits the dawn window" guarantee are not actually enforced

**File:** `ui/hud/dawn_payout_vfx.gd:19-23, 75-79, 126-131`
**Issue:**
- `MAX_COINS` is described as the coin budget of one payout, but `_coins_for_amount` clamps each spot up to at least one coin. With more than 12 paying spots the payout exceeds the budget.
- `_coins_for_amount` scales by the `total` argument, not by the sum of `per_spot`. If the two disagree, the budget check (`total <= MAX_COINS`) is evaluated against the wrong number.
- `launch_stagger` clamps to 0 when `dawn_seconds <= TRIP_SECONDS`. Every coin then launches at once and lands after the dawn window closes, contradicting the method's doc comment.
With the shipped tuning (`dawn_seconds = 2.0`, 12 coins) it works, but a rebalance breaks it silently.
**Fix:** Compute the scale from `carried = sum(per_spot)`. If the coin count would exceed `MAX_COINS`, merge the smallest spots into shared coins, or document that the cap is soft. Say in the `launch_stagger` doc that a window shorter than `TRIP_SECONDS` cannot be met, and log a `push_warning` once at bind time when `dawn_seconds <= TRIP_SECONDS`.

### WR-04: BuildingSystem hardening is inconsistent: empty-id spots are kept and `apply_next_tier` is unguarded

**File:** `simulation/buildings/building_system.gd:21-26, 94-104, 109-123`
**Issue:**
- The constructor skips null and duplicate spots but keeps a spot with `id == &""` (which `MapConfig.validate` reports). `nearest_spot_in_range` can then return `&""`, which every caller treats as "no spot in range". That spot can never be focused. `get_spot(&"")` is also non-null, so `CommandProcessor.validate_build(&"")` would not return `UNKNOWN_SPOT` on such a map. That contradicts the assumption in `test_build_spot.gd:95`.
- `apply_next_tier` will raise the tier past the building's last tier, or create an instance for a building id that has no definition. `test_dawn_income_skips_a_building_whose_id_no_map_building_defines` does exactly this directly. It emits `building_built` with a tier no `tier_def` can resolve. The doc says only `CommandProcessor` calls it, but the rest of this class is defensive against bad data and this method is not.
**Fix:** Skip `spot.id == &""` in `_init` alongside the null and duplicate checks. In `apply_next_tier`, add `if next_tier_def(spot_id) == null: return null` before mutating.

### WR-05: Two e2e tests claim more than they assert

**File:** `tests/e2e/test_dawn_payout.gd:219-245`, `tests/e2e/test_start_night_hold.gd:240-270`
**Issue:**
- `test_a_real_payout_lands_every_coin_inside_a_short_dawn_window` emits `dawn_payout` synthetically while the run is still in DAY, and waits up to `dawn_seconds + SETTLED_S` (4 s). It never measures that the coins land within 1.0 s, and there is no dawn window in play. The final message "every coin landed before the dawn window ended" is unverified. The test would pass with the stagger fix reverted.
- In `test_a_build_hold_is_cancelled_when_the_night_starts`, the "only dawn income moved gold" assertion is vacuous. The test asserts nothing was built, so `dawn_income_by_spot()` is empty and the expectation reduces to `gold == gold_before`. It cannot catch a payout bug.
**Fix:**
- Measure elapsed real time from the emit to `_total_shown`, and assert it is at most `dawn_seconds + slack`. Or drive a real dawn with two houses and a 1.0 s `dawn_seconds`.
- Drop the dawn-income arithmetic from the second test, or build a house on another spot first so the income is non-zero.

## Info

### IN-01: Orphaned comment above the house constants

**File:** `tests/e2e/test_dawn_payout.gd:14-17`
**Issue:** "Real-time allowance on top of the dawn window: tween delays are frame-quantised..." describes a constant that no longer exists. It now sits directly above `HOUSE_ONE`.
**Fix:** Delete the comment, or restore the constant it describes.

### IN-02: PAD_BUTTON_NAMES is Xbox-only

**File:** `ui/hud/hud.gd:17-26`
**Issue:** The A/B/X/Y and LB/RB labels are wrong for PlayStation and Switch pads. The default `start_night` binding (`button_index` 3) reads "(Y)", which is "Triangle" or "X" on other pads.
**Fix:** Fine for Phase 1. Note it as a known limitation, or key the names off `Input.get_joy_name` later.

### IN-03: `_coin_share` does integer division through floats

**File:** `ui/hud/dawn_payout_vfx.gd:135-138`
**Issue:** `floori(float(amount - remainder) / float(coin_count))` is `@warning_ignore("integer_division") amount / coin_count` written the long way. It is correct but obscures intent.
**Fix:** `var base: int = (amount - remainder) / coin_count`, with the warning ignore annotation.

### IN-04: Default-binding test depends on suite order

**File:** `tests/e2e/test_start_night_hold.gd:319-324`
**Issue:** `test_the_prompt_names_the_default_start_night_bindings` hardcodes "N / (Y)". It only passes if no earlier test in any file left `start_night` rebound. This file restores its own bindings, but other files are not covered.
**Fix:** In the test, set the events explicitly from `project.godot` defaults, or compare against text built from `InputMap.action_get_events` in `before_each`.

### IN-05: Debug overlay accepts duplicate titles and cannot detect impure providers

**File:** `ui/overlay/debug_overlay_model.gd:20-22`
**Issue:** `register_section` appends without checking for a duplicate title, so registering twice shows the section twice. The "must only read simulation state" contract is unenforced beyond the 200-collect test, which only covers the default sections.
**Fix:** Either replace an existing entry with the same title, or note in the doc that duplicates are allowed.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
