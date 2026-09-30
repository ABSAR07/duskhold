---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T14:02:24Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T14:02:24Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

**Verification location:** all gates ran in the main checkout (no worktree was created), on branch `gsd/phase-01-foundation-day-loop`, as the orchestrator's notes required (stage explicit paths, restore probes from backup copies). After the last commit: `bash tools/test.sh` gave 286/286 passing in 36 scripts (283 before, plus the three new tests), and `bash tools/lint.sh` was clean. `.planning/config.json` still carries its unrelated uncommitted change and was never staged.

Every behaviour change below has a mutation probe: the new or changed test was shown to fail against the unfixed or broken code, and the source was restored from a backup copy before committing. No probe edit remains in the tree.

## Fixed Issues

### WR-01: Spot-position check in the cache-isolation test passes when the copy shares the spot with the cache

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** 8c56d50
**Applied fix:** Added a file-level `EDITED_SPOT` constant. The test writes it to the copy and asserts `assert_ne(spot_seen, EDITED_SPOT, ...)`, so it no longer compares against the copy's property, which the restore of the cache also reset. The reviewer's second suggestion (the whole-map `_shared_resources` check) is applied under WR-03.
**Probe:** `OverlayTestSupport.new_map()` was changed to hand the copy the cached map's `spots` array. The unfixed test still passed 6/6 (the bug the review described). With the fix, the spot assertion fails ("and its spot position is not the one written to the copy") and the other tests are unaffected. `new_map()` was restored from a backup copy.

### WR-02: The replay of a pending section with a live owner is not tested

**Files modified:** `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 46791b1
**Applied fix:** Added `test_a_pending_section_whose_owner_is_freed_after_bind_run_is_dropped_with_a_warning`. It registers a section with a live owner and a second ownerless section before `bind_run`, checks the first shows, frees the owner, waits two refresh intervals, and asserts the section is gone, the other section remains, and the "skipped: its owner was freed" warning appears exactly once. It adapts the reviewer's sketch with the extra ownerless section and the warning count.
**Probe:** In `ui/overlay/debug_overlay.gd` the replay call was changed to pass `null` instead of `lifetime_owner`. The new test failed (section still listed, no warning), and it passes on the real code. The overlay source was restored from a backup copy.

### WR-03: `test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning` cannot fail today

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** df3e1f4
**Applied fix:** Replaced the vacuous `LoopTuning` test with `test_a_new_map_copy_shares_no_resource_with_the_cached_map_at_any_depth`, which runs `_shared_resources` over the cached map and a `new_map()` copy. It also asserts the map reaches more than one Resource, so the check has a subject. The stand-in test for the helper is kept, and a comment notes that a `LoopTuning` check can return when it gains a subresource.
**Probe:** `new_map()` was changed to `DEEP_DUPLICATE_INTERNAL`, which leaves the external building and tier resources shared. The new test failed ("the map copy shares no subresource with the cache", 7 of 7 entries differ); it passes on the real code. `new_map()` was restored from a backup copy.

### IN-01: The Ghost test does not pin the warning count or the "before bind_run" wording

**Files modified:** `tests/unit/test_debug_overlay_registration.gd`
**Commit:** b4e94ef
**Applied fix:** The Ghost test now matches the full text `... its owner was freed before bind_run` and adds `assert_push_warning_count(1, "the freed owner is named once")`.
**Probe:** Two probes against `ui/overlay/debug_overlay.gd`: dropping the `" before bind_run"` suffix made the test fail on the text match, and emitting the warning twice made it fail on the count (got 2). Both were restored from a backup copy.

### IN-02: A bind while the overlay is visible shows stale text for up to 0.25 s

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** a1c3b29
**Applied fix:** `bind_run` now ends with `if visible and _text != null: _refresh()`. The `_text != null` guard keeps a bind before the overlay enters the tree from touching the unset label. New test `test_binding_an_overlay_that_is_already_shown_fills_it_at_once` shows the overlay first (empty text), binds, and asserts the default rows and the early section are in the text with no frames waited. The commit was amended once to apply `gdformat` to the new test.
**Probe:** With the `bind_run` change reverted (backup copy of the original), the new test fails ("Expected text and search strings to be non-empty. You passed \"\""). It passes with the fix.

### IN-03: Overlay processing follows the tree's pause state

**Files modified:** `ui/overlay/debug_overlay.tscn`, `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** 6b073d9
**Applied fix:** Set `process_mode = 3` (`PROCESS_MODE_ALWAYS`) on the DebugOverlay root node. New e2e test `test_overlay_keeps_processing_while_the_tree_is_paused` spawns the real map, asserts the overlay's `process_mode` is `PROCESS_MODE_ALWAYS`, pauses the tree and asserts `overlay.can_process()`, then unpauses in the same frame (no await while paused, so GUT itself is not stalled). Full suite and the map-loading e2e scripts pass with the changed scene.
**Probe:** With the `process_mode` line removed from the scene, the new test failed on both assertions (`0 != 3`, and `can_process()` false while paused). The scene was restored from a backup copy.

---

_Fixed: 2026-09-30T14:02:24Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
