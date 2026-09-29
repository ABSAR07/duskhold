---
phase: 01-foundation-day-loop
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 106
files_reviewed_list:
  - .gdlintrc
  - .gitattributes
  - .github/workflows/ci.yml
  - .gitignore
  - .gutconfig.json
  - ASSETS.md
  - assets/attribution.json
  - data/buildings/house.tres
  - data/buildings/tower.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - export_presets.cfg
  - input/build_hold_controller.gd
  - input/start_night_hold_controller.gd
  - presentation/buildings/building_view_catalog.gd
  - presentation/buildings/building_view_catalog.tres
  - presentation/buildings/building_view_entry.gd
  - presentation/buildings/building_views.gd
  - presentation/buildings/models/castle_center.tscn
  - presentation/buildings/models/house_t1.tscn
  - presentation/buildings/models/house_t2.tscn
  - presentation/buildings/models/house_t3.tscn
  - presentation/buildings/models/tower_t1.tscn
  - presentation/buildings/models/tower_t2.tscn
  - presentation/camera/camera_rig.gd
  - presentation/environment/day_night_lighting.gd
  - presentation/king/king.gd
  - presentation/king/king.tscn
  - presentation/king/king_model.tscn
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/vfx/coin_drip_vfx.gd
  - project.godot
  - simulation/buildings/building_instance.gd
  - simulation/buildings/building_system.gd
  - simulation/commands/build_intent.gd
  - simulation/commands/command_processor.gd
  - simulation/commands/start_night_intent.gd
  - simulation/defs/build_spot_def.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/king_def.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/economy/economy.gd
  - simulation/events/sim_events.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_build_denied.gd
  - tests/e2e/test_building_models.gd
  - tests/e2e/test_coin_drip.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_debug_overlay_toggle.gd
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_spot_label.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_walking_skeleton.gd
  - tests/fixtures/fixture_map_empty.tres
  - tests/fixtures/fixture_map_one_tier.tres
  - tests/fixtures/fixture_map_poor.tres
  - tests/fixtures/fixture_map_tie.tres
  - tests/integration/test_build_flow.gd
  - tests/integration/test_build_hold_refund.gd
  - tests/integration/test_loop_gold_carryover.gd
  - tests/integration/test_upgrade_flow.gd
  - tests/unit/test_attribution_log.gd
  - tests/unit/test_build_phase_guard.gd
  - tests/unit/test_build_spot.gd
  - tests/unit/test_build_spot_affordability.gd
  - tests/unit/test_building_view_catalog.gd
  - tests/unit/test_dawn_income.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_economy_gold.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_king_movement_config.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_run_manager.gd
  - tests/unit/test_shot_blank_check.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_toolchain_smoke.gd
  - tools/_common.sh
  - tools/bootstrap.py
  - tools/export.sh
  - tools/godot.sh
  - tools/godot_sha512sums.txt
  - tools/godot_version.txt
  - tools/lint.sh
  - tools/prepush_check.sh
  - tools/requirements-lint.txt
  - tools/screenshot.sh
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_runner.tscn
  - tools/screenshot/shot_scenarios.gd
  - tools/test.sh
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
  - ui/overlay/debug_overlay_model.gd
  - ui/world/spot_label.gd
  - ui/world/spot_label.tscn
  - ui/world/spot_label_model.gd
findings:
  critical: 0
  warning: 9
  info: 8
  total: 17
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 106
**Status:** issues_found

## Summary

The simulation core is solid. `RunManager`, `Economy`, `CommandProcessor` and `BuildingSystem` keep their invariants:

- Gold cannot go negative.
- Every mutation passes the single command gate.
- The gate re-validates phase, spot and affordability on each submit.
- Dawn pays exactly once.
- At most one phase change happens per tick.

I found no gold or loop-state bug in the simulation layer. `Resource.duplicate(true)` really does deep-copy the spot sub-resources (verified with a headless probe), so the tests that mutate map duplicates do not leak state between tests.

The defects are at the seams:

- Scene wiring: `MapRoot` binds tree-wide instead of to its own subtree.
- HUD and dawn-payout presentation: the payout readout lags by a duration that grows with payout size, and it is unclamped.
- Tooling: `tools/bootstrap.py` has real Windows and `--all` failures and does not verify GUT.
- Provenance: the attribution guard can be defeated by an entry declaring its own license, and the horse asset's license caveat conflicts with the project's CC0-only constraint.
- Test reliability: a few tests are wall-clock sensitive or match loosely.

