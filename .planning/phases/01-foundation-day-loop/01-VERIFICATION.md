---
phase: 01-foundation-day-loop
verified: 2026-09-30T09:46:40Z
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
covered_digest: "v2:sha256:84b0921f841e9ff6d949ffe46d2c36654eebf2fdd3fe2246a7d07d0afa96bcd6"
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
  - finding: "Review 10 (01-REVIEW.md) records 0 critical, 1 warning (WR-01: DebugOverlayModel.collect relies on Callable.is_valid(), which does not detect a lambda that captured a freed Node, so such a provider would raise a script error on every refresh) and 2 info (IN-01 test-only hooks on DawnPayoutVfx, IN-02 overlay test uses cached shared resources); all three are open in 01-REVIEW-DISPOSITION.md"
    category: other
    reason: "WR-01 is latent: the only production sections today are the built-in Perf, Loop and Agents rows and no first-party code calls register_section with a lambda (grep: only tests and the DebugOverlay pass-through call it), so no shipped code path can hit it. It becomes reachable when Phase 2 registers wave and enemy-path providers, so the review's fix (document the contract or take an owner object) should land with that phase. None of the three breaks a ROADMAP success criterion or PLAN must-have."
    evidence_status: "grep -rn register_section over first-party .gd; ui/overlay/debug_overlay_model.gd lines 46-66 read this pass"
  - finding: "CI trigger is main, master and gsd/** pushes plus all pull requests, not literally every push"
    category: other
    reason: "ROADMAP SC4 and DEV-02 say 'on every push'; pushes to other branch names are covered only via a pull request. Owner-pending decision (record an override or widen the trigger)."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "The review-fix commits are not pushed: the branch is 160 commits ahead of origin and the last green CI run is on 981e4c8; build/windows/Duskhold.exe (Sep 29 21:57) predates the latest fixes"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current. Owner-pending."
    evidence_status: "git branch -vv (ahead 160); file listing; orchestrator report"
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
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight. The pass-10 landing margin (last coin scheduled 0.15 s before dawn ends) is covered by tests, but only a human can judge the on-screen feel and that the prompt and banner appear and disappear at the right moments in a real run"
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical, which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD"
    expected: "Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, 160 commits behind)"
    why_human: "Owner policy decision, and remote CI state cannot be observed from this environment"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T09:46:40Z
**Status:** human_needed (every automated check passes and no must-have fails; the remaining items are feel/visual judgments, a non-QWERTY layout check, and owner decisions on the horse licence and CI trigger/push)
**Re-verification:** Yes. The previous report (human_needed, 5/5, HEAD 61aeaa5) went stale after review-fix pass 10 (commits f1806f5, edf7e62, 532be7a, c3905c7) changed `ui/hud/dawn_payout_vfx.gd` and `ui/overlay/debug_overlay_model.gd`. I regenerated the verdicts from the current tree, not from the old report.

## Pass-10 change audit

I read the full source diff `git diff 61aeaa5 HEAD -- ui simulation presentation input project.godot .github tools`. Only two source files differ; `simulation`, `presentation`, `input`, `.github`, `tools` and `project.godot` are byte-identical to the last verification.

