---
phase: 01-foundation-day-loop
fixed_at: 2026-09-29T00:00:00Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 8
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-29
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (0 critical, 9 warning; Info items IN-01 to IN-08 out of scope for this run)
- Fixed: 8
- Skipped: 1

**Verification environment:** every fix was edited and verified in the main checkout on branch `gsd/phase-01-foundation-day-loop`. No worktree or temp branch was created, because the orchestrator forbade creating branches and a hand-rolled worktree has no `.tools/` or `.godot/` to run the gates. GDScript and scene fixes were verified with `bash tools/test.sh` (headless GUT 9.7.1) and `bash tools/lint.sh` in the main checkout. Final result: 194/194 tests passing (baseline 190; 4 new tests), lint clean. The tooling and CI fixes (WR-03/04/05/08/09) were verified offline only, as listed per finding below. No network downloads were made and nothing was pushed.

## Fixed Issues

### WR-01: `MapRoot` binds every `run_bound` node in the whole tree, so a second map cross-binds and duplicates the first map's views

**Files modified:** `presentation/map/map_root.gd`, `ui/hud/hud.gd` (comment only), `tests/e2e/test_map_binding.gd`, `tests/e2e/test_map_binding.gd.uid`
**Commit:** 263f35c
**Applied fix:** `MapRoot._ready` now iterates `get_nodes_in_group(&"run_bound")` and binds only nodes that are descendants of this map (`is_ancestor_of`). The HUD's now-stale comment about `call_group` was reworded; its `is_connected` guard stays as a defensive measure. New e2e test `test_map_binding.gd` spawns a second and third map. It asserts the first map's `BuildingViews` gains no extra children and its HUD keeps showing its own gold. Both tests fail against the old code and pass with the fix.

### WR-02: Dawn payout readout lag is unbounded and the HUD gold label can go negative

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `ui/hud/hud.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** d246214
**Applied fix:** Added `DawnPayoutVfx.MAX_COINS = 12`. While the payout fits under the cap it is still one coin per gold, so existing behaviour and tests are unchanged. Above the cap each spot gets its proportional share of coins (at least one), and the spot's gold is split across its coins so the shares sum exactly to the spot amount. `coin_landed` now carries the gold that coin holds (`coin_landed(amount: int)`), and `Hud._on_coin_landed` subtracts that amount, so the pending value still reaches exactly 0. `Hud._refresh` clamps the label at 0. New test `test_a_huge_payout_is_capped_in_coins_and_the_readout_never_goes_negative` emits a 203-gold payout and checks the clamp at "Gold: 0", the coin cap, and that the HUD settles on the ledger.

### WR-03: `tools/bootstrap.py --all` always exits 1 on a normal checkout and never installs the lint tools

**Files modified:** `tools/bootstrap.py`
**Commit:** c755f36
**Applied fix:** `install_gut` now skips (returns `""`) when `addons/gut` exists, `--force` is absent and `plugin.cfg` reports the pinned version. It still exits 1 with a clear message if the existing addon reports a different version. Offline check: with the network function stubbed to raise, `main(["--all", "--yes"])` returns 0 and calls godot, templates and lint tools (the committed GUT is skipped).

### WR-04: `download_asset` fails permanently on Windows once a target file already exists, and has no timeout

**Files modified:** `tools/bootstrap.py`
**Commit:** 67d418a
**Applied fix:** `part_path.rename` became `part_path.replace`, and `urlopen` now gets `timeout=DOWNLOAD_TIMEOUT_S` (60). `fetch_official_sums` deletes `SHA512-SUMS.txt` after parsing. Offline check with `file://` URLs and a temp downloads dir: a second download over an existing target succeeds, and `fetch_official_sums` runs twice in a row.

### WR-05: GUT is downloaded from a mutable tag and never checked against a pin, and a failed check destroys the committed addon

