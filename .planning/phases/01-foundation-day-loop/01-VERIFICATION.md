---
phase: 01-foundation-day-loop
verified: 2026-09-30T08:21:08Z
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
covered_digest: "v2:sha256:91401e98cb3d8601e29171da298c46ae1d711497913a72afc71e1e8417fad71c"
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
  - finding: "Review 7 WR-01: DawnPayoutVfx._whole_amounts validates amount types but not spot keys or non-finite floats, so a non-string key still aborts _on_dawn_payout after payout_started was skipped"
    category: other
    reason: "Hardening gap in a defensive path. RunManager always emits StringName keys and int amounts, so it cannot occur with the shipped payout source. Recorded open in 01-REVIEW-DISPOSITION.md."
    evidence_status: "review text; source read (ui/hud/dawn_payout_vfx.gd _whole_amounts, this pass)"
  - finding: "Review 7 WR-02: the '+X gold' label shows the claimed total while coins and the HUD readout use the carried gold; they diverge only if per_spot does not sum to total"
    category: other
    reason: "With the real RunManager (_apply_dawn_payout sums per_spot into total) the two are always equal; matters only when Phase 2 adds payout sources. Recorded open."
    evidence_status: "review text; run_manager.gd _apply_dawn_payout read this pass"
  - finding: "Review 7 IN-01..IN-03 (per-coin scheduling tweens not killed on payout reset; _count_buildings now allocates a snapshot per spot per refresh; a registered overlay section titled like a default section shows twice)"
    category: other
    reason: "Info-level; generation guard makes the tweens harmless; none touches a success criterion. Recorded open."
    evidence_status: "review text"
  - finding: "CI trigger is main, master and gsd/** pushes plus all PRs, not literally every push"
    category: other
    reason: "ROADMAP SC4 / DEV-02 say 'on every push'; pushes to other branch names are covered only via a PR. Acceptable for a solo repo; owner may record an override."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "build/windows/Duskhold.exe (Sep 29 21:57) is a local artifact older than the latest fix commits, and origin's last green CI run (981e4c8) is many commits behind HEAD; nothing is pushed"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current."
    evidence_status: "file listing; orchestrator report"
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
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight. The readout lag now comes from DawnPayoutVfx.payout_started and is released on leaving DAWN; tests cover the arithmetic, only a human can judge the on-screen feel. Pass 7 also removed the HUD's night_started/day_started handlers, so also confirm the start-night prompt and night banner still appear and disappear at the right moments in a real run"
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): Hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "Pass 6 names the key via DisplayServer.keyboard_get_label_from_physical, which is unavailable headless; only a fake-layout resolver seam is unit-tested, so the real OS-layout call is unexercised (also listed as manual-only in 01-VALIDATION.md)"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T08:21:08Z
**Status:** human_needed (every automated check passes and no must-have fails; remaining items are visual/feel judgments, one non-QWERTY layout check, and one owner licence decision)
**Re-verification:** Yes. The previous report went stale after review-fix pass 7 (6 fix commits b789dde..d4ef4f5) changed `simulation/buildings/building_system.gd`, `ui/hud/dawn_payout_vfx.gd`, `ui/hud/hud.gd` and `ui/overlay/debug_overlay_model.gd`. I read the full source diff (`git diff 1c3e320 HEAD -- simulation ui`), traced every caller of the changed APIs, and re-ran lint and the full test suite on HEAD 85cc110. No regressions.

## Pass-7 change audit (what changed, and whether it breaks a truth)