No BLOCKER-class defect was found.

## Warnings

### WR-01: `MapRoot` binds every `run_bound` node in the whole tree, so a second map cross-binds and duplicates the first map's views

**File:** `presentation/map/map_root.gd:18`
**Issue:** `get_tree().call_group(&"run_bound", &"bind_run", _ctx, self)` reaches every `run_bound` node in the SceneTree, not just this map's subtree. When a second `MapRoot` enters the tree while the first is still alive, the first map's nodes are re-bound to the second map's context:

- `BuildingViews.bind_run` adds a second castle and a second set of markers, because `_add_castle` and `_add_marker` are not idempotent.
- `SpotLabel`, `DayNightLighting`, `CoinDripVfx` and `Hud` connect additional signals to the new `ctx.events` and the new `BuildHold`.
- The old map's lighting and HUD then react to the new run's phase changes.

`hud.gd:33-36` documents this and patches only one symptom (the `coin_landed` double-connect). `tests/e2e/test_spot_label.gd:151-170` already spawns two maps at once, so the bug is exercised but not asserted. It will bite when Phase 2+ adds restart-run, map-select or scene reload with the new instance added before the old one is freed.
**Fix:** Scope the binding to this map's own subtree.
```gdscript
func _ready() -> void:
	_ctx = RunContext.new(map_config, loop_tuning)
	_king.global_position = map_config.king_spawn
	for node: Node in get_tree().get_nodes_in_group(&"run_bound"):
		if node != self and is_ancestor_of(node):
			node.call(&"bind_run", _ctx, self)
```
Also add an e2e test that spawns two maps and asserts the first map's `BuildingViews` still has exactly one `CastleCenter`.

### WR-02: Dawn payout readout lag is unbounded and the HUD gold label can go negative

**File:** `ui/hud/dawn_payout_vfx.gd:18,89-91` and `ui/hud/hud.gd:110-111`
**Issue:** One coin is launched per gold of income, staggered 0.08 s apart with no cap. Dawn lasts 2.0 s, so a payout of more than about 18 gold keeps coins flying after the day has started. `Hud._refresh` shows `economy.get_gold() - _pending - _payout_pending` with no clamp, and the Economy is already credited in full. In that window the player can start a hold and spend real gold that the label still hides:

- The label can show a wrong balance (for example the ledger says 15 and the label says 0).
- It can also go negative, for example "Gold: -3".

Later phases with larger incomes will make the lag last many seconds. A 200-gold payout would trickle in for about 16 s.
**Fix:** Cap the number of coins, or the total launch span, and clamp the display.
```gdscript
const MAX_COINS: int = 12  # each coin then carries amount/MAX_COINS visually
...
_gold_label.text = "Gold: %d" % maxi(_ctx.economy.get_gold() - _pending - _payout_pending, 0)
```
If a coin represents more than one gold, also change `Hud._on_coin_landed` to subtract that coin's share, so the pending amount still reaches exactly 0.

### WR-03: `tools/bootstrap.py --all` always exits 1 on a normal checkout and never installs the lint tools

**File:** `tools/bootstrap.py:437-439,503-531`
**Issue:** `--all` sets `args.gut = True`. `install_gut` hard-fails with `sys.exit(1)` when `addons/gut` exists and `--force` was not given, and GUT is vendored and committed. Because the order is godot, templates, gut, lint, the run downloads about 1.3 GB and then dies before `install_lint_tools`. The documented "Shorthand for --godot --templates --gut --lint-tools" cannot succeed on any checkout.
**Fix:** Make an existing addon a skip, not a fatal error, when the version already matches.
```python
if dest_dir.exists() and not args.force:
    print("addons/gut already present; skipping (use --force to reinstall)")
    return ""
```

### WR-04: `download_asset` fails permanently on Windows once a target file already exists, and has no timeout

**File:** `tools/bootstrap.py:171-189`
**Issue:** `part_path.rename(final_path)` raises `FileExistsError` on Windows if `final_path` exists. On POSIX it overwrites, so CI never sees this. `FileExistsError` is an `OSError`, so it is swallowed by the retry loop. All three attempts fail, then `FATAL: could not download`. It triggers whenever a previous run left a file in `.tools/downloads/`:

