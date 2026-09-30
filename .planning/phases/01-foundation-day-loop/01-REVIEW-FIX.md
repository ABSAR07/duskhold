---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T11:46:43Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T11:46:43Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

**Verification ran in the main checkout** (branch `gsd/phase-01-foundation-day-loop`), not in an isolated worktree. A hand-rolled worktree has no `.godot/` import cache, so it cannot run the project's gates, and the orchestrator's notes describe editing and committing in the main checkout (uncommitted edits, backup-and-restore probes). Every number below is reproducible from the current tree: `bash tools/test.sh` reports 265/265 tests in 35 scripts (baseline before this pass: 260/260 in 34), and `bash tools/lint.sh` is clean (71 files, no problems). `.planning/config.json` still carries its unrelated uncommitted change and was never staged. `.github/workflows/ci.yml`, `ui/hud/dawn_payout_vfx.gd` and the start-night prompt text were not touched, so the CR-01 guard probe did not need re-running.

Each behaviour change was checked with a mutation probe: the new or changed tests were run against the unfixed source (restored from a backup copy in the session scratchpad, not `git checkout`), and the fixed source was then put back. The probes are recorded per finding.

## Fixed Issues

### WR-01: `_warn_once` swallows a different, later problem within the same streak

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_providers.gd` (new), `tests/unit/test_debug_overlay_providers.gd.uid` (new)
**Commit:** 639f5fd
**Status:** fixed: requires human verification (logic change in warning suppression; covered by tests, but the semantics of "one streak" are a judgement call)
**Applied fix:** `_warned` now maps title to a problem kind, and `_warn_once(title, kind, problem)` skips only when the same kind was already named. Kinds are `skip <code>` for a Skip code, `returned <Type>` for a non-Array return (so Nil then String also warns twice), and `malformed rows` for dropped rows. The dropped-rows kind carries no count, so a changing number of bad rows stays one problem, as the review suggested. The `_warned.erase(title)` calls are unchanged. New tests: `test_a_provider_whose_problem_changes_within_one_streak_is_named_again` (malformed, then Nil, then String: three warnings, not one per refresh) and `test_the_count_of_malformed_rows_changing_is_not_a_new_problem`. The new file was created here because the read-only suite is at the 20-method cap (see IN-02).
**Mutation probe:** with the original model restored, `test_a_provider_whose_problem_changes_within_one_streak_is_named_again` fails (expected 3 warnings, got 1; the Nil and String warnings are missing). The count-guard test passes on both versions, as intended (it pins behaviour the fix must keep).

### WR-02: Nothing enforces that every `Skip` code has a `SKIP_MESSAGES` entry

**Files modified:** `tests/unit/test_debug_overlay_providers.gd`
**Commit:** fd1fd18
**Applied fix:** Added `test_every_skip_code_except_none_has_a_message`, iterating `DebugOverlayModel.Skip.keys()` and asserting `SKIP_MESSAGES.has(code)` for every code but NONE. The call site is deliberately not made defensive, so a missing message fails loudly in the test rather than being papered over at runtime.
**Mutation probe:** adding `PROBE_CODE` to the `Skip` enum without a message makes the test fail ("PROBE_CODE has a message"); the enum was restored afterwards.

### IN-01: Test-helper duplication across the two overlay suites

**Files modified:** `tests/support/overlay_test_support.gd` (new), `tests/support/overlay_test_support.gd.uid` (new), `tests/unit/test_debug_overlay_readonly.gd`, `tests/unit/test_debug_overlay_timed_phases.gd`, `tests/unit/test_debug_overlay_providers.gd`
**Commit:** 4e79ed5
**Applied fix:** New `OverlayTestSupport` (no `test_` prefix, so GUT does not collect it) holds `new_tuning`, `context_with_one_house(test, tuning)`, `section`, `row_value`, `COLLECT_REPEATS` and `assert_collecting_is_read_only(test, ctx, model)`. The three suites call it instead of their own copies. The shared read-only assertion is the stronger timed-phases variant, so the default-phase read-only test now also guards the phase timer and elapsed time. `row_value` returns null (not `""`) for a missing row, so the one assertion that expected `""` became `assert_null`. Note for plan 01-08's acceptance text: "loops `collect(` at least 200 times" is now satisfied by the shared helper rather than by the readonly file itself.
**Mutation probe:** adding `_ctx.run_manager.tick(0.001)` to the model's `_agent_rows` (a write inside `collect`) makes the read-only test in the readonly suite and both timed-phase read-only tests fail ("simulation time unchanged", "the phase timer unchanged"): 3 failing tests, 32 passing. The model was restored afterwards.

### IN-02: `test_debug_overlay_readonly.gd` sits exactly at the 20 public-method cap

**Files modified:** `tests/unit/test_debug_overlay_readonly.gd`, `tests/unit/test_debug_overlay_providers.gd`
**Commit:** f4ad323
**Applied fix:** Moved the twelve provider-registration and robustness tests (from `test_a_freed_section_provider_is_skipped_instead_of_crashing` through `test_registering_a_title_twice_replaces_the_section_instead_of_duplicating_it`) into `test_debug_overlay_providers.gd`. The signal drift guard stays in the readonly suite, where `SimSignals` points to it. Test bodies are unchanged. Public test-method counts are now readonly 8, providers 16 (after IN-04), timed phases 7, registration 6, all under the cap of 20.
**Mutation probe:** none; a pure move. The overlay unit total was 35 before and after the move.

### IN-03: Misleading comment in the negative-amounts payout test

**Files modified:** `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** e945cec
**Applied fix:** Reworded the comment to "The payout claims 5 gold, but no per-spot amount can carry a coin (the ledger is not credited in this synthetic emit)." and added the same note to the clamped-amounts test at the `dawn_payout.emit` call. Comment-only, so no probe.

### IN-04: `register_section` raises a script error if the `lifetime_owner` is already freed

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd`, `tests/unit/test_debug_overlay_providers.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 4fac944
**Applied fix:** Took the review's second option. `lifetime_owner` is now a `Variant` on both `DebugOverlayModel.register_section` and `DebugOverlay.register_section` (the overlay has the same parameter, so it had the same script error). A freed or non-object owner is refused with `debug overlay section '<title>' not registered: its owner was freed`, both on the model and on the overlay's pre-bind path. The guard uses `typeof(x) != TYPE_NIL`, not `!= null`: a headless probe on Godot 4.7.2 showed a freed instance compares equal to null, so `!= null` would have registered the section with no owner. The docstring states that the owner must be alive at registration. New tests: `test_a_section_whose_owner_was_already_freed_is_refused_with_a_warning` (model) and `test_a_section_registered_with_an_already_freed_owner_is_refused_before_and_after_bind_run` (overlay). The existing `test_register_section_does_not_name_a_parameter_after_the_node_owner_property` still passes (parameter names unchanged).
**Mutation probe:** with the original `Object`-typed sources restored, both new tests fail with the engine's "Invalid type in function 'register_section' ... (previously freed)" script error (2 failing, 35 passing); the fixed sources were then put back.

---

_Fixed: 2026-09-30T11:46:43Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
