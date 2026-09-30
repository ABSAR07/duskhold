---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T12:52:34Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T12:52:34Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

**Verification ran in the main checkout** (no worktree was created: the gates need the warmed `.godot/` cache, and `.planning/config.json` carries an unrelated uncommitted change that stays uncommitted). Final gates: `bash tools/test.sh` 276/276 in 36 scripts (was 275/275; +1 new test); `bash tools/lint.sh` clean (gdformat and gdlint). No Godot process is left running.

## Fixed Issues

### WR-01: `bind_run(null, ...)` is accepted and then raises a script error on every refresh

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 546c3dc
**Applied fix:** `bind_run` now returns with a `push_warning(NO_CONTEXT_WARNING)` ("debug overlay bind_run ignored: no RunContext") before `_model` is set, so the overlay stays unbound and a later valid `bind_run` still succeeds. New test `test_bind_run_with_no_context_warns_and_leaves_the_overlay_free_to_bind_properly` registers a section, binds null, then binds a real context and checks gold, the section and the single warning.
**Mutation probe:** with the guard removed the new test fails ("Expected push_warning error containing 'debug overlay bind_run ignored: no RunContext'", plus script errors "Invalid access to property or key 'run_manager' on a base object of type 'Nil'"). Source restored from a backup copy; the suite passes again.
**Note:** requires human verification: logic change to a bind guard (tested, but semantic).

### IN-01: `context_with_one_house` indexes `spot_ids()[0]` unguarded and carries on after a failed assert

**Files modified:** `tests/support/overlay_test_support.gd`
**Commit:** bd1c318
**Applied fix:** The helper asserts the spot list is non-empty and returns the context early when it is empty, instead of indexing `[0]`; the first spot is read from a typed `Array[StringName]`.
**Mutation probe:** with the prototype map temporarily pointed at an empty MapConfig, `test_debug_overlay_readonly.gd` under the old helper raised "Out of bounds get index '0' (on base: 'Array[StringName]')" (7 times) plus cascading Nil errors; under the new helper each failure is the readable "the map has a spot to build the setup House on". The temporary map file and the constant change were removed afterwards.

### IN-02: `new_tuning()` deep-copies differently from `new_map()`

**Files modified:** `tests/support/overlay_test_support.gd`, `tests/unit/test_overlay_test_support.gd`
**Commit:** 5738a3f
**Applied fix:** `new_tuning()` uses `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` like `new_map()`. The tuning test now also asserts the result is a distinct copy.
**Mutation probe:** none possible. `LoopTuning` holds only scalar exports today, so `duplicate(true)` and `duplicate_deep` behave identically; this is a latent-risk fix and no test can distinguish them until a subresource is added.

### IN-03: Rows longer than two entries are accepted silently, and the first test in `test_overlay_test_support.gd` can pass vacuously

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_providers.gd`, `tests/unit/test_overlay_test_support.gd`
**Commit:** c886c04
**Applied fix:** `_clean_rows` now requires exactly two entries (`size() == 2`), so an over-long row is dropped and counted in the existing "dropped N malformed row(s); rows are [label, value]" warning instead of being silently truncated; its doc comment says so. `test_a_provider_with_malformed_rows_keeps_only_the_well_formed_ones` previously asserted the truncation (`Wide` row kept as "1"); it now expects the row to be dropped (1 row left, "dropped 3"). In `test_new_map_shares_no_building_definition_or_tier_with_the_cached_map` added `assert_gt(... buildings.size(), 0)` and `assert_gt(... tiers.size(), 0)` so empty loops cannot pass vacuously.
**Mutation probes:** (1) with `>= 2` restored, the providers suite fails on the three changed assertions (row count 2 vs 1, "Wide" still "1", warning count 2 vs 3); source restored from a backup copy. (2) With the prototype map temporarily pointed at an empty MapConfig, the old map-copy test passed vacuously while the new one fails on "the map has buildings, so the loops below check something"; temporary file removed.
**Note:** requires human verification: this is a deliberate behaviour change (the review offered "require size() == 2" or "document the truncation"; the stricter option was chosen, reversing what the previous test asserted).

---

_Fixed: 2026-09-30T12:52:34Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
