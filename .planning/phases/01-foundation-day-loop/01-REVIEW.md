---
phase: 01-foundation-day-loop
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/ci.yml
  - input/start_night_hold_controller.gd
  - presentation/buildings/building_views.gd
  - simulation/defs/map_config.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_debug_overlay_toggle.gd
  - tests/e2e/test_map_binding.gd
  - tests/unit/test_attribution_log.gd
  - tests/unit/test_building_view_catalog.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_prototype_map_data.gd
  - tools/export.sh
  - tools/screenshot.sh
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 1
  warning: 5
  info: 5
  total: 11
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The 15 files are mostly sound. `StartNightHoldController`, `BuildingViews`, `DebugOverlayModel`, the shell scripts and the CI workflow all trace cleanly. The hold state machine handles early release, held-through-night and rejected-intent correctly. The model-swap seam frees mis-authored scene instances. The shell scripts quote the space-containing repo path throughout and delete stale outputs before checking for new ones.

One real defect stands out. The WR-10 fix for the dawn coin stagger (commit f1f472d) computes the tightened stagger and then never uses it. The test added with it checks only the pure helper, so the suite cannot see the no-op. The remaining findings are robustness gaps in `MapConfig.validate()`, an edge case in the vfx, a hazard in the overlay-provider contract, and test fragility.

No structural findings (fallow) were supplied. No external reviewer evidence was supplied.

## Critical Issues

### CR-01: WR-10 stagger fix is a no-op; the computed `stagger` is never used

**File:** `ui/hud/dawn_payout_vfx.gd:104-113`
**Issue:** `_on_dawn_payout` computes `var stagger: float = launch_stagger(coin_total)`. The launch loop then schedules each coin with `float(index) * STAGGER_SECONDS`, the un-tightened constant. `stagger` is dead, so the guarantee documented at lines 20-22 and 69-70 ("the last coin lands before the dawn window ends") is not enforced. The coin count is `MAX_COINS` plus up to one extra coin per paying spot, because each spot gets at least 1. With `dawn_seconds = 2.0` the window is 1.4 s, so about 19 coins (`18 * 0.08 = 1.44`) overrun it. A shorter `dawn_seconds` overruns sooner. When that happens the last coins land after day has returned and the HUD gold readout lags the ledger into the next day. That is the exact failure WR-10 was meant to close. Shipped data (5 houses, 10 coins) does not hit it, but `dawn_seconds` is a designer tuning knob.

The test `test_the_last_coin_lands_inside_the_dawn_window_however_many_spots_pay` (`tests/e2e/test_dawn_payout.gd:182-199`) only calls `vfx.launch_stagger(40)` and does arithmetic on the result. It never emits a payout, so it passes while the real launch path ignores the value. Godot will also raise an UNUSED_VARIABLE warning on this line.

**Fix:**
```gdscript
_schedule_launch(
	spot_id, float(index) * stagger, _coin_share(amount, coin_count, coin)
)
```
Then change the test to emit `dawn_payout` with more paying spots than `MAX_COINS` under a short `dawn_seconds`. Assert that the vfx's launched coin count reaches the expected total and that the HUD settles within `dawn_seconds`. Alternatively, expose the last scheduled delay and assert `delay + TRIP_SECONDS <= dawn_seconds`.

## Warnings

### WR-01: `MapConfig.validate()` misses an empty building id, and `RunContext` proceeds on invalid data

**File:** `simulation/defs/map_config.gd:24-30` (consumer: `simulation/run/run_context.gd:16`, `simulation/buildings/building_system.gd:14`)
**Issue:** There are two gaps.
1. A `BuildingDef` with `id == &""` is not reported, though an empty spot id is (line 51). A spot whose `building_id` is also empty then resolves to that building, so the "unknown building id" check passes silently.
2. `RunContext._init` only `push_error`s on validation errors and continues. A null entry in `buildings` is reported here, but `BuildingSystem._init` then does `building_def.id` on that null and crashes. A null spot is likewise dereferenced (`spot.id`). The T-01-10 "reported, not crashed" property therefore does not hold for the real construction path. The unit test only calls `validate()` in isolation.

**Fix:** In `validate()`, add `if building_def.id == &"": errors.append("a building has an empty id")`. In `RunContext._init`, either stop on errors (assert or return an error) or make `BuildingSystem._init` skip null entries. Add a test that constructs a `RunContext` from a map with a null building.

### WR-02: A payout with `total > 0` but no schedulable coins never shows a total and can leave the HUD lagging

**File:** `ui/hud/dawn_payout_vfx.gd:93-114` (with `ui/hud/hud.gd:_on_dawn_payout`)
**Issue:** `_on_dawn_payout` returns early only for `total <= 0`. If `per_spot` is empty or every amount is `<= 0` while `total > 0`, then `_expected_coins` stays 0 and `_show_total()` is never reached. `Hud._on_dawn_payout` has already set `_payout_pending = total`, and only `coin_landed` ever decrements it. The gold label would stay short by `total` until the next payout. `SimEvents.dawn_payout(total, per_spot)` does not guarantee that the parts sum to the total.

