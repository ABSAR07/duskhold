---
phase: 01-foundation-day-loop
verified: 2026-09-29T12:00:00Z
status: human_needed
score: 5/5 must-haves verified
covered_files:
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
  - "presentation/map/map_root.gd"
  - "simulation/buildings/building_system.gd"
  - "simulation/commands/command_processor.gd"
  - "simulation/run/run_manager.gd"
  - "ui/hud/hud.gd"
covered_digest: "v2:sha256:c3d9d609a22a405affb87b7757c2adf3a8c9b56ec17f96fd5540b41ffa151e92"
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5 itself states 'wave state and enemy paths join it once nights have enemies in Phase 2'; the overlay model exposes register_section for exactly this"
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
  - test: "Owner decision on the Quaternius horse licence (WR-06)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; the owner already approved it knowingly, but it is unresolved in the review disposition"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-29
**Status:** human_needed (all automated checks pass; no gaps; remaining items are visual/feel judgments the executors deliberately deferred to end-of-phase)
**Re-verification:** No, initial verification

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | `presentation/king/king.gd` reads `Input.get_vector(move_*)`, sprint multiplies `walk_speed` (5.0) by 1.6 from `data/king/king.tres`, accelerates via `move_toward`, faces velocity. `presentation/camera/camera_rig.gd` is a detached rig with a fixed offset and exp-smoothed follow; Camera3D aimed once, rotation never changes. `project.godot` binds WASD, arrows, left stick (axes 0/1), Shift and RB (button 10). `ui/world/spot_label_model.gd` produces title, cost, effect for the next tier; `ui/world/spot_label.gd` is wired in `prototype_map.tscn` (group `run_bound`). Tests `test_king_ride.gd` (10 tests: sprint ratio, diagonal, deadzone, camera rotation fixed, camera trails), `test_spot_label.gd`, `test_spot_label_model.gd` all pass. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House/tower or upgrades it after showing next tier cost/effect; only when affordable, only on spots, never at night | VERIFIED | `input/build_hold_controller.gd`: `_try_start_hold` calls `commands.validate_build`; per-frame `_advance_hold` cancels on release, leaving range, or `!is_build_allowed()`; coins drip at `coin_drip_interval`; completion submits a single `BuildIntent`. `simulation/commands/command_processor.gd` re-validates NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD before `try_spend` and `apply_next_tier`. `BuildingSystem` only contains map spots (unknown id rejected). Data: House 3 tiers (2/3/5 gold), Tower 2 tiers (4/6). Tests: `test_walking_skeleton`, `test_build_flow`, `test_upgrade_flow`, `test_build_hold_refund` (6, incl. refund mid-hold when building stops), `test_build_phase_guard` (night/dawn rejection), `test_build_denied`, `test_upgrade_at_spot`, `test_coin_drip`. Orchestrator additionally drove the real windowed game (gold 4 to 2, early release changes nothing). |
| 3 | Gold is the only currency, always on the HUD; ending the day (placeholder night) leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `ui/hud/hud.gd` `%GoldLabel` always shown, refreshed on `gold_changed`; HUD instanced in `prototype_map.tscn`. `RunManager` DAY to NIGHT_TRANSITION to NIGHT to DAWN to DAY; only `start_night` leaves DAY (hold-to-confirm `start_night_hold_controller.gd`, 1.5 s, N / gamepad Y); `_apply_dawn_payout` grants sum of `dawn_income_by_spot()` (House 1/2/3 by tier) exactly once per dawn; nothing rebases gold. Tests: `test_run_manager`, `test_dawn_income` (9 tests incl. upgrade-today pays new tier, empty dawn, once-per-dawn), `test_loop_gold_carryover` (three full cycles, gold moves only at dawn), `test_start_night_hold`, `test_dawn_payout`. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, day-to-day transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED | Ran `bash tools/test.sh`: 29 scripts, 190/190 tests, 1352 asserts, exit 0. Ran `bash tools/lint.sh`: "63 files would be left unchanged / Success: no problems found". `.github/workflows/ci.yml` triggers on push to `**` with no path filters; jobs lint, test, export (`needs: [lint, test]`), screenshots (xvfb, Compatibility renderer). `gh run view 36561636852` (981e4c8): lint, test, export, screenshots all succeeded; artifacts gut-results, duskhold-windows, duskhold-screenshots. Local artifacts exist: `build/windows/Duskhold.exe` (109 MB) + `.pck`, six non-empty PNGs in `screenshots/` (day_overview, spot_label, build_in_progress, night_banner, dawn_payout, overlay_on). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset recorded in the attribution log | VERIFIED | `ui/overlay/debug_overlay.gd` toggles on `toggle_debug_overlay` (F3 / gamepad Back, button 4), hidden by default; `debug_overlay_model.gd` provides Perf (FPS), Loop (phase/day/night/gold/buildings/timer), Agents (units/enemies) sections plus `register_section` for Phase 2. Read-only tested (`test_debug_overlay_readonly`, `test_debug_overlay_toggle`). `assets/attribution.json` (schema 1) + `ASSETS.md` list Godot, GUT, three Kenney packs and the Quaternius horse with source URL, license, sha256; `test_attribution_log` (walks `assets/third_party/` and `addons/`) passes. |