- `fetch_official_sums` never deletes `SHA512-SUMS.txt`, so a second `--write-pin` run fails.
- `--keep-downloads` and `--force` runs fail the same way.

`urllib.request.urlopen(req)` also has no `timeout`, so a stalled connection hangs indefinitely, until the CI job timeout.
**Fix:** Use `part_path.replace(final_path)` and pass `timeout=60` to `urlopen`. Optionally delete `SHA512-SUMS.txt` after parsing it.

### WR-05: GUT is downloaded from a mutable tag and never checked against a pin, and a failed check destroys the committed addon

**File:** `tools/bootstrap.py:441-470` (and `assets/attribution.json:70`)
**Issue:** `install_gut` downloads `refs/tags/v9.7.1.zip`, computes SHA256, prints it, and never compares it to anything. The value in `attribution.json` (`14969aa4...`) is not enforced, unlike the Godot artifacts, which are pinned. Git tags are mutable. The addon is then extracted straight into `addons/gut/` after `shutil.rmtree(dest_dir)`, and the `plugin.cfg` version check runs after the delete and extract. If that check fails, the committed vendored addon has already been replaced, and the run leaves the tree broken with exit 1. This is code that executes inside the editor and test runs.
**Fix:** Pin the expected SHA256 in a committed file (or read it from `attribution.json`) and compare before extracting. Extract to a temp directory, verify `plugin.cfg`, then swap directories.

### WR-06: License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint

**File:** `assets/attribution.json:83-99` and `tests/unit/test_attribution_log.gd:11,157`
**Issue:** `CLAUDE.md` requires CC0 (or equally permissive) assets only. The `quaternius-horse` entry declares `"license": "CC0-1.0"` and `"ships_in_build": true`, but its own notes say quaternius.com now publishes the Quaternius Asset License v1.0. That license forbids redistributing the assets "as a standalone asset". The GLB is shipped as a loose resource in the exported `.pck`, where it is trivially extractable, so it is arguably standalone redistribution. `test_every_license_is_on_the_allow_list` passes only because the manifest author typed `CC0-1.0`; the test cannot detect the conflict it was written to prevent. The caveat is disclosed but not resolved, and the build ships the asset today.
**Fix:** Before the itch.io push, do one of the following and record it in the manifest:
- Replace the horse with an asset whose current license page is unambiguously CC0.
- Obtain written confirmation from the author.
- Set the entry's license to `QAL-1.0`, and either drop it from the allow-list and swap the asset, or explicitly extend the constraint.

### WR-07: Simulation clock takes raw frame `delta` with no clamp

**File:** `presentation/map/map_root.gd:21-22`
**Issue:** `_ctx.run_manager.tick(delta)` uses the unclamped `_process` delta. On Windows a window drag, an alt-tab stall, a debugger pause or a disk hitch delivers one huge delta. That single tick can immediately end the 4 s night, or pay dawn and skip the whole dawn. The state machine is safe: it makes one transition per tick and discards the remainder. But real-time gameplay windows, and Phase 2 wave timers, will jump by the length of the stall.
**Fix:** Clamp the step, for example `tick(minf(delta, MAX_SIM_STEP))` with `MAX_SIM_STEP = 0.25`, or accumulate a fixed-step loop. Keep the existing huge-tick unit tests, which exercise `RunManager` directly.

### WR-08: `prepush_check.sh` credential regex misses common token formats

**File:** `tools/prepush_check.sh:58`
**Issue:** This script is the last gate before publishing the history to a public remote. `gh[pos]_` matches `ghp_`, `gho_` and `ghs_` but not `ghu_` or `ghr_`. Other common formats are not covered: Stripe `sk_live_`/`rk_live_` (the `sk-` alternative needs a hyphen), Google `AIza...`, npm `npm_...`, and Slack webhook URLs. A false "PASSED" is worse than no check. Separately, the scan only sees added lines in `git log -p`, so LFS pointer contents and binary blobs are not inspected.
**Fix:** Extend the pattern, for example `gh[pousr]_[A-Za-z0-9]{30,}|(sk|rk)_(live|test)_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{35}|npm_[A-Za-z0-9]{36}`. Better, run a maintained scanner (gitleaks or trufflehog) in CI or before push.

