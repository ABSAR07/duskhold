---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T12:09:20Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-09-30T12:09:20Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

**Verification:** run in the main checkout (no worktree; the orchestrator's environment notes place all edits and the uncommitted `.planning/config.json` change in the main tree). Full suite `bash tools/test.sh`: 268/268 in 35 scripts (was 265; 3 new tests). `bash tools/lint.sh`: clean. `.planning/config.json` was left uncommitted.

## Fixed Issues

### IN-01: `DebugOverlay.get_text()` dereferences an `@onready` node with no readiness guard

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 187f47a
**Applied fix:** `get_text()` now returns `_text.text if _text != null else ""`, with a doc comment. New test `test_get_text_before_the_overlay_is_in_the_tree_is_empty_instead_of_a_script_error` instantiates the overlay without `add_child` and asserts `""`.
**Mutation probe:** with the unfixed `debug_overlay.gd` restored from a backup copy, the new test failed (`Invalid access to property or key 'text' on a base object of type 'Nil'`, 6/7 passed). The fixed source was then put back and the suite passed 7/7.

### IN-02: Owner-validity handling is duplicated between the view and the model, and rejects non-Object owners with a misleading message

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_providers.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 0e6da7a
**Applied fix:** Added three static helpers on `DebugOverlayModel`: `owner_problem(lifetime_owner) -> String` (`""` when usable or absent, otherwise the reason: not an Object, or freed), `owner_ref(lifetime_owner) -> WeakRef`, and `warn_not_registered(title, reason)`. Added consts `OWNER_FREED_REASON` and `OWNER_NOT_OBJECT_REASON`; `SKIP_MESSAGES` reuses the freed wording. `DebugOverlayModel.register_section`, `DebugOverlay.register_section` (pre-bind path) and the `bind_run` replay of a pending section whose owner has since been freed all use them, so the wording lives in one place (the replay adds " before bind_run" to the shared reason). A non-Object owner (an int or a String) is now refused as "its owner is not an Object", not as freed. New tests: `test_a_section_whose_owner_is_not_an_object_is_refused_as_such_not_as_freed` (model, int and String) and `test_an_owner_that_is_not_an_object_is_refused_before_and_after_bind_run_as_such` (view, pre-bind and post-bind).
**Mutation probe:** with both unfixed source files restored from backup copies, the model test failed (16/17 passed) and the view test failed (7/8 passed). The unfixed code warned "its owner was freed" for the int and String owners, which is the misleading message the review described. Fixed sources were put back afterwards and the full suite passed.

### IN-03: Test scaffolding constants and context construction are duplicated

**Files modified:** `tests/support/overlay_test_support.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 49f4ae9
**Applied fix:** Added `OverlayTestSupport.new_map()` next to `new_tuning()`, and `context_with_one_house` now uses it. The registration suite drops its local `PROTOTYPE_MAP` and `TUNING` constants and builds its context from `OverlayTestSupport.new_map()` and `new_tuning()`. The e2e hardening suite was left alone: the reviewer marked it outside the overlay support's remit, and the same two constants are declared in seven other e2e and integration suites, so changing one would leave the convention half-migrated.
**Mutation probe:** this is a behaviour-preserving refactor. As a wiring check, making `new_map()` return `null` failed the registration suite (2/8 passed), confirming the helper is exercised; it was restored from a backup copy and the suite passed 8/8.

## Notes

- `tests/e2e/test_dawn_payout.gd` and `ui/hud/dawn_payout_vfx.gd` were not touched, so the CR-01 coin-schedule guard needed no re-probe.
- Public-method counts stay under the gdlint cap: registration suite 8 tests, providers suite 17 tests, `DebugOverlayModel` 5 public methods. No new `.gd` files were added, so no new `.uid` files.
- No Godot processes were left running.

---

_Fixed: 2026-09-30T12:09:20Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
