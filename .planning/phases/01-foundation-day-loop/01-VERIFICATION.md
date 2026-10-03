---
phase: 01-foundation-day-loop
verified: 2026-10-03T10:45:31Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/01-foundation-day-loop/01-01-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-01-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-02-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-02-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-03-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-03-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-04-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-04-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-05-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-05-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-06-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-06-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-07-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-07-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-08-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-08-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-09-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-09-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-10-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-10-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-11-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-11-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-12-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-12-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-13-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-13-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-14-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-14-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-15-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-15-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-16-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-16-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-17-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-17-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-18-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-18-SUMMARY.md"
  - "ASSETS.md"
  - "assets/attribution.json"
  - "data/tuning/loop_tuning.tres"
  - "export_presets.cfg"
  - "input/build_hold_controller.gd"
  - "input/start_night_hold_controller.gd"
  - "presentation/buildings/building_views.gd"
  - "presentation/camera/camera_rig.gd"
  - "presentation/king/king_model.tscn"
  - "presentation/map/map_root.gd"
  - "presentation/map/prototype_map.tscn"
  - "presentation/vfx/coin_drip_vfx.gd"
  - "presentation/vfx/xray_silhouette.gd"
  - "project.godot"
  - "simulation/buildings/building_system.gd"
  - "simulation/commands/command_processor.gd"
  - "simulation/defs/loop_tuning.gd"
  - "simulation/defs/map_config.gd"
  - "simulation/run/run_manager.gd"
  - "tests/e2e/e2e_support.gd"
  - "tests/e2e/test_build_hold_long.gd"
  - "tests/e2e/test_build_hold_timing.gd"
  - "tests/e2e/test_coin_drip_burst.gd"
  - "tests/e2e/test_hold_pacing_sandbox.gd"
  - "tests/unit/test_coin_drip_flight.gd"
  - "tests/unit/test_e2e_support_tuning.gd"
  - "tests/unit/test_loop_tuning_contract.gd"
  - "tests/unit/test_loop_tuning_curve.gd"
  - "tools/lint.sh"
  - "tools/sandbox/hold_pacing_sandbox.gd"
  - "tools/sandbox/hold_pacing_sandbox.tscn"
  - "tools/screenshot.sh"
  - "tools/screenshot/shot_scenarios.gd"
  - "tools/test.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay_model.gd"
  - "ui/world/spot_label.gd"
covered_digest: "v2:sha256:0d7f3884675c4aef24a24685bcfef7dfad7122105bddf9743820fd93945a4e76"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "Human item of the previous report (owner feel re-check of the uncapped hold, plan 01-18 human-check, UAT G-01-59) answered: 01-UAT.md test 60 is recorded pass, with the owner's delegation quote and the scripted real-window numbers"
    - "Open review findings WR-01, WR-02, IN-01, IN-02, IN-03 of the previous review are fixed (commits c3d2411, bf554d0, 40710e3, 3a6825b, afc393b) and each has a failing-when-reverted test"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (full DEV-03 wording)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5: 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3: 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "CI has not run the Phase 1 gap-closure or review-fix code: origin/gsd/phase-01-foundation-day-loop is at 7775fab (last green run 36980680883) and HEAD is 59 commits ahead"
    category: other
    reason: "git diff --stat 7775fab HEAD -- .github export_presets.cfg ASSETS.md assets is empty, so the workflow, export preset and asset records are unchanged; ci.yml runs lint, test, export and screenshots with no hard-coded counts. The same lint, the 367-test suite and 7 of 7 screenshots ran green locally in this pass. Not a must-have failure; a push will confirm. Not pushed by this verification."
    evidence_status: "git rev-list --count origin/gsd/phase-01-foundation-day-loop..HEAD = 59; gh run list; git diff --stat"
  - finding: "The owner did not personally feel the uncapped hold in the sandbox; UAT test 60 is recorded pass on the owner's delegation to a scripted real-window run"
    category: other
    reason: "The owner wrote 'im not gonna check all that, check it yourself and if its okay (which it seems to be okay!) then lets move on'. I count that as the owner's own accepted resolution of the plan 01-18 human-check, so no human item is outstanding. Note the open question the check asked ('0.05 s' as gap between coins, as built, or as flight time) was not answered explicitly; the one-line lever is CoinDripVfx.MIN_FLIGHT_SECONDS if the owner ever wants a shorter flight."
    evidence_status: "01-UAT.md test 60 note and self_check read in full"
  - finding: "Four open info findings in 01-REVIEW.md (IN-01 class doc says BuildIntent is sent when the last coin lands, IN-02 delayed coins aim at event-time positions, IN-03 sandbox test compares tuning to the cached shipped resource, IN-04 sandbox fails silently with a push_error)"
    category: other
    reason: "Review of 2026-10-03T10:37:00Z: 0 critical, 0 warning, 4 info. All are comment accuracy, cosmetic or test-robustness items; the reviewer found no correctness, security or data-loss defect and neither did I. Recorded open in 01-REVIEW-DISPOSITION.md."
    evidence_status: "01-REVIEW.md read in full; 01-REVIEW-DISPOSITION.md"
  - finding: "UAT test 11 (start-night key label on a non-QWERTY layout) is skipped as a deferred follow-up"
    category: other
    reason: "Owner skipped it on 2026-10-02 (no non-QWERTY layout at hand); the fake-layout resolver seam is unit-tested. It is not a ROADMAP success criterion."
    evidence_status: "01-UAT.md test 11"
  - finding: "Horse licence risk is owner-accepted; the unmodified horse GLB is public in the repo (Git LFS) and ships in the export"
    category: other
    reason: "Recorded in ASSETS.md and License.txt, accepted by the owner on 2026-10-01 (UAT test 15). ASSETS.md, assets/ and export_presets.cfg are unchanged against 7775fab."
    evidence_status: "01-UAT.md test 15; git diff --stat"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-03T10:45:31Z
