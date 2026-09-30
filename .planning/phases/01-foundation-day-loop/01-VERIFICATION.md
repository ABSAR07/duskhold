---
phase: 01-foundation-day-loop
verified: 2026-09-30T10:34:07Z
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
  - "tests/e2e/test_dawn_payout_hardening.gd"
  - "tests/unit/test_debug_overlay_registration.gd"
  - "tests/unit/test_debug_overlay_timed_phases.gd"
  - "tools/screenshot.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:3d66d2cf130178ec4974393f34561654a7e51006c94fef4fe98bf0ae853d6ba8"
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
  - finding: "Review 12 (01-REVIEW.md, 8 files) records 0 critical, 2 warnings and 3 info, all open in 01-REVIEW-DISPOSITION.md. WR-01: DebugOverlayModel._clean_rows drops malformed provider rows silently (every other provider fault warns once). WR-02: DawnPayoutVfx gives no warning when total <= 0 but per_spot lists gold, and the total > 0 with carried == 0 path has no e2e test. IN-01: _is_gone and _skip_reason duplicate the owner/validity checks. IN-02: the read-only test snapshots only part of the simulation state. IN-03: the registration tests set visible directly and depend on a 0.35 s wall-clock wait"
    category: other
    reason: "All five sit in the debug overlay, the dawn payout view and their tests. No first-party code registers an overlay section yet (only tests do), and the real RunManager always emits a total equal to the sum of per_spot, so neither warning is reachable from shipped Phase 1 behaviour. None breaks a ROADMAP success criterion or a PLAN must-have. WR-01 lands naturally with Phase 2, which registers the first real providers."
    evidence_status: "ui/overlay/debug_overlay_model.gd, ui/hud/dawn_payout_vfx.gd and simulation/run/run_manager.gd read this pass; grep register_section shows only test callers"
  - finding: "CI trigger is main, master and gsd/** pushes plus all pull requests, not literally every push"
    category: other
    reason: "ROADMAP SC4 and DEV-02 say 'on every push'; pushes to other branch names are covered only via a pull request. Owner-pending decision (record an override or widen the trigger)."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "The review-fix commits are not pushed: origin/gsd/phase-01-foundation-day-loop is still 981e4c8 and the local branch is 182 commits ahead; build/windows/Duskhold.exe (Sep 29 21:57) predates the latest fixes"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current. Owner-pending."
    evidence_status: "git branch -vv (ahead 182); git ls-remote --heads origin; file listing"
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
  - test: "Hold N (and gamepad Y) for 1.5 s, then watch night banner, lighting, dawn payout and return to Day as 'Night 2'. Watch specifically: the gold counter must stay lagged while coins fly, tick up as each coin lands, and be exactly the ledger gold once dawn ends (never stuck low, never ahead of the coins)"
    expected: "Prompt fills, banner and night lighting show, dawn coins fly from each paying House to the gold counter, '+X gold' appears, day returns with carried-over gold"
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight. The landing margin (last coin scheduled 0.15 s before dawn ends) is covered by tests, but only a human can judge the on-screen feel and that the prompt and banner appear and disappear at the right moments in a real run"
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical (ui/hud/hud.gd line 189), which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD"
    expected: "Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, the current origin tip; the local branch is 182 commits ahead)"
    why_human: "Owner policy decision, and remote CI state cannot be observed from this environment"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T10:34:07Z
**Status:** human_needed (every automated check passes and no must-have fails; the remaining items are feel and visual judgments, a non-QWERTY layout check, and owner decisions on the horse licence and the CI trigger and push)
**Re-verification:** Yes. The previous report (human_needed, 5/5) went stale after review-fix pass 12 changed `ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd` and `ui/hud/dawn_payout_vfx.gd` and added three test files. I regenerated every verdict from the current tree at HEAD 714c573 and did not copy the old ones.

## Pass-12 change audit

`git diff 43755b7 HEAD` outside `.planning` touches 8 files: the three UI files below and five test files. `simulation`, `presentation`, `input`, `.github`, `tools` and `project.godot` are unchanged; only `.planning/config.json` is modified in the working tree.

