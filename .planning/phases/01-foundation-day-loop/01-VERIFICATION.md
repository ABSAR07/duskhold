---
phase: 01-foundation-day-loop
verified: 2026-09-30T07:20:46Z
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
covered_digest: "v2:sha256:473ef6d725f40437f48973e68e11427c7daa695fbf8781a162577ed4e22fd1a1"
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
    evidence: "ROADMAP Phase 1 SC5: 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3 requires 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "Review 5 WR-01: Hud._key_text names a physical key by its US-QWERTY position (as_text_physical_keycode), so on Dvorak/AZERTY the 'Hold N' prompt can name the wrong keycap"
    category: other
    reason: "Default binding is N / gamepad Y; no rebinding UI until Phase 13 and no SC covers layout-aware labels. Recorded open in 01-REVIEW-DISPOSITION.md."
    evidence_status: "review text; source read (ui/hud/hud.gd lines 181-190)"
  - finding: "Review 5 WR-02: DebugOverlayModel silently drops providers that take (even defaulted) arguments or are invalid Callables"
    category: other
    reason: "Extension point is first used in Phase 2; the shipped default sections work and are test-covered."
    evidence_status: "review text; source read (ui/overlay/debug_overlay_model.gd)"
  - finding: "Review 5 WR-03: BuildingSystem does not skip a BuildingDef whose id is empty (spots with an empty id are now skipped)"
    category: other
    reason: "MapConfig.validate() reports it and the shipped prototype map is valid; no SC affected."
    evidence_status: "review text; source read (simulation/buildings/building_system.gd lines 16-20)"
  - finding: "Review 5 IN-01..IN-05 (in-place rebind not detected, joypad axis direction hidden, tautological last-lands test, double-bind test covers only 4 signals, coin start point behind camera)"
    category: other
    reason: "Info-level; none touches a success criterion."
    evidence_status: "review text"
  - finding: "CI trigger is main, master and gsd/** pushes plus all PRs, not literally every push"
    category: other
    reason: "ROADMAP SC4 / DEV-02 say 'on every push'; pushes to other branch names are covered only via a PR. Acceptable for a solo repo; owner may record an override."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "build/windows/Duskhold.exe is a local artifact older than the latest fix commits, and origin's last green CI run (981e4c8) is 96 commits behind HEAD (1d0601f); nothing is pushed"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current."
    evidence_status: "file listing; git rev-list --count 981e4c8..HEAD = 96"
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
  - test: "Hold N (and gamepad Y) for 1.5 s, then watch night banner, lighting, dawn payout and return to Day as 'Night 2'. Pass-5 change to watch specifically: the gold counter must stay lagged while coins fly, tick up as each coin lands, and be exactly the ledger gold once dawn ends (never stuck low, never ahead of the coins)"
    expected: "Prompt fills, banner and night lighting show, dawn coins fly from each paying House to the gold counter, '+X gold' appears, day returns with carried-over gold"
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight. The readout lag now comes from DawnPayoutVfx.payout_started and is released on leaving DAWN; tests cover the arithmetic, only a human can judge the on-screen feel"
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T07:20:46Z
**Status:** human_needed (every automated check passes and no must-have fails; remaining items are visual/feel judgments plus one owner licence decision)
**Re-verification:** Yes. The previous report went stale after review-fix pass 5 (9 fix commits e83e5e0..17c661d) changed `simulation/buildings/building_system.gd`, `ui/hud/dawn_payout_vfx.gd`, `ui/hud/hud.gd` and `ui/overlay/debug_overlay_model.gd`. I read the full source diff of those four files (`git diff a3b5b4a..17c661d -- simulation ui presentation input`) and re-checked every truth against the current tree (HEAD 1d0601f; only docs commits follow 17c661d). No regressions.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | King, camera rig, spot-label sources untouched by pass 5; their tests are in the 227/227 run I executed. `MapRoot` builds the `RunContext` and calls `bind_run` on the run-bound nodes. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd`, `build_hold_controller.gd` untouched. The only pass-5 change in this path is `BuildingSystem.apply_next_tier` returning null (no mutation) for a missing tier def, and empty-id spots being skipped: strictly more guarded. Build-hold, refund, phase-guard, upgrade and denied tests pass. |
| 3 | Gold is the only currency and on the HUD; ending the day via the placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` untouched: `_apply_dawn_payout` grants the total then emits `dawn_payout`. Pass-5 change read in full: `DawnPayoutVfx._on_dawn_payout` sums positive per-spot amounts, plans every coin, emits `payout_started(carried)` before scheduling, and the HUD sets `_payout_pending` from it, decrements per `coin_landed`, and zeroes it when the phase leaves DAWN. Signal order is safe: `grant` fires `gold_changed` (full readout) then `payout_started` lowers it synchronously in the same call stack, so no visible frame. CR-01 line still schedules with the computed `stagger` (`float(launches.size()) * stagger`). Dawn income, payout, carryover, start-night hold tests pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see advisory) | I ran `bash tools/lint.sh`: 65 files unchanged, no problems. I ran `bash tools/test.sh` once: 31 scripts, 227/227 tests, 1484 asserts, exit 0. `ci.yml` defines lint, test, export (`needs` lint+test) and screenshots jobs using the same `tools/*.sh` wrappers. `screenshots/` holds 6 PNGs; `build/windows/Duskhold.exe` and `.pck` exist. Origin's last green CI run is 981e4c8; 96 local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` pass-5 change: `register_section` now replaces an existing title in place (no duplicate section). Overlay model/toggle/read-only tests and the attribution-coverage test pass; `assets/attribution.json` present. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing, carryover, HUD lag release) are exercised by named GUT tests that passed in the run above. The CR-01 stagger guard (`test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window`) now asserts on `get_launch_delays()` (last delay == `(n-1) * launch_stagger(n)`, plus trip time within the dawn window), which is a discriminating check, not a wall-clock wait; the orchestrator's revert probe (14/15 failing with the stagger line reverted) corroborates it. I did not repeat that probe.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

