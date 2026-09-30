---
phase: 01-foundation-day-loop
verified: 2026-09-30T10:06:10Z
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
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:9355a0f2bcfd4e5bd95303d197934bc3f87cf8f8b67570fa5e591579e9be2826"
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
  - finding: "Review 11 (01-REVIEW.md, 4 files) records 0 critical, 2 warnings and 3 info, all open in 01-REVIEW-DISPOSITION.md. WR-01: DebugOverlay.register_section is a silent no-op before bind_run and a second bind_run discards registered sections. WR-02: the model's Timer row and NIGHT/DAWN branches are not unit-tested. IN-01: DawnPayoutVfx treats every child as a coin. IN-02: the new `owner` parameter shadows Node.owner. IN-03: _registered.erase(entry) compares by Dictionary content"
    category: other
    reason: "All five sit in the debug overlay and payout view internals. No first-party code registers an overlay section yet (only tests do), so WR-01 is latent until Phase 2 registers wave and enemy-path providers; it should land with that phase. WR-02 is a test-coverage gap, not a behaviour defect, and the NIGHT/DAWN loop rows are exercised by the overlay e2e and the HUD/phase tests. None breaks a ROADMAP success criterion or a PLAN must-have."
    evidence_status: "grep register_section; ui/overlay/debug_overlay.gd and debug_overlay_model.gd read this pass; git diff 61aeaa5 HEAD"
  - finding: "CI trigger is main, master and gsd/** pushes plus all pull requests, not literally every push"
    category: other
    reason: "ROADMAP SC4 and DEV-02 say 'on every push'; pushes to other branch names are covered only via a pull request. Owner-pending decision (record an override or widen the trigger)."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "The review-fix commits are not pushed: the branch is 170 commits ahead of origin and the last green CI run is on 981e4c8; build/windows/Duskhold.exe (Sep 29 21:57) predates the latest fixes"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current. Owner-pending."
    evidence_status: "git branch -vv (ahead 170); file listing"
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
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical, which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD"
    expected: "Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, 160 commits behind)"
    why_human: "Owner policy decision, and remote CI state cannot be observed from this environment"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T10:06:10Z
**Status:** human_needed (every automated check passes and no must-have fails; the remaining items are feel/visual judgments, a non-QWERTY layout check, and owner decisions on the horse licence and CI trigger/push)
**Re-verification:** Yes. The previous report (human_needed, 5/5) went stale after review-fix pass 11 changed `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd` and `ui/hud/dawn_payout_vfx.gd`. I regenerated the verdicts from the current tree at HEAD 43755b7 and did not copy the old ones.

## Pass-11 change audit

I read `git diff 61aeaa5 HEAD` over `ui simulation presentation input project.godot .github tools tests`. Only six files differ: three tests and the three UI files below. `simulation`, `presentation`, `input`, `.github`, `tools` and `project.godot` are byte-identical to the last verified state. `git status` shows only `.planning/config.json` modified.