| Change | Source read | Impact on a truth |
|--------|-------------|-------------------|
| `DebugOverlay.register_section` holds sections registered before `bind_run` in `_pending` (owner kept as a `WeakRef`) and `bind_run` replays them in order, warning and skipping an owner that was freed in the meantime; a repeat `bind_run` returns early (`if _model != null: return`) | `debug_overlay.gd` lines 20-58 | Closes the old WR-01 (silent no-op before bind). Additive to SC5. Built-in Perf, Loop and Agents sections are untouched. Covered by `test_debug_overlay_registration.gd` (early registration, order, repeat bind, freed owner, parameter not named `owner`). |
| Parameter renamed `owner` to `lifetime_owner` in both `register_section` signatures | `debug_overlay.gd` line 51, `debug_overlay_model.gd` line 39 | Naming only; a test reads the script's method list to keep it from shadowing `Node.owner`. |
| Model keeps registered sections in a Dictionary keyed by title (replace in place, erase by title); default titles refused; freed-owner and invalid-callable entries dropped after one warning; warning re-arms after a provider recovers | `debug_overlay_model.gd` lines 16-100 | Closes old IN-03. Covered by the extended `test_debug_overlay_readonly.gd`. |
| Model Loop section adds a `Timer` row in NIGHT and DAWN only | `debug_overlay_model.gd` lines 126-140 | Closes old WR-02. Covered by `test_debug_overlay_timed_phases.gd`. |
| `DawnPayoutVfx` counts and frees only children in the `payout_coin` group (`COIN_GROUP`, `_coins()`); coins join the group at launch | `dawn_payout_vfx.gd` lines 40-43, 262-265, 292 | Closes old IN-01. Payout amounts, landing margin and HUD lag are unchanged. `live_coin_count`, `_reset_for_new_payout` and `_coins()` all go through the group. New test in `test_dawn_payout_hardening.gd`. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | King, camera rig and spot-label sources are unchanged since the last verification and their tests pass in this pass's full run (258/258). `day_overview.png` and `overlay_on.png` (viewed this pass) show the mounted king, the castle, two build plots, HUD gold and the start-night prompt. `verify.artifacts` reports every artifact present and non-stub for all ten plans. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (read this pass): NOT_DAY when `is_build_allowed()` is false, then UNKNOWN_SPOT when `get_spot` is null, then MAX_TIER when `next_action_cost < 0`, then CANNOT_AFFORD via `can_afford`, else OK. `submit` routes `BuildIntent` through the same validation. `RunManager.is_build_allowed()` is `_phase == RunPhase.DAY` (line 35-36). Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` (read this pass): `start_night` returns false unless the phase is DAY; `_enter_dawn` changes phase then `_apply_dawn_payout`, which sums `_buildings.dawn_income_by_spot()`, calls `_economy.grant(total)` and emits `dawn_payout(total, per_spot)`. Nothing in the gold path resets Economy between phases (`_enter_day` only bumps the day and emits), so unspent gold carries over. HUD gold is visible in `day_overview.png` and `dawn_payout.png` (Gold: 23 with coins in flight, lag working). Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED locally; CI on final HEAD not yet run and trigger narrower than "every push" (both owner-pending, see advisory) | I ran `bash tools/lint.sh` (68 files unchanged, no problems, exit 0) and `bash tools/test.sh` once (34 scripts, 258/258, 1691 asserts, exit 0). `ci.yml` defines lint, test, export and screenshots jobs through the same `tools/*.sh` wrappers, read-only token, actions pinned by SHA, trigger `push: [main, master, "gsd/**"]` plus `pull_request` and `workflow_dispatch`. `screenshots/` holds 6 PNGs stamped 15:26-15:27 local today (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label); I viewed overlay_on and dawn_payout and both are real renders. `build/windows/Duskhold.exe` and `.pck` exist (Sep 29 local artifact, stale). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` builds Perf, Loop (Phase, Day, Night, Gold, Buildings, plus Timer in NIGHT/DAWN) and Agents (Units, Enemies) rows plus registered sections; `overlay_on.png` (viewed) shows exactly those rows in the running scene. `debug_overlay.gd` toggles on `toggle_debug_overlay` in `_process` and refreshes every 0.25 s. Read-only, toggle, refresh, registration, timed-phase and owner/recovery tests pass. `assets/attribution.json` exists and its coverage test passes in the suite. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window with margin, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches, payout clamp, only-coins-are-counted, overlay pre-bind registration and repeat-bind idempotency, overlay warning re-arm, overlay owner-freed drop) each have a named GUT test inside the 258/258 run, so none is left present-but-unverified. Only the real `DisplayServer.keyboard_get_label_from_physical` call cannot run headless and stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings and owner-pending items, not must-have failures)