See the `advisory` frontmatter list. Fresh review 01-REVIEW.md (0 critical, 3 warnings, 5 info, all recorded open in 01-REVIEW-DISPOSITION.md) was cross-checked against the code; none breaks a ROADMAP success criterion or PLAN must-have. Prior-pass advisories WR-05 (weak CR-01 test), WR-02 (HUD payout state derived independently of the VFX), WR-03 (soft coin cap) and WR-04 (empty-id spot, unguarded apply_next_tier) are now resolved by the pass-5 code and tests; the start-night hint's joypad-motion, mouse and modifier handling (old WR-01) is also fixed.

### Required Artifacts

`gsd_run query verify.artifacts` on all ten PLAN frontmatters, run this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5 (all exist, none stub).

### Key Link Verification

`gsd_run query verify.key-links`: 29 of 30 verified. The one miss is plan 01's `tools/godot.sh -> tools/godot_version.txt`: `godot.sh` sources `_common.sh`, which reads the pin (`_common.sh:23`). Wired; the plan named the wrong file.

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_bound nodes | `RunContext.new`, then `bind_run` (map_root.gd:25) | WIRED |
| hud | dawn_payout_vfx | `payout_started`, `coin_landed` (hud.gd:63-64) | WIRED |
| dawn_payout_vfx | sim_events | `dawn_payout.connect(_on_dawn_payout)` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX | per_spot amounts | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` | Yes | FLOWING |
| Start-night prompt | key names | `InputMap.action_get_events(&"start_night")` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 31 scripts, 227/227, 1484 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 65 files unchanged, no problems | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshots on disk | `ls screenshots` | 6 PNGs (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label) | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (local artifact, older than fixes) | PASS |

I relied on the orchestrator's reported results for `tools/screenshot.sh` (6/6 non-blank PNGs), the headless screenshot guard (exit 2), `tools/prepush_check.sh` (PASSED) and the CR-01-reverted experiment; I did not re-run them. Remote CI was not queried.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters (01: DEV-01, DEV-02; 02: BLDG-01, BLDG-03, ECON-01, KING-01, DEV-01; 03: DEV-02; 04: KING-01, KING-02; 05: BLDG-01, BLDG-02, BLDG-04; 06: BLDG-02, BLDG-03; 07: ART-02; 08: DEV-03; 09: BLDG-06, ECON-01, ECON-02, ECON-07; 10: DEV-04, DEV-02, ECON-02) is exactly the 15 ROADMAP Phase 1 IDs. All 15 are "Phase 1 / Complete" in the REQUIREMENTS.md traceability table. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king ride and input-map tests |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem, unknown/empty-id spot rejection |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model and world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | upgrade flow test |
| BLDG-06 | 01-09 | SATISFIED | NOT_DAY guard, mid-hold cancel, phase-guard test |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, gold never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income and payout tests |
| ECON-07 | 01-09 | SATISFIED | gold carryover test |
| ART-02 | 01-07 | SATISFIED (horse licence decision pending) | attribution.json, coverage test |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 227 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-5 files. No blocker anti-patterns. Open review warnings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter (7 items, matching the 7 pending items in 01-UAT.md; item 6 now flags the pass-5 HUD payout-lag behaviour). Non-UAT recommendation: push the 96 local commits and confirm CI is green on the new HEAD, since DEV-02's remote evidence still comes from 981e4c8.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (227/227, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-30T07:20:46Z_
_Verifier: Claude (gsd-verifier)_
