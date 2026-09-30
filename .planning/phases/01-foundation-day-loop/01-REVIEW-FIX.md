---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T09:56:01Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T09:56:01Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

**Verification environment:** all gates ran in the main checkout, not in an isolated worktree. The pinned Godot binary and the lint venv live in the untracked `.tools/` directory, which a fresh worktree does not have, so gates could not run there. Full suite after the last commit: `bash tools/test.sh` 245/245 (243 before, plus the two new tests); `bash tools/lint.sh` clean. `.planning/config.json` was already modified before this run and was left alone (each commit staged explicit paths only).

## Fixed Issues

### WR-01: Overlay provider guard does not catch a lambda that captured a freed object

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** a273e88
**Applied fix:** Took the reviewer's second option and also documented the contract. `register_section` (model and the `DebugOverlay` forwarder) takes an optional `owner: Object`. The model keeps it as a `WeakRef`, so the overlay never extends a RefCounted owner's life. When the owner is freed, collect() skips the section, warns once ("its owner was freed") and drops the entry, the same lifecycle as an invalid Callable (`_is_gone` / `_skip_reason` now take the entry). The doc comment states that without an owner a provider may only capture run-lifetime objects (RunContext and what it holds) or check `is_instance_valid` itself, because a script error cannot be caught in GDScript. Two tests added: a lambda capturing a Node that is freed is skipped and named once when the Node is passed as owner, and a lambda capturing live objects keeps showing with and without an owner (pins the supported shape). The logic is about lifecycle handling, so a human may want to glance at it.
**Mutation probe:** replaced both `owner_ref != null and owner_ref.get_ref() == null` checks with `false` in `debug_overlay_model.gd`. `test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner` failed (the "Watched" section was still present with empty rows, and the expected "its owner was freed" warning was missing; 19/20 passed), and the older `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning` also showed the shifted warning text. Source restored from a backup copy and re-run: 20/20. Note: the probe's `git checkout` restore step initially reverted the whole file to HEAD (before the fix was committed), which I noticed at once and fixed by restoring the backup; the committed content is the intended fix.

### IN-01: Production class exposes several test-only hooks

**Files modified:** `ui/hud/dawn_payout_vfx.gd`
**Commit:** f66045f
**Applied fix:** Comment and ordering change only, no behaviour change. `launch_stagger` moved above a `# --- Test hooks ---` banner, so the two genuine test hooks (`get_launch_delays`, `get_launch_tweens`) sit together under it. `get_spawned_count` and `start_point` were left in the normal API because production code uses them (`_launch_coin`). The reviewer's `duplicate()` suggestion was not applied: `get_launch_tweens` already builds a fresh filtered array, and the live `Tween` references are what `test_a_new_payout_stops_the_pending_launches_of_the_one_it_supersedes` needs to assert they were killed. The doc comment now says so explicitly: the array is a copy, the Tweens are live, and only tests should read them. No new public methods, so the gdlint cap is unaffected.
**Mutation probe:** not applicable to the comment/reorder itself. Because the file was touched, the CR-01 guard probe was re-run: with `float(launches.size()) * stagger` changed to `* STAGGER_SECONDS`, `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` failed (17/18 in `test_dawn_payout.gd`). Source restored and confirmed identical to the committed reorder; `test_dawn_payout*` 22/22 afterwards.

### IN-02: Overlay test builds its context from shared cached resources

**Files modified:** `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 46299c3
**Applied fix:** `_prototype_with_one_house` now builds the context from `(load(PROTOTYPE_MAP) as MapConfig).duplicate(true)` and `(load(TUNING) as LoopTuning).duplicate(true)`, matching the e2e tests. Test-hygiene change with no behaviour to probe, so no mutation probe. The file now has 20 public methods (18 plus the two WR-01 tests), which is exactly gdlint's cap; lint is clean.

---

_Fixed: 2026-09-30T09:56:01Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
