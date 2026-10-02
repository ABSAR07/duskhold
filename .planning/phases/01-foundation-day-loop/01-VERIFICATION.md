---
phase: 01-foundation-day-loop
verified: 2026-10-02T20:57:44Z
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
covered_digest: "v2:sha256:5501ed4294dcdc6c3f14c3f45048b88238f1f27dd6ad57633bc166330396ae5f"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "G-01-59 (UAT test 59, minor): the 3 s hard cap and the 0.08 s coin floor are gone; the shipped hold is uncapped, every coin drips at its own due time, and no coin comes faster than 0.05 s after the acceleration (plans 01-17, 01-18; D-05 amended again). Closed in code, tests, tooling and records; the owner's feel re-check is the human item below."
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5: 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3: 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "Gap-closure code from plans 01-14 to 01-18 is not pushed, so CI has not run it"
    category: other
    reason: "origin/gsd/phase-01-foundation-day-loop is at 7775fab (last green CI run 36980680883); HEAD is 42 commits ahead. `git diff --stat 7775fab HEAD -- .github export_presets.cfg ASSETS.md assets` is empty, so the workflow, export preset and asset records are unchanged. ci.yml runs `bash tools/screenshot.sh` with no hard-coded count. The same lint, the 363-test suite and the 7 screenshots ran green locally in this pass. Not a must-have failure; a push will confirm. Not pushed by this verification."
    evidence_status: "git log origin/..., git rev-list --count = 42, git diff --stat on .github/export/assets"
  - finding: "Open code-review finding WR-01 (current 01-REVIEW.md, 2026-10-02T20:50:30Z): test_a_long_hold_is_not_capped cannot fail, so the cap guard in E2eSupport.flat_drip_tuning is unpinned"
    category: other
    reason: "tests/unit/test_e2e_support_tuning.gd:19-23 guards tests/e2e/e2e_support.gd:49. The shipped cap is 0.0, so the helper's `max_build_hold_seconds = 0.0` writes the value already there; deleting the line leaves the suite green. Test robustness only; the reviewer found no production defect. The review proposes a `base: LoopTuning` parameter so a capped base can be fed in."
    evidence_status: "01-REVIEW.md read in full, 01-REVIEW-DISPOSITION.md: open"
  - finding: "Open code-review finding WR-02: test_every_shipped_coin_lands_before_the_next_one_leaves asserts a property the design does not hold at the floor"
    category: other
    reason: "tests/unit/test_coin_drip_flight.gd:69-80 requires flight < gap for every coin of every shipped tier. MIN_FLIGHT_SECONDS (0.12 s) makes that false once a gap is under about 0.133 s (coin 8 onward). It passes today only because the dearest shipped tier is 6 coins; the first shipped tier of 8 or more coins would turn it red without any regression. Test premise only."
    evidence_status: "01-REVIEW.md; the test file passes 10/10 in this run"
  - finding: "Open info findings IN-01 (tautological MAX_FLIGHT_SECONDS test), IN-02 (delayed burst and refund coins visible and stacked before they launch), IN-03 (sandbox starting gold covers one plot's upgrade chain, the map has five House plots)"
    category: other
    reason: "IN-01 and IN-02 carry over from the previous cycle's IN-02 and IN-03. IN-02 is visual and sits inside the owner's feel re-check (coins at the floor and refund groups); the 01-UAT test 59 self-check already noted rush coins hidden in stills. IN-03: building House tier I on the four other plots first can leave too little gold for the 50-coin tiers and `hold_denied` fires; the owner can avoid it by holding at one plot. None makes a truth false. 01-REVIEW-DISPOSITION.md records 5 of 21 open; the previous review's WR-01, WR-02, IN-01 and IN-04 are confirmed closed."
    evidence_status: "01-REVIEW.md, 01-REVIEW-DISPOSITION.md"
  - finding: "The spot label's coin-icon row is very wide at the synthetic 15/30/50-coin sandbox costs"
    category: other
    reason: "No shipped building costs more than 6 coins, so the shipped game is unaffected; label layout for expensive buildings belongs to the later phase that adds them (stated in 01-UAT test 59 and the 01-18 human-check)."
    evidence_status: "01-UAT.md test 59 expected text"
  - finding: "Horse licence risk is owner-accepted; the unmodified horse GLB is public in the repo (Git LFS) and ships in the export"
    category: other
    reason: "Recorded in ASSETS.md and License.txt, accepted by the owner on 2026-10-01 (UAT test 15). Unchanged: the git diff on ASSETS.md, assets, export_presets.cfg and .github against 7775fab is empty."
    evidence_status: "01-UAT.md test 15; git diff --stat"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
