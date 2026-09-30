---
phase: 01-foundation-day-loop
verified: 2026-09-30T13:05:36Z
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
  - "tests/support/overlay_test_support.gd"
  - "tests/support/sim_signals.gd"
  - "tests/unit/test_debug_overlay_providers.gd"
  - "tests/unit/test_debug_overlay_readonly.gd"
  - "tests/unit/test_debug_overlay_registration.gd"
  - "tests/unit/test_debug_overlay_timed_phases.gd"
  - "tests/unit/test_overlay_test_support.gd"
  - "tools/screenshot.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:62f8fb6837d4968f97bda51f80a3fd998b71ac796f272e05ef94744005f01623"
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
  - finding: "The freshest review (01-REVIEW.md, 0 critical, 1 warning, 3 info) is OPEN. WR-01: lifetime_owner does not protect a RefCounted owner that the provider lambda captures, because the stored Callable keeps it alive, so OWNER_FREED never fires for it; no test covers the RefCounted case. IN-01: three warning assertions in test_debug_overlay_providers.gd match only the substring 'skipped', so a wrong skip reason still passes. IN-02: the local variable owner_ref in DebugOverlayModel._skip_code shadows the static function owner_ref. IN-03: the new_tuning test edits one scalar and would pass with a shallow copy, so the 'copied all the way down' claim is unguarded"
    category: other
    reason: "All four concern the debug overlay's lifetime_owner contract and its test helpers. Every shipped registration passes a Node owner or none, and no shipped provider captures a RefCounted; Phase 2 is the stated consumer of lifetime_owner. None breaks a ROADMAP success criterion or a PLAN must-have. They are recorded as open in 01-REVIEW-DISPOSITION.md and await the next fix pass. 01-REVIEW-FIX.md describes the PREVIOUS review's fixes (null-context bind_run, over-long row drop, deep-copied tuning, guarded spot index), which are in the tree."
    evidence_status: "01-REVIEW.md and 01-REVIEW-DISPOSITION.md read in full (4 rows open); ui/overlay/debug_overlay.gd and ui/overlay/debug_overlay_model.gd read in full at HEAD: owner_ref returns a WeakRef while _registered and _pending store the provider Callable strongly, and _skip_code declares var owner_ref beside static func owner_ref; the review's claims match the code"
  - finding: "CI trigger is main, master and gsd/** pushes plus all pull requests and workflow_dispatch, not literally every push"
    category: other
    reason: "ROADMAP SC4 and DEV-02 say 'on every push'; plan 01-03's truth says 'every push to any branch'. Pushes to other branch names are covered only via a pull request. Owner-pending decision (record an override or widen the trigger)."
    evidence_status: ".github/workflows/ci.yml lines 8-12"
  - finding: "The branch is not pushed: origin/gsd/phase-01-foundation-day-loop is still 981e4c8 and the local branch is 250 commits ahead; build/windows/Duskhold.exe (Sep 29 21:57) predates the latest fixes"
    category: other
    reason: "Plan 01-10's last truth ('the final phase state is pushed to origin and its CI run is green') and plan 01-03's 'first push and green CI' cannot be observed from this environment for the current HEAD. CI rebuilds the export from the pushed tree. Owner-pending."
    evidence_status: "git rev-list --count origin/gsd/phase-01-foundation-day-loop..HEAD returns 250; git ls-remote --heads origin returns 981e4c8; ls -la build/windows"
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
    expected: "Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, the current origin tip; the local branch is 250 commits ahead)"
    why_human: "Owner policy decision, and remote CI state cannot be observed from this environment"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T13:05:36Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is feel and visual judgment, a non-QWERTY layout check, and owner decisions on the horse licence and on the CI trigger and push)
**Re-verification:** Yes. The previous report (HEAD 0f44b8d) went stale after review-fix pass 18 changed `ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd` and four overlay test-side files. Every verdict below was regenerated from the current tree at HEAD e8b3ed8; none was copied.

## Pass-18 change audit

`git diff 0f44b8d HEAD` outside `.planning` touches 6 files: two source files (`ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd`) and four test-side files (`tests/support/overlay_test_support.gd`, `tests/unit/test_debug_overlay_providers.gd`, `tests/unit/test_debug_overlay_registration.gd`, `tests/unit/test_overlay_test_support.gd`). `simulation`, `presentation`, `input`, `.github`, `tools`, `ui/hud` and `project.godot` are unchanged. Working tree is clean except `.planning/config.json`.