**Files modified:** `tools/bootstrap.py`
**Commit:** 276a403
**Applied fix:** Added `GUT_ZIP_SHA256` (the value recorded in `assets/attribution.json` and 01-01-SUMMARY.md). The zip's SHA256 is compared before anything is extracted, and a mismatch deletes the zip and exits 1. Extraction and the `plugin.cfg` version check now happen in a staging directory under `.tools/downloads/`. `swap_directory` then replaces `addons/gut` and restores the original if the swap fails. A bad archive or wrong version can no longer damage the committed addon. Offline check with fake zips, a patched `ROOT` and a stubbed download, all against a temp tree so the real `addons/gut` was never touched:
- SHA mismatch: exit 1, addon untouched, bad zip deleted.
- Wrong `plugin.cfg` version: exit 1, original addon preserved, staging removed.
- Good zip: swapped, no leftovers.
- Fresh install with no existing addon: works.

The consent guard (`--godot` without `--yes`) still exits 2, and `--dry-run` works.

### WR-07: Simulation clock takes raw frame `delta` with no clamp

**Files modified:** `presentation/map/map_root.gd`, `tests/e2e/test_walking_skeleton.gd`
**Commit:** 9678ec7
**Applied fix:** Added `MapRoot.MAX_SIM_STEP = 0.25`, and `_process` now calls `tick(minf(delta, MAX_SIM_STEP))`. The `RunManager` huge-tick unit tests are unchanged. New e2e test `test_a_stalled_frame_advances_the_simulation_by_at_most_the_clamp` calls `_process(100.0)` during night and asserts elapsed advanced by exactly 0.25 and the night did not end.
**Status note:** fixed: requires human verification (logic change to the sim clock; a tuning value of 0.25 s was chosen per the reviewer's suggestion).

### WR-08: `prepush_check.sh` credential regex misses common token formats

**Files modified:** `tools/prepush_check.sh`
**Commit:** 6755379
**Applied fix:** The pattern now uses `gh[pousr]_` and adds Stripe `sk_`/`rk_` live/test keys, Google `AIza` keys, npm tokens and Slack webhook URLs. When `gitleaks` is installed the script also runs it and fails on findings. Otherwise it prints a note that LFS and binary contents were not scanned. Checks: `bash -n` passes. The regex has zero matches against the script itself. Synthetic samples of each new format, built by string concatenation so no token-shaped text was committed, all match. Plain prose does not match. The full script still ends `PREPUSH CHECK PASSED`.

### WR-09: CI actions are pinned to mutable major tags, and the LFS cache key omits pointer verification

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 767e570
**Applied fix:** All four actions are pinned to full commit SHAs, each with a trailing release comment. SHAs were resolved read-only via `gh api repos/actions/<name>/git/ref/tags/<tag>` and matched to exact patch tags:
- `actions/checkout` 3d3c42e5aac5ba805825da76410c181273ba90b1 (v7.0.1)
- `actions/setup-python` 5fda3b95a4ea91299a34e894583c3862153e4b97 (v7.0.0)
- `actions/cache` 55cc8345863c7cc4c66a329aec7e433d2d1c52a9 (v6.1.0)
- `actions/upload-artifact` 043fb46d1a93c77aae656e7c1c64a875d1fc6a0a (v7.0.1)

A header comment explains the pinning. The workflow parses with PyYAML. Not done: the optional re-hash of the cached Godot binary, because the archive is not kept after extraction. The cache key is already derived from the committed SHA512 pin. CI validation happens when the owner pushes.

## Skipped Issues

### WR-06: License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint

**File:** `assets/attribution.json:83-99` and `tests/unit/test_attribution_log.gd:11,157`
**Reason:** Owner decision. The owner knowingly approved the 2021 CC0 Poly Pizza copy of the Quaternius horse; keeping or replacing it is tracked as UAT item 7 in 01-UAT.md. The asset and its declared licence were left unchanged, as instructed by the orchestrator.
**Original issue:** The `quaternius-horse` entry declares `CC0-1.0` and `ships_in_build: true`, but its own notes say quaternius.com now publishes the Quaternius Asset License v1.0, which forbids standalone redistribution. The allow-list test passes only because the manifest author typed `CC0-1.0`, so it cannot detect the conflict it was written to prevent.

---

_Fixed: 2026-09-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
