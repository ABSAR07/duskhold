---
phase: 01-foundation-day-loop
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/ci.yml
  - presentation/map/map_root.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/e2e/test_walking_skeleton.gd
  - tools/bootstrap.py
  - tools/prepush_check.sh
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
findings:
  critical: 0
  warning: 2
  info: 10
  total: 12
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 9 (incremental scope: everything changed since 0b7a22c)
**Status:** issues_found

## Summary

This is an incremental re-review of the eight warning fixes recorded in 01-REVIEW-FIX.md, plus a carry-forward check of every finding in the prior report against current source.

**Verified fixed (omitted from this report):** WR-01, WR-02, WR-03, WR-04, WR-05, WR-07, WR-08, WR-09.

- WR-01: `MapRoot._ready` binds only `run_bound` nodes for which `is_ancestor_of(node)` holds. `test_map_binding.gd` covers it.
- WR-02: `MAX_COINS` caps the coins and `coin_landed(amount)` carries each coin's share. `_coin_share` sums exactly to the spot amount. `Hud._refresh` clamps at 0. One residual gap remains and is filed as a new finding (WR-10).
- WR-03: `install_gut` skips when the vendored addon reports the pinned version.
- WR-04: `Path.replace` and `timeout=60` are in place. `fetch_official_sums` deletes the sums file.
- WR-05: the zip SHA256 is pinned and checked before extraction. Extraction and the version check happen in staging, and `swap_directory` restores the original on failure.
- WR-07: `tick(minf(delta, MAX_SIM_STEP))`, with a test.
- WR-08: the regex is extended to `gh[pousr]_`, Stripe, Google, npm and Slack formats, and gitleaks runs when installed. I read the pattern and found no self-match.
- WR-09: all 20 `uses:` lines are pinned to 40-character SHAs with release comments. I did not re-resolve the SHAs against GitHub (no network use). Verify them once with `gh api` before relying on them. The optional re-hash of the cached Godot binary was not done. It was marked optional in the original finding, so this is not a regression.

**Carried forward, still open after re-reading the cited source:** WR-06 and IN-01 through IN-08. Line numbers were refreshed. The IN-06 `test_attribution_log.gd` reference was wrong in the prior report (786-797) and is corrected to 236-251.

**New findings:** WR-10, IN-09 and IN-10. No critical defect and no regression was found in the changed code. The full set of fixes is otherwise sound.

## Warnings

### WR-06: License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint

**File:** `assets/attribution.json:83-99` and `tests/unit/test_attribution_log.gd:11,153-159`
**Issue:** `CLAUDE.md` requires CC0 (or equally permissive) assets only. The `quaternius-horse` entry declares `"license": "CC0-1.0"` and `"ships_in_build": true`, but its own notes say quaternius.com now publishes the Quaternius Asset License v1.0. That license forbids redistributing the assets "as a standalone asset". The GLB is shipped as a loose resource in the exported `.pck`, where it is trivially extractable, so it is arguably standalone redistribution. `test_every_license_is_on_the_allow_list` passes only because the manifest author typed `CC0-1.0`; the test cannot detect the conflict it was written to prevent. The caveat is disclosed but not resolved, and the build ships the asset today. The prior fix pass skipped this as an owner decision (UAT item 7 in 01-UAT.md). It remains open.
**Fix:** Before the itch.io push, do one of the following and record it in the manifest:
- Replace the horse with an asset whose current license page is unambiguously CC0.
- Obtain written confirmation from the author.
- Set the entry's license to `QAL-1.0`, and either drop it from the allow-list and swap the asset, or explicitly extend the constraint.

### WR-10: The `MAX_COINS` cap is soft, and the "stays inside the dawn window" guarantee does not hold for many paying spots or a shorter dawn

**File:** `ui/hud/dawn_payout_vfx.gd:20-23,105-110`
**Issue:** The WR-02 fix caps coins per payout at `MAX_COINS = 12`, and the constant's comment says the whole flight "stays inside the dawn window". The cap is per spot. `_coins_for_amount` returns `clampi(floor(amount * 12 / total), 1, amount)`, so every paying spot gets at least one coin. With N paying spots and `total > 12`, the payout launches at least N coins. The last coin lands at `(N-1) * 0.08 + 0.6` seconds. That exceeds `dawn_seconds = 2.0` once N is 19 or more. `STAGGER_SECONDS` and `TRIP_SECONDS` are also hard-coded and not tied to `LoopTuning.dawn_seconds`. Shortening the dawn in tuning (for example to 1.0 s) reintroduces the original WR-02 window, where the HUD label hides gold the player can already spend. The prototype map has only 5 house plots, so this is latent, but later phases add plots.
**Fix:** Enforce the cap on the total coin count, not per spot. Either distribute the `MAX_COINS` budget with a largest-remainder method (spots beyond the budget share a coin), or compute the stagger from the available window. For example, `stagger = minf(STAGGER_SECONDS, (dawn_seconds - TRIP_SECONDS) / maxi(coin_total - 1, 1))`, using `_ctx.tuning.dawn_seconds`. Add a test with more paying spots than `MAX_COINS`.

## Info

### IN-01: `BuildingViews._instance_model` leaks the instantiated scene when its root is not a `Node3D`

**File:** `presentation/buildings/building_views.gd:126-132`
**Issue:** `scene.instantiate() as Node3D` yields null for a non-`Node3D` root, but the instantiated node is never freed. The caller then falls back to a primitive, so a mis-authored catalog entry silently leaks a node per build instead of failing loudly.
**Fix:** Instantiate into a `Node` variable, and `push_warning` and `free()` it if the cast fails.

### IN-02: `MapConfig.validate` has gaps that let unbuildable or crashing data through