human_verification:
  - test: "Owner feel re-check of the uncapped, accelerating build hold (plan 01-18 human-check, UAT G-01-59 re-check; replaces the capped-hold check of plan 01-15). (1) Normal game: from Git Bash in the repo root run `bash tools/godot.sh --path .` (or F5 in the editor). Hold Space or gamepad A at a House plot for House I, II and III, and at a tower plot. (2) Sandbox: run `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn`. House plots cost 15, 30 and 50 coins per tier and you start with enough gold for all three; hold at one House plot three times, and on the 50-coin tier let go once at about 3.5 s, then hold it again."
    expected: "(1) Unchanged since the last check: the first coin leaves after 0.25 s and the coins then come faster; House I takes about 0.5 s, House III about 1.1 s, a tower about 0.9 s, one coin at a time. (2) The 15-coin build takes about 2.2 s, the 30-coin build about 2.9 s and the 50-coin build about 3.9 s. There is no time limit any more: every coin drips in on its own and nothing is fast-forwarded. After the acceleration the coins come every 0.05 s, so up to 3 coins are in the air at once. Letting go early flies the coins back (at most 12 are drawn) and builds nothing. Judge whether the pace feels right, and say whether your '0.05 s' meant the gap between coins (as built) or how long each coin takes to fly (each flight still lasts at least 0.12 s so a coin stays visible). The label's very wide coin-icon row at these synthetic costs is not part of this check."
    why_human: "Pace, acceleration and readability of a 3-coins-in-the-air stream are feel and look judgments (UAT tests 58 and 59 were both feel complaints), and the reading of '0.05 s' is an owner decision no test can assert. Already proven by scripts: the curve numbers (independently recomputed in this pass: 0.5, 0.725, 0.9275, 1.1098, 1.2738 for 2-6 coins, 1.7814 for 10, 2.1781 for 15, 2.9367 for 30, 3.9367 for 50, floor first reached at coin 18), the uncapped due-time drip with one BuildIntent and one debit, the full refund on early release, the 12-coin visual cap, the sandbox boot, and the real-window self-check of plan 01-18 (15/30/50 coins at 2.178/2.942/3.938 s, one coin per frame, at most 3 in the air, late release refunded all 41 paid coins)."
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-02T20:57:44Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is the owner's feel judgment of the uncapped hold, the single re-check queued by plan 01-18)
**Re-verification:** Yes, after the second round of UAT gap closure (G-01-59). The previous report (2026-10-02T13:24:05Z, HEAD 4d163fb) is stale because covered files changed. Every verdict below was regenerated from the current tree (HEAD c3a8277, whose only commits after c0c6e74 touch `.planning/`); none was copied.

## Change audit since the previous report

