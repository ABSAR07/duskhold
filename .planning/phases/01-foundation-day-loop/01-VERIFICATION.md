---
phase: 01-foundation-day-loop
verified: 2026-09-29T16:56:23Z
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
covered_digest: "v2:sha256:698c3cc5e4514e878dd2d4e2c42d1bba219187c4ce3ce1b11d8e11745d8e664c"
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
  - finding: "Review 3 WR-01: DawnPayoutVfx.bind_run has no idempotency guard (Hud.bind_run now has one) and the 'bind again' test only exercises the HUD"
    category: other
    reason: "MapRoot._ready binds each run_bound node exactly once per MapRoot; no re-bind path exists in the shipped game. Not in any ROADMAP SC or PLAN must_have. Recorded open in 01-REVIEW-DISPOSITION.md."
    evidence_status: "source read (presentation/map/map_root.gd, ui/hud/dawn_payout_vfx.gd); no failing test"
  - finding: "Review 3 WR-02: start-night prompt hint is rebuilt only on phase/day/night signals, so a runtime rebind does not update it until the next phase change"
    category: other
    reason: "No rebind UI exists yet (input rebinding is a later phase). Placeholder prompt copy; no SC covers it."
    evidence_status: "source read (ui/hud/hud.gd _refresh_loop / _start_night_hint); no failing test"
  - finding: "Review 3 WR-03: wall-clock slack assertion (1.0 s dawn + 0.5 s) in test_a_real_payout_lands_every_coin_inside_a_short_dawn_window and fixed waits in the dawn hand-back test can flake on a slow runner"
    category: other
    reason: "Test-reliability only; passed here (215/215). Worth fixing before relying on CI as a hard gate."
    evidence_status: "review text; suite green 215/215 here"
  - finding: "Review 3 WR-04/WR-05: BuildingSystem keeps first spot but last building def on duplicate ids; spot_ids() returns the internal order array"
    category: other
    reason: "Data errors are already reported by MapConfig.validate(); the shipped prototype map is test-covered; no caller mutates the array."
    evidence_status: "source read (simulation/buildings/building_system.gd); no failing test"
  - finding: "Review 3 IN-01..IN-04 and earlier open items (IN-03 CI double-run of a gsd/** branch once a PR is open)"
    category: other
    reason: "Info-level; CI double-run is a pending owner decision (ci.yml untouched)."
    evidence_status: "review text"
  - finding: "CI trigger is main, master and gsd/** pushes plus all PRs, not literally every push"
    category: other
    reason: "ROADMAP SC4 / DEV-02 say 'on every push'; pushes to other branch names are covered only via a PR. Acceptable for a solo repo; owner may record an override."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "build/windows/Duskhold.exe is a local artifact older than the latest fix commits"
    category: other
    reason: "CI rebuilds the export from the pushed tree; re-run tools/export.sh if the local build is to be shipped."
    evidence_status: "file listing"
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
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-29T16:56:23Z
**Status:** human_needed (every automated check passes and no must-have fails; the remaining items are visual/feel judgments plus one owner licence decision)
**Re-verification:** Yes. The previous report went stale after review-fix pass 3 (7 fix commits ecea4ff..9cae015, touching `simulation/buildings/building_system.gd`, `ui/hud/dawn_payout_vfx.gd`, `ui/hud/hud.gd`, `ui/overlay/debug_overlay_model.gd` plus tests). I read the full source diff of that pass and re-checked every truth against the current tree (HEAD c8e4a6b). No regressions. The source has not changed since 9cae015 (only docs commits follow).

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | King, camera rig and spot label sources unchanged by pass 3. `MapRoot._ready` builds the `RunContext`, places the king at `map_config.king_spawn` and binds every `run_bound` node (CameraRig, SpotLabel, HUD, etc. are in `prototype_map.tscn`). King/camera/spot-label tests are in the 215/215 run. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd` and `build_hold_controller.gd` not touched by pass 3. `BuildingSystem` change only de-duplicates spot ids (`_spots.has(spot.id)`) so `spot_ids()` stays unique. Build-hold, refund, phase-guard, upgrade and denied tests pass. |
| 3 | Gold is the only currency and is on the HUD; ending the day through the placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` unchanged. `BuildingSystem.dawn_income_by_spot` now skips instances whose building def is missing instead of hard-indexing `_defs`; the paying path is unchanged. HUD gold readout, `DawnPayoutVfx` stagger (`launch_stagger` now guards `_ctx == null`) and `_start_point` (null camera or spot falls back to screen centre) verified in the diff. `test_dawn_income`, `test_dawn_payout`, `test_loop_gold_carryover`, `test_start_night_hold` all pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see advisory) | I ran `bash tools/lint.sh`: 65 files unchanged, no problems. I ran `bash tools/test.sh` once: 31 scripts, 215/215, 1439 asserts, exit 0. `ci.yml` has lint, test, export (`needs: [lint, test]`) and screenshots (`needs: [test]`) jobs. `screenshots/` holds 6 PNGs; `build/windows/Duskhold.exe` and `.pck` exist. Last green CI run on origin is 981e4c8 (`gh run list`: success, 2m36s); 65 local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` now normalises provider rows to `[label, value]` strings via `_clean_rows` and still skips invalid providers and non-Array returns. Overlay model/toggle/read-only tests (the read-only test now watches every simulation signal) and `test_attribution_log` pass; `assets/attribution.json` present. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing, carryover) are each exercised by a named GUT test that passed in the run above, not just by symbol presence.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

See the `advisory` frontmatter list. Fresh review 01-REVIEW.md (0 critical, 5 warnings, 4 info, all recorded open in the disposition) was cross-checked against the code: none of them breaks a ROADMAP success criterion or a PLAN must-have. The most notable are the un-guarded `DawnPayoutVfx.bind_run` (unreachable, MapRoot binds once), the start-night hint not refreshing on a runtime rebind (no rebind UI yet) and one wall-clock slack assertion in an e2e test (potential CI flake). CI narrowing to `main`, `master`, `gsd/**` pushes plus PRs is a deviation from the literal "every push" wording.

### Required Artifacts

`gsd_run query verify.artifacts` on all ten PLAN frontmatters: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5 (all exist, none stub). No orphans; spot-read this pass: `building_system.gd`, `hud.gd`, `dawn_payout_vfx.gd`, `debug_overlay_model.gd`, `map_root.gd`, `ci.yml`.

### Key Link Verification

`gsd_run query verify.key-links`: 29 of 30 links verified by pattern. The one miss is plan 01's `tools/godot.sh -> tools/godot_version.txt`: the pattern is absent from `godot.sh` itself, but the pin is read one hop away in `tools/_common.sh` (`DUSKHOLD_GODOT_VERSION="$(tr -d '\r\n' < .../tools/godot_version.txt)"`), which `godot.sh` sources. It is wired; the plan named the wrong file.

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_bound nodes | `RunContext.new`, then `bind_run` on own-subtree nodes only | WIRED |
| hud | sim_events / dawn_payout_vfx | `dawn_payout`, `coin_landed` (connected once, guarded by `_ctx`) | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins | `Economy.get_gold()`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX | per_spot amounts | `SimEvents.dawn_payout` from `dawn_income_by_spot()` over real instances | Yes | FLOWING |
| Start-night prompt | key names | `InputMap.action_get_events(&"start_night")` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 31 scripts, 215/215, 1439 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 65 files unchanged, no problems | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshots on disk | `ls screenshots` | 6 PNGs | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (local artifact, older than fixes) | PASS |
| Remote CI | `gh run list` | 981e4c8 success (older than HEAD) | PASS (stale) |

I relied on the orchestrator's reported results for `tools/screenshot.sh` (6/6 non-blank PNGs), the headless screenshot guard (exit 2) and `tools/prepush_check.sh` (PASSED); I did not re-run them.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is exactly the 15 ROADMAP Phase 1 IDs (ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02). All are `[x]` / "Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king ride and input-map tests |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem, unknown-spot rejection |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model and world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | upgrade flow test |
| BLDG-06 | 01-09 | SATISFIED | NOT_DAY guard, mid-hold cancel, phase-guard test |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, gold never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income and payout VFX tests |
| ECON-07 | 01-09 | SATISFIED | gold carryover test |
| ART-02 | 01-07 | SATISFIED (licence note: horse decision pending) | attribution.json, coverage test |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 215 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in the phase's source or tests. No stubs, hollow props or static-return data paths in the pass-3 files. No blocker or warning anti-patterns; the open review warnings are listed as advisories.

### Human Verification Required

See the `human_verification` list in the frontmatter (7 items, identical to the pending items in 01-UAT.md). Non-UAT recommendation: push the 65 local commits and confirm CI is green on the new HEAD, since DEV-02's remote CI evidence still comes from 981e4c8.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (215/215, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX feel and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-29T16:56:23Z_
_Verifier: Claude (gsd-verifier)_
