---
phase: 01-foundation-day-loop
fixed_at: 2026-09-29T13:10:00Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 12
fixed: 11
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-29
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 12 (fix_scope: all)
- Fixed: 11
- Skipped: 1

**Verification:** every code-touching commit passed `bash tools/lint.sh` and the GUT suite via `bash tools/test.sh`. The final full run was 201 of 201 passing (194 before this pass, plus 7 new tests). All gates ran in the main checkout, using the git-ignored `.tools/` Godot toolchain. No isolated worktree was created, because a hand-rolled worktree has no `.tools/` or `.godot/` and cannot run the gates. Commits landed directly on `gsd/phase-01-foundation-day-loop`; nothing was pushed. Shell-script fixes were verified offline only: `bash -n`, a fake-Godot stub for `export.sh`, and one real local `tools/screenshot.sh day_overview` run for `screenshot.sh`. `tools/bootstrap.py` was not modified or run.

## Fixed Issues

### WR-10: The `MAX_COINS` cap is soft, and the "stays inside the dawn window" guarantee does not hold for many paying spots or a shorter dawn

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** f1f472d
**Status:** fixed: requires human verification (timing logic)
**Applied fix:** Took the review's second option and made the stagger fit the window. New `launch_stagger(coin_total)` returns `clampf((dawn_seconds - TRIP_SECONDS) / max(coin_total - 1, 1), 0, STAGGER_SECONDS)`, reading `_ctx.tuning.dawn_seconds`. `_on_dawn_payout` now counts coins per spot first, then schedules launches with that stagger. The `MAX_COINS` comment no longer claims the cap alone guarantees the window. The per-spot minimum of one coin is unchanged, which is a behaviour-preserving choice. New test: with a 1.0 s dawn and 40 coins, the last coin lands inside the dawn, and a small payout keeps the default stagger.

### IN-01: `BuildingViews._instance_model` leaks the instantiated scene when its root is not a `Node3D`

**Files modified:** `presentation/buildings/building_views.gd`, `tests/unit/test_building_view_catalog.gd`
**Commit:** b31f36b
**Applied fix:** Instantiates into a `Node` variable. When the cast to `Node3D` fails, it calls `push_warning` and `free()`, then returns null so the primitive fallback is used. New test: a catalog scene with a plain `Node` root falls back to the primitive and leaves no orphan. I mutation-checked it: the test fails when the `free()` is removed.

### IN-02: `MapConfig.validate` has gaps that let unbuildable or crashing data through

**Files modified:** `simulation/defs/map_config.gd`, `tests/unit/test_prototype_map_data.gd`
**Commit:** 06c82f5
**Applied fix:** Added an error for a spot with an empty `id`. Added null guards in the buildings, tiers and spots loops, so a null entry now reports an error instead of crashing. Two new tests. Not applied: the review's optional suggestion to refuse to start the run when `validate()` is non-empty. That changes boot behaviour and is a design decision, so `RunContext._init` still only `push_error`s.

### IN-03: `StartNightHoldController._confirm` emits `night_requested` regardless of the submit result

**Files modified:** `input/start_night_hold_controller.gd`
**Commit:** 886be9e
**Applied fix:** `night_requested` is emitted only when `commands.submit(StartNightIntent.new()) == CommandProcessor.OK`. The existing `test_start_night_hold.gd` success-path tests still pass. No new test was added because the phase pre-check means a rejection cannot currently be reached.

### IN-04: `tools/export.sh` ignores the import pass's exit status

**Files modified:** `tools/export.sh`
**Commit:** 408a8df
**Applied fix:** The import output goes to `build/export-import.log`. The script captures the exit status and, on failure, prints the status and the last 20 log lines, then exits with that status. Verified offline with a fake Godot stub that exits 7: the script exited 7 with the diagnostic.

### IN-05: `tools/screenshot.sh` expands possibly-empty arrays under `set -u`

