---
phase: 01-foundation-day-loop
verified: 2026-10-02T13:24:05Z
status: human_needed
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
  - "tests/e2e/test_build_hold_cap.gd"
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
covered_digest: "v2:sha256:5291a5babd2ecd61a0813b5c98ef8d6c862d32d804553d6e1b87078754a34a51"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "G-01-58 (UAT test 58, minor): build hold had no upper bound and a constant pace; now 0.25 s first coin, accelerating, capped at 3 s with the remainder paid at once (plans 01-14, 01-15, 01-16; D-05 amended)"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5: 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3: 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "Gap-plan code from plans 01-14 to 01-16 is not pushed, so CI has not run the 358-test suite or the curve-timed build_in_progress shot"
    category: other
    reason: "origin/gsd/phase-01-foundation-day-loop is at 7775fab (CI run 36980680883, success). HEAD 4d163fb is 23 commits ahead. `git diff --stat 7775fab HEAD -- .github` is empty, so the workflow is unchanged; ci.yml runs `bash tools/screenshot.sh` with no hard-coded count. The same suite and the 7 screenshots ran green locally in this pass. Not a must-have failure; a push will confirm."
    evidence_status: "git ls-remote origin, git rev-list --count 7775fab..HEAD = 23, gh run list, git diff --stat on .github"
  - finding: "Open review findings WR-01 and WR-02 (current 01-REVIEW.md, commit cd4e28e), IN-01 to IN-04, all OPEN"
    category: other
    reason: "These are NEW findings that reuse old IDs. WR-01: test_build_hold_cap (release-before-cap test) and test_coin_drip_burst (group-size test) assume no single frame lasts 0.25-0.3 s, so a stall on a loaded CI runner could fail them (a test fault, not a game fault). WR-02: max_build_hold_seconds <= 0 means 'no cap', so a mistyped or lost shipped value would silently reintroduce G-01-58; the shipped cap is guarded by test_shipped_cap_is_set_and_at_most_the_owner_maximum, but decay, floor and steady-coin fields have no in-range contract assertion. IN-01 to IN-04: hard-coded pacing numbers in comments, a tautological test, delayed burst/refund coins visible and stacked before launch, duplicated test scaffolding. None makes a truth false; the reviewer found no production defect. The previous cycle's WR-01 (hold-clock timing) and IN-02 (derived flight ceiling) are confirmed closed in the code (test_build_hold_timing stamps coins with get_hold_elapsed(); MAX_FLIGHT_SECONDS is derived from LoopTuning.COIN_DRIP_INTERVAL_MAX_S)."
    evidence_status: "01-REVIEW.md read in full; the cited code read; 358/358 pass"
  - finding: "The spot label's coin-icon row is very wide at the synthetic 15/30/50-coin sandbox costs"
    category: other
    reason: "No shipped building costs more than 6 coins, so the shipped game is unaffected. 01-15's own human-check says label layout for expensive buildings belongs to the later phase that adds them; it is not part of the feel check."
    evidence_status: "01-15-PLAN.md Task 2 human-check text"
  - finding: "Horse licence risk is owner-accepted; the unmodified horse GLB is public in the repo (Git LFS) and ships in the export"
    category: other
    reason: "Recorded in ASSETS.md and License.txt, accepted by the owner on 2026-10-01 (UAT test 15). Unchanged since the previous report: `git diff --stat 7ae173b HEAD -- ASSETS.md assets export_presets.cfg .github` is empty."
    evidence_status: "01-UAT.md test 15; git diff --stat"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