| Change | Source read | Impact on a truth |
|--------|-------------|-------------------|
| `register_section(title, provider, owner = null)`: the owner is held as a `WeakRef`; a section whose owner was freed is warned about once and dropped (`_is_gone`, `_skip_reason(entry)`) | `debug_overlay_model.gd` lines 26-108, `debug_overlay.gd` lines 21-27 | Additive to the DEV-03 overlay. The built-in Perf, Loop and Agents sections are untouched and no first-party caller registers a section yet. New tests `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning`, `test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner` and `test_a_lambda_that_captured_a_live_object_keeps_showing_with_or_without_an_owner` pass. |
| Provider warning re-arms after a provider returns rows (`_warned.erase(title)`) | `debug_overlay_model.gd` lines 72-76 | Covered by `test_a_flapping_provider_warns_again_after_it_recovers`. |
| `DAWN_MARGIN_SECONDS = 0.15` in `launch_stagger`; `start_point` returns mid-screen before `bind_run`; test hooks regrouped and re-documented | `dawn_payout_vfx.gd` lines 36-40, 96-127, 297-304 | No behaviour change to payout amounts. Strengthens the SC3/SC4 landing margin (last coin lands 0.15 s before dawn ends); the two e2e tests assert it. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | The king, camera rig and spot-label sources are unchanged since the last verification and their tests pass in this pass's full run (245/245). `day_overview.png` (viewed) shows the mounted king, castle, two House plots, the HUD gold and the start-night prompt. `verify.artifacts` reports every artifact present and non-stub for all ten plans. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (read): NOT_DAY via `is_build_allowed()`, then UNKNOWN_SPOT when `get_spot(spot_id) == null`, then MAX_TIER when `next_action_cost < 0`, then CANNOT_AFFORD via `can_afford`. `submit` routes `BuildIntent` through the same validation. `RunManager.is_build_allowed()` is `_phase == RunPhase.DAY`. Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd`: `start_night` is legal only in DAY; `_enter_dawn` changes phase then `_apply_dawn_payout` grants the `dawn_income_by_spot()` total and emits `dawn_payout`. Nothing in the gold path resets Economy between phases, so unspent gold carries over. HUD gold shown in `day_overview.png`. Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED locally; CI on final HEAD not yet run and trigger narrower than "every push" (both owner-pending, see advisory) | I ran `bash tools/lint.sh` (66 files unchanged, no problems, exit 0) and `bash tools/test.sh` once (32 scripts, 245/245 passing, 1614 asserts, exit 0). `ci.yml` defines lint, test, export and screenshots jobs through the same `tools/*.sh` wrappers, read-only token, actions pinned by SHA. `screenshots/` holds 6 PNGs stamped today 15:00-15:01 local (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label); I viewed two and they are real renders. `build/windows/Duskhold.exe` and `.pck` exist (Sep 29 local artifact, stale). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` builds Perf, Loop and Agents rows plus registered sections; `overlay_on.png` (viewed) shows Perf/FPS, Loop (Phase, Day, Night, Gold, Buildings) and Agents (Units, Enemies). Read-only, toggle, refresh and the new owner/recovery tests pass. `assets/attribution.json` exists and its coverage test passes in the suite. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window with margin, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches, payout clamp, overlay warning re-arm, overlay owner-freed drop) each have a named GUT test inside the 245/245 run, so none is left present-but-unverified. Only the real `keyboard_get_label_from_physical` call cannot run headless and stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings and owner-pending items, not must-have failures)

See the `advisory` frontmatter list. Review 11 is 0 critical, 2 warnings, 3 info, all open in 01-REVIEW-DISPOSITION.md and all confined to overlay and payout-view internals. WR-01 (registration before `bind_run` is dropped silently) is latent until Phase 2 registers providers.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5. All exist, none stub.

### Key Link Verification

`gsd-tools query verify.key-links` this pass: plans 02-10 all verified. Plan 01 reports 2/3 because of one link, `tools/godot.sh -> tools/godot_version.txt` (pattern not found in `godot.sh`). `godot.sh` sources `tools/_common.sh`, which reads the pin from `tools/godot_version.txt`, and the file exists, so the link is wired; the plan named the wrong file. Not a gap.

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
| debug_overlay | debug_overlay_model | `_model.register_section(title, provider, owner)` | WIRED |
| debug_overlay_model | building_system | `current_tier(spot_id)` | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started(carried)`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX "+X gold" | carried gold from per_spot (clamped, coerced) | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, building count, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 32 scripts, 245/245, 1614 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 66 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | no matches | PASS |
| Screenshots on disk | `ls -la screenshots` | 6 PNGs dated today; day_overview and overlay_on viewed and non-blank | PASS |
| Windows export on disk | `ls -la build/windows` | Duskhold.exe + Duskhold.pck (Sep 29 local artifact) | PASS (stale, see advisory) |

I did not re-run `tools/screenshot.sh` (orchestrator reports 6/6 this iteration; I inspected the resulting files), `tools/export.sh` or `tools/prepush_check.sh`, and I did not query remote CI.

### Probe Execution

No `probe-*.sh` scripts are declared by any PLAN or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02: exactly the 15 IDs given for this verification. All 15 are `Phase 1 | Complete` in REQUIREMENTS.md traceability. No orphaned Phase 1 requirements; BLDG-05 belongs to Phase 5.

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
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 245 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED locally (trigger narrower than "every push"; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-11 files. No blocker anti-patterns. The open review findings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position (item 9 is the CI trigger decision plus push-and-confirm-green step). The item 9 text still says "160 commits behind"; the branch is now 170 ahead of origin.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (245/245, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, the Quaternius horse licence, and the CI trigger/push confirmation cannot be verified programmatically or are owner decisions. ROADMAP.md still shows the Phase 1 checkbox unticked; that is the orchestrator's phase-completion step, not a verification gap.

---

_Verified: 2026-09-30T10:06:10Z_
_Verifier: Claude (gsd-verifier)_