- UAT (`01-UAT.md`, 59 tests). Test 58's gap G-01-58 (capped hold) is resolved. Test 59, the owner's feel check of the accelerating, 3 s-capped hold, came back `issue`: no hard time limit, and a 0.05 s minimum per coin after the acceleration. It is recorded as G-01-59 with status `failed` in the UAT file (read-only for me); plans 01-17 and 01-18 (`gap_closure: true`, `gap_ids: [G-01-59]`) implement the fix and both have SUMMARYs. The previous report's single human item (feel of the capped hold) is therefore answered and superseded; the carried human item is plan 01-18's re-check.
- `git diff --stat 4d163fb HEAD -- . ':!.planning'` touches exactly 15 files, all hold-pacing code, tests and tooling: `data/tuning/loop_tuning.tres`, `simulation/defs/loop_tuning.gd`, `input/build_hold_controller.gd` (comments), `presentation/vfx/coin_drip_vfx.gd` (comments), `tools/sandbox/hold_pacing_sandbox.gd`, `tests/e2e/e2e_support.gd`, the renamed `test_build_hold_cap.gd` -> `test_build_hold_long.gd` (+ `.uid`), `test_coin_drip_burst.gd`, `test_hold_pacing_sandbox.gd`, `test_coin_drip_flight.gd`, `test_e2e_support_tuning.gd`, `test_loop_tuning_contract.gd`, `test_loop_tuning_curve.gd`. No other production file changed, so success criteria 1, 3 and 5 are unaffected by this round.
- `tests/e2e/test_build_hold_cap.gd` no longer exists; nothing in code, tests, scripts or CI references it (grep, exit 1). `test_build_hold_long.gd.uid` is tracked.
- The only working-tree modification is `.planning/config.json`.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED | No production file for this truth changed since the last report (see change audit); UAT tests 1, 2, 3 (re-check 56), 5, 6 and 57 are `pass` in `01-UAT.md`. King ride, camera zoom, input-map, X-Ray and spot-label suites are inside the 363/363 run (spot label model 9, spot label e2e 7, 0 failures). `king_behind_keep.png` and `spot_label.png` regenerated this pass. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED (feel: human) | `input/build_hold_controller.gd` `_advance_hold` (read in full): the release / range / `is_build_allowed()` check runs before any coin, then `_hold_elapsed += delta` and `while _coins_paid < _cost and _hold_elapsed >= _ctx.tuning.coin_due_seconds(_coins_paid + 1)` pays each coin at its own due time; one `commands.submit(BuildIntent)` goes out in `_finish_hold`, and a failed completion cancels with a refund. `_try_start_hold` runs `validate_build` first (unknown spot, unaffordable, max tier, not day all deny with `hold_denied` and move no gold). `simulation/defs/loop_tuning.gd` `coin_due_seconds` (read) returns the plain running sum when `max_build_hold_seconds <= 0` and only clamps when a positive cap is set; `data/tuning/loop_tuning.tres` carries 0.25 / 2 / 0.9 / 0.05 / cap 0.0, equal to the script defaults (`test_script_defaults_match_the_shipped_pacing_data`). I recomputed the curve independently in Python and it matches the helper and the owner table (see Spot-Checks). Shipped tiers are 2/3/5 (House) and 4/6 (tower), so normal holds are 0.5 s to 1.27 s. Behavior-dependent invariants (drip at due time, one debit, long-frame completion, refund on release) have named passing tests. The remaining uncertainty is how the pace feels, routed to the human item. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd`, `economy`, `hud.gd`, `dawn_payout_vfx.gd` are not in the 4d163fb..HEAD production diff. UAT tests 9 and 10 verified in a real window; dawn income, payout VFX, HUD lag release and carryover suites pass in the 363/363 run; `dawn_payout.png` regenerated this pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (gap-closure code not yet CI-run, see Advisory) | This pass: `bash tools/lint.sh` exit 0 ("84 files would be left unchanged", "no problems found"); `bash tools/test.sh` run once, exit 0, 46 scripts, 363/363, 3101 asserts, 138 s; `bash tools/screenshot.sh` exit 0, `Saved 7 of 7 screenshots`. `.github/workflows/ci.yml` has no path filters, triggers on every push, and jobs `lint`, `test`, `export` (`needs: [lint, test]`) and `screenshots` (`needs: [test]`); unchanged against origin. Last pushed run (36980680883 on 7775fab) was green; plans 01-14 to 01-18 are 42 commits beyond it. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | Overlay and attribution suites pass in the full run; UAT test 8 verified in a real window; `overlay_on.png` regenerated. `ASSETS.md`, `assets/` and `export_presets.cfg` are byte-unchanged against 7775fab. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified. The human item is a feel judgment on top of a verified mechanism, not a truth left unproven.

### Gap-plan must-haves (plans 01-17 and 01-18, G-01-59)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| No hold lasts a hard maximum: with the shipped data every coin of a 30-coin tier drips at its own due time, never two in one step, completing when the last coin lands (about 2.94 s) with one BuildIntent and one full-cost debit | VERIFIED | `loop_tuning.tres` `max_build_hold_seconds = 0.0`; `coin_due_seconds` has no cap branch when 0. `tests/e2e/test_build_hold_long.gd` (6 tests, all pass) steps the controller with a fixed 1/64 s delta: `test_every_coin_drips_at_its_own_due_time_and_never_two_in_one_step` asserts each stamp is within `[due, due + STEP]` and strictly rising; `test_the_hold_lasts_the_uncapped_sum_of_its_intervals`; `test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit` asserts progress 1..cost in order, one `hold_completed`, no `hold_cancelled`, one `gold_changed(remaining, -cost)`. `test_shipped_data_has_no_cap_so_every_coin_drips` pins no cap on purpose. |
| After the acceleration a coin takes at least 0.05 s (floor reached at coin 18; each coin past it adds exactly the floor); normal-game holds unchanged | VERIFIED | Python recomputation: floor first reached at coin 18 (coin 17 = 0.05147 s); holds 2 -> 0.5, 3 -> 0.725, 4 -> 0.9275, 5 -> 1.1098, 6 -> 1.2738 s, 10 -> 1.7814, 15 -> 2.1781, 30 -> 2.9367, 50 -> 3.9367, 100 -> 6.4367. `test_loop_tuning_curve` (15, pass: owner table, each coin past the floor adds exactly the floor) and `test_loop_tuning_contract` (8, pass: floor is the owner's and never undercut, in-range asserts) agree. |
| Release or leaving range before the last coin refunds every dripped coin and builds nothing (D-06 unchanged); one long frame pays all due coins with one debit | VERIFIED | `_advance_hold` runs the cancel check ahead of the drip. `test_releasing_before_the_last_coin_refunds_everything` and `test_one_long_frame_pays_every_due_coin_and_completes_with_one_debit` pass; `tests/integration/test_build_hold_refund.gd` (6) passes. Real-window self-check (01-18 SUMMARY): late release of the 50-coin tier at hold clock 3.493 s refunded 41 (all paid), gold 55 -> 55, tier unchanged. |
| Coin VFX staggers a same-frame group, draws at most 12 coins for groups and refunds; at most 3 drip coins in the air on the shipped curve; flight stays at least 0.12 s | VERIFIED (look: human) | `coin_drip_vfx.gd` read: `flight_seconds_for` (0.9 x gap clamped to 0.12..0.27), `launch_stagger`, same-frame group detection via `Engine.get_process_frames()`, `MAX_BURST_COINS = 12`, refund fly-back. `test_coin_drip_burst` (5), `test_coin_drip_flight` (10, includes the airborne-bound test) pass. Delayed burst coins being visible before launch is open review IN-02 (Advisory). |
| Sandbox repriced on a deep copy, never touching shipped data or the export; startup line describes the uncapped hold | VERIFIED | `tools/sandbox/hold_pacing_sandbox.gd` read: `shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`, House repriced to 15/30/50, gold = tier sum + 5; the startup line derives hold seconds from `tuning.build_hold_seconds`. `export_presets.cfg` `exclude_filter="tests/*, addons/gut/*, tools/*"` keeps it out of the build. `test_hold_pacing_sandbox` (3) passes, and `test_repricing_a_tier_leaves_the_cached_house_resource_untouched` passes. |
| D-05 amended in 01-CONTEXT.md for G-01-59; security and validation records refreshed | VERIFIED | 01-CONTEXT.md D-05 (lines 66-70): the 2026-10-02 capped amendment is marked superseded and the 2026-10-03 amendment states no time limit, 0.05 s floor, D-06 unchanged, shipped curve, "0.05 s" read as pace between coins, UAT re-check pending. 01-SECURITY.md: T-01-27 (closed, accepted) and AR-06 present; 32 register rows. |
| Controller and VFX doc comments describe the uncapped drip with no seconds in them; the 01-18 docs commit changed only comments | VERIFIED | Both files read in full: no hard-coded seconds in comments, no code change visible beyond the 4d163fb diff of 14 and 17 lines of comment text. Lint and 363/363 pass. |

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `simulation/defs/loop_tuning.gd` | Curve fields, sanitised pure helpers `coin_interval`, `coin_due_seconds`, `build_hold_seconds`; dormant cap switch | VERIFIED | Substantive (79 lines); used by controller, VFX, sandbox, screenshot tool and tests |
| `data/tuning/loop_tuning.tres` | Shipped curve: 0.25 / 2 / 0.9 / 0.05 / cap 0.0 | VERIFIED | Read |
| `input/build_hold_controller.gd` | Hold clock, due-time drip, release/range/day check before any coin | VERIFIED | Read in full; `$BuildHold` in `prototype_map.tscn` / `map_root.gd`, reads `_ctx.tuning` |
| `presentation/vfx/coin_drip_vfx.gd` | Curve-following stream, staggered groups, refund fly-back | VERIFIED | Read in full; connects `hold_progress` and `hold_cancelled` in `bind_run` |
| `tools/sandbox/hold_pacing_sandbox.{gd,tscn}` | Real-window sandbox, excluded from export | VERIFIED | Read; loaded by `test_hold_pacing_sandbox` |
| `tests/e2e/test_build_hold_long.gd` (+ `.uid`) | Six deterministic uncapped-hold tests | VERIFIED | Present, substantive (read lines 80-205), 6/6 pass; replaces the deleted `test_build_hold_cap.gd` |
| `tests/e2e/e2e_support.gd` | `stand_at_spot`, `begin_stepped_hold`, `step_hold`, `flat_drip_tuning`, `map_with_tier_cost` | VERIFIED | Used by the long-hold, burst and refund suites |
| `tests/e2e/test_coin_drip_burst.gd`, `tests/e2e/test_hold_pacing_sandbox.gd`, `tests/unit/test_loop_tuning_contract.gd`, `tests/unit/test_loop_tuning_curve.gd`, `tests/unit/test_coin_drip_flight.gd`, `tests/unit/test_e2e_support_tuning.gd` | Real-scene and unit proofs | VERIFIED | Present, 0 failures, 0 skipped in the JUnit XML |
| `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` D-05 | G-01-59 amendment | VERIFIED | Lines 66-70 |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `build_hold_controller.gd` | `loop_tuning.gd` | `_ctx.tuning.coin_due_seconds(_coins_paid + 1)` | WIRED | Read, line 107 |
| `loop_tuning.gd` | `loop_tuning.tres` | exported curve fields | WIRED | Script defaults equal data (contract test) |
| `coin_drip_vfx.gd` | `build_hold_controller.gd` | `hold_progress` and `hold_cancelled` connections in `bind_run` | WIRED | Read |
| `coin_drip_vfx.gd` | `loop_tuning.gd` | `coin_interval(coins_paid + 1)`, `COIN_DRIP_INTERVAL_MAX_S` | WIRED | Read |
| `build_hold_controller.gd` | `command_processor.gd` | single `commands.submit(BuildIntent)` in `_finish_hold` | WIRED | Read; `gold_changed` emitted exactly once in the long-hold tests |
| `test_build_hold_long.gd` | `build_hold_controller.gd` | `E2eSupport.step_hold` -> `_process(fixed delta)`, `get_hold_elapsed()` | WIRED | Read |
| `hold_pacing_sandbox.gd` | prototype map | deep-copied `MapConfig` assigned to the instantiated `MapRoot` | WIRED | Read; test loads it |
| `tools/screenshot/shot_scenarios.gd` | `loop_tuning.gd` | curve helpers for the build-in-progress wait | WIRED | `Saved 7 of 7 screenshots` this pass |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Build hold | due time per coin | `loop_tuning.tres` via `ctx.tuning` and the pure helper | Yes | FLOWING |
| Coin VFX flight and groups | `coin_interval`, coins_paid, cost | `hold_progress` signal and `ctx.tuning` | Yes | FLOWING |
| Spot label coin row | coins_paid | `hold_progress` | Yes | FLOWING |
| Sandbox gold and costs | repriced tier costs, gold | deep copy of the shipped map | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Lint | `bash tools/lint.sh` | exit 0, 84 files unchanged, no problems | PASS |
| Full suite (run once) | `bash tools/test.sh` | exit 0, 46 scripts, 363/363, 3101 asserts, 138.3 s | PASS |
| Hold-pacing suites in the JUnit XML | parse `build/test-results/gut-junit.xml` | long 6, burst 5, curve 15, contract 8, flight 10, e2e-support 4, sandbox 3, timing 4, refund 6, coin drip 4, spot label 7 and 9, night hold 14; 0 failures, 0 errors, 0 skipped overall | PASS |
| Curve arithmetic | independent Python recomputation (scratch script) | 2:0.5, 3:0.725, 4:0.9275, 5:1.1098, 6:1.2738, 10:1.7814, 15:2.1781, 30:2.9367, 50:3.9367, 100:6.4367; floor first at coin 18 | PASS |
| Scripted screenshots | `bash tools/screenshot.sh` (real window, Forward+, RTX 3060) | exit 0, `Saved 7 of 7 screenshots` | PASS |
| Stale references to the deleted cap test | grep for `test_build_hold_cap` outside `.planning` | no matches | PASS |
| No stray Godot process | PowerShell `Get-CimInstance Win32_Process` filter `Godot%` | none running after the runs | PASS |

### Probe Execution

Step 7c: SKIPPED. No phase plan declares a `probe-*.sh`, and `scripts/*/tests/probe-*.sh` does not exist; the verification entry points are `tools/lint.sh`, `tools/test.sh` and `tools/screenshot.sh`, run above.

### Requirements Coverage

All 15 phase IDs were extracted from the `requirements:` field of plans 01-01 to 01-18 and each appears in REQUIREMENTS.md as Phase 1 / Complete (`[x]`). REQUIREMENTS.md maps no other ID to Phase 1 (BLDG-05 is Phase 5), so there is no orphaned requirement.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| KING-01 | 01-02, 01-04 | Move the mounted king with WASD / left stick, sprint | SATISFIED | input-map and king ride tests; UAT 1, 2 |
| KING-02 | 01-04, 01-11, 01-12 | Camera follows from a fixed isometric-style angle | SATISFIED | camera and X-Ray suites; UAT 3, 56, 57 |
| BLDG-01 | 01-02, 01-05 | Fixed build spots; buildings only on spots | SATISFIED | `validate_build` unknown-spot tests |
| BLDG-02 | 01-05, 01-06 | Near a spot by day, see what can be built and its cost | SATISFIED | spot label model and scene tests; `spot_label.png` |
| BLDG-03 | 01-02, 01-06, 01-13 to 01-18 | Build by holding the action key with a visible progress indicator | SATISFIED (pace feel: human) | hold controller, uncapped curve, long-hold and VFX tests; `build_in_progress.png` regenerated; real-window self-check |
| BLDG-04 | 01-05, 01-13 to 01-15, 01-17, 01-18 | Upgrade the same way, seeing next-tier cost and effect | SATISFIED | tier tests, label model, long-hold tests on a repriced tier |
| BLDG-06 | 01-09 | Build and upgrade only by day | SATISFIED | not-day validation tests; the hold cancels when `is_build_allowed()` turns false (`_advance_hold` read) |
| ECON-01 | 01-02, 01-09 | Gold is the only currency; HUD shows it | SATISFIED | HUD and economy tests |
| ECON-02 | 01-09, 01-10 | House pays flat income each dawn that rises with tier | SATISFIED | dawn income tests; UAT 10 |
| ECON-07 | 01-09 | Unspent gold carries over | SATISFIED | carryover tests |
| ART-02 | 01-07 | Third-party assets in an attribution log | SATISFIED | `ASSETS.md`, `assets/attribution.json`, attribution test |
| DEV-01 | 01-01, 01-02, 01-16 | Headless simulation and GUT tests from the CLI | SATISFIED | 363/363 headless |
| DEV-02 | 01-01, 01-03, 01-10 | CI lint and tests on every push, Windows export | SATISFIED | `ci.yml` read; last pushed CI run green; gap-closure code not yet pushed (Advisory) |
| DEV-03 | 01-08 | Toggleable debug overlay | SATISFIED (wave state and pathing deferred to Phase 2) | overlay tests, `overlay_on.png`, UAT 8 |
| DEV-04 | 01-10, 01-12, 01-15 | Automated screenshot capture of scripted scenes | SATISFIED | 7 of 7 locally |

### Anti-Patterns Found

TBD/FIXME/XXX grep over the hold controller, VFX, tuning script and data, sandbox, e2e support and all hold-pacing test files: no matches (exit 1), so no unreferenced debt marker. No stubs: controller, helpers, VFX, sandbox and tests are substantive and wired; the only hard-wired empty value is `_burst_delays`, a test hook refilled on every progress signal. The five open review findings are test-robustness and maintainability items (see Advisory); the reviewer found no production defect and I found none.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `tests/unit/test_e2e_support_tuning.gd` | 19-23 | cap guard in `flat_drip_tuning` cannot be failed by the shipped data (review WR-01, OPEN) | Warning | a later cap retune could slip past the helper unnoticed; no effect today |
| `tests/unit/test_coin_drip_flight.gd` | 69-80 | asserts flight < gap for every shipped coin, false by design at the floor from coin 8 (review WR-02, OPEN) | Warning | false red the first time a tier of 8 or more coins ships |
| `tests/unit/test_coin_drip_flight.gd`, `simulation/defs/loop_tuning.gd` | 60-66, 12 | tautological ceiling test, constant read only by tests (review IN-01, OPEN) | Info | weak pin only |
| `presentation/vfx/coin_drip_vfx.gd` | 94-107, 126-143 | delayed burst and refund coins visible and stacked before launch (review IN-02, OPEN) | Info | slightly weakens the staggered look; covered by the owner's feel check |
| `tools/sandbox/hold_pacing_sandbox.gd` | 16-17, 54-58 | starting gold covers one plot's chain, five House plots share the repriced def (review IN-03, OPEN) | Info | stray builds on other plots can deny the 50-coin holds in the sandbox |

### Human Verification Required

1. **Uncapped, accelerating build hold feel** (harvested from plan 01-18's `<human-check>`, copied from 01-18-SUMMARY.md; supersedes the capped-hold check).
   - **Test:** In the normal game hold the action key at House I, II, III and a tower plot; then in `tools/sandbox/hold_pacing_sandbox.tscn` hold at the 15, 30 and 50-coin House plots, and on the 50-coin tier release once at about 3.5 s, then hold it again.
   - **Expected:** Normal game unchanged (0.25 s first coin, House I about 0.5 s, House III about 1.1 s, tower about 0.9 s, one coin at a time). Sandbox: the 15, 30 and 50-coin builds take about 2.2, 2.9 and 3.9 s, every coin drips and nothing is fast-forwarded, up to 3 coins are in the air once the coins come every 0.05 s, and an early release flies up to 12 coins back and builds nothing. Say whether "0.05 s" meant the gap between coins (as built) or each coin's flight time (flights last at least 0.12 s).
   - **Why human:** feel, look and an interpretation the owner must confirm; UAT tests 58 and 59 were feel complaints. If the owner wants a shorter flight too, the one-line lever is `CoinDripVfx.MIN_FLIGHT_SECONDS`.

No other human item is outstanding: the camera and silhouette re-checks (tests 56, 57) are owner-passed, the non-QWERTY label check was skipped by the owner on 2026-10-02, and the horse licence and CI trigger decisions were owner-accepted.

### Gaps Summary

No gaps. G-01-59 is closed in the shipped data (cap off, 0.05 s floor), in the runtime path (due-time drip needed no logic change), in the tests (long-hold, burst, contract and curve suites pin the owner's decision and the WR-02 in-range asserts of the previous review), in the sandbox and records (D-05, T-01-27 / AR-06, validation rows), and in a real-window self-check recorded by plan 01-18. UAT test 59 stays `issue` in `01-UAT.md` until the owner re-checks, which is the one item holding this phase at human_needed. Remaining risks are advisory only: the gap-closure commits are unpushed so CI has not run them, and five open review findings concern test robustness, a visual detail and the sandbox's starting gold.

---

_Verified: 2026-10-02T20:57:44Z_
_Verifier: Claude (gsd-verifier)_
