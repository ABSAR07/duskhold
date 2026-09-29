---
phase: 01-foundation-day-loop
verified: 2026-09-29T16:19:14Z
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
  - "tools/screenshot.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:361f730b4f030953ebd350d744eed1681c8b3ba902ac0c027c30abfdfeb06e53"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "CR-01 (advisory in prior report): dawn coins now scheduled with the tightened `stagger`; a real-payout test would fail without it"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5 states 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3 requires 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "WR-01 (review 2): unknown spot id in a dawn payout `per_spot` would null-dereference in DawnPayoutVfx._start_point and strand the HUD readout"
    category: other
    reason: "Per-spot ids come from BuildingSystem.dawn_income_by_spot, which only iterates real built instances, so an unknown id is unreachable with the shipped game. Not in any ROADMAP SC or PLAN must_have. Recorded open in 01-REVIEW-DISPOSITION.md."
    evidence_status: "source read (ui/hud/dawn_payout_vfx.gd); no failing test"
  - finding: "WR-02 (review 2): BuildingSystem does not de-duplicate spot ids and hard-indexes _defs for an unknown building id"
    category: other
    reason: "Both are data errors MapConfig.validate() reports; the shipped prototype map is covered by test_prototype_map_data and CommandProcessor rejects unknown building ids on the normal path. Recorded open."
    evidence_status: "source read; no failing test"
  - finding: "WR-03 (review 2): DebugOverlayModel.collect validates the provider return is an Array but not each row's shape"
    category: other
    reason: "Only the in-repo providers exist and they return well-formed rows; robustness hardening only. Recorded open."
    evidence_status: "source read; no failing test"
  - finding: "IN-01..IN-04 (review 2): Hud.bind_run partly idempotent, hard-coded key hint and placeholder copy, read-only test watches 4 of 7 signals, timing-sensitive e2e slack and CI double-run on PR branches"
    category: other
    reason: "Info-level. IN-03 (CI double-run) was skipped as an owner decision."
    evidence_status: "review text; suite green 206/206 here"
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
**Verified:** 2026-09-29T16:20:00Z
**Status:** human_needed (all automated checks pass and no must-have fails; remaining items are visual/feel judgments plus one owner licence decision)
**Re-verification:** Yes. The previous report (human_needed, 5/5) went stale after review-fix pass 2 (10 commits 83b1c10..a8b919e). Every truth was re-checked against the current tree; no regressions, and the prior CR-01 advisory is now closed.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | No king/camera/spot-label source changed since the prior verification (fix diff touches only building_views marker lookup, building_system null-skip, map_config id check, hud, dawn_payout_vfx, overlay model, ci.yml, screenshot.sh). King/camera/spot-label tests are in the 206/206 run I executed. |
| 2 | Holding the action key near a spot with a visible progress indicator builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd` and `build_hold_controller.gd` unchanged; validation order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD before spending; hold/refund/phase-guard/upgrade/denied tests pass. |
| 3 | Gold is the only currency and always on the HUD; ending the day via placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` logic unchanged. `hud.gd` now clamps the in-flight payout to the gold coins can carry; `dawn_payout_vfx.gd` line 112 now schedules with the tightened `stagger` (previously STAGGER_SECONDS) and shows the total immediately when no coin can fly. `test_dawn_payout` includes a real emit-and-wait test (`test_a_real_payout_lands_every_coin_inside_a_short_dawn_window`: 12 coins, 1.0 s dawn) that would fail with the un-tightened stagger (last coin at 1.48 s); `test_dawn_income`, `test_loop_gold_carryover`, `test_start_night_hold` pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see warning) | I ran `bash tools/lint.sh`: 64 files unchanged, no problems. I ran `bash tools/test.sh` once: 30 scripts, 206/206, 1414 asserts, exit 0. `ci.yml` has lint, test, export (`needs: [lint, test]`) and screenshots jobs; screenshots job now uploads with `if: always()`. `screenshots/` holds 6 PNGs (41-77 KB each) and `build/windows/Duskhold.exe` + `.pck` exist. Last green CI on origin is 981e4c8 (`gh run list`); 51 local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` skips invalid providers and non-Array returns; overlay toggle/readonly tests and `test_attribution_log` pass in the 206/206 run; `assets/attribution.json` present. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | WR-01: unknown spot id in `per_spot` would null-deref in `_start_point` | other | Unreachable: ids originate from built instances in `dawn_income_by_spot`; no SC/must-have covers it |
| 2 | WR-02: duplicate spot ids / unknown building ids in `BuildingSystem` | other | Data errors already reported by `MapConfig.validate()`; shipped map is test-covered |
| 3 | WR-03: overlay row shape unvalidated | other | Only well-formed in-repo providers exist |
| 4 | IN-01..IN-04 | info | IN-03 (CI double-run once a `gsd/**` branch has a PR) skipped by owner decision |
| 5 | CI trigger narrowed to `main`, `master`, `gsd/**` pushes plus all PRs (was every push) | other | ROADMAP SC4 / DEV-02 say "on every push"; pushes to other branches are covered only via a PR. Acceptable for a solo repo; consider an override note |
| 6 | `build/windows/Duskhold.exe` (mtime 18:50 local) predates the fix commits (19:25-19:33 local) | other | Local artifact only; CI rebuilds the export from the pushed tree. Re-run `tools/export.sh` if the local build is to be shipped |
| 7 | Phase is `Mode: mvp` but its goal is not in "As a..., I want to..., so that..." form | other | The MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract |

### Required Artifacts

All artifacts declared in the ten PLAN frontmatters exist and are substantive; re-spot-checked this pass: `run_manager.gd`, `command_processor.gd`, `build_hold_controller.gd`, `start_night_hold_controller.gd`, `dawn_payout_vfx.gd`, `debug_overlay(_model).gd`, `assets/attribution.json`, `export_presets.cfg`, `ci.yml`, `tools/screenshot.sh`. All wired (behavior exercised by the passing suite). No orphans or stubs.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)`, `validate_build` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent.new())`, emit only on OK | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_context | `RunContext.new` then `call_group(run_bound)` | WIRED |
| hud | sim_events / dawn_payout_vfx | `dawn_payout`, `coin_landed` | WIRED |
| dawn_payout_vfx | launch_stagger | `stagger` now used at scheduling (line 112) | WIRED (was dead in prior report) |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED (CI on new HEAD pending) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins | `Economy.get_gold()`, `coin_landed`, per_spot-clamped pending | Yes | FLOWING |
| Dawn payout vfx | per_spot amounts | `SimEvents.dawn_payout` from `dawn_income_by_spot()` | Yes | FLOWING |
| Spot label | title/cost/effect | `SpotLabelModel` from `.tres` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold | Engine + RunContext | Yes (units/enemies honestly 0 until Phase 2) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 30 scripts, 206/206, 1414 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 64 files unchanged, no problems | PASS |
| Debt markers | grep `TBD|FIXME|XXX|TODO|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshot outputs on disk | `ls screenshots` | 6 PNGs, 41-77 KB | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (stale vs fixes, see advisory 6) | PASS |
| Last remote CI | `gh run list` | 981e4c8 success (older than HEAD) | PASS (stale) |

I relied on the orchestrator's report for the headless screenshot guard and `prepush_check.sh` and did not re-run them.

### Probe Execution

No `probe-*.sh` scripts declared; SKIPPED.

### Requirements Coverage

All 15 IDs from the ROADMAP Phase 1 list appear in the PLAN `requirements:` fields (extracted union: ART-02 BLDG-01 BLDG-02 BLDG-03 BLDG-04 BLDG-06 DEV-01 DEV-02 DEV-03 DEV-04 ECON-01 ECON-02 ECON-07 KING-01 KING-02) and all are `[x]` / "Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king.gd, test_king_ride, test_input_map |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem, `unknown_spot` rejection |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model + world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | test_upgrade_flow |
| BLDG-06 | 01-09 | SATISFIED | NOT_DAY guard, mid-hold cancel, test_build_phase_guard |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, Economy never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income + payout VFX (stagger now enforced and tested) |
| ECON-07 | 01-09 | SATISFIED | test_loop_gold_carryover |
| ART-02 | 01-07 | SATISFIED (licence note: WR-06 owner decision) | attribution.json, ASSETS.md, test_attribution_log |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 206 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed, CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh + shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers. No blocker or warning anti-patterns in the changed files. The prior dead-`stagger` finding (CR-01) is resolved. The three open review warnings (WR-01..03) are robustness items on unreachable data paths and are listed as advisories above.

### Human Verification Required

See the `human_verification` list in the frontmatter. These match the 7 pending items in 01-UAT.md. Non-UAT recommendations: push the 51 local commits and confirm CI is green on the new HEAD (DEV-02 CI evidence is still from 981e4c8), and optionally close WR-01..03 first.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by code I re-read and by a full passing suite I ran (206/206, lint clean). The phase is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX feel and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-29T16:20:00Z_
_Verifier: Claude (gsd-verifier)_