See the `advisory` frontmatter list. Review 12 is 0 critical, 2 warnings, 3 info, all open in 01-REVIEW-DISPOSITION.md. I confirmed WR-01 (silent row drop in `_clean_rows`) and WR-02 (no warning in the `total <= 0` branch of `_on_dawn_payout`) against the source. Both are unreachable from shipped Phase 1 behaviour: no first-party code registers a section, and `_apply_dawn_payout` always emits a total equal to the per-spot sum. Neither breaks a success criterion.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5. All exist, none stub.

### Key Link Verification

`gsd-tools query verify.key-links` this pass: plans 02-10 all verified. Plan 01 reports 2/3 because of one link, `tools/godot.sh -> tools/godot_version.txt` (pattern not found in `godot.sh`). `tools/_common.sh` line 23 reads the pin from `tools/godot_version.txt`, and `godot.sh` sources `_common.sh`, so the link is wired; the plan named the wrong file. Not a gap.

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_bound nodes | `RunContext.new`, then `bind_run` | WIRED |
| hud | dawn_payout_vfx | `payout_started`, `coin_landed` | WIRED |
| hud | run_manager | `phase_changed` -> `_refresh_loop` | WIRED |
| dawn_payout_vfx | sim_events | `dawn_payout.connect(_on_dawn_payout)` | WIRED |
| debug_overlay | debug_overlay_model | `bind_run` builds the model and replays `_pending` via `_model.register_section(title, provider, lifetime_owner)` | WIRED |
| debug_overlay_model | building_system | `current_tier(spot_id)` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started(carried)`, `coin_landed` | Yes (`dawn_payout.png` shows a lagged 23 with coins in flight) | FLOWING |
| Dawn payout VFX "+X gold" | carried gold from per_spot (clamped, coerced) | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, building count, timer, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 34 scripts, 258/258, 1691 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 68 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github, project.godot | no matches | PASS |
| Screenshots on disk | `ls -la screenshots` | 6 PNGs dated today; overlay_on and dawn_payout viewed and non-blank | PASS |
| Windows export on disk | `ls -la build/windows` | Duskhold.exe + Duskhold.pck (Sep 29 local artifact) | PASS (stale, see advisory) |

I did not re-run `tools/screenshot.sh` (the orchestrator reports 6/6 this iteration; the PNGs on disk carry that run's timestamps), `tools/export.sh` or `tools/prepush_check.sh`, and I did not query remote CI beyond `git ls-remote`, which shows the origin branch still at 981e4c8.

### Probe Execution

No `probe-*.sh` scripts are declared by any PLAN or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02: exactly the 15 IDs given for this verification. All 15 are checked `[x]` and `Phase 1 | Complete` in REQUIREMENTS.md. No orphaned Phase 1 requirements; BLDG-05 belongs to Phase 5.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | king ride and input-map tests |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | spot-only BuildingSystem; `validate_build` returns UNKNOWN_SPOT for any non-spot id |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model and world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | upgrade flow and MAX_TIER rejection |
| BLDG-06 | 01-09 | SATISFIED | `is_build_allowed()` is DAY-only; NOT_DAY rejection; mid-hold cancel tests |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label, gold never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income and payout tests |
| ECON-07 | 01-09 | SATISFIED | gold carryover test |
| ART-02 | 01-07 | SATISFIED (horse licence decision pending) | attribution.json and coverage test |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 258 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED locally (trigger narrower than "every push"; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-12 files (the `_pending` list and `_registered` dictionary are populated by `register_section` and consumed by `bind_run` and `collect`). No blocker anti-patterns. The open review findings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position. Item 9 (CI trigger decision plus push-and-confirm-green) has its `expected:` text refreshed to the current facts (origin tip 981e4c8, local branch 182 commits ahead); its `test:` wording is unchanged.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (258/258, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, the Quaternius horse licence, and the CI trigger and push confirmation cannot be verified programmatically or are owner decisions. ROADMAP.md still shows the Phase 1 checkbox unticked; that is the orchestrator's phase-completion step, not a verification gap.

---

_Verified: 2026-09-30T10:34:07Z_
_Verifier: Claude (gsd-verifier)_
