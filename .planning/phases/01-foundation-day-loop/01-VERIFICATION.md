---
phase: 01-foundation-day-loop
verified: 2026-09-29T14:10:12Z
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
  - "input/build_hold_controller.gd"
  - "input/start_night_hold_controller.gd"
  - "presentation/buildings/building_views.gd"
  - "presentation/map/map_root.gd"
  - "simulation/buildings/building_system.gd"
  - "simulation/commands/command_processor.gd"
  - "simulation/defs/map_config.gd"
  - "simulation/run/run_manager.gd"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:567de129cced1596c1c8e4be4fe1cfd1e0bd3b99dcd195b61b5a7a1c47d403d3"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed: []
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5 itself states 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3 requires 'the debug overlay shows live enemy counts, wave state, and enemy paths'; the overlay model exposes register_section for exactly this"
advisory:
  - finding: "CR-01: ui/hud/dawn_payout_vfx.gd computes `stagger = launch_stagger(coin_total)` (line 104) but schedules coins with the un-tightened STAGGER_SECONDS (line 112). The WR-10 'last coin lands inside the dawn window' guarantee is dead code; its test only exercises the pure helper."
    category: other
    reason: "Confirmed by reading the file. Not reachable with shipped data (max 5 Houses x tier-3 income 3 = 15 gold, capped to 10 coins, last landing at about 1.5 s of a 2.0 s dawn) and not part of any ROADMAP success criterion or PLAN must_have, so it does not fail the phase goal. It is a one-token fix (STAGGER_SECONDS to stagger) plus a real test. Recommended before push/PR because the review rates it critical and the fix commit f1f472d claims a guarantee the code does not provide."
    evidence_status: "deterministic: source lines 104 and 112 of dawn_payout_vfx.gd"
human_verification:
  - test: "Ride the king with keyboard and with a gamepad (walk, sprint, diagonal, stop) and watch the follow camera"
    expected: "Acceleration, turning and camera trail feel responsive and readable; sprint is clearly faster; camera never rotates"
    why_human: "Game feel cannot be judged from tests; the tests only prove speeds, ratio, deadzone and fixed camera rotation"
  - test: "Ride around the whole prototype map and look at the spot markers, plot colours and castle landmark"
    expected: "Map is readable; the 8 spots are distinguishable; edge-to-edge ride feels like 20-30 s"
    why_human: "Visual readability"
  - test: "Ride up to a House and a tower plot and read the world-space spot label; hold, release early, hold to completion, try with too little gold"
    expected: "Label is legible (the 'House I' title reportedly overlaps its effect line in the spot_label screenshot); coins drip and refund visibly; red cost plus shake when unaffordable"
    why_human: "Label layout and coin-drip feel are visual/UX judgments"
  - test: "Look at the king (horse plus rider) and the House / tower / castle models in the running game"
    expected: "Models read as a mounted king and as buildings (rider currently in T-pose on an unanimated horse, horse small; cosmetic, Phase 8 art pass)"
    why_human: "Model look"
  - test: "Press F3 (and gamepad Back) in a real window"
    expected: "Overlay appears with FPS, units, enemies, phase, day, night, gold, buildings and is readable"
    why_human: "Overlay look in a real window (logic is covered by tests)"
  - test: "Hold N (and gamepad Y) for 1.5 s, then watch night banner, lighting, dawn payout and return to Day as 'Night 2'"
    expected: "Prompt fills, banner and night lighting show, dawn coins fly from each paying House to the gold counter, '+X gold' appears, day returns with carried-over gold"
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight"
  - test: "Owner decision on the Quaternius horse licence (WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-29