**File:** `simulation/defs/map_config.gd:19-47`
**Issue:**
- A spot with an empty `id` passes validation, but `nearest_spot_in_range` and `BuildHoldController` use `&""` as "no spot", so that spot can never be built.
- Null entries in `buildings`, `spots` or `tiers` crash with a null dereference instead of a validation error.
- `RunContext._init` only `push_error`s and continues, so invalid data still boots the run.
**Fix:** Add `if spot.id == &"": errors.append(...)` and null guards in each loop. Consider refusing to start the run when `validate()` is non-empty.

### IN-03: `StartNightHoldController._confirm` emits `night_requested` regardless of the submit result

**File:** `input/start_night_hold_controller.gd:49-53`
**Issue:** The return value of `commands.submit(StartNightIntent.new())` is ignored. Today the phase was just checked, so it cannot fail, but the signal is a future SFX or analytics hook and would fire on a rejection once other gates exist.
**Fix:** `if _ctx.commands.submit(StartNightIntent.new()) == CommandProcessor.OK: night_requested.emit()`.

### IN-04: `tools/export.sh` ignores the import pass's exit status

**File:** `tools/export.sh:28`
**Issue:** `--import >/dev/null 2>&1` discards both output and status, so a failed import surfaces only as a confusing export failure later, with no diagnostic. `tools/screenshot.sh` checks the same step.
**Fix:** Capture the status as in `screenshot.sh:50-55`, and log the output to `build/`.

### IN-05: `tools/screenshot.sh` expands possibly-empty arrays under `set -u`

**File:** `tools/screenshot.sh:76-78`
**Issue:** `"${wrapper[@]}"` and `"${renderer_args[@]}"` are empty in the local Windows path. On bash older than 4.4 (for example macOS `/bin/bash` 3.2) this raises "unbound variable". Git Bash and Ubuntu CI are fine, so this is latent portability only.
**Fix:** Use `${wrapper[@]+"${wrapper[@]}"}`, or drop `set -u` for those expansions.

### IN-06: Loose or timing-dependent test assertions

**File:** `tests/unit/test_attribution_log.gd:236-251`, `tests/e2e/test_debug_overlay_toggle.gd:8-10`, `tests/e2e/test_dawn_payout.gd:92-104`, `tests/e2e/test_king_ride.gd:62-69`
**Issue:**
- `test_assets_md_lists_every_entry_in_json_order` uses `text.find(name, cursor)`, which can match the name in prose rather than the table row, and then checks `row.contains(license)`. The substring `"MIT"` matches any row containing it.
- The overlay test's `"DAY"` matches `Phase: DAY`, so the actual `Day:` and `Night:` rows are never checked in the e2e test. They are only covered in `test_dawn_income.gd`.
- The dawn-lag test asserts wall-clock ordering, with a coin flight of 0.6 s against a 0.25 s wait, and the sprint test asserts a real-time ratio within 15%. Both are reasonable today but are the first candidates to flake on a loaded CI runner.
**Fix:** Anchor the ASSETS.md check to the table row (for example `text.find("| %s |" % name)`). Assert `"Day: 1"` in the overlay test. Consider driving these e2e timings from `RunManager.tick` or a fixed-step harness.

### IN-07: `DebugOverlay` ships in release exports and its section providers are called unguarded

**File:** `ui/overlay/debug_overlay.gd:36-40,46-55` and `ui/overlay/debug_overlay_model.gd:30-33`
**Issue:** The overlay is documented as accepted-risk (T-01-15), but F3 is reachable in the shipped build. `provider.call()` in `collect()` is unguarded, so an invalid or freed `Callable` registered by a later phase crashes the overlay every 0.25 s while it is visible.
**Fix:** Gate the toggle with `OS.is_debug_build()` or a feature flag, and check `provider.is_valid()` before calling.

### IN-08: CI runs every push twice on PR branches, and `cancel-in-progress` applies to `main`

**File:** `.github/workflows/ci.yml:7-18`
**Issue:** `push: branches: ["**"]` plus `pull_request` runs the whole matrix twice per commit on a PR branch. `concurrency` with `cancel-in-progress: true` can also cancel an in-flight `main` run, including the export job that produces the release artifact.
**Fix:** Restrict `push` to `main` (PRs are covered by `pull_request`), and set `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.

### IN-09: `test_a_second_map_does_not_hear_the_first_maps_phase_changes` never triggers a phase change

**File:** `tests/e2e/test_map_binding.gd:36-53`
**Issue:** The test name and header claim the first map ignores the second map's phase changes, but no phase change is ever emitted. It only checks gold and the first HUD's label after a third map spawns. That does catch the old re-bind of the HUD (the label would show the rich map's gold). It does not exercise the `DayNightLighting`, `SpotLabel` or `CoinDripVfx` re-binding described in the original WR-01, so a regression there would pass.
**Fix:** Submit a `StartNightIntent` on the second map and assert the first map's `RunManager` phase and `DayNightLighting` state are unchanged. Otherwise rename the test to what it asserts (for example `..._does_not_rebind_the_first_maps_hud`).

### IN-10: The GUT SHA256 pin in `bootstrap.py` duplicates `assets/attribution.json` with nothing tying them together

**File:** `tools/bootstrap.py:43-44`
**Issue:** `GUT_ZIP_SHA256` is a hand-copied second source of truth for the value in `assets/attribution.json` (gut entry). A future GUT bump that updates only one of them leaves the installer rejecting a valid archive, or the manifest recording a hash that is not the pinned one. There is no test that compares them.
**Fix:** Add a unit test that reads both and asserts equality, or have `bootstrap.py` read the value from `attribution.json`.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