**Status:** passed
**Re-verification:** Yes. The previous report (2026-10-02T20:57:44Z, status human_needed) is stale because covered files changed. Every verdict below was regenerated from the current tree (HEAD 8872ebc); none was copied.

## Change audit since the previous report

- `git diff --stat 502e364 HEAD` restricted to non-`.planning` paths touches exactly 7 files: `presentation/vfx/coin_drip_vfx.gd` (+4 lines), `tools/sandbox/hold_pacing_sandbox.gd`, `tests/e2e/e2e_support.gd`, `tests/e2e/test_coin_drip_burst.gd`, `tests/e2e/test_hold_pacing_sandbox.gd`, `tests/unit/test_coin_drip_flight.gd`, `tests/unit/test_e2e_support_tuning.gd`. I read the diff. The only production-runtime change is in `CoinDripVfx._fly`: a coin with a launch delay is set `visible = false`, and a `tween_callback(coin.set_visible.bind(true))` shows it when its delay ends. Timing, counts and the build/refund simulation path are untouched (`input/build_hold_controller.gd`, `simulation/**`, `data/tuning/loop_tuning.tres` are not in the diff).
- The sandbox change sizes starting gold as `total * house_plot_count(config) + GOLD_MARGIN` (review IN-03 of the previous cycle); `E2eSupport.flat_drip_tuning` gained an optional `base: LoopTuning` parameter (WR-01); the rest is test tightening.
- 01-UAT.md is `status: complete`: 60 tests, 59 passed, 0 issues, 1 skipped (test 11, deferred). All four gaps (G-01-3, G-01-4, G-01-58, G-01-59) are `resolved`.
- The only working-tree modification is `.planning/config.json` (pre-existing, left alone).

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED | No king, camera, input-map or spot-label production file is in the 502e364..HEAD diff. King ride, camera zoom, input map, X-Ray and spot-label suites are inside the 367/367 run (0 failures). `king_behind_keep.png` and `spot_label.png` regenerated by `tools/screenshot.sh` this pass. UAT tests 1, 2, 3 (re-checks 56, 57), 5, 6 are `pass`. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier's cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `input/build_hold_controller.gd` `_advance_hold` read this pass: release / out-of-range / `is_build_allowed()` is checked before any coin, then `_hold_elapsed += delta` and `while _coins_paid < _cost and _hold_elapsed >= coin_due_seconds(_coins_paid + 1)` pays each coin at its own due time; one `commands.submit(BuildIntent)` in `_finish_hold`; `_cancel_hold` refunds (D-06). `_try_start_hold` runs `validate_build` first (unknown spot, unaffordable, max tier and not-day all emit `hold_denied`). `data/tuning/loop_tuning.tres` carries 0.25 / 2 / 0.9 / 0.05 / cap 0.0. Behavior-dependent invariants have passing named tests this pass: `test_build_hold_long` 6/6 (every coin drips at its due time, one debit, long-frame completion, refund on release), plus `test_build_hold_refund` and `test_build_denied` in the full run. The pace feel was judged in UAT test 60 (see Human Verification). |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd`, `hud.gd`, `dawn_payout_vfx.gd` and the economy code are unchanged since the previous report. Dawn income, payout VFX, HUD and gold-carryover suites (`test_dawn_income`, `test_dawn_payout`, `test_dawn_payout_hardening`, `test_loop_gold_carryover`) are inside the 367/367 run; `dawn_payout.png` regenerated. UAT tests 9 and 10 verified in a real window. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI has not yet run the newest commits, see Advisory) | This pass: `bash tools/lint.sh` exit 0 ("84 files would be left unchanged", "no problems found"); `bash tools/test.sh` run once, exit 0, 46 scripts, 367/367, 3122 asserts, 134 s; `bash tools/screenshot.sh` exit 0, 7 screenshots written. `.github/workflows/ci.yml` triggers on every push (no path filters), jobs `lint`, `test`, `export` (`needs: [lint, test]`), `screenshots` (`needs: [test]`), unchanged against the last green run (36980680883 on 7775fab). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `test_debug_overlay_toggle`, overlay model/provider suites and `test_attribution_log` pass in the full run; `overlay_on.png` regenerated; UAT test 8 verified in a real window. `ASSETS.md`, `assets/` and `export_presets.cfg` are byte-unchanged against 7775fab. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