### WR-09: CI actions are pinned to mutable major tags, and the LFS cache key omits pointer verification

**File:** `.github/workflows/ci.yml:25,28,41,47,53,57,67,79,...`
**Issue:** `actions/checkout@v7`, `setup-python@v7`, `cache@v6` and `upload-artifact@v7` are floating tags. They can be moved by the publisher or after a compromise, and this workflow builds the artifact that gets pushed to itch.io. The Godot binary is cached and reused without re-hashing. `install_godot` only checks `bin_path.exists()` (bootstrap.py:357). A poisoned cache entry under `godot-editor-linux-...` would then be executed by the test and screenshots jobs. The token is read-only and there is no injection of `github.event.*` into `run:`, which limits the blast radius. The pin discipline stops at the Godot checksum.
**Fix:** Pin actions to full commit SHAs, and optionally add a `sha512sum -c` step over the cached binary or archive before use.

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
**Fix:** `if _ctx.commands.submit(...) == CommandProcessor.OK: night_requested.emit()`.

### IN-04: `tools/export.sh` ignores the import pass's exit status

**File:** `tools/export.sh:28`
**Issue:** `--import >/dev/null 2>&1` discards both output and status, so a failed import surfaces only as a confusing export failure later, with no diagnostic. `tools/screenshot.sh` checks the same step.
**Fix:** Capture the status as in `screenshot.sh:50-55`, and log the output to `build/`.

### IN-05: `tools/screenshot.sh` expands possibly-empty arrays under `set -u`

**File:** `tools/screenshot.sh:76-78`
**Issue:** `"${wrapper[@]}"` and `"${renderer_args[@]}"` are empty in the local Windows path. On bash older than 4.4 (for example macOS `/bin/bash` 3.2) this raises "unbound variable". Git Bash and Ubuntu CI are fine, so this is latent portability only.
**Fix:** Use `${wrapper[@]+"${wrapper[@]}"}`, or drop `set -u` for those expansions.

### IN-06: Loose or timing-dependent test assertions

**File:** `tests/unit/test_attribution_log.gd:786-797`, `tests/e2e/test_debug_overlay_toggle.gd:8-10`, `tests/e2e/test_dawn_payout.gd:92-104`, `tests/e2e/test_king_ride.gd:62-69`
**Issue:**
- `test_assets_md_lists_every_entry_in_json_order` uses `text.find(name, cursor)`, which can match the name in prose rather than the table row, and then checks `row.contains(license)`. The substring `"MIT"` matches any row containing it.
- The overlay test's `"DAY"` matches `Phase: DAY`, so the actual `Day:` and `Night:` rows are never checked in the e2e test. They are only covered in `test_dawn_income.gd`.
- The dawn-lag test asserts wall-clock ordering, with a coin flight of 0.6 s against a 0.25 s wait, and the sprint test asserts a real-time ratio within 15%. Both are reasonable today but are the first candidates to flake on a loaded CI runner.
**Fix:** Anchor the ASSETS.md check to the table row (for example `text.find("| %s |" % name)`). Assert `"Day: 1"` in the overlay test. Consider driving these e2e timings from `RunManager.tick` or a fixed-step harness.

### IN-07: `DebugOverlay` ships in release exports and its section providers are called unguarded

**File:** `ui/overlay/debug_overlay.gd:1-6,46-55` and `ui/overlay/debug_overlay_model.gd:30-33`
**Issue:** The overlay is documented as accepted-risk (T-01-15), but F3 is reachable in the shipped build. `provider.call()` in `collect()` is unguarded, so an invalid or freed `Callable` registered by a later phase crashes the overlay every 0.25 s while it is visible.
**Fix:** Gate the toggle with `OS.is_debug_build()` or a feature flag, and check `provider.is_valid()` before calling.

### IN-08: CI runs every push twice on PR branches, and `cancel-in-progress` applies to `main`

**File:** `.github/workflows/ci.yml:6-17`
**Issue:** `push: branches: ["**"]` plus `pull_request` runs the whole matrix twice per commit on a PR branch. `concurrency` with `cancel-in-progress: true` can also cancel an in-flight `main` run, including the export job that produces the release artifact.
**Fix:** Restrict `push` to `main` (PRs are covered by `pull_request`), and set `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
