---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T10:20:59Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T10:20:59Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

**Verification (where it ran):** every gate ran in the main checkout on branch
`gsd/phase-01-foundation-day-loop`, not in an isolated worktree, as the orchestrator instructed
(the project's gates need the warmed `.godot/` import cache, which a fresh worktree lacks). After
the last commit: `bash tools/lint.sh` clean (68 files), `bash tools/test.sh` 258/258 (was 245; the
13 new tests are listed below). `.planning/config.json` has an unrelated uncommitted change and was
never staged. `.github/workflows/ci.yml` and the start-night prompt text were not touched.

## Fixed Issues

### WR-01: `DebugOverlay.register_section` silently drops registrations made before `bind_run`, and a second `bind_run` wipes all registered sections

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd` (new), `tests/unit/test_debug_overlay_registration.gd.uid` (new)
**Commit:** 8ee2508
**Status:** fixed: requires human verification (logic change; the tests below cover it, but the bind-order behaviour is worth a look when Phase 2 registers its first section)
**Applied fix:** Followed the reviewer's design with one adaptation. `register_section` before `bind_run` now appends `{title, provider, owner}` to `_pending` (the owner is held as a `WeakRef`, like the model, so a pending section never keeps its owner alive). `bind_run` returns early if `_model` already exists, otherwise builds the model and replays `_pending` in order. If a pending section's owner was freed before the bind, replaying it would have registered it as an owner-less section that shows a dead reference, so it is left out with a `push_warning` instead. Four new tests: an early section shows after bind; early and late sections keep registration order; a second `bind_run` keeps earlier sections; a freed pending owner is skipped with a warning.
**Mutation probe:** with `debug_overlay.gd` restored to its committed (unfixed) form, the new file fails 0/4 (the four new tests all fail); with the fix, 4/4 pass. The fixed source was restored from a backup copy.

### WR-02: Untested branches of the read-only model: `Timer` row and NIGHT/DAWN phases

**Files modified:** `tests/unit/test_debug_overlay_timed_phases.gd` (new), `tests/unit/test_debug_overlay_timed_phases.gd.uid` (new)
**Commit:** daa8311
**Applied fix:** Test-only. A new unit file drives a `RunContext` to NIGHT and DAWN and asserts: no `Timer` row by day (with `Day: 1`, `Night: 0`); the `Timer` row at NIGHT and DAWN equals the full phase length with the right `Day` and `Night` values; the night timer row follows the clock down after a tick; the `Timer` row disappears and `Day` becomes 2 when dawn hands over to day; and 200 collects in NIGHT and in DAWN leave gold, phase, phase timer and elapsed time unchanged and emit no `SimEvents` signal. It is a new file because `test_debug_overlay_readonly.gd` is at the 20-public-method cap.
**Mutation probes (on `debug_overlay_model.gd`, restored from backup after each):** (A) dropping the `Timer` row append fails 6 of 7 tests; (B) adding the `Timer` row in every phase fails 2 (the DAY test and the after-handover test); (C) a getter side effect (`run_manager.tick(0.01)` inside the timed rows) fails 2 (the read-only NIGHT and DAWN tests). Unmutated: 7/7 pass.

### IN-01: `_reset_for_new_payout` and `live_coin_count` treat every child as a coin

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** 6964a08
**Applied fix:** Added `COIN_GROUP := &"payout_coin"`; `_launch_coin` adds each coin to it, and a small `_coins()` helper returns only this node's children in that group. `live_coin_count` and `_reset_for_new_payout` iterate `_coins()`, so any other child is neither counted nor freed. New e2e test `test_a_child_that_is_not_a_coin_is_neither_counted_nor_freed_by_a_payout` adds a `Control` child, runs two payouts back to back, and checks it is not counted, not queued for deletion and still valid after the payout lands.
**Mutation probe:** with `dawn_payout_vfx.gd` restored to its committed form, `test_dawn_payout_hardening.gd` fails 1 of 5 (the new test); with the fix, 5/5. The CR-01 guard `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` was re-probed because this file was touched: replacing `stagger` with `STAGGER_SECONDS` in the coin schedule (line 176) fails it (last coin delay 0.88 vs 0.25, and 1.48 > 0.851), 17/18 in `test_dawn_payout.gd`. The fixed source was restored from backup (diff-verified) and `test_dawn_payout.gd` passes 18/18.

### IN-02: `owner` parameter shadows `Node.owner` in `DebugOverlay.register_section`

**Files modified:** `ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 8ef9f79
**Applied fix:** Renamed the parameter to `lifetime_owner` in both `DebugOverlay.register_section` and `DebugOverlayModel.register_section`, and updated the doc comments that named `owner`. Every existing caller passes it positionally, so no call site changed. Added `test_register_section_does_not_name_a_parameter_after_the_node_owner_property`, which pins the parameter names of both methods via `get_script_method_list`.
**Mutation probe:** with the parameters renamed back to `owner` in both files, the new test fails (`["title","provider","owner"] != ["title","provider","lifetime_owner"]` for both classes), 4/5 in the file; with the fix, 5/5. The fixed sources were restored from backup (diff-verified).

### IN-03: `_registered.erase(entry)` removes by Dictionary content equality

**Files modified:** `ui/overlay/debug_overlay_model.gd`
**Commit:** 7e7a1f2
**Applied fix:** `_registered` is now a `Dictionary` keyed by title (`{title: {provider, owner}}`) instead of an `Array[Dictionary]`. Godot Dictionaries keep insertion order, so sections still show in registration order; assigning an existing title replaces it in place, a new title goes last, and dropping a dead section is `_registered.erase(title)`. `collect` iterates `_registered.keys()` (a copy) and passes the title through to `_warn_once`/`_warned`. No behaviour change, so no new test; the existing `test_registering_a_title_twice_replaces_the_section_instead_of_duplicating_it` and `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning` pin the ordering semantics.
**Mutation probe:** making a replacement erase the title before assigning (so it moves to the end) fails the replace-in-place test (`["Other","Wave"] != ["Wave","Other"]`), 19/20 in `test_debug_overlay_readonly.gd`; unmutated 20/20. Restored from backup (diff-verified).

---

_Fixed: 2026-09-30T10:20:59Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