**Score:** 5/5 truths verified, 0 behavior-unverified (every state-transition/cancel/ordering invariant has a passing named test in the 190-test run).

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | ROADMAP Phase 1 SC5 explicitly scopes these to Phase 2; `register_section` seam present |

### Required Artifacts (PLAN must_haves)

All artifacts listed in the ten PLAN frontmatters exist, are substantive and are wired. Spot-checked in code: `command_processor.gd` (single mutation gate), `run_context.gd`, `economy.gd`, `building_system.gd` (`nearest_spot_in_range`, `dawn_income_by_spot`), `build_hold_controller.gd`, `map_root.gd` (`RunContext.new`, `call_group run_bound`), `camera_rig.gd`, `king.gd`, `king_def.gd`, `map_config.gd` (validate), `start_night_hold_controller.gd`, `day_night_lighting.gd`, `dawn_payout_vfx.gd`, `debug_overlay*.gd`, `tools/{bootstrap.py,test.sh,lint.sh,export.sh,screenshot.sh,prepush_check.sh}`, `export_presets.cfg`, `.github/workflows/ci.yml`, `assets/attribution.json`, `ASSETS.md`. No file is orphaned: every run_bound node (Lighting, BuildHold, StartNightHold, BuildingViews, HUD, SpotLabel, CoinDripVfx, CameraRig) is in `presentation/map/prototype_map.tscn`; the debug overlay is instanced in the HUD/scene per the plan 01-08 tests that toggle it on the real scene.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent.new(spot_id))`, `validate_build` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent.new())` | WIRED |
| run_manager | economy | `grant(total)` from `dawn_income_by_spot()` on DAWN entry | WIRED |
| map_root | run_context | `RunContext.new(map_config, loop_tuning)` then `call_group(run_bound, bind_run)` | WIRED (see WR-01 caveat) |
| hud | sim_events / build_hold | `gold_changed`, `dawn_payout`, `hold_progress` connects | WIRED |
| day_night_lighting | sim_events | `phase_changed` drives mood tween | WIRED |
| ci.yml | tools/test.sh, export.sh, screenshot.sh, bootstrap.py | same wrappers as local dev | WIRED (CI green) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold | `Economy.get_gold()` minus in-flight coins, updated by `gold_changed` | Yes | FLOWING |
| Spot label | title/cost/effect | `SpotLabelModel.describe(ctx, ...)` from `.tres` tier data | Yes | FLOWING |
| Dawn payout | per-spot income | `BuildingSystem.dawn_income_by_spot()` from live instances and tier `.tres` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, counts | `Engine.get_frames_per_second()`, RunContext getters | Yes (units/enemies are honestly 0 in Phase 1) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite | `bash tools/test.sh` | 190/190, 1352 asserts, exit 0 | PASS |
| Lint + format | `bash tools/lint.sh` | clean, exit 0 | PASS |
| CI on phase branch | `gh run view 36561636852 --repo ABSAR07/duskhold` | 4/4 jobs success, 3 artifacts | PASS |
| Windows export present | `ls build/windows` | Duskhold.exe + Duskhold.pck | PASS |
| Screenshots present and non-empty | `ls screenshots` | 6 PNGs 41-77 KB | PASS |
| No mouse gameplay binding | grep `InputEventMouse` in project.godot and code; `test_input_map` | none bound; test asserts it | PASS |

