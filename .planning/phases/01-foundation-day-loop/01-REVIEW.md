---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T13:22:42Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - tests/unit/test_debug_overlay_providers.gd
  - tests/unit/test_overlay_test_support.gd
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

**Reviewed:** 2026-09-30T13:22:42Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

I read the overlay view, the overlay model, the provider suite and the OverlayTestSupport suite in full. I also read `tests/support/overlay_test_support.gd`, `debug_overlay.tscn` and the registration suite, to check the callers and helpers these files depend on.

I found no bugs in the production code. I traced these paths and each held up:
- pre-bind registration and replay
- the WeakRef owner handling
- the Skip code and GONE_FOR_GOOD flow
- the warn-once re-arm logic
- row cleaning
- the toggle and refresh path

The overlay stays read-only. It only calls RunContext getters, and provider exceptions are the documented caller responsibility.

The remaining findings are about test reliability and hygiene. They matter mostly on the day a guard regresses. One warning: a test writes into a resource that would be shared if the guard broke, and it never restores it.

## Warnings

### WR-01: Mutating test can poison the cached map for every later suite when the guard it tests regresses

**File:** `tests/unit/test_overlay_test_support.gd:30-44`
**Issue:** `test_editing_a_new_map_copy_leaves_the_cached_map_and_later_copies_alone` writes `cost`, `dawn_income` and `spots[0].position` on the copy. If `new_map()` ever shares a building definition, tier or spot with the cached `load(PROTOTYPE_MAP)` (the regression this suite exists to catch), those writes land on the cached resource. Nothing restores them. The test then fails, but the dirtied cache stays in place for the rest of the run, so unrelated suites fail or pass depending on script order. That is exactly the order dependence this file's header says it prevents. The failure is then misattributed to other suites, which makes it harder to diagnose.
**Fix:** Restore the cached values on the way out, so a failure stays local. `add_child_autofree` does not help here, because these are plain Resources. Use something like:
```gdscript
var cached_tier: BuildingTier = cached.buildings[0].tiers[0]
var spot_before: Vector3 = cached.spots[0].position
# ... mutate the copy and assert ...
cached_tier.cost = cost_before
cached_tier.dawn_income = income_before
cached.spots[0].position = spot_before
```
Alternatively, write into a sentinel that the copy is asserted not to share, using identity checks only (test 1 already does this) and no value mutation.

## Info

### IN-01: Local `name` shadows `Node.name` in a GutTest

**File:** `tests/unit/test_overlay_test_support.gd:77`
**Issue:** `var name: String = property["name"]` shadows the inherited `Node.name` member of `GutTest`. Godot's default SHADOWED_VARIABLE_BASE_CLASS warning fires. `project.godot` does not silence it, and gdlint does not catch it.
**Fix:** Rename it, for example `var prop_name: String = property["name"]`, and use `prop_name` in the two `get(...)` calls and in the assert message.

### IN-02: `test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning` is vacuous today and its final assert overstates what it checks

**File:** `tests/unit/test_overlay_test_support.gd:66-81`
**Issue:** LoopTuning has no subresource, so the inner assert never runs. The closing `assert_gt(checked, 0, "... so the loop above checked something")` counts properties, not resources, so it passes while checking nothing. Three limits mean it will not catch some future regressions:
- `get_script().get_script_property_list()` lists only properties declared in LoopTuning's own script. A resource-typed property inherited from a future base script is missed.
- `_resources_in` inspects only resources held directly, or one Array or Dictionary level down. A shared resource nested inside a subresource is not found.
- The comment already admits the test passes trivially now.

**Fix:** State that limit in the assertion message instead of implying coverage. Consider walking the property list of each found resource recursively, and including base-script properties. An alternative is to guard the promise structurally, for example by asserting `OverlayTestSupport.new_tuning()` uses `Resource.DEEP_DUPLICATE_ALL`.

### IN-03: Pre-bind registration warns about a replaced section whose owner was freed

**File:** `ui/overlay/debug_overlay.gd:40-48`
**Issue:** `_pending` keeps every pre-bind registration, including two with the same title. At replay, the first entry (owner freed before bind) raises "not registered ... its owner was freed before bind_run", even though the second registration would have replaced it anyway. This is a harmless but noisy warning, in the one case where the caller already fixed the problem. It also means the pre-bind path and the post-bind path differ: post-bind, a replacement with the same title silently supersedes the old one.
**Fix:** Optional. Replace an existing pending entry with the same title at registration instead of appending, for example by scanning `_pending` for a matching `title` and overwriting it. That matches the model's replace-in-place semantics and drops the stale warning.

---

_Reviewed: 2026-09-30T13:22:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
