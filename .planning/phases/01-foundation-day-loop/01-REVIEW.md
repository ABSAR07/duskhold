---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T13:46:36Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_overlay_test_support.gd
  - ui/overlay/debug_overlay.gd
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T13:46:36Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

I reviewed `ui/overlay/debug_overlay.gd` and its two test suites. I also read `debug_overlay_model.gd`, `debug_overlay.tscn`, `overlay_test_support.gd`, `map_root.gd` and `map_config.gd` to check the call chains.

The production code is sound. The pending-section buffer, the replace-in-place rule, the refusal checks and the `bind_run` idempotency all agree with `DebugOverlayModel`. I found no crash, security or data-loss defect.

The findings are in test reliability: one assertion can pass when it should fail, one branch has no coverage, and one test cannot fail today.

## Warnings

### WR-01: Spot-position check in the cache-isolation test passes when the copy shares the spot with the cache

**File:** `tests/unit/test_overlay_test_support.gd:56`
**Issue:** The test writes `Vector3(123, 0, 456)` to `copy.spots[0].position`, captures `spot_seen` from the cached map, then restores the cached position at line 52. Only then does it assert `assert_ne(spot_seen, copy.spots[0].position)`.

If `new_map()` regressed and `copy.spots[0]` were the same `BuildSpotDef` as `cached.spots[0]`:
- `spot_seen` would be `(123, 0, 456)`, because the write reached the cache.
- The restore at line 52 would reset the shared object, so `copy.spots[0].position` would read back `spot_before`.
- The two values would differ and the assertion would pass.

The cost and income checks are safe because they compare values captured before the restore. The spot check is the one that hides the failure it was written to catch. The first test, `test_new_map_shares_no_building_definition_or_tier_with_the_cached_map`, does not look at spots either, so nothing else covers this.

**Fix:** Compare against the value that was written, not the copy's current property:
```gdscript
const EDITED_SPOT := Vector3(123.0, 0.0, 456.0)
...
copy.spots[0].position = EDITED_SPOT
...
assert_ne(spot_seen, EDITED_SPOT, "and its spot position")
```
Better still, reuse the generic helper that already exists in this file:
```gdscript
assert_eq(_shared_resources(load(OverlayTestSupport.PROTOTYPE_MAP), OverlayTestSupport.new_map()),
	[] as Array[Resource], "the map copy shares no subresource with the cache")
```
This covers spots, buildings and tiers at any depth, and it is what `_shared_resources` is for. It is currently applied only to `LoopTuning`.

### WR-02: The replay of a pending section with a live owner is not tested

**File:** `tests/unit/test_debug_overlay_registration.gd` (gap), `ui/overlay/debug_overlay.gd:42-49`
**Issue:** The suite covers a pending owner that is already freed at `bind_run` (line 114) and one that was replaced (line 131). Nothing covers a pending owner that is alive at `bind_run` and freed afterwards. That path is line 49, `_model.register_section(entry["title"], entry["provider"], lifetime_owner)`, and it is the only place the pending owner is handed on to the model. If `lifetime_owner` were dropped there (for example, the call changed to pass `null`), every test in this file would still pass. The section would then never end when its owner is freed, and the provider would call a freed node.

`test_debug_overlay_providers.gd` tests the model's owner handling, but not the overlay's replay.

**Fix:** Add a test along these lines:
```gdscript
func test_a_pending_section_whose_owner_is_freed_after_bind_run_is_dropped() -> void:
	var overlay: DebugOverlay = _overlay()
	var watched: Node = Node.new()
	overlay.register_section("Watched", func() -> Array: return [["Kids", str(watched.get_child_count())]], watched)
	overlay.bind_run(_context(), null)
	var before: String = await _shown_text(overlay)
	assert_string_contains(before, "Kids: 0")
	watched.free()
	await wait_seconds(DebugOverlay.REFRESH_INTERVAL_S * 2.0)
	assert_false(overlay.get_text().contains("Watched"))
	assert_push_warning("debug overlay section 'Watched' skipped: its owner was freed")
```

### WR-03: `test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning` cannot fail today

**File:** `tests/unit/test_overlay_test_support.gd:79-91`
**Issue:** The test's own comment says it "passes without checking anything yet", because `LoopTuning` has no subresource. It is a green check that guards nothing until someone adds a subresource. The companion test at line 94 proves the helper works on stand-in resources, which is the useful part. This one adds only a false sense of coverage.

**Fix:** Replace it with the `MapConfig` sharing check from WR-01, which is meaningful today. The stand-in test at line 94 already proves the helper works, and a `LoopTuning` check can be added back when it gains a subresource.

## Info

### IN-01: The Ghost test does not pin the warning count or the "before bind_run" wording

**File:** `tests/unit/test_debug_overlay_registration.gd:128`
**Issue:** `assert_push_warning("debug overlay section 'Ghost' not registered: its owner was freed")` is a substring match. The overlay emits `... its owner was freed before bind_run` (`debug_overlay.gd:46`). A regression that dropped the "before bind_run" suffix, or emitted the warning twice, would still pass. Most neighbouring tests do assert `assert_push_warning_count(...)`.
**Fix:** Add `assert_push_warning_count(1, "the freed owner is named once")` and match the full text including `before bind_run`.

### IN-02: A bind while the overlay is visible shows stale text for up to 0.25 s

**File:** `ui/overlay/debug_overlay.gd:39-50`
**Issue:** If the player has toggled the overlay on before `bind_run` runs, `_refresh()` returned early because `_model == null`. The label stays empty until the next 0.25 s refresh tick. In practice `MapRoot._ready` binds before the first input, so this is cosmetic.
**Fix:** Optionally end `bind_run` with `if visible: _refresh()`.

### IN-03: Overlay processing follows the tree's pause state

**File:** `ui/overlay/debug_overlay.gd:96`, `ui/overlay/debug_overlay.tscn`
**Issue:** The scene sets no `process_mode`, so it inherits the parent's mode. If a later phase pauses the tree (a pause menu, for example), the F3 toggle and the refresh stop working while paused. The overlay is a dev tool, so this is low priority. It is worth deciding on before Phase 2 adds paused states.
**Fix:** Set `process_mode = Node.PROCESS_MODE_ALWAYS` on the DebugOverlay node if it should stay usable while paused.

---

_Reviewed: 2026-09-30T13:46:36Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