| Change | Source read | Impact on a truth |
|--------|-------------|-------------------|
| New `DAWN_MARGIN_SECONDS = 0.15`; `launch_stagger` window is now `dawn_seconds - TRIP_SECONDS - DAWN_MARGIN_SECONDS` | `dawn_payout_vfx.gd` lines 36-40, 113-123 | Strengthens SC3/SC4: the last coin is scheduled to land 0.15 s before dawn ends, so sim-clock vs process-clock skew cannot push it past the boundary. With the shipped tuning (2.0 s dawn, at most 12 coins) the default stagger still applies, so the visible timing is unchanged. The two updated e2e tests assert the margin explicitly. |
| `start_point` returns mid-screen when `_ctx == null` | `dawn_payout_vfx.gd` lines 295-300 | Null guard only; new test `test_start_point_before_the_run_is_bound_falls_back_to_mid_screen`. |
| `collect()` calls `_warned.erase(title)` after a provider returns rows, so a provider that recovers and fails again warns again | `debug_overlay_model.gd` lines 62-66 | Additive to the DEV-03 overlay; default Perf/Loop/Agents sections untouched. New test `test_a_flapping_provider_warns_again_after_it_recovers`. |
| Tests: `assert_push_warning` added to two skipped-provider tests | `tests/unit/test_debug_overlay_readonly.gd` | Tests only. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | King, camera rig and spot-label sources are unchanged since the last verification and their tests pass in the 243/243 run I executed. `day_overview.png` (viewed) shows the mounted king, castle, two House plots and the HUD gold. All ten PLAN `verify.artifacts` checks report every artifact present and non-stub. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` (read in full): `validate_build` checks `is_build_allowed()` (DAY only), then `get_spot(spot_id) == null`, then `next_action_cost < 0` (max tier), then `can_afford`; `_submit_build` re-validates, spends through `Economy.try_spend`, then `apply_next_tier`. The hold controller only submits a `BuildIntent`. Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd`: `start_night` is only legal in DAY, `_enter_dawn` changes phase then `_apply_dawn_payout` grants `dawn_income_by_spot()` and emits `dawn_payout`; `is_build_allowed()` is `phase == DAY`. Nothing in the gold path resets Economy between phases, so unspent gold carries over. `dawn_payout.png` (viewed) shows coins flying to the counter with the day HUD. Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. The pass-10 margin does not touch payout amounts. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED locally; CI on final HEAD not yet run, trigger narrower than "every push" (both owner-pending, see advisory) | I ran `bash tools/lint.sh` (66 files unchanged, no problems) and `bash tools/test.sh` once (32 scripts, 243/243 passing, 1604 asserts, exit 0). `ci.yml` defines lint, test, export (`needs: [lint, test]`, uploads `duskhold-windows`) and screenshots (xvfb, Compatibility renderer, uploads `duskhold-screenshots`) jobs, all through the same `tools/*.sh` wrappers, read-only token, actions pinned by SHA. `screenshots/` holds 6 PNGs stamped 09:35-09:36Z today (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label); I viewed two and they are real renders. `build/windows/Duskhold.exe` and `.pck` exist (local artifact from Sep 29). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` builds Perf (FPS), Loop and Agents rows plus registered sections; overlay read-only, toggle and refresh tests pass, including the new recovery case. `assets/attribution.json` exists and its coverage test passes in the suite. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window with margin, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches, payout clamp, overlay warning re-arm) each have a named GUT test inside the 243/243 run, so none is left present-but-unverified. Only the real `keyboard_get_label_from_physical` call cannot run headless and stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings and owner-pending items, not must-have failures)

See the `advisory` frontmatter list. Review 10 is 0 critical, 1 warning, 2 info, all open in 01-REVIEW-DISPOSITION.md. The warning (WR-01, lambda capturing a freed node) is latent because no first-party code registers a lambda provider yet.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5; all exist, none stub.

### Key Link Verification

`gsd-tools query verify.key-links` this pass: plans 02-10 all verified. Plan 01 reports 2/3 because of one link, `tools/godot.sh -> tools/godot_version.txt` (pattern not found in `godot.sh`). `godot.sh` sources `tools/_common.sh`, which reads the pin from `tools/godot_version.txt` and the file exists, so the link is wired; the plan named the wrong file. Not a gap.

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
| debug_overlay_model | building_system | `current_tier(spot_id)` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started(carried)`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX "+X gold" | carried gold from per_spot (clamped, coerced) | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, building count, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 32 scripts, 243/243, 1604 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 66 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | no matches | PASS |
| Screenshots on disk | `ls -la screenshots` | 6 PNGs dated today; day_overview and dawn_payout viewed and non-blank | PASS |
| Windows export on disk | `ls -la build/windows` | Duskhold.exe + Duskhold.pck (Sep 29 local artifact) | PASS (stale, see advisory) |

I did not re-run `tools/screenshot.sh` (orchestrator reports 6/6 this iteration; I inspected the resulting files), `tools/export.sh` or `tools/prepush_check.sh`, and I did not query remote CI.

### Probe Execution

No `probe-*.sh` scripts are declared by any PLAN or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02: exactly the 15 IDs given for this verification. All 15 are `[x]` and `Phase 1 | Complete` in REQUIREMENTS.md (15 traceability rows for Phase 1, re-checked by grep). No orphaned Phase 1 requirements; BLDG-05 belongs to Phase 5.

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
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 243 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED locally (trigger narrower than "every push"; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-10 files. No blocker anti-patterns. The open review findings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items. The first 8 match 01-UAT.md; the ninth is the CI trigger decision plus push-and-confirm-green step, which the UAT file does not list.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (243/243, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, the Quaternius horse licence, and the CI trigger/push confirmation cannot be verified programmatically or are owner decisions. ROADMAP.md still shows the Phase 1 checkbox unticked; that is the orchestrator's phase-completion step, not a verification gap.

---

_Verified: 2026-09-30T09:46:40Z_
_Verifier: Claude (gsd-verifier)_