The full suite was run once, as the constraint requires; no per-truth re-runs.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED (the equivalent evidence is the GUT suite and CI run above).

### Requirements Coverage

All 15 IDs in the ROADMAP Phase 1 requirement list appear in at least one PLAN `requirements:` field, and all are marked `[x]` in REQUIREMENTS.md. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king.gd, test_king_ride, test_input_map |
| KING-02 | 01-04 | SATISFIED | camera_rig.gd fixed-offset rig; camera tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | BuildingSystem spot-only, `unknown_spot` rejection, 8-spot map, tests |
| BLDG-02 | 01-05, 01-06 | SATISFIED | world-space spot label, model + e2e tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller + coin drip + refund tests |
| BLDG-04 | 01-05 | SATISFIED | test_upgrade_flow (cost/effect shown, max_tier rejection) |
| BLDG-06 | 01-09 | SATISFIED | not_day guard in validate_build and submit; mid-hold cancel on night start |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, Economy never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | House income 1/2/3 by tier paid at dawn, visible payout VFX |
| ECON-07 | 01-09 | SATISFIED | test_loop_gold_carryover |
| ART-02 | 01-07 | SATISFIED (see licence note) | attribution.json, ASSETS.md, test_attribution_log |
| DEV-01 | 01-01, 01-02 | SATISFIED | RunContext built without scene tree; 190 headless tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED | ci.yml green with lint, test, export, screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | Overlay covers FPS, unit/enemy counts, loop state; wave state/pathing deferred to Phase 2 per ROADMAP SC5 |
| DEV-04 | 01-10 | SATISFIED | tools/screenshot.sh + shot_runner (headless guard, blank check), six PNGs, CI job |

### Anti-Patterns Found

Scan of `simulation input presentation ui tools tests data .github` for `TBD|FIXME|XXX|TODO|HACK`: no matches (no debt-marker blockers).

Code-review findings (01-REVIEW.md, 0 critical / 9 warning / 8 info, all `open`) were assessed against the goal. None breaks a success criterion, so none is a gap:

| Finding | Severity | Impact on Phase 1 goal |
|---------|----------|------------------------|
| WR-01 MapRoot binds every run_bound node in the tree | Warning | Only bites when two MapRoots coexist (restart/map-select, Phase 2+); single-map goal unaffected. Fix before Phase 2 adds run restart |
| WR-02 Dawn payout readout lag unbounded and HUD gold clamp missing | Warning | Irrelevant at current 1 to 3 gold per House (payout <= 15 gold lasts under 2 s); becomes real with larger incomes |
| WR-06 Horse licence (Quaternius QAL vs CC0-only constraint) | Warning | Owner knowingly approved; disclosed in attribution notes. Needs an explicit owner decision before itch.io (human item 7) |
| WR-07 Unclamped simulation delta | Warning | A stall can skip the 4 s placeholder night; harmless now, matters when Phase 2 adds wave timers |
| WR-03/04/05/08/09 Tooling robustness | Warning | Affect `bootstrap.py --all` and Windows re-download paths, not the CI or the verified wrappers |

### Human Verification Required

See the `human_verification` list in the frontmatter. These are the end-of-phase items the executors deferred (`human_verify_mode = end-of-phase`): riding and camera feel on keyboard and gamepad, map readability, spot-label readability (title/effect overlap in the screenshot) and coin-drip feel, model look (T-pose rider, small horse), F3 overlay look, the day to night to dawn to day feel (dawn lighting mostly night-coloured in the capture), and the horse licence decision.

### Gaps Summary

No gaps. Every ROADMAP success criterion is backed by code I read and by passing tests I ran (190/190 locally, 4/4 CI jobs on 981e4c8). Two minor process notes: local HEAD (e6579d5) is two docs-only commits ahead of the CI-verified origin commit 981e4c8, so CI has not yet run on the final HEAD; and `.planning/config.json` is uncommitted. Status is `human_needed` solely because visual and game-feel judgments cannot be verified programmatically and the horse-licence decision is an open owner call.

---

_Verified: 2026-09-29_
_Verifier: Claude (gsd-verifier)_