**Status:** human_needed (all automated checks pass and no must-have fails; remaining items are visual/feel judgments plus one owner licence decision)
**Re-verification:** Yes. The prior report (human_needed, 5/5) was made stale by 20 review-fix commits that changed covered source files. Every truth was re-checked against the current tree; no regressions.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | Unchanged by the fix commits (`git diff 981e4c8..HEAD` touches none of king/camera/spot-label files). King, camera rig, spot label model and their tests (`test_king_ride`, `test_spot_label*`) are in the 201/201 run I executed. |
| 2 | Holding the action key near a spot with a visible progress indicator builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd` still validates in order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD (lines 7-10, 29-39) before spending. `build_hold_controller.gd` unchanged since the prior verification. Hold, refund, phase-guard, upgrade and denied tests pass in the full run. |
| 3 | Gold is the only currency, always on the HUD; ending the day via placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `RunManager` unchanged in logic (WR-07 clamp lives in `map_root.gd`, not the simulation clock semantics). `start_night_hold_controller.gd` now emits `night_requested` only on `CommandProcessor.OK` (line 52-53). `hud.gd` and `dawn_payout_vfx.gd` changed (WR-02 cap, HUD clamp, WR-10); the payout logic is intact and `test_dawn_payout`, `test_dawn_income`, `test_loop_gold_carryover`, `test_start_night_hold` all pass. See advisory CR-01 for the one defective sub-behaviour (stagger), which is outside this truth's wording. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see warning) | I ran `bash tools/lint.sh`: "64 files would be left unchanged / Success: no problems found". I ran `bash tools/test.sh` once: 30 scripts, 201/201 passing, 1393 asserts, exit 0. `ci.yml` still has lint, test, export (`needs: [lint, test]`), screenshots jobs; all four pinned action SHAs resolve on GitHub (`gh api`). Last CI run on origin (981e4c8, `gh run list`) was 4/4 success; the 28 later local commits (including the SHA pinning and trigger change) have not run in CI. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` now skips invalid providers (IN-07); `test_debug_overlay_toggle` and `test_debug_overlay_readonly` pass; `test_attribution_log` (now with exact-cell License check) passes. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | CR-01: `stagger` computed at `dawn_payout_vfx.gd:104` but line 112 still uses `STAGGER_SECONDS`; the "coins land inside the dawn window" guarantee is dead code and its test (`test_the_last_coin_lands_inside_the_dawn_window_however_many_spots_pay`) passes vacuously | other | Verified in source. Unreachable with shipped data; in no ROADMAP SC or PLAN must_have. Fix is one token plus a real emit-and-assert test; recommended before push. |
| 2 | WR-01 (validate misses empty building id; `RunContext` proceeds on invalid data), WR-02 (payout with total>0 but no schedulable coins leaves HUD lagging), WR-03 (overlay provider returning non-Array crashes refresh), WR-04 (screenshot.sh discards import log), WR-05 (test coupled to balance data and wall-clock) | warning | All robustness/test-fragility items in paths unreachable with shipped data; none breaks a success criterion. |
| 3 | IN-01..IN-05 | info | Unused constant, weak assertion, CI double-run, artifact upload on failure, redundant lookup. |
| 4 | CI trigger narrowed by IN-08 to `main`, `master`, `gsd/**` pushes plus all pull requests (was every push) | other | ROADMAP SC4 / DEV-02 say "on every push". A push to any other branch is covered only once a PR exists. Acceptable deviation for a solo repo, but it is a literal narrowing; consider an override note. |
| 5 | Phase is `Mode: mvp` in ROADMAP, but the goal is not in "As a ..., I want to ..., so that ..." form (`user-story.validate` returns false) | other | The MVP verification narrowing could not be applied; verified as standard goal-backward against the roadmap contract. Same as the prior verification. |

### Required Artifacts

