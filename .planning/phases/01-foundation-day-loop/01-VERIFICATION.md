---
phase: 01-foundation-day-loop
verified: 2026-09-30T11:05:17Z
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
  - "tests/unit/test_debug_overlay_readonly.gd"
  - "tests/unit/test_debug_overlay_registration.gd"
  - "tests/unit/test_debug_overlay_timed_phases.gd"
  - "tools/screenshot.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:3749f0918f311cce82f30258952ac8dcab33f3bc285924165f9d45d93ac49d67"
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
  - finding: "Review 13 (01-REVIEW.md) records 1 warning and 4 info, all test-suite hygiene or one overlay-model code-style point, no production defect. WR-01: SIM_SIGNALS is duplicated across test files and only one copy has a drift guard. IN-01: DebugOverlayModel branches on free-text reason strings (now mitigated by the REASON_* constants and the _is_gone derivation). IN-02: dead tuning setup in the hardening e2e test. IN-03: a test name and message say 'owner freed' for a no-owner case. IN-04: the clamp e2e test does not check what it claims about the amounts"
    category: other
    reason: "None sits on a shipped Phase 1 behaviour path and none breaks a ROADMAP success criterion or PLAN must-have. Dispositions are recorded in 01-REVIEW-DISPOSITION.md."
    evidence_status: "01-REVIEW.md headings read this pass; ui/overlay/debug_overlay_model.gd read in full"
  - finding: "CI trigger is main, master and gsd/** pushes plus all pull requests, not literally every push"
    category: other
    reason: "ROADMAP SC4 and DEV-02 say 'on every push'; 01-03 plan truth says 'every push to any branch'. Pushes to other branch names are covered only via a pull request. Owner-pending decision (record an override or widen the trigger)."
    evidence_status: ".github/workflows/ci.yml lines 9-12 and header comment lines 3-7"
  - finding: "The branch is not pushed: origin/gsd/phase-01-foundation-day-loop is still 981e4c8 and the local branch is 194 commits ahead; build/windows/Duskhold.exe (Sep 29 21:57) predates the latest fixes"
    category: other
    reason: "Plan 01-10's last truth ('the final phase state is pushed to origin and its CI run is green') and plan 01-03's 'first push and green CI' cannot be observed from this environment for the current HEAD. CI rebuilds the export from the pushed tree. Owner-pending."
    evidence_status: "git branch -vv (ahead 194); git ls-remote --heads origin returns 981e4c8; ls -la build/windows"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
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
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical (ui/hud/hud.gd), which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD"
    expected: "Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, the current origin tip; the local branch is 194 commits ahead)"
    why_human: "Owner policy decision, and remote CI state cannot be observed from this environment"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T11:05:17Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is feel and visual judgment, a non-QWERTY layout check, and owner decisions on the horse licence and on the CI trigger and push)
**Re-verification:** Yes. The previous report (human_needed, 5/5, HEAD 714c573) went stale after review-fix pass 13 changed `ui/overlay/debug_overlay_model.gd` and `ui/hud/dawn_payout_vfx.gd` and tightened or added four test files. I regenerated every verdict from the current tree at HEAD 48fc248 and did not copy the old ones.

## Pass-13 change audit

`git diff 714c573 HEAD` outside `.planning` touches 6 files: two source files and four test files. `simulation`, `presentation`, `input`, `.github`, `tools` and `project.godot` are unchanged. The working tree is clean except `.planning/config.json`.

