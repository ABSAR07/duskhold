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
  - tests/unit/test_build_spot.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the building system, the dawn payout VFX, the HUD, the debug overlay model and their unit and e2e tests.
I traced the payout accounting end to end (RunManager `_apply_dawn_payout` -> `dawn_payout` -> `DawnPayoutVfx` -> `payout_started` / `coin_landed` -> `Hud._payout_pending`).
Carried-gold accounting is consistent: a spot's coin shares always sum to its amount, `payout_started` carries exactly the sum of the shares, and the phase-change backstop covers coins that never land.
The HUD change that dropped the `night_started` and `day_started` handlers is sound. `RunManager.start_night` bumps `_night_number` before `_change_phase`, and `_enter_day` bumps `_day_number` before `_change_phase`, so `phase_changed` alone always sees current numbers.
`BuildingSystem` snapshot and skip logic is correct.
No crash, security or data-loss defects were found. The remaining issues are robustness gaps in the new `_whole_amounts` hardening, one HUD/label inconsistency, and minor quality items.

## Warnings

### WR-01: `_whole_amounts` validates amounts but not spot keys, so a bad key still aborts the payout

**File:** `ui/hud/dawn_payout_vfx.gd:161-174` (consumed at 132 and 140)
**Issue:** The docstring promises "one bad entry cannot abort the whole payout", but only the value type is checked. Keys are copied through as-is (`amounts[spot_id] = int(amount)`), and the later loops are typed `for spot_id: StringName in amounts`. A non-string key (for example an `int`, or `null`) makes the typed loop raise a script error and abort `_on_dawn_payout`.
By then `_reset_for_new_payout()` has run and `_pending_total` is set, but `payout_started` was never emitted. The result is a half-initialised payout: the HUD is not told what the coins carry and no total is shown.
The same function also does not guard `int(float)` for non-finite floats (`INF` and `NAN` convert to an implementation-defined integer), so a bad float can slip through as a garbage amount.
**Fix:** Validate the key type in the same pass, and reject non-finite floats:
```gdscript
for spot_id: Variant in per_spot:
	var amount: Variant = per_spot[spot_id]
	var key_ok: bool = spot_id is StringName or spot_id is String
	var amount_ok: bool = amount is int or (amount is float and is_finite(amount))
	if key_ok and amount_ok:
		amounts[StringName(spot_id)] = int(amount)
	else:
		push_warning("dawn payout entry %s ignored: %s" % [spot_id, amount])
```
Add a test with a non-string key alongside the existing float/null-amount test.

### WR-02: The "+X gold" label shows the claimed total while the coins and the HUD readout use the carried gold

**File:** `ui/hud/dawn_payout_vfx.gd:124, 273-275` (asserted by `tests/e2e/test_dawn_payout.gd:207`)
**Issue:** `_pending_total = total` (the claimed total) feeds the label, but the readout is held back and released by `carried` (the sum of the coin shares). The two diverge whenever `per_spot` does not sum to `total`.
Example: `emit(9, {A: 4, B: -2})` flies 4 gold, the HUD lags by 4, and the label then reads "+9 gold". `test_the_coin_cap_follows_the_gold_that_flies_not_the_claimed_total` uses claimed 5 against 120 flying gold. The other tests treat `get_last_total()` as "the full payout", which enshrines the mismatch.
With the real `RunManager` the two are equal, so this only bites when a later payout source (Phase 2 rebuild or LOOP-05 rules) reports a total that differs from `per_spot`. The displayed number would then contradict what the player watched fly in and what the counter gained.
**Fix:** Decide on one source of truth. Either show the carried total (`_pending_total = carried`, set after the planning loop and before `payout_started.emit`), or log a `push_warning` when `carried != total` so the divergence is visible instead of silent. Update the tests to match.

## Info

### IN-01: `_launch` tweens from an earlier payout are never killed on reset

**File:** `ui/hud/dawn_payout_vfx.gd:196-217`
**Issue:** `_reset_for_new_payout` kills `_total_tween` and frees coins, but the per-coin delay tweens created in `_schedule_launch` (`create_tween()` on the VFX node) keep running until they fire. The `generation` guard makes them harmless no-ops, but a payout that supersedes an in-progress one leaves up to `MAX_COINS` orphan tweens alive for up to the previous stagger window.
**Fix:** Keep the scheduling tweens in an `Array[Tween]` and kill them in `_reset_for_new_payout`, or drive one sequential tween per payout. The generation guard can stay as a backstop.

### IN-02: `_count_buildings` allocates a snapshot per spot on every overlay refresh just to test for emptiness

**File:** `ui/overlay/debug_overlay_model.gd:112-117`
**Issue:** `get_instance` now returns a fresh `BuildingInstance` copy (`_snapshot`), so counting buildings allocates one object per occupied spot on every `collect()`. `current_tier(spot_id) > 0` answers the same question without allocating and states the intent more directly.
**Fix:**
```gdscript
if _ctx.buildings.current_tier(spot_id) > 0:
	count += 1
```

### IN-03: A registered section named like a default ("Perf", "Loop", "Agents") shows twice

**File:** `ui/overlay/debug_overlay_model.gd:23-30, 33-38`
**Issue:** `register_section` de-duplicates only against other registered sections. Registering the title "Loop" appends a second "Loop" section after the built-in one. The docstring's "a section never shows twice" therefore holds only among registered sections, and the test helper `_section()` returns the first match, hiding the duplicate.
**Fix:** Reject or warn on titles that collide with the default section names, or document the limitation on `register_section`.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