### Review-fix must-haves (cycle since the previous report)

| Item | Status | Evidence |
|------|--------|----------|
| IN-02 hidden-while-waiting coins: a delayed burst or refund coin is not drawn as a stack and is shown when it launches | VERIFIED | `coin_drip_vfx.gd` lines 102-111 read (`coin.visible = false` + `tween_callback(coin.set_visible.bind(true))`, only when `delay > 0.0`). `test_coin_drip_burst` 8/8 pass in the JUnit XML (3 guard tests added by 6975168). Orchestrator mutation probes: deleting the hide fails 2/8, deleting the show callback fails 1/8 (recorded in 01-VALIDATION.md). Orchestrator real-window run: a 13-coin refund drew 12 coins, 11 started hidden and became visible one at a time about every 0.03 s, no stack, all gold returned. I did not re-run the window run or the mutations. |
| WR-01 capped-base helper test, WR-02 break-even test scope, IN-01 literal ceiling pin, IN-03 sandbox gold by plot count | VERIFIED | `test_e2e_support_tuning` 5/5, `test_coin_drip_flight` 10/10, `test_hold_pacing_sandbox` 3/3 pass. WR-01 and IN-03 source diffs read (`flat_drip_tuning(seconds, base)`, `house_plot_count`). Orchestrator revert-probes (01-VALIDATION.md "re-audit after review-fix pass 26") show each fix fails at least one test when reverted; not re-run by me. |

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `input/build_hold_controller.gd` | Due-time drip, release/range/day check before any coin | VERIFIED | 146 lines, read; wired as `$BuildHold` in the prototype map |
| `simulation/defs/loop_tuning.gd` + `data/tuning/loop_tuning.tres` | Curve, floor, dormant cap | VERIFIED | Script defaults equal data (contract test); used by controller, VFX, sandbox, screenshots |
| `presentation/vfx/coin_drip_vfx.gd` | Curve-following stream, staggered groups, refund fly-back, hidden-while-waiting | VERIFIED | Read; connects `hold_progress` / `hold_cancelled` |
| `simulation/buildings/building_system.gd`, `simulation/run/run_manager.gd`, `simulation/commands/command_processor.gd` | Rules, day/night/dawn, validation | VERIFIED | Present and substantive; suites pass |
| `ui/hud/hud.gd`, `ui/overlay/debug_overlay*.gd`, `ui/world/spot_label.gd` | HUD gold, overlay, spot label | VERIFIED | Present and substantive; suites pass |
| `tools/sandbox/hold_pacing_sandbox.{gd,tscn}` | Real-window sandbox, excluded from export | VERIFIED | Read diff; test loads it; `exclude_filter` keeps `tools/*` out |
| `tools/{lint,test,screenshot}.sh`, `.github/workflows/ci.yml`, `export_presets.cfg` | DEV-01/02/04 entry points | VERIFIED | Ran lint, test, screenshot this pass; CI file read |
| `ASSETS.md`, `assets/attribution.json` | Attribution log | VERIFIED | Attribution test passes |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `build_hold_controller.gd` | `loop_tuning.gd` | `_ctx.tuning.coin_due_seconds(_coins_paid + 1)` | WIRED | line 107 |
| `build_hold_controller.gd` | `command_processor.gd` | single `commands.submit(BuildIntent)` in `_finish_hold` | WIRED | read; one `gold_changed` in long-hold tests |
| `coin_drip_vfx.gd` | `build_hold_controller.gd` | `hold_progress` and `hold_cancelled` handlers | WIRED | `_on_hold_progress`, `_on_hold_cancelled` read |
| `hold_pacing_sandbox.gd` | prototype map | deep-copied `MapConfig` | WIRED | `test_hold_pacing_sandbox` loads it |
| `ci.yml` | `tools/{lint,test,screenshot,export}.sh` | job steps | WIRED | read |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Build hold | due time per coin | `loop_tuning.tres` via `ctx.tuning` | Yes | FLOWING |
| Coin VFX | coins_paid, cost, interval | `hold_progress` signal, `ctx.tuning` | Yes | FLOWING |
| Sandbox gold and costs | repriced tiers, `total * house_plot_count + margin` | deep copy of the shipped map | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Lint | `bash tools/lint.sh` | exit 0, 84 files unchanged, no problems | PASS |
| Full suite (run once) | `bash tools/test.sh` | exit 0, 46 scripts, 367/367, 3122 asserts, 134 s | PASS |
| Hold-pacing suites in JUnit XML | parse `build/test-results/gut-junit.xml` | burst 8, flight 10, sandbox 3, e2e-support 5, long-hold 6; 0 failures, 0 skipped | PASS |
| Scripted screenshots | `bash tools/screenshot.sh` (real window) | exit 0, 7 screenshots written | PASS |
| Debt markers | grep TBD/FIXME/XXX over changed and production dirs | no matches | PASS |
| No stray Godot process | `tasklist` filter godot | none running | PASS |

