---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T09:42:14Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T09:42:14Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

I reviewed the dawn payout view (`DawnPayoutVfx`), the debug overlay model, and their three test files. I also read `ui/hud/hud.gd`, `hud.tscn` and `SimEvents` to check how the payout view is consumed. No correctness or security defects turned up in the payout view.

Things I traced and found sound:
- **Coin budget:** `_coins_for_amount` and `_coin_share` never divide by zero. Each spot's shares sum to its amount. The coin cap holds for the gold that actually flies.
- **Amount sanitizing:** `_whole_amounts` clamps before `int()`, so the huge-float and near-int64 cases cannot overflow the carried sum.
- **Superseded payouts:** the generation guard, together with killing the delay tweens and freeing the coins, stops a stale payout from touching the HUD. A superseded coin's `_on_coin_arrived` returns before emitting `coin_landed`.
- **HUD hold-back:** the readout is released by the landing coins and, as a backstop, by the DAWN to next phase transition. `PayoutTotal` is a sibling of the vfx node in `hud.tscn`, not a child, so `_reset_for_new_payout` freeing children cannot free it.
- **Overlay model:** `collect()` iterates a duplicate of `_registered` while erasing. Titles are unique, so `Array.erase` value-equality cannot remove the wrong entry.

The one real gap is in the overlay provider guard, below.

## Warnings

### WR-01: Overlay provider guard does not catch a lambda that captured a freed object

**File:** `ui/overlay/debug_overlay_model.gd:52-63`
**Issue:** `collect()` promises to skip a provider whose owner was freed "instead of raising a script error on every refresh". It relies on `Callable.is_valid()`. I verified on Godot 4.7.2 headless that this only covers method Callables and lambdas whose `self` was freed.

A lambda that captured a local Node (for example `func() -> Array: return [["Kids", str(node.get_child_count())]]`) still reports `is_valid() == true` after that node is freed. `provider.call()` then raises "invalid call on previously freed instance" on every refresh. That is the exact failure the guard exists to prevent, and it is the natural way Phase 2 will write providers, e.g. for a wave manager.

The tests only cover `owner_node.get_children` (a method Callable). The lambda-capture case is untested and unguarded.
**Fix:** A script error cannot be caught in GDScript, so the cheapest fix is to narrow the contract. Document in `register_section` that a provider must not capture a node that can be freed before the overlay. Have providers read from `RunContext`, which lives for the whole run, or check `is_instance_valid` inside the lambda. Add a test with a lambda capturing a live object that stays alive, so the supported shape is pinned. Alternatively, let `register_section` take an optional owner `Object` and skip the section when `not is_instance_valid(owner)`.

## Info

### IN-01: Production class exposes several test-only hooks

**File:** `ui/hud/dawn_payout_vfx.gd:91-110`
**Issue:** `get_spawned_count`, `get_launch_delays`, `get_launch_tweens` and `start_point` exist mainly so tests can inspect internals. That is documented, and the project's gdlint public-method cap is already the constraint (`test_dawn_payout.gd:1-4` in the hardening file header). The surface does grow the public API of a HUD node. `get_launch_tweens` in particular hands out live `Tween` references, which a caller could kill or extend.
**Fix:** Optional. Return `duplicate()` of the tween array, or group the hooks under a clearly named `# --- test hooks ---` section. Nothing needs to change now.

### IN-02: Overlay test builds its context from shared cached resources

**File:** `tests/unit/test_debug_overlay_readonly.gd:20`
**Issue:** `RunContext.new(load(PROTOTYPE_MAP), load(TUNING))` passes the cached `.tres` instances straight in. The e2e tests deliberately `duplicate(true)` before mutating them. Nothing in this file mutates the resources today, so this is not a bug. If a later test in the suite, or `RunContext` itself, ever writes to a shared resource, this file's read-only guarantee (DEV-03) would be tested against polluted data.
**Fix:** Use `(load(PROTOTYPE_MAP) as MapConfig).duplicate(true)` and the same for tuning, matching the e2e tests.

---

_Reviewed: 2026-09-30T09:42:14Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
