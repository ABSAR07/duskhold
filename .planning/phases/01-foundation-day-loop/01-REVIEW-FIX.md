---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T13:15:04Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T13:15:04Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

**Verification environment:** all fixes were edited, tested and committed in the main checkout (no isolated worktree), as the orchestrator's instructions required, so the numbers below are reproducible from the tree. After the last commit, `bash tools/test.sh` ran 279/279 in 36 scripts (276 before, plus the 3 new tests) and `bash tools/lint.sh` was clean. No Godot process was left running.

## Fixed Issues

### WR-01: `lifetime_owner` is a no-op for the RefCounted owners the docs say it protects, and no test covers that case

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_providers.gd`
**Commit:** a7d732d
**Applied fix:** Took the reviewer's first option (narrow the contract) and the second (document it with a test). The doc comments on `DebugOverlayModel.register_section`, `DebugOverlayModel.owner_ref`, `DebugOverlay.register_section` and the pending-entry comment now say the overlay's own reference is a WeakRef, but the stored provider Callable strongly holds whatever a lambda captured. So `lifetime_owner` ends a section only for an owner freed explicitly (a Node: `free()` or `queue_free()`); a RefCounted captured by its provider is kept alive by that capture, and the way to let a RefCounted end its section is to capture a `weakref()` of it. Two tests pin both sides: `test_a_refcounted_owner_captured_by_its_provider_is_kept_alive_by_the_section` and `test_a_weakly_captured_refcounted_owner_ends_its_section_when_freed`. Runtime behaviour is unchanged.
**Mutation probes:**
- Made `owner_ref()` return `null` (the owner is never tracked): 2 tests failed (the new weak-capture test and the existing freed-lambda-owner test). Source restored from a backup copy.
- Changed the keep-alive test's provider so it no longer captures the owner: the keep-alive test failed. Test restored from a backup copy.
- The keep-alive test asserts a GDScript language rule (a lambda's capture holds a strong reference), so it guards the documented limit rather than a line of overlay code.

### IN-01: Several warning assertions match only the substring "skipped", so a wrong skip reason still passes

**Files modified:** `tests/unit/test_debug_overlay_providers.gd`
**Commit:** 7c562d9
**Applied fix:** The `Ghost`, `Needy` and `Defaulted` assertions now pin the full reason: `its callable is no longer valid` for `Ghost`, `it declares parameters` for `Needy` and `Defaulted`.
**Mutation probes:**
- Changed the `DECLARES_PARAMETERS` message to the callable text: `Needy` and `Defaulted` now fail (they passed before the fix; `Wave` failed already). Source restored from a backup copy.
- Changed the `CALLABLE_INVALID` message to the owner-freed text: the `Ghost` assertion at line 75 now fails (line 86 already pinned it). Source restored from a backup copy.

### IN-02: Local variable `owner_ref` reuses the name of the static function `owner_ref`

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`
**Commit:** 1aa833d
**Applied fix:** Renamed the WeakRef local to `owner_weak` in `DebugOverlayModel._skip_code`, and in `DebugOverlay.bind_run` for consistency. Pure rename, no behaviour change, so no mutation probe; the five `test_debug_overlay*` scripts pass and lint is clean.

### IN-03: `test_overlay_test_support.gd` does not cover the tuning "copied all the way down" claim

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** 79b4513
**Applied fix:** Took the reviewer's second option and added `test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning`. It walks `LoopTuning`'s stored script properties and asserts that no Resource (directly, or inside an Array or Dictionary) is shared between the cached tuning and `OverlayTestSupport.new_tuning()`. It also asserts it visited at least one property. It passes trivially today because `LoopTuning` has no subresources.
**Mutation probe:** temporarily added `@export var probe_sub: Resource = Resource.new()` to `LoopTuning`. With the current deep copy the test passes (5/5). With `new_tuning()` switched to a shallow `duplicate()` it fails with `'probe_sub' shares a subresource with the cache`. Both `loop_tuning.gd` and `overlay_test_support.gd` were restored from backup copies and confirmed clean in `git status`.

---

_Fixed: 2026-09-30T13:15:04Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
