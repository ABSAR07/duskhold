---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - tests/e2e/test_dawn_payout.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The four files were read in full and cross-checked against `ui/hud/hud.gd`, `ui/hud/hud.tscn`, `simulation/buildings/building_system.gd`, `simulation/events/sim_events.gd` and the GUT addon. `DebugOverlayModel` is sound: the read-only contract holds, the warn-once and replace-in-place paths are consistent, and the tests cover them. `DawnPayoutVfx` has correct generation guarding, HUD hold-back accounting (`payout_started` / `coin_landed` sum to the carried total) and dawn-window stagger math. No blockers. The remaining issues are one input-hardening gap in the VFX (int overflow bypasses the coin cap), one accessor whose behaviour contradicts its doc comment, and one test that dereferences an unchecked null.

## Warnings

### WR-01: Integer overflow in `carried_gold` defeats the coin cap and can spawn a huge number of coins

**File:** `ui/hud/dawn_payout_vfx.gd:135-143, 192, 201-206`
**Issue:** `_whole_amounts` exists to stop malformed `per_spot` entries aborting the payout. It rejects NaN, Inf and non-numbers, but not very large finite values. `int(amount)` on a float such as 1e30 is undefined, and two large int amounts can sum past 2^63. `carried_gold` then wraps to a negative number. `_coins_for_amount` tests `carried_gold <= MAX_COINS`, which is true for a negative value, so it returns `amount` as the coin count. `_on_dawn_payout` then builds a `launches` array of that many dictionaries and hangs the game. The cap is documented as a soft cap that always holds, and this input bypasses it. It needs a corrupt payout to trigger, so it is unlikely in practice, but the function's own goal is to survive malformed data.
**Fix:** Clamp each coerced amount to a sane range in `_whole_amounts` so the sum cannot overflow, and clamp the result of `_coins_for_amount`:
```gdscript
const MAX_AMOUNT: int = 1_000_000
...
amounts[StringName(spot_id)] = clampi(int(amount), -MAX_AMOUNT, MAX_AMOUNT)
...
func _coins_for_amount(amount: int, carried_gold: int) -> int:
	if amount <= 0:
		return 0
	if carried_gold <= MAX_COINS:
		return mini(amount, MAX_COINS)
	return clampi(floori(float(amount) * float(MAX_COINS) / float(carried_gold)), 1, amount)
```

### WR-02: `get_launch_tweens()` returns finished tweens, contradicting its documentation

**File:** `ui/hud/dawn_payout_vfx.gd:94-97, 241-244`
**Issue:** The doc says it returns "the delay tweens ... that have not launched yet". `_launch_tweens` is only appended to in `_schedule_launch` and only cleared in `_reset_for_new_payout`. A tween that has fired and finished stays in the array as an invalid Tween until the next payout. The accessor therefore reports launched coins as pending. `test_a_new_payout_stops_the_pending_launches...` passes only because it reads the array before any tween has fired. The array is also never pruned within a payout.
**Fix:** Prune when a launch fires, or filter on read:
```gdscript
func get_launch_tweens() -> Array[Tween]:
	return _launch_tweens.filter(func(t: Tween) -> bool: return t.is_valid())
```
Alternatively remove the tween from `_launch_tweens` inside `_launch_coin`.

### WR-03: Camera test dereferences a possibly-null `vfx`

**File:** `tests/e2e/test_dawn_payout.gd:233-236`
**Issue:** `test_a_coin_starts_mid_screen_when_its_plot_is_behind_the_camera` calls `vfx.get_viewport()` without the `assert_not_null(vfx)` / early-return guard that every other test in the file uses. If the HUD node is missing, the test dies with a script error instead of a readable assertion failure. It also calls the private `vfx._start_point` directly.
**Fix:** Add the guard used elsewhere:
```gdscript
var vfx: DawnPayoutVfx = _vfx(map_root)
assert_not_null(vfx, "the HUD has a DawnPayoutVfx")
if vfx == null:
	return
```

## Info

### IN-01: `_last_total` is not reset between payouts

**File:** `ui/hud/dawn_payout_vfx.gd:41, 217-233`
**Issue:** `_reset_for_new_payout` clears every other per-payout field but not `_last_total`. After day 1 pays, a day 2 payout with no coins still reports the day 1 total from `get_last_total()`. The doc ("most recent payout whose total was shown") permits this. The test at line 315 (`get_last_total() == 0`, "no total was shown") only passes because it runs on a fresh VFX, so the assertion is weaker than its message.
**Fix:** Either reset `_last_total = 0` in `_reset_for_new_payout`, or make the test messages say "no total yet".

### IN-02: Test-only accessors and private access widen the production surface

**File:** `ui/hud/dawn_payout_vfx.gd:88-97`, `tests/e2e/test_dawn_payout.gd:241, 251`
**Issue:** `get_launch_delays`, `get_launch_tweens` and `get_spawned_count` exist only for tests, and the tests still reach into `_start_point`. Harmless, but the accessors are a coupling point that WR-02 shows can drift from their documentation.
**Fix:** Keep them, but name or annotate them as test hooks, or make `_start_point` a public `start_point` so the test does not use a private member.

### IN-03: Unreachable providers stay registered for the model's lifetime

**File:** `ui/overlay/debug_overlay_model.gd:49-56`
**Issue:** A section whose Callable has gone invalid, or that declares parameters, is skipped on every `collect()` and re-checked on every refresh. It is never pruned. It is warned about once, so nothing breaks. An invalid-callable entry can never recover and could be dropped after the warning.
**Fix:** Optionally remove entries whose `provider.is_valid()` is false after warning. Low priority.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