| Change | Source read | Impact on a truth |
|--------|-------------|-------------------|
| `DebugOverlay.bind_run` with a null `RunContext` now warns (`NO_CONTEXT_WARNING`) and returns before `_model` is set, so the overlay stays unbound and a later valid bind still works (closes the previous review's WR-01) | full file read | Diagnostics path only. Pinned by the new `test_bind_run_with_no_context_warns_and_leaves_the_overlay_free_to_bind_properly` (in the passing suite). `MapRoot` binds once with a real `RunContext`, so the built-in Perf, Loop and Agents rows are untouched. |
| `DebugOverlayModel._clean_rows` keeps only rows of exactly two entries (`size() == 2`); a longer row is dropped and counted by the existing malformed-row warning instead of being truncated | full file read | Diagnostics path only. Pinned by the tightened `test_a_provider_with_malformed_rows_keeps_only_the_well_formed_ones` (Mixed section: 1 row kept, 3 dropped). No shipped provider returns a 3-entry row. |
| `OverlayTestSupport.new_tuning()` deep-copies with `duplicate_deep`; `context_with_one_house` asserts the map has a spot before indexing; `test_overlay_test_support.gd` gains non-vacuity guards | diff read | Test structure only. |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | King, camera rig and spot-label sources are unchanged since the last verification; their tests pass in this pass's full run (276/276). `project.godot` defines the `sprint`, `start_night` and `toggle_debug_overlay` actions. `overlay_on.png` (viewed; captured 17:57 local today) shows the mounted king (rider T-pose on a small horse), the castle, two build plots, the HUD gold and the start-night prompt. `verify.artifacts` reports every artifact present and non-stub for all ten plans (see below). |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (read this pass, lines 30-40): NOT_DAY when `is_build_allowed()` is false, then UNKNOWN_SPOT when `get_spot` is null, then MAX_TIER when `next_action_cost < 0`, then CANNOT_AFFORD via `can_afford`, else OK. Build, upgrade, affordability, range, NOT_DAY and refund tests (e2e and integration folders) pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` `_apply_dawn_payout` (read this pass): sums `_buildings.dawn_income_by_spot()`, calls `_economy.grant(total)` when positive, emits `dawn_payout(total, per_spot)`; nothing resets gold at day start, so unspent gold carries over. `Gold: 30` is visible in `overlay_on.png`; `dawn_payout.png` (viewed) shows gold coins in flight from two built Houses toward the counter, HUD at `Gold: 23` while coins are airborne (the lagged counter). Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED locally; CI on the final HEAD not yet run, and the trigger is narrower than "every push" (both owner-pending, see advisory and human item 9) | I ran `bash tools/lint.sh` (72 files unchanged, no problems, exit 0) and `bash tools/test.sh` once (36 scripts, 276/276, 1822 asserts, exit 0). `ci.yml` defines lint, test, export and screenshots jobs through the same `tools/*.sh` wrappers; trigger is `push: [main, master, "gsd/**"]` plus `pull_request` and `workflow_dispatch`. `screenshots/` holds 6 PNGs stamped 17:56-17:57 local today (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label). `build/windows/Duskhold.exe` and `.pck` exist (Sep 29 21:57 local artifact, stale). |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` (read in full) builds Perf (FPS), Loop (Phase, Day, Night, Gold, Buildings, plus Timer in NIGHT and DAWN only) and Agents (Units, Enemies) rows plus registered sections; `overlay_on.png` (viewed) shows exactly those rows in the running scene (FPS 13 in the headless-software capture is a render-environment artifact, not a measurement of target hardware). `debug_overlay.gd` (read in full) toggles on `toggle_debug_overlay` and refreshes every 0.25 s. Read-only, toggle, refresh, registration, timed-phase, provider and owner/recovery tests pass, including the new null-context bind test and the tightened over-long-row test. `assets/attribution.json` exists and its coverage test passes in the suite. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches, payout clamp, overlay pre-bind registration and repeat-bind idempotency, repeat bind with another context warns, null-context bind warns and leaves the overlay bindable, default titles refused before and after bind, overlay warning re-arm and per-problem re-warning, malformed-row and over-long-row drop, owner-freed and invalid-callable drop, refusal of an already-freed or non-Object owner, `get_text()` before ready) each have a named GUT test inside the 276/276 run, so none is left present-but-unverified. Only the real `DisplayServer.keyboard_get_label_from_physical` call cannot run headless and stays a human item.

Coincidental-reliance check: no truth holds on an undeclared precondition, unenforced ordering or fixture-only setup; the deep-copy helpers exist precisely so tests do not share cached resources, so `coincidental_reliance_items` is empty.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings and owner-pending items, not must-have failures)

