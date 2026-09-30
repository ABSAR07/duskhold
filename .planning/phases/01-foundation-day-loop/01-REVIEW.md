---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T12:17:18Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - tests/support/overlay_test_support.gd
  - tests/unit/test_debug_overlay_providers.gd
  - tests/unit/test_debug_overlay_registration.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T12:17:18Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the debug overlay view (`DebugOverlay`), its view model (`DebugOverlayModel`), the shared
test helper (`OverlayTestSupport`) and the two suites for provider and registration handling.

I traced every test against the model and view code:
- `collect()`: the skip, warn-once and drop paths.
- `register_section()`: the owner and default-title refusals.
- The pre-bind replay in `bind_run`.
- The warn-once "kind" keys, including the streak-change and count-change cases.

The logic holds. I found no crash path, no read-only violation, and no incorrect warn-once state
transition. The remaining issues are a test-isolation claim that is only partly true (verified by a
probe) and two low-impact consistency points.

## Warnings

### WR-01: `new_map()` / `new_tuning()` are documented as private copies, but building definitions stay shared with the cached resource

**File:** `tests/support/overlay_test_support.gd:12-19` (also the same pattern in `tests/e2e/*`)
**Issue:** The doc comments say a test that edits the copy "never writes to the cached resource",
and `context_with_one_house` says nothing is "ever tested against a shared cached resource".
`Resource.duplicate(true)` only deep-copies sub-resources that are embedded in the `.tres`. It does
not copy external resources.
- I probed this against `res://data/maps/prototype_map.tres`. `spots[0]` is a distinct copy, but
  `buildings[0]` and `buildings[0].tiers[0]` are the same objects as in the cached resource
  (`SHARED_BUILDING=true`, `SHARED_TIER=true`).
- `house.tres` and `tower.tres` are external resources.
- Any test built on these helpers that edits a `BuildingDef` or `BuildingTierDef` (cost, dawn_income)
  would write to the process-wide cached resource and leak into every later suite in the same
  GUT run. The pass/fail result would then depend on script order.
- Nothing in the five reviewed files does that today, so the suite is green. The guarantee the
  helper advertises is nonetheless false, and the next test author will rely on it.

**Fix:** Either narrow the comment to what is true (spots and tuning are private; building
definitions are shared and must not be edited), or make the promise real by deep-copying the
building set in `new_map()`:
```gdscript
static func new_map() -> MapConfig:
	var map: MapConfig = (load(PROTOTYPE_MAP) as MapConfig).duplicate(true)
	var own_buildings: Array[BuildingDef] = []
	for def: BuildingDef in map.buildings:
		var copy: BuildingDef = def.duplicate(true)
		var tiers: Array[BuildingTierDef] = []
		for tier: BuildingTierDef in def.tiers:
			tiers.append(tier.duplicate(true))
		copy.tiers = tiers
		own_buildings.append(copy)
	map.buildings = own_buildings
	return map
```
The spots reference building ids, not objects, so replacing the array is safe. Alternatively use
`duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` if it is available in 4.7.2.

## Info

### IN-01: A pre-bind registration of a default title is accepted silently and only refused at `bind_run`

**File:** `ui/overlay/debug_overlay.gd:44-58`
**Issue:** After bind, `register_section("Perf", ...)` warns immediately. Before bind, the same call
is buffered without any title check and is refused only when `bind_run` replays it. That happens
later, possibly never, if the overlay is never bound. The two paths therefore refuse the same
mistake at different times. Owner problems were unified through `owner_problem`, but the
default-title refusal was not.
**Fix:** Check the title in the pre-bind branch too, for example by moving the default-title test
into a static `DebugOverlayModel.title_problem(title)` used by both paths:
```gdscript
if title in DebugOverlayModel.DEFAULT_TITLES:
	DebugOverlayModel.warn_not_registered(title, "the title is a default section")
	return
```

### IN-02: A repeat `bind_run` with a different `RunContext` is silently ignored, and a test locks that in

**File:** `ui/overlay/debug_overlay.gd:23-25`, `tests/unit/test_debug_overlay_registration.gd:64-74`
**Issue:** The early return keeps the sections, as intended (the doc comment says it mirrors
`Hud.bind_run`). It also means an overlay that is bound a second time to a fresh run (restart or new
map) keeps reading the first run's `RunContext`. The overlay then shows stale phase, gold and
counts with no warning. `test_a_second_bind_run_keeps_the_sections_registered_so_far` passes a new
context but only asserts that the section survives. It never checks which context the overlay
reads, so the stale-context behaviour is untested.
**Fix:** If the overlay outlives a run, rebuild the model against the new context while carrying
over the registered sections. That needs a `DebugOverlayModel` method to move them, or a
`_ctx` rebind. If the overlay is always recreated per run, add a one-line comment saying so, and
either warn on a repeat bind with a different context or assert that behaviour in the test.

---

_Reviewed: 2026-09-30T12:17:18Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