**Files modified:** `tools/screenshot.sh`
**Commit:** a457421
**Applied fix:** Used the `${arr[@]+"${arr[@]}"}` idiom for `wrapper`, `renderer_args` and also the `saved` loop, which has the same empty-array hazard when every shot fails. Checked with `bash -n`, a stub of the idiom under `set -u`, and one real `tools/screenshot.sh day_overview` run (saved the PNG).

### IN-06: Loose or timing-dependent test assertions

**Files modified:** `tests/unit/test_attribution_log.gd`, `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** 980b28f
**Applied fix:** Partial. The ASSETS.md check now anchors on `"| <name> |"` and compares the License table cell exactly, instead of a substring match. The overlay test now requires `Phase: DAY`, `Day: 1` and `Night: 0`. Not changed: the wall-clock timing in `test_dawn_payout.gd` (lag test) and `test_king_ride.gd` (sprint ratio). The review only said to "consider" a fixed-step harness, which is a larger test-infrastructure change, and both tests have passed on every run.

### IN-07: `DebugOverlay` ships in release exports and its section providers are called unguarded

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 834002b
**Applied fix:** Partial. `collect()` now skips a section whose provider `Callable` is invalid (for example a freed owner). New test: a freed provider is skipped and a valid one still shows. Not applied: gating the F3 toggle with `OS.is_debug_build()` or a flag. The overlay in release builds is a documented accepted risk (T-01-15). Removing it from shipped builds changes product behaviour and is an owner decision.

### IN-08: CI runs every push twice on PR branches, and `cancel-in-progress` applies to `main`

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 1786066, eeec04c
**Applied fix:** `push` is restricted to `main`, and `cancel-in-progress` is now `${{ github.ref != 'refs/heads/main' }}`. The header comment was updated. The YAML parses cleanly.
**Orchestrator follow-up (eeec04c):** this repo has no `main` branch. The default is `master`, and phase work is pushed to `gsd/**` branches without a PR, so `push: [main]` would never have run CI. Push builds now cover `main`, `master` and `gsd/**`, and runs on `main` and `master` are never cancelled. Other branches are still built only through their PR. A PR opened from a `gsd/**` branch would build twice; that is accepted so phase branches keep CI.

### IN-09: `test_a_second_map_does_not_hear_the_first_maps_phase_changes` never triggers a phase change

**Files modified:** `tests/e2e/test_map_binding.gd`
**Commit:** 5e480f7
**Applied fix:** Added `test_a_second_maps_night_does_not_reach_the_first_map`. It submits a `StartNightIntent` on the second map and asserts that the second map's `DayNightLighting` goes to night, while the first map's `RunManager` phase stays DAY and its lighting mood stays day. The old gold and HUD test was kept and renamed to what it asserts (`test_a_third_map_does_not_rebind_the_first_maps_hud`).

### IN-10: The GUT SHA256 pin in `bootstrap.py` duplicates `assets/attribution.json` with nothing tying them together

**Files modified:** `tests/unit/test_attribution_log.gd`
**Commit:** 05a0f6c
**Applied fix:** Added `test_bootstrap_gut_sha256_matches_the_manifest`, which reads `GUT_ZIP_SHA256` from `tools/bootstrap.py` and compares it with the `gut` entry's `sha256`. Mutation-checked: changing the pin makes it fail. `bootstrap.py` itself is unchanged, so the consent guard behaviour is unchanged.

## Skipped Issues

### WR-06: License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint

**File:** `assets/attribution.json:83-99` and `tests/unit/test_attribution_log.gd:11,153-159`
**Reason:** Owner decision, already recorded as UAT item 7 in 01-UAT.md. Every fix option (replace the asset, get written confirmation from the author, or change the constraint) is outside a code fixer's remit. The asset was neither swapped nor deleted.
**Original issue:** The `quaternius-horse` entry declares `CC0-1.0` and ships in the build, but quaternius.com now publishes the Quaternius Asset License v1.0, which forbids standalone redistribution. The allow-list test passes only because the manifest author typed `CC0-1.0`.

---

_Fixed: 2026-09-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
