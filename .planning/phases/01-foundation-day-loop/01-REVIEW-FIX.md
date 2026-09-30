---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T13:38:30Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T13:38:30Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

**Verification ran in the main checkout** (not an isolated worktree), as the orchestrator directed: the hand-rolled worktree has no `.godot` import cache or tools, so it cannot run the gates. Numbers below are reproducible from the tree at HEAD. After the last fix, `bash tools/test.sh` passed 283/283 in 36 scripts (279 before, plus 1 test for IN-02 and 3 for IN-03), and `bash tools/lint.sh` was clean (gdformat: 72 files unchanged; gdlint: no problems). All temporary probe edits were restored from backup copies (byte-compared) and the working tree holds only the unrelated uncommitted `.planning/config.json` change.

## Fixed Issues

### WR-01: Mutating test can poison the cached map for every later suite when the guard it tests regresses

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** 66e7307
**Applied fix:** The test now keeps a reference to the cached tier, reads the cached cost, dawn income and spot position, writes through the copy, records what the cache and a later copy show, restores the cached values, and only then asserts. A failing assert can no longer skip the restore, and the "later copy starts clean" value is read before the restore, so it still sees a dirtied cache.
**Mutation probe:** `OverlayTestSupport.new_map()` was temporarily changed to `return load(PROTOTYPE_MAP)` (the shared-resource regression), with a temporary holder of the cached map and a temporary `test_zz_cache_is_pristine` that asserts the cached spot is not at the test's write value. Against the unfixed test, the suite ended 3/6 with `cache not poisoned` failing (the cache stayed dirty for later tests). Against the fixed test it ended 4/6, with the two guard tests failing as they should and the pristine check passing. The holder was needed because a `load()`ed resource with no reference is freed and reloaded from disk, so the poison persists only while something else holds the cached map. Support file and test restored from backup; the temporary test and holder were never committed.

### IN-01: Local `name` shadows `Node.name` in a GutTest

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** 2b580e4
**Applied fix:** Renamed the local to `prop_name`, in both `get(...)` calls and the assert message (gdformat then wrapped the assert across lines). No behaviour change, so no probe.

### IN-02: `test_a_new_tuning_copy_shares_no_resource_with_the_cached_tuning` is vacuous today and its final assert overstates what it checks

**Files modified:** `tests/unit/test_overlay_test_support.gd`
**Commit:** dc28bfc
**Applied fix:** Replaced the property-count assert with `_shared_resources(cached, copy)`, which walks every stored property of both resources through `get_property_list()` (base scripts included), at any depth and through Arrays and Dictionaries, skipping the shared `script` resource. The assertion message now says LoopTuning has no subresource yet, so it guards a later one. Added `test_the_sharing_check_finds_a_nested_resource_under_a_base_script_property`, which runs the same check on stand-in inner-class resources (a property on a base script, the shared resource two levels down) so the check itself is exercised today. The DEEP_DUPLICATE_ALL structural assertion was not added.
**Mutation probes (on the new check):**
- Removing the recursion (`_reachable` no longer descends): the new test fails (`[] != [<Resource>]`), 5/6.
- Removing the `script` skip: the tuning test and both halves of the new test fail (the shared GDScript is reported), 4/6.
- Limiting the walk to `get_script().get_script_property_list()`: still 6/6. Godot's script property list includes inherited script properties, so the reviewer's base-script limit did not hold in this engine. I kept the base-script arrangement in the stand-ins but reworded the comment so it only claims what the recursion probe shows (a top-level-only check would miss the nested resource).
All probe edits restored (byte-compared to the committed copy).

### IN-03: Pre-bind registration warns about a replaced section whose owner was freed

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 9ef9e59
**Applied fix:** A pre-bind `register_section` with a title already pending now replaces that entry in place (keeping its position), as the model does after bind, so `bind_run` no longer warns about the owner of a replaced section. Refused registrations still return before touching `_pending`. The `_pending` doc comment now says it holds one entry per title. Three tests added: the replaced-owner case (no warning, replacement rows shown), the replaced entry keeping its place in the order, and a refused replacement (freed owner) leaving the earlier registration alone.
**Mutation probe:** the new no-warning test was run against the unfixed source before the fix and failed (`Expected 0 push_warning errors. Got 1`), 14/15; with the fix 15/15. The order test and the refused-replacement test pass on unfixed code too, because the model's own replace-in-place hides the difference for those cases; they guard the new implementation (position kept, bad replacement ignored) rather than the old behaviour. Source restored from backup during probing; the final committed source is the fix.

---

_Fixed: 2026-09-30T13:38:30Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