**Fix:** In the vfx, after the launch loop, `if _expected_coins == 0: _show_total()`. Alternatively, have the HUD clear `_payout_pending` when `_per_spot` sums to zero. Consider asserting `sum(per_spot.values()) == total` at the producer.

### WR-03: Registered overlay providers are trusted to return an `Array`; a bad one crashes every refresh

**File:** `ui/overlay/debug_overlay_model.gd:30-36`
**Issue:** The IN-07 fix guards against a freed owner but not against a provider that returns `null` or a non-Array. `_section(title, rows: Array)` is typed, so such a return raises a runtime error inside `collect()`. `collect()` runs about 4 times a second, and Phase 2 will register wave and path providers. The header comment promises that one bad section cannot take down the overlay.

**Fix:**
```gdscript
var rows: Variant = provider.call()
if rows is Array:
	sections.append(_section(entry["title"], rows))
```
Add a test for a provider that returns null.

### WR-04: `screenshot.sh` discards the import output, so an import failure is undiagnosable

**File:** `tools/screenshot.sh:50-55`
**Issue:** The `--import` warm-up is sent to `/dev/null`, so on failure the script prints only "exited with N". `export.sh` logs the same step to `build/export-import.log` and tails it on failure. In CI (the `screenshots` job) nothing is uploaded on failure, so there is no way to see why.

**Fix:** Log to `${DUSKHOLD_ROOT}/build/screenshot-import.log`, mirroring `export.sh`. Print `tail -n 20` on failure. In `ci.yml`, add `if: always()` to the upload step, or upload the logs separately.

### WR-05: `test_each_house_spawns_as_many_coins_as_it_pays` is coupled to balance data and to real time

**File:** `tests/e2e/test_dawn_payout.gd:140-152`
**Issue:** The test waits `EARLY_S` (0.5 s) and then asserts `get_spawned_count(house) == tier income`. That holds only while the total payout stays within both limits:
- **Cap:** total gold must not exceed `MAX_COINS` (12), because the cap merges gold onto fewer coins.
- **Launch time:** roughly 6 coins or fewer, because the last launch is at `(n-1) * 0.08` s.

The current values (1 + 2 = 3) pass. Rebalancing house income, which `house.tres` is expected to undergo, makes the test fail for a non-bug reason. It also fails under a slow frame, since it waits wall-clock time (`await wait_seconds`).

**Fix:** Assert against `_coins_for_amount`-derived expectations. Alternatively, wait with `wait_until` for the spawned count to reach the expected value instead of a fixed sleep, and set a low fixed income in a duplicated map.

## Info

### IN-01: Unused constant `HOUSE_SPOT`

**File:** `tests/e2e/test_map_binding.gd:8`
**Issue:** `HOUSE_SPOT` is declared and never referenced.
**Fix:** Delete it.

### IN-02: The `view_source` assertion compares an empty string to an empty string

**File:** `tests/unit/test_building_view_catalog.gd:61`
**Issue:** The stub scene is packed in memory, so `stub.resource_path` is `""`. The assertion `modelled.get_meta("view_source") == stub.resource_path` therefore passes for any empty-string meta. It does still distinguish the model path from `"primitive"`, but it does not prove that the source path is recorded.
**Fix:** Save the stub to `user://` or a `res://` temp path first. Alternatively, assert `assert_ne(..., VIEW_SOURCE_PRIMITIVE)` together with an explicit check that the model branch ran.

### IN-03: CI runs each push twice once a `gsd/**` branch has a pull request

**File:** `.github/workflows/ci.yml:9-13`
**Issue:** `push: branches: [..., "gsd/**"]` plus `pull_request` runs every job for the same commit under two concurrency groups, `refs/heads/gsd/...` and `refs/pull/N/merge`, so neither cancels the other. This includes the 30-minute `export` job. The header comment justifies the push trigger for branches without a PR, but that trigger stays on after a PR exists.
**Fix:** Accept the duplication, or gate the push trigger, for example with a job-level `if: github.event_name != 'push' || !contains(github.event.head_commit.message, ...)`. Better, use a shared concurrency group keyed on `github.head_ref || github.ref_name`.

### IN-04: The screenshot job's artifact upload is skipped when capture fails

**File:** `.github/workflows/ci.yml:153-159`
**Issue:** The `test` job uses `if: always()` for its results upload. The `screenshots` job does not, so partial screenshots that would show which shot broke are dropped on failure (see WR-04).
**Fix:** Add `if: always()` to the upload step. Keep `if-no-files-found: error`, or switch it to `warn` for the failure case.

### IN-05: Redundant `get_spot` lookups and a magic-number spacing in `_add_marker`

**File:** `presentation/buildings/building_views.gd:87,92`
**Issue:** `_ctx.buildings.get_spot(spot_id)` is called twice. A null (unknown spot) would crash at the first call. This is unreachable with `spot_ids()` today.
**Fix:** `var spot: BuildSpotDef = _ctx.buildings.get_spot(spot_id)` once, then use `spot.building_id` and `spot.position`.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
