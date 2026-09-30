---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T13:01:40Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - tests/support/overlay_test_support.gd
  - tests/unit/test_debug_overlay_providers.gd
  - tests/unit/test_debug_overlay_registration.gd
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

**Reviewed:** 2026-09-30T13:01:40Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the debug overlay view (`DebugOverlay`), its read-only view model (`DebugOverlayModel`), the shared test support, and the three unit suites that exercise them. I also re-ran `test_debug_overlay_providers.gd` (17/17 passing) and `tools/lint.sh` (clean).

I found no correctness bugs or security problems in the logic:

- The bind order, idempotent `bind_run`, pending-section replay and registration-order paths hold up.
- The freed-owner / invalid-Callable / arity / non-Array / malformed-row handling is consistent between the pre-bind and post-bind paths.
- The one-warning-per-streak logic in `_warn_once` was traced against the sequences in the tests and behaves as described.

The remaining findings are one misleading lifetime guarantee that no test covers, and three low-severity test and naming issues.

## Warnings

### WR-01: `lifetime_owner` is a no-op for the RefCounted owners the docs say it protects, and no test covers that case

**File:** `ui/overlay/debug_overlay_model.gd:99-102` (also `ui/overlay/debug_overlay.gd:67-73`)
**Issue:** `owner_ref` is documented as "so the overlay never keeps a RefCounted owner alive", and the view says "a pending section never keeps its owner alive". That only holds for the WeakRef. The same registration also stores the `provider` Callable strongly, in `_registered` and in `_pending`. The intended use of `lifetime_owner` is a lambda that reads the owner, so the lambda captures the owner. A captured RefCounted (for example a wave-manager Resource or RefCounted helper) is therefore kept alive by the stored Callable. Its refcount never reaches zero, `get_ref()` never returns null, and `OWNER_FREED` never fires. The section then keeps rendering a stale object for the rest of the run, while the comments promise it will be dropped.

For a Node the mechanism does work, because `free()` is explicit. Every test uses `Node` owners (`test_debug_overlay_providers.gd:58, 107, 140`; `test_debug_overlay_registration.gd:116`), so the RefCounted case is untested. Phase 2 is the stated consumer of this API.

**Fix:** Either narrow the contract in the doc comments (state that `lifetime_owner` is only effective for Nodes or other objects freed with `free()` or `queue_free()`, and that a RefCounted captured by the provider is kept alive by it), or add a test that documents the actual behaviour:

```gdscript
func test_a_refcounted_owner_captured_by_its_provider_is_kept_alive_by_the_section() -> void:
	var model: DebugOverlayModel = _model()
	var owner_obj: RefCounted = RefCounted.new()
	var ref: WeakRef = weakref(owner_obj)
	model.register_section("Held", func() -> Array: return [["Id", str(owner_obj.get_instance_id())]], owner_obj)
	owner_obj = null
	assert_not_null(ref.get_ref(), "the provider's capture keeps the owner alive")
```

## Info

### IN-01: Several warning assertions match only the substring "skipped", so a wrong skip reason still passes

**File:** `tests/unit/test_debug_overlay_providers.gd:75, 180, 193`
**Issue:** The `Ghost`, `Needy` and `Defaulted` tests assert `assert_push_warning("debug overlay section 'X' skipped")`. `SKIP_MESSAGES` maps each Skip code to a distinct reason, and other tests in the same file do pin the reason (lines 86, 134, 206). These three would still pass if `Needy` or `Defaulted` were reported as "callable is no longer valid" or "owner was freed". That is exactly the mislabelling the `SKIP_MESSAGES` table exists to prevent.
**Fix:** Pin the reason, for example `"...'Needy' skipped: it declares parameters"`, and use the same text at lines 75 (`its callable is no longer valid`) and 193 (`it declares parameters`).

### IN-02: Local variable `owner_ref` reuses the name of the static function `owner_ref`

**File:** `ui/overlay/debug_overlay_model.gd:161` (function defined at line 101)
**Issue:** `_skip_code` declares `var owner_ref: WeakRef`, which has the same name as the class's static `owner_ref()` helper. It works (a probe with `--check-only` printed no warning, and the suite passes), but a reader has to work out which `owner_ref` is meant. It is a shadowing hazard if `_skip_code` later needs to call the helper. `debug_overlay.gd:41` uses the same local name but has no such helper in scope.
**Fix:** Rename the local, for example `var owner_weak: WeakRef = entry["owner"]`.

### IN-03: `test_overlay_test_support.gd` does not cover the tuning "copied all the way down" claim

**File:** `tests/unit/test_overlay_test_support.gd:55-63`; `tests/support/overlay_test_support.gd:12-15`
**Issue:** The `new_tuning` doc comment promises that "a subresource added to LoopTuning later is not shared". The only test edits a single scalar (`dawn_seconds`) and checks the copy differs from the cached resource. It would pass with a shallow `duplicate()`, so nothing guards the claim that motivated `DEEP_DUPLICATE_ALL`. `LoopTuning` has no subresources today (`loop_tuning.tres` references only its script), so this is a future-regression gap, not a current bug.
**Fix:** Either drop the forward-looking claim from the comment, or add a guard that fails when a Resource-typed property appears on `LoopTuning` without an isolation assertion. For example, iterate `LoopTuning.get_script().get_script_property_list()` and assert that any property of type `TYPE_OBJECT` is distinct between the cached resource and the copy.

---

_Reviewed: 2026-09-30T13:01:40Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