All artifacts declared in the ten PLAN frontmatters exist, are substantive and wired (re-spot-checked: `command_processor.gd`, `map_root.gd`, `start_night_hold_controller.gd`, `dawn_payout_vfx.gd`, `debug_overlay_model.gd`, `ci.yml`). `map_root.gd` now scopes `run_bound` binding to its own subtree (`is_ancestor_of`, line 24) and clamps the frame delta. No orphans.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)`, `validate_build` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent.new())`, emit only on OK | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_context | `RunContext.new` then `call_group(run_bound)`, own-subtree scoped | WIRED |
| hud | sim_events / dawn_payout_vfx | `dawn_payout`, `coin_landed` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED (SHAs resolve; CI on new HEAD pending) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins | `Economy.get_gold()`, `coin_landed` | Yes | FLOWING |
| Dawn payout vfx | per_spot amounts | `SimEvents.dawn_payout` from `dawn_income_by_spot()` | Yes | FLOWING (launch stagger sub-defect: CR-01) |
| Spot label | title/cost/effect | `SpotLabelModel` from `.tres` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold | Engine + RunContext | Yes (units/enemies honestly 0) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 30 scripts, 201/201, 1393 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 64 files unchanged, no problems | PASS |
| Pinned CI action SHAs exist | `gh api repos/<action>/commits/<sha>` x4 | all resolve | PASS |
| Last remote CI | `gh run list` | 981e4c8 success (older than current HEAD) | PASS (stale) |
| Debt markers | grep `TBD|FIXME|XXX|TODO|HACK` over source dirs | none | PASS |

I relied on the orchestrator's report for the Windows export/headless launch, `prepush_check.sh` and the six screenshots and did not re-run them; the prior verification saw those artifacts on disk.

### Probe Execution

No `probe-*.sh` scripts declared; SKIPPED.

### Requirements Coverage

All 15 IDs from the ROADMAP Phase 1 list appear in a PLAN `requirements:` field (01-01 DEV-01, DEV-02; 01-02 BLDG-01, BLDG-03, ECON-01, KING-01, DEV-01; 01-03 DEV-02; 01-04 KING-01, KING-02; 01-05 BLDG-01, BLDG-02, BLDG-04; 01-06 BLDG-02, BLDG-03; 01-07 ART-02; 01-08 DEV-03; 01-09 BLDG-06, ECON-01, ECON-02, ECON-07; 01-10 DEV-04, DEV-02, ECON-02), and all are `[x]` / "Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king.gd, test_king_ride, test_input_map |
| KING-02 | 01-04 | SATISFIED | camera_rig fixed-offset rig, camera tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem, `unknown_spot` rejection |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model + world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | test_upgrade_flow |
| BLDG-06 | 01-09 | SATISFIED | NOT_DAY guard, mid-hold cancel, test_build_phase_guard |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, Economy never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income + payout VFX (CR-01 stagger caveat is visual timing only) |
| ECON-07 | 01-09 | SATISFIED | test_loop_gold_carryover |
| ART-02 | 01-07 | SATISFIED (licence note: WR-06 owner decision) | attribution.json, ASSETS.md, test_attribution_log |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 201 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed, CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh + shot_runner, CI job |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| ui/hud/dawn_payout_vfx.gd | 104, 112 | Computed value never used (`stagger`); fix claim not implemented (CR-01) | Warning (reviewer: critical) | Guarantee "last coin lands inside dawn window" not enforced; unreachable with shipped data |
| tests/e2e/test_dawn_payout.gd | 182-199 | Test asserts only the helper, not the launch path (vacuous for CR-01) | Warning | Suite cannot see the no-op |

No debt markers (TBD/FIXME/XXX/TODO/HACK) in source. All 11 open review findings remain recorded as `open` in 01-REVIEW-DISPOSITION.md; none is a ROADMAP success-criterion failure.

### Human Verification Required

See the `human_verification` list in the frontmatter. These match the 7 pending items in 01-UAT.md (no change to their content). Plus one recommendation that is not a UAT item: decide whether to fix CR-01 (and WR-01..WR-05) before pushing the 28 local commits, since CI has not yet run against them.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by code I re-read and by a full passing suite I ran (201/201, lint clean). The phase is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX feel and the Quaternius horse licence cannot be verified programmatically. The one substantive defect found is CR-01 (dead `stagger`), confirmed in source; it does not break a success criterion with shipped data, so it is an advisory, but it is cheap to fix and should be closed before the phase is shipped.

---

_Verified: 2026-09-29_
_Verifier: Claude (gsd-verifier)_
