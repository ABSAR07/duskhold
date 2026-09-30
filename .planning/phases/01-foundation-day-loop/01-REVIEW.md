---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T11:55:47Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/support/overlay_test_support.gd
  - tests/support/overlay_test_support.gd.uid
  - tests/unit/test_debug_overlay_providers.gd
  - tests/unit/test_debug_overlay_providers.gd.uid
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_debug_overlay_timed_phases.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 0
  info: 3
  total: 3
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-30T11:55:47Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

I reviewed the debug overlay view (`debug_overlay.gd`), its model (`debug_overlay_model.gd`), the shared test support, and the four overlay suites plus the dawn-payout hardening e2e suite. I also read `debug_overlay.tscn`, the `toggle_debug_overlay` input action, `hud.tscn` (the overlay is in the `run_bound` group) and `MapRoot._ready` to check the bind path.

I traced the following paths and found no defects:

- Pending-section replay in `bind_run`: order is kept, and a freed owner is warned about and skipped.
- The `WeakRef` owner handling in both the view and the model.
- `Skip` code handling: control flow branches on codes, and `GONE_FOR_GOOD` sections are erased along with their warning state.
- Warning re-arm: `_warned` is erased when a provider returns only well-formed rows, and on replacement of a provider.
- `_clean_rows` and the dropped-row count.
- The `Timer` row being limited to NIGHT and DAWN.
- The read-only assertions: every signal in `SimSignals.ALL` is watched, and `SimEvents` is a `RefCounted`, so the drift-guard test does not leak an orphan node.
- The `.uid` files: both are well-formed and distinct.
- The payout e2e tests: the int and float clamping inputs are valid (9e18 is below int64 max), and the warning assertions match the emitted text.

The remaining findings are minor robustness and duplication points.

## Info

### IN-01: `DebugOverlay.get_text()` dereferences an `@onready` node with no readiness guard

**File:** `ui/overlay/debug_overlay.gd:64-65`
**Issue:** `get_text()` is public API and reads `_text.text`, but `_text` is `@onready`. Calling it before the node is in the tree (for example, right after `instantiate()` and before `add_child`) raises a null-instance script error instead of returning "". The current tests only call it after adding the overlay to the tree, so nothing exercises this. The same window exists for `_refresh`, which is only reachable from `_process`, so that one is safe.
**Fix:**
```gdscript
func get_text() -> String:
	return _text.text if _text != null else ""
```

### IN-02: Owner-validity handling is duplicated between the view and the model, and rejects non-Object owners with a misleading message

**File:** `ui/overlay/debug_overlay.gd:47-57`, `ui/overlay/debug_overlay_model.gd:57-73`
**Issue:** `DebugOverlay.register_section` re-implements the model's `has_owner` / `is_instance_valid` / `weakref` logic for the pre-bind path. The two copies use slightly different warning text ("its owner was freed", "its owner was freed before bind_run"), so a later change to one can drift from the other. Because `lifetime_owner` is a `Variant`, a caller who passes a non-Object by mistake (an int or a String) gets `is_instance_valid(5) == false` and is told "its owner was freed", which points at the wrong cause. The pending path in `bind_run` (lines 27-38) has a third copy of the freed-owner check.
**Fix:** Extract one helper, for example a static `DebugOverlayModel.owner_ref(title, lifetime_owner) -> WeakRef` (with a sentinel for "refused"), and use it from both paths. Distinguish `typeof(lifetime_owner) != TYPE_OBJECT` and warn "its owner is not an Object" separately from the freed case.

### IN-03: Test scaffolding constants and context construction are duplicated

**File:** `tests/unit/test_debug_overlay_registration.gd:6-18`, `tests/e2e/test_dawn_payout_hardening.gd:5-6,15-16`
**Issue:** `PROTOTYPE_MAP` and `TUNING` are declared again in the registration suite and in the e2e suite, although `OverlayTestSupport` already owns them, along with `new_tuning()`. The registration suite's `_context()` repeats the duplicate-the-resources recipe from `OverlayTestSupport.context_with_one_house`, minus the House. If the resource paths move, several files break instead of one. The e2e suite is outside the overlay support's remit, but the registration suite could reuse it.
**Fix:** In the registration suite, build the context from `OverlayTestSupport.new_tuning()` and a shared duplicated-map helper (add `new_map()` next to `new_tuning()`), and drop the two local constants.

---

_Reviewed: 2026-09-30T11:55:47Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