human_verification:
  - test: "Feel check of the accelerating, capped build hold (plan 01-15 Task 2 human-check, UAT G-01-58 re-check). (1) Normal game: from Git Bash in the repo root run `bash tools/godot.sh --path .`, then hold Space or gamepad A at a House plot for House I, II and III, and at a tower plot. (2) Sandbox: run `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn`; House plots cost 15, 30 and 50 coins per tier and you start with enough gold for all three; hold at one House plot three times, and once release just before 3 s."
    expected: "(1) The first coin leaves after 0.25 s and the coins then come visibly faster; House I takes about 0.5 s, House III about 1.1 s, a tower about 0.9 s; the stream still reads as one coin at a time. (2) The 15-coin build takes about 2.2 s with a clearly accelerating stream; the 30-coin build stops at 3.0 s with its last 6 coins rushing in at once; the 50-coin build also stops at 3.0 s with about half its coins rushed in; releasing just before 3 s flies the coins back and builds nothing. Judge whether the 0.25 s start, the acceleration and the 3 s rush feel right."
    why_human: "Pace, acceleration and rush are feel and look judgments (UAT test 58 was a feel complaint). Already proven by scripts: the curve numbers (independently recomputed in this pass: 0.5, 0.725, 0.9275, 1.1098, 1.2738, 1.7814, 2.2055, then 3.0 for 30 and 50 coins), the cap frame paying every remaining coin with one BuildIntent and one debit, the full refund just before the cap, the staggered 12-coin-capped rush, and the sandbox loading (test_build_hold_cap 6, test_loop_tuning_curve 14, test_build_hold_timing 4, test_coin_drip_flight 9, test_coin_drip_burst 4, test_hold_pacing_sandbox 3)."
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-02T13:24:05Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is the owner's feel judgment of the accelerating, capped hold)
**Re-verification:** Yes, after gap closure for UAT G-01-58. The earlier report (2026-10-02T07:48:00Z) was stale because covered files changed. Every verdict below was regenerated from the current tree at HEAD 4d163fb; none was copied.

## Change audit since the previous report

- UAT (`01-UAT.md`, 58 tests). The three re-checks added after plans 01-11 to 01-13 were answered by the owner: tests 56 (camera framing and zoom) and 57 (king silhouette) are `pass`, so the two human items the previous report carried for them are closed. Test 58 (build hold length) is `issue`, recorded as gap G-01-58 with root cause "a linear fixed-interval drip with no acceleration and no cap".
- Plans 01-14, 01-15 and 01-16 (`gap_closure: true`, `gap_ids: [G-01-58]`) all have SUMMARYs. 01-CONTEXT.md D-05 carries the owner's amendment (first coin 0.25 s, accelerating, 3 s cap, remainder paid at once; D-06 unchanged).
- The only working-tree modification is `.planning/config.json`.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED | Unchanged since the last report except through owner UAT: tests 1, 2, 3 (re-check 56), 5, 6 and 57 are `pass` in `01-UAT.md`. King ride, camera zoom, input-map, X-Ray and spot-label suites pass in the 358/358 run. `king_behind_keep.png` regenerated. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED (feel: human) | `input/build_hold_controller.gd` `_advance_hold`: the release, range and `is_build_allowed()` checks run before any coin, then `_hold_elapsed += delta` and `while _coins_paid < _cost and _hold_elapsed >= _ctx.tuning.coin_due_seconds(_coins_paid + 1)` pays each coin at its due time; the single `commands.submit(BuildIntent)` goes out in `_finish_hold`. `simulation/defs/loop_tuning.gd` `coin_due_seconds` returns the cap as soon as the running sum reaches `max_build_hold_seconds`, so every coin due at or past the cap has due time == cap and is paid in the cap frame (no special branch). I recomputed the curve independently in Python (first 2 coins 0.25 s, x0.9 after, floor 0.08, cap 3.0): cost 2 -> 0.5 s, 3 -> 0.725, 4 -> 0.9275, 5 -> 1.1098, 6 -> 1.2738, 10 -> 1.7814, 15 -> 2.2055, 30 and 50 -> 3.0; it matches the plan table and the helper. `data/tuning/loop_tuning.tres` carries all five fields (0.25, 2, 0.9, 0.08, 3.0), equal to the script defaults (contract test). Shipped tiers are 2/3/5 (House) and 4/6 (tower), so shipped holds are 0.5 s to 1.27 s and the cap only binds for the future expensive buildings the owner mentioned; the sandbox exercises the cap. Behavior-dependent invariants (cancel/refund, cap fast-forward, one debit) have named passing tests, see Spot-Checks. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | Untouched by the gap plans (`git diff` since 7775fab touches no `run_manager`, `economy` or HUD file). UAT tests 9 and 10 verified in a real window; dawn income, payout VFX, HUD lag release and carryover suites pass; `dawn_payout.png` regenerated this pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (new code not yet CI-run, see Advisory) | This pass: `bash tools/lint.sh` exit 0 (84 files unchanged, no problems); `bash tools/test.sh` run once, exit 0, 46 scripts, 358/358, 2796 asserts, 144 s; `bash tools/screenshot.sh` exit 0, `Saved 7 of 7 screenshots`. CI: `ci.yml` unchanged against origin, triggers on every push, last run on 7775fab green (run 36980680883). Plans 01-14 to 01-16 are 23 commits beyond that run. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | Overlay and attribution suites pass; UAT test 8 verified in a real window; `overlay_on.png` regenerated. The gap plans added no third-party asset and the licence and asset records are unchanged. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