See the `advisory` frontmatter list. The freshest review (01-REVIEW.md: 0 critical, 1 warning, 3 info) is OPEN and awaits the next fix pass. WR-01: `lifetime_owner` cannot protect a RefCounted owner that the provider lambda captures, because the stored Callable holds it alive (a Node owner works, since `free()` is explicit); the doc comments overstate the guarantee and no test covers the RefCounted case. IN-01: three `assert_push_warning` calls match only "skipped". IN-02: `owner_ref` local shadows the static helper of the same name. IN-03: the `new_tuning` test would pass with a shallow copy. I read both overlay sources: the behaviours the review describes are real (`owner_ref` returns a `WeakRef` while `_registered` and `_pending` hold the Callable strongly; `_skip_code` declares `var owner_ref`), but no shipped registration captures a RefCounted, the overlay's built-in rows are unaffected, and none touches a success criterion, so they are advisory. Plan 01-10's "pushed and CI green" truth and 01-03's "every push to any branch" wording are the owner-pending remote facts.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5. All exist, none stub.

### Key Link Verification

`gsd-tools query verify.key-links` this pass: plans 02-10 all verified. Plan 01 reports 2/3 because of one link, `tools/godot.sh -> tools/godot_version.txt` (pattern not found in `godot.sh`). `tools/_common.sh` line 23 reads `tools/godot_version.txt` and `godot.sh` sources `_common.sh`, so the link is wired; the plan named the wrong file. Not a gap.

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
| debug_overlay | debug_overlay_model | `bind_run` refuses a null context, then builds the model and replays pending registrations through the shared owner check | WIRED |
| debug_overlay | debug_overlay_model | pre-bind `register_section` calls `title_problem` and `owner_problem` | WIRED |
| debug_overlay_model | building_system | `current_tier(spot_id)` in the Buildings count | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started(carried)`, `coin_landed` | Yes (`dawn_payout.png`: Gold 23 with coins in flight) | FLOWING |
| Dawn payout VFX "+X gold" | carried gold from per_spot | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, building count, timer, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes (`overlay_on.png`) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 36 scripts, 276/276, 1822 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 72 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github, data, project.godot | no matches | PASS |
| Screenshots on disk | `ls -la screenshots`; `overlay_on.png` and `dawn_payout.png` viewed | 6 PNGs dated today 17:56-17:57 local; both viewed are real renders | PASS |
| Windows export on disk | `ls -la build/windows` | Duskhold.exe + Duskhold.pck (Sep 29 21:57 local artifact) | PASS (stale, see advisory) |

I did not re-run `tools/screenshot.sh` (the orchestrator reports 6/6 this iteration and the PNGs carry that run's timestamps), `tools/export.sh` or `tools/prepush_check.sh`, and I did not query remote CI beyond `git ls-remote`, which shows the origin branch still at 981e4c8. No Godot process was left running (checked after the suite finished).

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
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 276 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED locally (trigger narrower than "every push"; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the two pass-18 source files: `SKIP_MESSAGES` covers every non-NONE `Skip` code, `_registered` and `_pending` are populated by `register_section` and consumed by `bind_run` and `collect`, refused titles, owners and a null context return before anything is stored, and `get_text()` guards the null label. The open review findings (RefCounted-owner contract wording and untested case, loose warning assertions, a name shadow, a shallow-copy test gap) are robustness and documentation edges, recorded as advisory, not blockers.

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position with `test:` wording unchanged. Item 9's `expected:` text is refreshed to the current fact (local branch 250 commits ahead of the origin tip 981e4c8).

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (276/276, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, the Quaternius horse licence, and the CI trigger and push confirmation cannot be verified programmatically or are owner decisions. ROADMAP.md still shows the Phase 1 checkbox unticked; that is the orchestrator's phase-completion step, not a verification gap.

---

_Verified: 2026-09-30T13:05:36Z_
_Verifier: Claude (gsd-verifier)_