### Probe Execution

Step 7c: SKIPPED. No phase plan declares a `probe-*.sh`; entry points are `tools/lint.sh`, `tools/test.sh`, `tools/screenshot.sh`, run above.

### Requirements Coverage

The union of the `requirements:` fields of plans 01-01 to 01-18 is exactly the 15 IDs given for this phase; every one appears in REQUIREMENTS.md as Phase 1 / Complete (`[x]`). REQUIREMENTS.md maps no other ID to Phase 1 (BLDG-05 is Phase 5, Pending), so there is no orphaned requirement.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| KING-01 | 01-02, 01-04 | Move the mounted king with WASD / left stick, sprint | SATISFIED | king ride and input-map tests; UAT 1, 2 |
| KING-02 | 01-04, 01-11, 01-12 | Fixed isometric-style follow camera | SATISFIED | camera, zoom and X-Ray suites; UAT 3, 56, 57 |
| BLDG-01 | 01-02, 01-05 | Fixed build spots; buildings only on spots | SATISFIED | `validate_build` unknown-spot tests |
| BLDG-02 | 01-05, 01-06 | Near a spot by day, see what can be built and its cost | SATISFIED | spot label model and e2e suites; `spot_label.png` |
| BLDG-03 | 01-02, 01-06, 01-13 to 01-18 | Build by holding the action key, with progress indicator, if affordable | SATISFIED | hold controller read, long-hold/timing/refund/burst suites; UAT 4, 58-60 |
| BLDG-04 | 01-05, 01-13 to 01-15, 01-17, 01-18 | Upgrade the same way, seeing next-tier cost and effect | SATISFIED | tier and upgrade suites, label model |
| BLDG-06 | 01-09 | Build and upgrade only by day | SATISFIED | not-day validation tests; `_advance_hold` cancels when `is_build_allowed()` turns false |
| ECON-01 | 01-02, 01-09 | Gold is the only currency; HUD shows it | SATISFIED | HUD and economy tests |
| ECON-02 | 01-09, 01-10 | House pays flat income each dawn rising with tier | SATISFIED | dawn income tests; UAT 10 |
| ECON-07 | 01-09 | Unspent gold carries over | SATISFIED | carryover tests |
| ART-02 | 01-07 | Third-party assets in an attribution log | SATISFIED | `ASSETS.md`, `assets/attribution.json`, attribution test |
| DEV-01 | 01-01, 01-02, 01-16 | Headless simulation and GUT tests from the CLI | SATISFIED | 367/367 headless this pass |
| DEV-02 | 01-01, 01-03, 01-10 | CI lint and tests on every push, Windows export | SATISFIED | `ci.yml` read; last pushed run green; newest commits unpushed (Advisory) |
| DEV-03 | 01-08 | Toggleable debug overlay | SATISFIED (wave state and pathing deferred to Phase 2) | overlay tests, `overlay_on.png`, UAT 8 |
| DEV-04 | 01-10, 01-12, 01-15 | Automated screenshot capture of scripted scenes | SATISFIED | 7 screenshots this pass |