### Gap-plan must-haves (plans 01-14, 01-15, 01-16, G-01-58)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| Holding pays the first two coins 0.25 s apart, later coins faster (x0.9, floor 0.08 s): House I 0.5 s, House II 0.725 s, House III 1.11 s, Tower I 0.93 s, Tower II 1.27 s | VERIFIED (feel: human) | Python recomputation above; `test_loop_tuning_curve` (14 tests, `test_hold_seconds_match_the_owner_table`) and `test_build_hold_timing` (4) pass |
| No hold lasts longer than 3.0 s; at the cap every remaining coin is paid in that frame, one BuildIntent, one full-cost debit | VERIFIED | `coin_due_seconds` cap clamp read; `test_build_hold_cap` (6) read: asserts 30 `hold_progress` signals numbered 1..30 in order, one `hold_completed`, no `hold_cancelled`, exactly one `gold_changed` of the full cost, last coin stamped at the cap and within one frame of it, every coin due at the cap stamped on the same frame, more than one coin fast-forwarded. All pass. |
| Release or leaving range at any moment before the cap, including just before it, refunds every dripped coin and builds nothing (D-06) | VERIFIED | `_advance_hold` runs the release/range/day check ahead of the drip; `test_releasing_just_before_the_cap_refunds_everything` passes (hold_cancelled with the paid count, no hold_completed, no gold_changed, tier 0, gold unchanged); `test_build_hold_refund` (6) passes. See Advisory WR-01 for the test's frame-length assumption. |
| A pricier tier never takes less time than a cheaper one; cheapest shipped hold at least 0.5 s | VERIFIED | `test_loop_tuning_contract` (6) pins it from the shipped data; recomputation gives House I exactly 0.5 s |
| Hold timing tests measure the hold's own accumulated frame delta, not wall-clock time; every duration read through `LoopTuning.build_hold_seconds` | VERIFIED | `get_hold_elapsed()` exists in the controller; `test_build_hold_timing` stamps with it; grep finds no `coin_drip_interval` multiplication in `tools/screenshot/shot_scenarios.gd` or the e2e waits |
| D-05 amended in 01-CONTEXT.md | VERIFIED | Lines 66-70 read: steady-rate statement marked superseded, the amendment records 0.25 s, acceleration, 3 s cap, remainder paid at once, D-06 unchanged, shipped curve and plan references |
| Coin stream follows the curve (flight 90% of the gap to the next coin, floor 0.12 s, ceiling derived from `COIN_DRIP_INTERVAL_MAX_S`); the cap rush is staggered inside 0.3 s and at most 12 coins are drawn | VERIFIED (look: human) | `coin_drip_vfx.gd` read: `flight_seconds_for`, `launch_stagger`, same-frame group detection via `Engine.get_process_frames()`, `MAX_BURST_COINS` guard; `test_coin_drip_flight` (9) and `test_coin_drip_burst` (4) pass |
| `build_in_progress` screenshot timed from the curve; real-window sandbox with 15/30/50-coin House tiers that never mutates shipped data or ships | VERIFIED | `shot_scenarios.gd` waits `coin_due_seconds(2) + 0.5 * coin_interval(3)` and requires `get_coins_paid() > 0 and is_holding()`. I viewed the fresh `build_in_progress.png`: Gold 28, Tower I label with two of four coin icons filled, a coin in flight at the king. `hold_pacing_sandbox.gd` uses `duplicate_deep(DEEP_DUPLICATE_ALL)`; I launched the sandbox scene (40 s timeout, `--quit-after`) and it printed "House plots cost [15, 30, 50] coins per tier; holds accelerate and stop at 3.0 s"; `export_presets.cfg` `exclude_filter="tests/*, addons/gut/*, tools/*"` keeps it out of the build. `test_hold_pacing_sandbox` (3) passes. |
| Slow-drip fixtures independent of the shipped curve through one flat-pace helper; security and validation records updated | VERIFIED | `E2eSupport.flat_drip_tuning` read in `e2e_support.gd` line 42; `test_e2e_support_tuning` (4) passes; `01-SECURITY.md` has T-01-23 to T-01-26 and a refreshed T-01-22 (31 of 31 closed, audit row 27); `01-VALIDATION.md` lists the 358 tests and the queued manual check |

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3 (ROADMAP line 104): "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `simulation/defs/loop_tuning.gd` | Curve fields, sanitised pure helpers `coin_interval`, `coin_due_seconds`, `build_hold_seconds` | VERIFIED | Substantive; used by controller, VFX, screenshot tool, sandbox and tests |
| `data/tuning/loop_tuning.tres` | Shipped curve data | VERIFIED | 0.25, 2, 0.9, 0.08, 3.0 |
| `input/build_hold_controller.gd` | Hold clock, due-time drip, cap fast-forward | VERIFIED | Wired in `prototype_map.tscn` / `map_root.gd` (`$BuildHold`), reads `_ctx.tuning` |
| `presentation/vfx/coin_drip_vfx.gd` | Curve-following stream and staggered rush | VERIFIED | `CoinDripVfx` node in `prototype_map.tscn` (group `run_bound`), connects to `hold_progress` and `hold_cancelled` |
| `tools/sandbox/hold_pacing_sandbox.{gd,tscn}` | Real-window sandbox | VERIFIED | Boots; excluded from export |
| `tools/screenshot/shot_scenarios.gd` | Curve-timed build shot, seven shots | VERIFIED | 7 of 7 saved |
| `tests/e2e/test_build_hold_cap.gd`, `tests/e2e/test_coin_drip_burst.gd`, `tests/e2e/test_hold_pacing_sandbox.gd`, `tests/unit/test_loop_tuning_curve.gd`, `tests/unit/test_coin_drip_flight.gd`, `tests/unit/test_e2e_support_tuning.gd` and their `.uid` files | Real-scene and unit proofs | VERIFIED | Present, substantive, 0 failures in the JUnit XML |
| `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` D-05 | Amendment | VERIFIED | Lines 66-70 |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `build_hold_controller.gd` | `loop_tuning.gd` | `_ctx.tuning.coin_due_seconds(_coins_paid + 1)` | WIRED | Read |
| `loop_tuning.gd` | `loop_tuning.tres` | exported curve fields | WIRED | Script defaults equal data (contract test) |
| `coin_drip_vfx.gd` | `build_hold_controller.gd` | `hold_progress` and `hold_cancelled` connections in `bind_run` | WIRED | Read |
| `coin_drip_vfx.gd` | `loop_tuning.gd` | `coin_interval(coins_paid + 1)`, `COIN_DRIP_INTERVAL_MAX_S` | WIRED | Read |
| `shot_scenarios.gd` | `loop_tuning.gd` | `coin_due_seconds`, `coin_interval` | WIRED | Read |
| `test_build_hold_timing.gd` | `build_hold_controller.gd` | `get_hold_elapsed()` | WIRED | Per the review and grep |
| `hold_pacing_sandbox.gd` | prototype map | deep-copied `MapConfig` assigned to the instantiated `MapRoot` | WIRED | Launched it |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Build hold | due time per coin | `loop_tuning.tres` via `ctx.tuning` and the pure helper | Yes | FLOWING |
| Coin VFX flight and burst | `coin_interval`, coins_paid, cost | `hold_progress` signal and `ctx.tuning` | Yes | FLOWING |
| Spot label coin row | coins_paid | `hold_progress` (viewed in `build_in_progress.png`: two coins filled) | Yes | FLOWING |
| Build_in_progress shot wait | curve helpers | `ctx.tuning` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Lint | `bash tools/lint.sh` | exit 0, 84 files unchanged, no problems | PASS |
| Full suite (run once) | `bash tools/test.sh` | exit 0, 46 scripts, 358/358, 2796 asserts | PASS |
| Gap-plan suites in the JUnit XML | parse `build/test-results/gut-junit.xml` | cap 6, timing 4, curve 14, contract 6, flight 9, burst 4, sandbox 3, flat helper 4, refund 6, coin drip 4, spot label 7, night hold 14; 0 failures, 0 skipped | PASS |
| Curve arithmetic | independent Python recomputation | matches the plan table and the owner decision | PASS |
| Scripted screenshots | `bash tools/screenshot.sh` (real window) | exit 0, `Saved 7 of 7 screenshots` | PASS |
| In-progress build shot | read `screenshots/build_in_progress.png` | two coins filled, coin in flight, Gold 28 | PASS |
| Sandbox boots | `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn --quit-after 120` | prints the 15/30/50 line, exits; no Godot process left running | PASS |

