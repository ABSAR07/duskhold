---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T10:50:43Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T10:50:43Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

**Verification environment:** every gate ran in the main checkout on branch `gsd/phase-01-foundation-day-loop`, not in an isolated worktree. The orchestrator's notes describe in-place edits (backup-and-restore mutation probes, an unrelated uncommitted `.planning/config.json` that had to stay uncommitted), so no worktree was created and no recovery sentinel or cleanup tail applies. The results below are reproducible from the current tree: `bash tools/test.sh` gave 260/260 in 34 scripts (258 before, plus the 2 new WR-02 tests), and `bash tools/lint.sh` is clean.

## Fixed Issues

### WR-01: Malformed provider rows are dropped silently, unlike every other provider failure

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** b223b55
**Applied fix:** `collect` now compares the provider's row count with the cleaned row count and calls `_warn_once` ("dropped N malformed row(s); rows are [label, value]") when any were dropped. The `_warned.erase(title)` re-arm moved to the branch where nothing was dropped, so a provider that keeps returning bad rows warns once per failure streak instead of on every refresh (the concern the review raised). `_warn_once` now takes the tail of the message so "skipped: ..." (section absent) and "dropped ..." (section present, rows missing) read correctly; existing "skipped: ..." texts are unchanged. `_clean_rows` keeps its old signature and still only filters; the warning lives in `collect`, next to the re-arm.
**Test:** `test_a_provider_with_malformed_rows_keeps_only_the_well_formed_ones` (in the file at gdlint's public-method cap, so an existing test was extended rather than a new one added) now collects three times and asserts one warning each for `Flat` and `Mixed` and a warning count of 2.
**Mutation probe:** with `debug_overlay_model.gd` restored to its pre-fix copy, that test failed (3 assertions: both warnings not seen, "Expected 2 push_warning errors. Got 0"; 19/20 passing). Fixed source restored; 20/20 passing.
**Status note:** this changes warning behaviour (a logic-adjacent change); the warn-once/re-arm ordering is worth a glance from a human.

### WR-02: A payout with a positive `total` but only bad or negative `per_spot` entries gives no "+X gold" total and no feedback beyond a warning

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** 51f29b2
**Applied fix:** the `total <= 0` early return in `_on_dawn_payout` now warns ("dawn payout claims %d gold but lists per-spot amounts; nothing shown") when `per_spot` is non-empty, then still emits `payout_started(0)` and returns. I checked `BuildingSystem.dawn_income_by_spot`: it only ever lists positive incomes, so a real dawn with no gold has an empty `per_spot` and the new warning cannot fire spuriously. The `total > 0`, `carried == 0` path already warned and emitted `payout_started(0)` (the review's own note); it is now pinned by a test.
**Tests added (2, hardening file now 7 test/hook methods, well under the cap of 20):**
- `test_a_payout_of_only_negative_amounts_shows_nothing_and_leaves_the_hud_on_the_ledger` (`emit(5, {HOUSE_ONE: -3})`): `payout_started` with 0, the existing "claims 5 gold ... carry 0" warning, no coin, `get_last_total() == 0`, no "+X gold" label, HUD readout equals the ledger. This pins existing behaviour, so it passes against unfixed code by design.
- `test_a_payout_claiming_no_gold_but_listing_amounts_is_reported_and_shows_nothing` (`emit(0, {HOUSE_ONE: 3})`): the new warning exactly once, `payout_started` with 0, no coin, no label, HUD on the ledger.
**Mutation probe:** with `dawn_payout_vfx.gd` restored to its pre-fix copy, the second test failed (missing warning, "Expected 1 push_warning errors. Got 0"; 6/7 passing); the first passed, as expected. Fixed source restored; 7/7 passing.
**CR-01 guard re-check (the file was touched):** replacing `float(launches.size()) * stagger` with `STAGGER_SECONDS` in the fixed source made `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` fail (delay 0.88 instead of 0.25; 17/18 passing). Restored from backup; `test_dawn_payout.gd` is 18/18 again.
**Note:** `gdformat --fix` was run once to wrap the new warning line under 100 columns; it only touched this file.

### IN-01: `_is_gone` and `_skip_reason` duplicate the owner/validity checks

**Files modified:** `ui/overlay/debug_overlay_model.gd`
**Commit:** 3b68379
**Applied fix:** `_skip_reason` is now the single place that decides why a provider cannot be called. Two constants, `REASON_OWNER_FREED` and `REASON_CALLABLE_INVALID`, name the permanent reasons, and `_is_gone(skip_reason)` is derived from them instead of re-checking the owner and the Callable. The transient "declares parameters" reason stays a literal in `_skip_reason` (as a constant it did not fit gdlint's 100-column limit). Behaviour is unchanged.
**Mutation probe:** none possible, this is a behaviour-preserving refactor. The existing suites that drive both branches (`test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning`, `test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner`, `test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing`) still pass: readonly 20/20, registration 5/5.

### IN-02: The read-only assertion covers only part of the simulation state

**Files modified:** `tests/unit/test_debug_overlay_timed_phases.gd`
**Commit:** ee97f17
**Applied fix:** new helper `_agents_and_buildings(ctx)` snapshots `current_tier` for every spot id plus `get_unit_count` and `get_enemy_count`; `_assert_collecting_is_read_only` takes it before the 200 collects and asserts it unchanged afterwards.
**Mutation probe:** a temporary edit made `_count_buildings` silently bump a built spot's tier on every call (no gold change, no event). With it in place both read-only tests failed (`house_1` 202 versus 2; 5/7 passing), which the old assertions could not have caught. Model restored from backup; 7/7 passing.

### IN-03: The registration tests bypass the toggle path, and the visible-refresh timing is wall-clock dependent

**Files modified:** `tests/unit/test_debug_overlay_registration.gd`
**Commit:** 6c38829
**Applied fix:** `_shown_text` now shows the overlay through `Input.action_press` / `action_release` of `DebugOverlay.TOGGLE_ACTION`, so it exercises `_process`'s toggle branch and its immediate `_refresh()`, waits a few process frames instead of 0.35 s, and asserts the overlay became visible. The `REFRESH_WAIT_S` constant is gone and an `after_each` releases all actions so no input state leaks. A first attempt without a leading `wait_process_frames(1)` failed deterministically in the first test of the file (the overlay had not yet run a `_process` frame), so one warm-up frame was added; 3 consecutive runs then passed 5/5.
**Mutation probe:** with the toggle branch's `_refresh()` removed from `debug_overlay.gd`, 4 of 5 tests failed (empty overlay text). The old wall-clock version would have passed against that break because the 0.25 s interval refreshed it anyway. Source restored from backup; 5/5 passing.

---

_Fixed: 2026-09-30T10:50:43Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
