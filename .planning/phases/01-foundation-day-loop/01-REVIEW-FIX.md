---
phase: 01-foundation-day-loop
fixed_at: 2026-09-29T14:36:41Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 10
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-29
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11
- Fixed: 10
- Skipped: 1

**Verification:** run in the main checkout (no worktree, per orchestrator instruction), not an isolated worktree. After the last fix: `bash tools/lint.sh` clean (gdformat --check + gdlint), and `bash tools/test.sh` 206/206 green (was 201; 5 tests added). Per-fix checks ran the touched test file plus lint before each commit.

## Fixed Issues

### CR-01: WR-10 stagger fix is a no-op; the computed `stagger` is never used

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 83b1c10
**Applied fix:** The launch loop now schedules coins at `index * stagger` (the tightened value) instead of `index * STAGGER_SECONDS`. Added `test_a_real_payout_lands_every_coin_inside_a_short_dawn_window`, which emits a real `dawn_payout` (12 coins, `dawn_seconds = 1.0`), waits `dawn_seconds + 0.2 s`, and asserts all 12 coins launched, the HUD settled on the ledger, the total shown and no coin still in the air. Confirmed the new test fails (7/8 passed) when the fix is temporarily reverted, then restored.

### WR-01: `MapConfig.validate()` misses an empty building id, and `RunContext` proceeds on invalid data

**Files modified:** `simulation/defs/map_config.gd`, `simulation/buildings/building_system.gd`, `tests/unit/test_prototype_map_data.gd`
**Commit:** 657afb1
**Applied fix:** `validate()` now reports "a building has an empty id". `BuildingSystem._init` skips null building and spot entries (already reported by `validate()`), so `RunContext` construction no longer crashes on them. Added tests for the empty building id and for constructing a `RunContext` from a map with null entries (expects the two `push_error`s via `assert_push_error`).

### WR-02: A payout with `total > 0` but no schedulable coins never shows a total and can leave the HUD lagging

**Files modified:** `ui/hud/hud.gd`, `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 964f489
**Applied fix:** The HUD now lags only by the gold coins can carry (`min(total, sum of positive per_spot amounts)`), so a malformed payout cannot leave the readout permanently short. The vfx calls `_show_total()` when no coin was scheduled. Added a test that emits `dawn_payout(5, {})` and asserts the HUD settles and the total is shown. This avoids emitting `coin_landed` from the vfx, which would race the HUD's own handler ordering.

### WR-03: Registered overlay providers are trusted to return an `Array`; a bad one crashes every refresh

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 57da6f8
**Applied fix:** `collect()` now stores the provider result as a `Variant` and appends the section only when it is an `Array`. Added a test with providers returning null and a String alongside a valid one.

### WR-04: `screenshot.sh` discards the import output, so an import failure is undiagnosable

**Files modified:** `tools/screenshot.sh`
**Commit:** fc8f904
**Applied fix:** The import warm-up logs to `build/screenshot-import.log` (mirroring `export.sh`) and prints `tail -n 20` on failure. Checked with `bash -n` and a real `bash tools/screenshot.sh day_overview` run (saved the PNG, log written).

### WR-05: `test_each_house_spawns_as_many_coins_as_it_pays` is coupled to balance data and to real time

**Files modified:** `tests/e2e/test_dawn_payout.gd`
**Commit:** 8bbf06e
**Applied fix:** Replaced the fixed `wait_seconds(EARLY_S)` with `E2eSupport.wait_until` on the launched coin count. Added an explicit precondition that the paid gold fits `MAX_COINS`, so a rebalance past the cap fails with a clear reason instead of a wrong coin count.

### IN-01: Unused constant `HOUSE_SPOT`

**Files modified:** `tests/e2e/test_map_binding.gd`
**Commit:** d63ed43
**Applied fix:** Deleted the constant.

### IN-02: The `view_source` assertion compares an empty string to an empty string

**Files modified:** `tests/unit/test_building_view_catalog.gd`
**Commit:** bc90a06
**Applied fix:** The stub scene takes over a `user://stub_building_view.tscn` path, and the test asserts the recorded `view_source` equals that non-empty path.

### IN-04: The screenshot job's artifact upload is skipped when capture fails

**Files modified:** `.github/workflows/ci.yml`
**Commit:** a344178
**Applied fix:** The upload step has `if: always()`, also uploads `build/screenshot-import.log`, and `if-no-files-found` is `warn`. YAML parse checked; the workflow itself cannot be run locally.

### IN-05: Redundant `get_spot` lookups and a magic-number spacing in `_add_marker`

**Files modified:** `presentation/buildings/building_views.gd`
**Commit:** a8b919e
**Applied fix:** One `var spot: BuildSpotDef = _ctx.buildings.get_spot(spot_id)` lookup, reused for `building_id` and `position`.

## Skipped Issues

### IN-03: CI runs each push twice once a `gsd/**` branch has a pull request

**File:** `.github/workflows/ci.yml:9-13`
**Reason:** Design trade-off, not applied. The reviewer's preferred fix (a shared concurrency group keyed on `github.head_ref || github.ref_name`) makes the push run and the pull_request run cancel each other. If the surviving run is the push run, the PR's check shows as cancelled, which can block merging under branch protection. Dropping the `gsd/**` push trigger would lose CI for phase branches that have no PR. The duplication is accepted until a human chooses between those options.
**Original issue:** `push` on `gsd/**` plus `pull_request` runs every job twice for the same commit under different concurrency groups, including the 30-minute export job.

---

_Fixed: 2026-09-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