### Probe Execution

Step 7c: SKIPPED. No phase plan declares a `probe-*.sh`, and `scripts/*/tests/probe-*.sh` does not exist; the verification entry points are `tools/lint.sh`, `tools/test.sh` and `tools/screenshot.sh`, run above.

### Requirements Coverage

All 15 phase IDs were extracted from the `requirements:` field of plans 01-01 to 01-16 and each appears in REQUIREMENTS.md as Phase 1 / Complete. No orphaned Phase 1 requirement (REQUIREMENTS.md maps no other ID to Phase 1).

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| KING-01 | 01-02, 01-04 | Move the mounted king with WASD / left stick, sprint | SATISFIED | input-map and king ride tests; UAT 1, 2 |
| KING-02 | 01-04, 01-11, 01-12 | Camera follows from a fixed isometric-style angle | SATISFIED | camera and X-Ray suites; UAT 3, 56, 57 pass |
| BLDG-01 | 01-02, 01-05 | Fixed build spots; buildings only on spots | SATISFIED | `validate_build` UNKNOWN_SPOT tests |
| BLDG-02 | 01-05, 01-06 | Near a spot by day, see what can be built and its cost | SATISFIED | spot label model and scene tests; `spot_label.png` |
| BLDG-03 | 01-02, 01-06, 01-13, 01-14, 01-15, 01-16 | Build by holding the action key with a visible progress indicator | SATISFIED (pace feel: human) | hold controller, curve, cap and VFX tests; `build_in_progress.png` |
| BLDG-04 | 01-05, 01-13, 01-14, 01-15 | Upgrade the same way, seeing next-tier cost and effect | SATISFIED | tier tests, label model, cap test on a tier I to higher repricing |
| BLDG-06 | 01-09 | Build and upgrade only by day | SATISFIED | NOT_DAY validation tests; the hold loop cancels when `is_build_allowed()` turns false |
| ECON-01 | 01-02, 01-09 | Gold is the only currency; HUD shows it | SATISFIED | HUD and economy tests |
| ECON-02 | 01-09, 01-10 | House pays flat income each dawn that rises with tier | SATISFIED | dawn income tests; UAT 10 |
| ECON-07 | 01-09 | Unspent gold carries over | SATISFIED | carryover tests |
| ART-02 | 01-07 | Third-party assets in an attribution log | SATISFIED | `ASSETS.md`, `assets/attribution.json`, attribution test |
| DEV-01 | 01-01, 01-02, 01-16 | Headless simulation and GUT tests from the CLI | SATISFIED | 358/358 headless |
| DEV-02 | 01-01, 01-03, 01-10 | CI lint and tests on every push, Windows export | SATISFIED | `ci.yml` read; last CI run green; new code not yet pushed (Advisory) |
| DEV-03 | 01-08 | Toggleable debug overlay | SATISFIED (wave state and pathing deferred to Phase 2) | overlay tests, `overlay_on.png`, UAT 8 |
| DEV-04 | 01-10, 01-12, 01-15 | Automated screenshot capture of scripted scenes | SATISFIED | 7 of 7 locally, curve-timed hold shot |

