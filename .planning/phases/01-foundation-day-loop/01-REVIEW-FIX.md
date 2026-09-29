---
phase: 01-foundation-day-loop
fixed_at: 2026-09-29T16:36:33Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-29T16:36:33Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7 (IN-04 is fixed except one sub-item that is a pending owner decision, see below)
- Skipped: 0

**Verification:** the full GUT suite (`bash tools/test.sh`, 215/215 green, up from 206) and `bash tools/lint.sh` (clean) ran in the main checkout on branch `gsd/phase-01-foundation-day-loop`, not in an isolated worktree (the orchestrator directed work on the main checkout). Each finding also had its own test file run and lint before its commit. The WR-01 regression test was confirmed to fail without the source fix (null dereference) and pass with it.

## Fixed Issues

### WR-01: Unknown spot id in `per_spot` crashes coin launch and strands the HUD readout

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** ecea4ff
**Applied fix:** `_start_point` now looks the spot up first and falls back to the screen centre when the spot is null (or there is no camera), so the coin still launches, lands and settles the HUD readout. Added an e2e test that pays out to an unknown spot id and asserts the readout settles and the total is shown.

### WR-02: BuildingSystem null-skip hardening leaves duplicate ids and unknown building ids unhandled

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_building_system_data_errors.gd` (new), `tests/unit/test_building_system_data_errors.gd.uid` (new)
**Commit:** 3947eb2
**Applied fix:** A spot whose id is already registered is skipped (first definition wins), so `spot_ids()` never lists an id twice. `dawn_income_by_spot` resolves the building def with `_defs.get(...)` and skips an instance whose building id is unknown instead of hard-indexing. The tests live in a new file because `test_prototype_map_data.gd` is already at gdlint's 20-public-method cap.

### WR-03: Debug overlay only validates the top-level provider return, not the row shape

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 491114f
**Applied fix:** `collect` now passes provider rows through `_clean_rows`, which keeps only Array rows with at least two entries and stringifies label and value. Flat pairs, short rows and non-Array rows are dropped. Added a test covering all three malformed shapes plus a non-String value.

### IN-01: `Hud.bind_run` is only partly idempotent

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_map_binding.gd`
**Commit:** fe800bd
**Applied fix:** `bind_run` returns early when a context is already bound, which protects every connection rather than only `coin_landed`; the special-case `is_connected` guard was removed and the single-call contract is documented. Added a test that a second `bind_run` leaves the `gold_changed`, `dawn_payout` and `coin_landed` connection counts unchanged.

### IN-02: Player-facing strings hard-code the key hint and a placeholder

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** 1dc27ae
**Applied fix:** The start-night hint is built from `InputMap.action_get_events(&"start_night")` (keyboard keys first, gamepad buttons in parentheses), so it follows a runtime rebind the next time the prompt refreshes. With the default bindings the text is unchanged: "Hold N / (Y) to start Night 1". The prompt format and the placeholder night banner moved to constants (`START_NIGHT_PROMPT`, `NIGHT_BANNER`) for Phase 2 to replace; the banner text is unchanged. Added tests for the default text and for a rebind to M, and the test restores the InputMap in `after_each`.

### IN-03: Read-only test watches only 4 of 7 simulation signals

**Files modified:** `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 079d2af
**Applied fix:** `SIM_SIGNALS` now lists `night_started`, `dawn_payout` and `day_started` as well. Added a guard test that compares the list with the signals `SimEvents` declares, so a future signal that is not watched fails the test.

### IN-04: Timing-sensitive e2e assertions and CI trigger overlap

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 9cae015
**Applied fix (parts a and c):**
- (a) The short-dawn-window test no longer sleeps a fixed `dawn_seconds + slack`. It polls until the total is shown (so a slow runner cannot fail the state assertions), then asserts the elapsed real time is within `dawn_seconds + LAND_SLACK_S`, with `LAND_SLACK_S` widened from 0.2 s to 0.5 s. The early-dawn lag test no longer waits 0.25 s against a 0.6 s trip; the first coin launches synchronously when dawn pays, so it asserts one frame after dawn began.
- (c) `launch_stagger` returns the default `STAGGER_SECONDS` when called before `bind_run` instead of dereferencing a null `_ctx`; added a test.

**Not applied (owner decision pending):** the "CI builds a `gsd/**` branch twice once a PR is open" sub-item (push to `gsd/**` plus `pull_request`, and the header comment that says a feature branch is not built twice). `.github/workflows/ci.yml` triggers, concurrency and comment were left unchanged, as directed. The inaccurate comment and the double build still stand until the owner picks a trigger policy.

---

_Fixed: 2026-09-29T16:36:33Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
