---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T12:38:01Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - tests/support/overlay_test_support.gd
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_overlay_test_support.gd
  - tests/unit/test_overlay_test_support.gd.uid
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T12:38:01Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the debug overlay view and model and the shared overlay test support with its suites. I traced the pre-bind and post-bind registration paths, the owner and title validation, the replay in `bind_run`, the skip and warn-once state machine in `collect`, and the deep-copy helpers. I found no correctness or security defects that break the shipped behavior. The pending-section replay, the WeakRef owner handling, the Variant `lifetime_owner` (freed-instance safe) and the read-only guarantees hold up. The remaining findings are one robustness gap (a null `RunContext` is accepted and then fails on every refresh) and minor test-support weaknesses.

The `.uid` file is a single-line valid uid, and its value is unique across the repo's `.uid`, `.tscn`, `.tres` and `.gd` files. The `toggle_debug_overlay` action exists in `project.godot` with key and gamepad bindings, and `DebugOverlay` is instanced in `hud.tscn` in the `run_bound` group.

## Warnings

### WR-01: `bind_run(null, ...)` is accepted and then raises a script error on every refresh

**File:** `ui/overlay/debug_overlay.gd:28-34`
**Issue:** `bind_run` guards against a repeated bind, but not against a null `ctx`. With `ctx == null` it sets `_ctx = null` and `_model = DebugOverlayModel.new(null)`. That call is not refused, and `_model != null` also makes every later `bind_run` a silent no-op. As soon as the overlay is shown, `_refresh` calls `collect`, which dereferences `_ctx.run_manager` in `_loop_rows`. The result is a script error every `REFRESH_INTERVAL_S` while visible, with no message pointing at the real cause. The overlay ships in release builds (see the class doc), and the run_bound group order is documented as not guaranteed, so a caller wiring mistake is plausible. The rest of this class is deliberately defensive about caller mistakes (owner, title, rebind), so this gap is inconsistent with it.
**Fix:**
```gdscript
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if ctx == null:
		push_warning("debug overlay bind_run ignored: no RunContext")
		return
	if _model != null:
		...
```
Returning before `_model` is set also lets a later valid `bind_run` still succeed.

## Info

### IN-01: `context_with_one_house` indexes `spot_ids()[0]` unguarded and carries on after a failed assert

**File:** `tests/support/overlay_test_support.gd:30-33`
**Issue:** If a map ever has no spots, `spot_ids()[0]` raises an out-of-bounds script error instead of a readable assertion. A rejected build is only recorded with `assert_eq` and the helper still returns the context, so the calling suites fail later with less useful messages (for example "Buildings: 1" mismatches).
**Fix:** Assert `not spot_ids.is_empty()` first, and return the context early when the first assert fails, or use `test.assert_true(...)` plus `if spot_ids.is_empty(): return ctx`.

### IN-02: `new_tuning()` deep-copies differently from `new_map()`

**File:** `tests/support/overlay_test_support.gd:14`
**Issue:** `new_map()` uses `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` because `duplicate(true)` leaves external subresources shared (the reason given in its own doc comment). `new_tuning()` still uses `duplicate(true)`. `LoopTuning` holds only scalar exports today, so nothing leaks, but the day a subresource is added, a test that edits it would leak into later suites, which is the exact failure this helper exists to prevent. `test_editing_a_new_tuning_copy_leaves_the_cached_tuning_alone` only checks a scalar, so it would not catch that.
**Fix:** Use `.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` in `new_tuning()` as well.

### IN-03: Rows longer than two entries are accepted silently, and the first test in `test_overlay_test_support.gd` can pass vacuously

**File:** `ui/overlay/debug_overlay_model.gd:190` and `tests/unit/test_overlay_test_support.gd:12-23`
**Issue:** `_clean_rows` keeps any Array with `size() >= 2`, so `["a", "b", "c"]` is truncated to two columns without a warning. That is inconsistent with the malformed-row warning "rows are [label, value]" and hides a provider mistake. Separately, `test_new_map_shares_no_building_definition_or_tier_with_the_cached_map` only compares sizes to the cached map. If the map had no buildings, or a definition had no tiers, the loops would run zero times and the test would pass without checking anything.
**Fix:** Either require `size() == 2` in `_clean_rows` (and count the others as dropped), or document that extra elements are ignored. In the test, add `assert_gt(copy.buildings.size(), 0)` and the same for `tiers`.

---

_Reviewed: 2026-09-30T12:38:01Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