### Anti-Patterns Found

TBD/FIXME/XXX grep over the gap-plan source, tool and test files: no matches, so no unreferenced debt marker. No stubs: the controller, helpers, VFX, sandbox and tests are substantive and wired. The only value hard-wired empty is `_burst_delays` (a test hook that is filled on every progress signal). The six open review findings are listed in the Advisory; none blocks a truth.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `tests/e2e/test_build_hold_cap.gd`, `tests/e2e/test_coin_drip_burst.gd` | 147-170, 307-320 | tests assume no single frame of 0.25-0.3 s (review WR-01, OPEN) | Warning | possible CI flake on a stalled runner; passed locally |
| `simulation/defs/loop_tuning.gd` | 28-30, 44-67 | cap <= 0 silently means no cap; decay/floor/steady values sanitised without a contract assertion (review WR-02, OPEN) | Warning | a bad edit to the data would not be flagged for those fields; the shipped cap is guarded |
| `presentation/vfx/coin_drip_vfx.gd` | 92-141 | delayed burst and refund coins visible and stacked before launch (review IN-03, OPEN) | Info | slightly weakens the staggered look; the owner's feel check covers it |

### Human Verification Required

1. **Accelerating, capped build hold feel** (the frontmatter holds the full text; harvested from plan 01-15 Task 2's `<human-check>`).
   - **Test:** In the normal game hold the action key at House I, II, III and a tower plot; then in `tools/sandbox/hold_pacing_sandbox.tscn` hold at the 15, 30 and 50-coin House plots and release once just before 3 s.
   - **Expected:** 0.25 s start, visibly faster coins, House I about 0.5 s, stream still one coin at a time; the 15-coin build about 2.2 s; the 30 and 50-coin builds stop at 3.0 s with the remaining coins rushing in; an early release flies the coins back and builds nothing.
   - **Why human:** feel and look; UAT test 58 was a feel complaint.

No other human item is outstanding: the camera and silhouette re-checks (tests 56, 57) are owner-passed, the non-QWERTY label check was skipped by the owner on 2026-10-02, and the horse licence and CI trigger decisions were owner-accepted.

### Gaps Summary

No gaps. G-01-58 is closed in code (hold clock, due-time schedule, cap fast-forward), in the visuals (curve-following stream, staggered capped rush), in the tooling (curve-timed screenshot, sandbox) and in tests (358/358). Remaining risks are advisory only: the gap-plan code has not been pushed so CI has not yet run it, six open review findings concern test robustness and maintainability, and the owner's feel verdict on the new pace is pending.

---

_Verified: 2026-10-02T13:24:05Z_
_Verifier: Claude (gsd-verifier)_