| Change | Source read | Impact |
|--------|-------------|--------|
| `BuildingSystem.get_instance` / `apply_next_tier` return `_snapshot` copies | `building_system.gd` lines 54, 118-141 | Internal reads (`current_tier`, `dawn_income_by_spot`, `apply_next_tier`) now read `_instances` directly, so payout and tier logic still see the live state. The only external callers are `command_processor.gd:67` (discards the return value) and `debug_overlay_model.gd:115` (null test only). No consumer relied on mutating a returned instance. Build/upgrade and dawn income unchanged. |
| HUD drops `night_started` / `day_started` handlers | `hud.gd` `_on_phase_changed` | `RunManager.start_night` increments `_night_number` before `_change_phase`, and `_enter_day` increments `_day_number` before `_change_phase`; `phase_changed` is emitted at the end of `_change_phase` after `_phase` is set. So `_refresh_loop` on `phase_changed` alone sees current phase and numbers. Prompt/banner logic intact (real-run feel still a human item). |
| `DawnPayoutVfx._whole_amounts` coerces amounts to int | `dawn_payout_vfx.gd` lines 125-175 | Real payout source emits int amounts with StringName keys, so behaviour is identical; non-numeric amounts are dropped with a warning. Residual key-validation gap is advisory WR-01. |
| Overlay provider warn-once for non-Array, erase on re-register | `debug_overlay_model.gd` lines 24-53 | Additive diagnostics; default sections unchanged. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | King, camera rig and spot-label sources untouched since the last verification; their tests are in the 235/235 run I executed this pass. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd` and `build_hold_controller.gd` untouched; `apply_next_tier` still performs the mutation (snapshot return is discarded by its only caller). Build, upgrade, affordability, range and NOT_DAY tests pass. |
| 3 | Gold is the only currency and on the HUD; ending the day via the placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` untouched (`_apply_dawn_payout` reads `dawn_income_by_spot`, grants once per DAWN entry, nothing resets gold). Dawn income, payout VFX (including the CR-01 guard, which the orchestrator re-probed as discriminating), carryover and start-night hold tests pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see advisory) | I ran `bash tools/lint.sh`: 65 files unchanged, no problems. I ran `bash tools/test.sh` once: 31 scripts, 235/235 tests, 1536 asserts, exit 0. `ci.yml` defines lint, test, export and screenshots jobs using the same `tools/*.sh` wrappers. `screenshots/` holds 6 PNGs (regenerated today 13:13 local); `build/windows/Duskhold.exe` and `.pck` exist. Origin's last green CI run is 981e4c8; local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` pass-7 change is additive; new `test_debug_overlay_readonly.gd` case passes; default sections and read-only behaviour covered. `assets/attribution.json` present, coverage test passes. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation) are exercised by named GUT tests inside the 235/235 run. The snapshot contract has a new case in `tests/unit/test_build_spot.gd`; the HUD phase-change-only refresh is exercised by `test_start_night_hold.gd` driving a real dawn end. Only the real `keyboard_get_label_from_physical` call cannot run headless, so it stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

See the `advisory` frontmatter list. Fresh review 01-REVIEW.md (0 critical, 2 warnings, 3 info, all recorded open in 01-REVIEW-DISPOSITION.md) was cross-checked against the code; neither warning is reachable with the shipped payout source and none breaks a ROADMAP success criterion or PLAN must-have.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters, run this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5 (all exist, none stub).

### Key Link Verification

`gsd-tools query verify.key-links`: 29 of 30 verified. The one miss is plan 01's `tools/godot.sh -> tools/godot_version.txt`: `godot.sh` sources `_common.sh`, which reads the pin (`_common.sh:23`, confirmed this pass). Wired; the plan named the wrong file.

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` (line 67) | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_bound nodes | `RunContext.new`, then `bind_run` | WIRED |
| hud | dawn_payout_vfx | `payout_started`, `coin_landed` | WIRED |
| hud | run_manager | `phase_changed` -> `_on_phase_changed` -> `_refresh_loop` | WIRED |
| dawn_payout_vfx | sim_events | `dawn_payout.connect(_on_dawn_payout)` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX | per_spot amounts | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, building count, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 31 scripts, 235/235, 1536 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 65 files unchanged, no problems | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshots on disk | `ls screenshots` | 6 PNGs (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label) | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (local artifact, older than fixes) | PASS |

I relied on the orchestrator's reported results for `tools/screenshot.sh` (6/6 non-blank PNGs), the headless screenshot guard (exit 2), `tools/prepush_check.sh` (PASSED) and the CR-01-reverted experiment (16/17 fail); I did not re-run them. Remote CI was not queried.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters (re-extracted this pass: ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02) is exactly the 15 ROADMAP Phase 1 IDs. All 15 are `[x]` and "Phase 1 / Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king ride and input-map tests |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem, unknown/empty-id spot and def rejection |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model and world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | upgrade flow test |
| BLDG-06 | 01-09 | SATISFIED | NOT_DAY guard, mid-hold cancel, phase-guard test |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, gold never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income and payout tests |
| ECON-07 | 01-09 | SATISFIED | gold carryover test |
| ART-02 | 01-07 | SATISFIED (horse licence decision pending) | attribution.json, coverage test |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 235 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-7 files. No blocker anti-patterns. Open review warnings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter: 8 items, wording unchanged from the previous report (item 6 gains one clause about confirming the start-night prompt and banner still toggle correctly after the HUD handler removal), matching the 8 pending items in 01-UAT.md. Non-UAT recommendation: push the local commits and confirm CI is green on the new HEAD, since DEV-02's remote evidence still comes from 981e4c8.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (235/235, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-30T08:21:08Z_
_Verifier: Claude (gsd-verifier)_