### Anti-Patterns Found

TBD/FIXME/XXX grep over `input`, `simulation`, `presentation`, `ui`, `tools` and the changed test files: no matches, so no unreferenced debt marker. No stub: controller, VFX, sandbox and tests are substantive and wired. The four open review findings are all info-level (see Advisory).

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `presentation/vfx/coin_drip_vfx.gd` | 11 | header says BuildIntent is sent when the last coin lands, it is sent when it is paid (review IN-01, OPEN) | Info | misleading comment only |
| `presentation/vfx/coin_drip_vfx.gd` | 134-147 | delayed coins aim at event-time positions (review IN-02, OPEN) | Info | cosmetic, at most 0.3 s of drift |
| `tests/e2e/test_hold_pacing_sandbox.gd` | 78-87 | tuning compared to the cached resource, so in-place mutation is undetected (review IN-03, OPEN) | Info | weak guard only |
| `tools/sandbox/hold_pacing_sandbox.gd` | 23-25 | silent empty scene when the map has no House (review IN-04, OPEN) | Info | dev tool, excluded from export |

### Human Verification Required

None outstanding. The one item carried from the previous report (plan 01-18's `<human-check>`, the owner's feel re-check of the uncapped, accelerating hold) is recorded in `01-UAT.md` test 60 as `result: pass`. I weighed that record: the owner explicitly delegated the check ("check it yourself and if its okay (which it seems to be okay!) then lets move on") and accepted the scripted real-window result (normal game House I/II/III 0.51/0.73/1.11 s, tower 0.93/1.28 s, first coin 0.25 s; sandbox 15/30/50 coins in 2.18/2.94/3.94 s; at most one coin paid per frame; at most 3 in the air; a release at 3.50 s refunded all 41 paid coins with 12 drawn, gold and tier unchanged). Those numbers match the curve verified in code and in `test_build_hold_long` / `test_loop_tuning_curve`. The UAT file has no remaining `pending` tests. This is an accepted owner decision rather than the owner's own eyes on the pace, which is recorded as an Advisory; I did not treat it as an open human item because the human-check asked for the owner's sign-off and the owner gave it.

### Gaps Summary

No gaps. All five roadmap success criteria are verified against the current tree, all 15 requirement IDs are accounted for, the full suite (367/367), lint (84 files) and the 7 scripted screenshots pass, and the review-fix cycle after the previous report changed one four-line production VFX behavior that is covered by tests and a real-window run. Remaining risks are advisory only: 59 commits are not pushed, so CI has not run them; four open info-level review findings; and the non-QWERTY label check (UAT test 11) is a deferred owner follow-up.

---

_Verified: 2026-10-03T10:45:31Z_
_Verifier: Claude (gsd-verifier)_