| Change | Source read | Impact on a truth |
|--------|-------------|-------------------|
| `DebugOverlayModel.collect` now warns once per failure streak when a provider returns malformed rows (`dropped %d malformed row(s)`), and re-arms the warning when the provider returns only well-formed rows | `debug_overlay_model.gd` lines 77-85, 114-132 | Closes the old WR-01 (silent row drop). Additive to SC5. Built-in Perf, Loop and Agents sections untouched. |
| The permanent-failure check is derived from the skip reason: `_is_gone(skip_reason)` names `REASON_OWNER_FREED` and `REASON_CALLABLE_INVALID`; any other reason is transient | `debug_overlay_model.gd` lines 12-15, 93-111 | Removes the second copy of the owner/validity checks (old IN-01). Behaviour unchanged. |
| `DawnPayoutVfx._on_dawn_payout` warns when `total <= 0` but `per_spot` is non-empty, then still emits `payout_started(0)` and shows nothing | `dawn_payout_vfx.gd` lines 149-159 (diff read) | Closes the old WR-02. The real `RunManager._apply_dawn_payout` always emits `total` equal to the sum of `per_spot` (lines 111-118), so it is unreachable from shipped behaviour and is covered by two new e2e tests. |
| Tests: 2 new payout e2e tests (only-negative amounts; claims-no-gold-but-lists-amounts); overlay read-only, timed-phase and registration tests tightened | `git diff --stat` and the test diff read | Strengthens behavioural evidence for overlay read-only, timed phases and pre-bind registration; the full run passes. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | King, camera rig and spot-label sources are unchanged since the last verification, and their tests pass in this pass's full run (260/260). `overlay_on.png`, viewed this pass, shows the mounted king (rider T-pose on a small horse), the castle, two build plots and the HUD gold. `verify.artifacts` reports every artifact present and non-stub for all ten plans. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (lines 30-40, read this pass): NOT_DAY when `is_build_allowed()` is false, then UNKNOWN_SPOT when `get_spot` is null, then MAX_TIER when `next_action_cost < 0`, then CANNOT_AFFORD via `can_afford`, else OK. `submit` routes `BuildIntent` through the same validation. `RunManager.is_build_allowed()` is `_phase == RunPhase.DAY` (line 35-36). Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` `_apply_dawn_payout` (lines 111-118): sums `_buildings.dawn_income_by_spot()`, calls `_economy.grant(total)` when positive, emits `dawn_payout(total, per_spot)`. `_enter_day` only bumps the day and emits, so nothing resets gold and unspent gold carries over. `Gold: 30` is visible in `overlay_on.png`. Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED locally; CI on the final HEAD not yet run, and the trigger is narrower than "every push" (both owner-pending, see advisory and human item 9) | I ran `bash tools/lint.sh` (68 files unchanged, no problems, exit 0) and `bash tools/test.sh` once (34 scripts, 260/260, 1714 asserts, exit 0). `ci.yml` defines lint, test, export (`needs: [lint, test]`) and screenshots (`needs: [test]`) jobs through the same `tools/*.sh` wrappers, read-only token, actions pinned by SHA, trigger `push: [main, master, "gsd/**"]` plus `pull_request` and `workflow_dispatch`. `screenshots/` holds 6 PNGs stamped 15:55-15:56 local today (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label). `build/windows/Duskhold.exe` and `.pck` exist (Sep 29 local artifact, stale). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` builds Perf (FPS), Loop (Phase, Day, Night, Gold, Buildings, plus Timer in NIGHT and DAWN only) and Agents (Units, Enemies) rows plus registered sections; `overlay_on.png` (viewed) shows exactly those rows in the running scene. Read-only, toggle, refresh, registration, timed-phase and owner/recovery tests pass. `assets/attribution.json` exists and its coverage test passes in the suite. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window with margin, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches, payout clamp, only-coins-are-counted, payout/total disagreement warnings, overlay pre-bind registration and repeat-bind idempotency, overlay warning re-arm, malformed-row warning, overlay owner-freed drop) each have a named GUT test inside the 260/260 run, so none is left present-but-unverified. Only the real `DisplayServer.keyboard_get_label_from_physical` call cannot run headless and stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings and owner-pending items, not must-have failures)

See the `advisory` frontmatter list. Review 13 is 1 warning and 4 info, all about test hygiene or overlay-model style. `grep register_section` outside tests shows only the overlay's own definitions, so no first-party provider exists yet and the malformed-row path is not reachable from shipped Phase 1 behaviour. Plan 01-10's "pushed and CI green" truth and 01-03's "every push to any branch" wording are the owner-pending remote facts.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5. All exist, none stub.

### Key Link Verification

`gsd-tools query verify.key-links` this pass: plans 02-10 all verified. Plan 01 reports 2/3 because of one link, `tools/godot.sh -> tools/godot_version.txt` (pattern not found in `godot.sh`). `tools/_common.sh` reads the pin from `tools/godot_version.txt` and `godot.sh` sources `_common.sh`, so the link is wired; the plan named the wrong file. Not a gap.

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
| debug_overlay | debug_overlay_model | `bind_run` builds the model and replays `_pending` via `_model.register_section(...)` | WIRED |
| debug_overlay_model | building_system | `current_tier(spot_id)` in `_count_buildings` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started(carried)`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX "+X gold" | carried gold from per_spot (clamped, coerced) | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, building count, timer, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes (`overlay_on.png`) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 34 scripts, 260/260, 1714 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 68 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github, data, project.godot | no matches | PASS |
| Screenshots on disk | `ls -la screenshots`; `overlay_on.png` viewed | 6 PNGs dated today; overlay_on is a real render | PASS |
| Windows export on disk | `ls -la build/windows` | Duskhold.exe + Duskhold.pck (Sep 29 local artifact) | PASS (stale, see advisory) |

I did not re-run `tools/screenshot.sh` (the orchestrator reports 6/6 this iteration and the PNGs on disk carry that run's timestamps), `tools/export.sh` or `tools/prepush_check.sh`, and I did not query remote CI beyond `git ls-remote`, which shows the origin branch still at 981e4c8.

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
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 260 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED locally (trigger narrower than "every push"; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-13 files (`_registered` and `_pending` are populated by `register_section` and consumed by `bind_run` and `collect`). No blocker anti-patterns.

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position with `test:` wording unchanged. Item 9's `expected:` text is refreshed to the current facts (origin tip 981e4c8, local branch 194 commits ahead).

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (260/260, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, the Quaternius horse licence, and the CI trigger and push confirmation cannot be verified programmatically or are owner decisions. ROADMAP.md still shows the Phase 1 checkbox unticked; that is the orchestrator's phase-completion step, not a verification gap.

---

_Verified: 2026-09-30T11:05:17Z_
_Verifier: Claude (gsd-verifier)_
