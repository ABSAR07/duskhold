---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T12:29:54Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T12:29:54Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: `new_map()` / `new_tuning()` are documented as private copies, but building definitions stay shared with the cached resource

**Files modified:** `tests/support/overlay_test_support.gd`, `tests/unit/test_overlay_test_support.gd` (new), `tests/unit/test_overlay_test_support.gd.uid` (new)
**Commit:** 457e334
**Applied fix:** Made the promise real rather than narrowing the comment. `new_map()` now uses
`duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (available in 4.7.2, verified by running it) instead of
`duplicate(true)`, so `buildings` and their `tiers` are private copies too; the doc comment says why.
A new suite, `tests/unit/test_overlay_test_support.gd`, pins it: no `BuildingDef` or
`BuildingTierDef` is shared with the cached map, editing a copy's cost, dawn income or spot position
leaves the cached map and later copies untouched, the copy still validates and builds a `RunContext`,
and `new_tuning()` is private. The suite is a new file, not an addition to an existing one, because
`test_dawn_payout.gd` is at the 20-public-method lint cap and the helper belongs to no single suite.
`.gd.uid` committed.
Scope: the 13 other test files that use `load(...).duplicate(true)` directly were left alone. The
finding is about the shared helper, and no test edits a building definition today.
**Mutation probe:** with `new_map()` reverted to `duplicate(true)` the new suite fails 2 of 4 tests
(every building and tier reported as "not a copy", and the edited cost/dawn income leaked into the
cached resource: `[102] expected to equal [2]`). Restored from a saved copy; 4/4 pass.

### IN-01: A pre-bind registration of a default title is accepted silently and only refused at `bind_run`

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 062ad46
**Applied fix:** Added static `DebugOverlayModel.title_problem(title)` (and a `DEFAULT_TITLE_REASON`
constant, with the same wording as before) beside `owner_problem`. `DebugOverlayModel.register_section`
and the pre-bind branch of `DebugOverlay.register_section` both use it, title first then owner, so both
paths refuse the same mistake at the same moment in the same words. Two new tests: a default title
registered before `bind_run` warns at once (asserted before `bind_run` runs), is never buffered, and
warns only once overall; the post-bind path is pinned the same way.
**Mutation probe:** with `ui/overlay/debug_overlay.gd` restored to its pre-fix version the pre-bind
test fails (`Expected push_warning error containing 'debug overlay section 'Perf' not registered: the
title is a default section'`, 9/10 pass). Restored from a saved copy.

### IN-02: A repeat `bind_run` with a different `RunContext` is silently ignored, and a test locks that in

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 8a440c0
**Applied fix:** The overlay is always recreated per run (`MapRoot` builds one `RunContext` and binds
each `run_bound` node once; the overlay lives under the HUD in the map scene), so rebuilding the model
was not warranted. Took the review's second option: the `bind_run` doc comment now states the per-run
lifetime, the overlay remembers its `_ctx`, and a repeat bind with a different context emits
`REBIND_IGNORED_WARNING` (binding the same context again stays silent). Tests: the existing
`test_a_second_bind_run_keeps_the_sections_registered_so_far` now rebinds the same context and asserts
no warning; a new test binds a second, different context and asserts the warning, that the overlay still
shows the first run's gold (not the second's), and that the registered section survives.
**Mutation probes:** (a) with the `push_warning` call removed the new test fails (`Expected push_warning
error containing 'debug overlay bind_run ignored: already bound to another run'`); (b) with the
`ctx != _ctx` condition replaced by `true` the same-context test fails (`Expected 0 push_warning
errors. Got 1`). Restored from a saved copy after each.

## Skipped Issues

None -- all findings were fixed.

## Verification

- Ran in the main checkout, not an isolated worktree. The orchestrator's notes (uncommitted
  `.planning/config.json` to leave alone, restore-from-backup probes, `.godot` import cache) required it,
  and `workflow.use_worktrees` is not set in `.planning/config.json`, so no worktree, temp branch or
  recovery sentinel was created and there was no cleanup tail. Commits are on
  `gsd/phase-01-foundation-day-loop`.
- Full suite after the last commit: `bash tools/test.sh` 275/275 in 36 scripts (was 268/268 in 35;
  +4 in the new suite, +3 in the registration suite).
- `bash tools/lint.sh`: clean (72 files, no problems).
- `.planning/config.json` still has its unrelated uncommitted change; it was never staged. No Godot
  processes were left running. `.github/workflows/ci.yml`, the start-night prompt text and
  `ui/hud/dawn_payout_vfx.gd` were not touched, so the CR-01 probe was not re-run.

---

_Fixed: 2026-09-30T12:29:54Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
