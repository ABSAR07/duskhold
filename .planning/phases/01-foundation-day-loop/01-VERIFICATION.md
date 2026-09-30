---
phase: 01-foundation-day-loop
verified: 2026-09-30T08:50:17Z
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
covered_digest: "v2:sha256:97f464bc518171f510b884589cfaa37dad1ba137283258f4136c3f4ac5e70d47"
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
  - finding: "Review 8 (01-REVIEW.md, commit 2da2b0f) records 0 critical, 3 warnings, 3 info against the pass-8 commits, all recorded open in 01-REVIEW-DISPOSITION.md"
    category: other
    reason: "Not re-triaged line by line here; I read the full pass-8 source diff and found no path by which any of them breaks a ROADMAP success criterion or PLAN must-have. They concern defensive/hardening paths that the shipped payout source (RunManager: StringName keys, int amounts, per_spot summing to total) does not reach."
    evidence_status: "review text; ui/hud/dawn_payout_vfx.gd and ui/overlay/debug_overlay_model.gd read this pass"
  - finding: "CI trigger is main, master and gsd/** pushes plus all PRs, not literally every push"
    category: other
    reason: "ROADMAP SC4 / DEV-02 say 'on every push'; pushes to other branch names are covered only via a PR. Acceptable for a solo repo; owner may record an override."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "build/windows/Duskhold.exe is a local artifact older than the latest fix commits, and origin's last green CI run (981e4c8) is many commits behind HEAD; nothing is pushed"
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
    why_human: "Timing, lighting mood and VFX feel. Known observation: the dawn_payout capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight. The readout lag comes from DawnPayoutVfx.payout_started and is released on leaving DAWN; tests cover the arithmetic, only a human can judge the on-screen feel. Also confirm the start-night prompt and night banner appear and disappear at the right moments in a real run (the HUD refreshes on phase_changed only). The '+X gold' label now shows the carried gold (same figure the coins fly and the readout lags by); with the real payout source this equals the paid total"
  - test: "Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release"
    why_human: "Legal/licence risk against the project's CC0-only constraint; unresolved in the review disposition"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): Hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical, which is unavailable headless; only a fake-layout resolver seam is unit-tested, so the real OS-layout call is unexercised (also listed as manual-only in 01-VALIDATION.md)"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-09-30T08:50:17Z
**Status:** human_needed (every automated check passes and no must-have fails; remaining items are visual/feel judgments, one non-QWERTY layout check, and one owner licence decision)
**Re-verification:** Yes. The previous report (human_needed, 5/5) went stale after review-fix pass 8 (5 fix commits 60d4881..30d0dd4) changed `ui/hud/dawn_payout_vfx.gd` and `ui/overlay/debug_overlay_model.gd`. I read the complete source diff `git diff 85cc110 HEAD -- ui simulation presentation input` (only those two files changed in source; tests changed in `tests/e2e/test_dawn_payout.gd` and `tests/unit/test_debug_overlay_readonly.gd`; `.github`, `tools` and `project.godot` are untouched), checked the callee `BuildingSystem.current_tier`, and re-ran lint and the full test suite on HEAD 4f71265. No regressions.

## Pass-8 change audit (what changed, and whether it breaks a truth)

| Change | Source read | Impact |
|--------|-------------|--------|
| `DawnPayoutVfx._on_dawn_payout` now sets `_pending_total = carried` (gold the coins carry) instead of the claimed `total`; warns if they differ; no longer force-shows a total when zero coins fly | `dawn_payout_vfx.gd` lines 130-176, 300-302 | The "+X gold" label, the coins and the HUD readout lag now use one figure. For the shipped source (`RunManager._apply_dawn_payout` sums `per_spot` into `total`) the values are identical, so SC3 behaviour is unchanged. The malformed-per_spot case (no coin to fly) shows no total and does not hold back the readout (`payout_started(0)`); covered by `test_a_payout_with_no_coin_to_fly_shows_no_total_and_does_not_leave_the_hud_short`. |
| `_whole_amounts` validates spot keys (StringName/String) and rejects non-finite floats; stores keys as StringName | lines 152-195 | Hardening only; real payouts already use StringName keys and int amounts. Covered by `test_a_malformed_payout_entry_does_not_abort_the_payout`. |
| Pending launch tweens tracked (`_launch_tweens`) and killed on a superseding payout; `get_launch_tweens()` accessor | lines 39-40, 94-98, 223-244 | Cleanup only; the generation guard already made stale launches inert. Covered by `test_a_new_payout_stops_the_pending_launches_of_the_one_it_supersedes`. |
| `DebugOverlayModel._count_buildings` uses `current_tier(spot_id) > 0` | `debug_overlay_model.gd` line 122-127; `building_system.gd` lines 59-63 | `current_tier` returns 0 for an empty spot, tier otherwise, so the count is identical and no longer allocates a snapshot per spot. |
| `register_section` refuses titles "Perf"/"Loop"/"Agents" with a warning | `debug_overlay_model.gd` lines 10-33 | Additive; default sections unchanged. New case in `test_debug_overlay_readonly.gd` passes. |

The CR-01 guard (coin schedule must land inside the dawn window) was re-probed by the orchestrator as still discriminating: with the schedule reverted to fixed STAGGER_SECONDS spacing, `test_dawn_payout.gd` fails 17/18. I did not repeat that experiment; the current test file has 18 tests and all pass on HEAD.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | King, camera rig and spot-label sources unchanged in pass 8 (empty diff for `input`, `presentation`, `simulation`); their tests are in the 237/237 run I executed. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd`, `build_hold_controller.gd`, `building_system.gd` unchanged; build, upgrade, affordability, range and NOT_DAY tests pass in the full run. |
| 3 | Gold is the only currency and on the HUD; ending the day via the placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` unchanged. Dawn income, payout VFX (including the label = carried gold test `test_the_label_the_coins_and_the_hud_readout_all_use_the_gold_that_flies` and HUD release test `test_the_hud_releases_a_held_back_readout_when_dawn_ends`), carryover and start-night hold tests pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see advisory) | I ran `bash tools/lint.sh`: 65 files unchanged, no problems. I ran `bash tools/test.sh` once: 31 scripts, 237/237 tests, 1578 asserts, exit 0. `ci.yml` (unchanged) defines lint, test, export and screenshots jobs using the same `tools/*.sh` wrappers. `screenshots/` holds 6 PNGs (regenerated 13:42 local, 41-77 KB each; orchestrator confirmed non-blank); `build/windows/Duskhold.exe` and `.pck` exist. Origin's last green CI run is 981e4c8; local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` pass-8 changes are additive/equivalent; overlay tests pass; `assets/attribution.json` present and its coverage test passes. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, superseded payouts stop pending launches) are exercised by named GUT tests inside the 237/237 run. Only the real `keyboard_get_label_from_physical` call cannot run headless, so it stays a human item.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

See the `advisory` frontmatter list. The fresh review 01-REVIEW.md (0 critical, 3 warnings, 3 info) is recorded open in 01-REVIEW-DISPOSITION.md; none breaks a ROADMAP success criterion or PLAN must-have.

### Required Artifacts

`gsd-tools query verify.artifacts` on all ten PLAN frontmatters, run this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5 (all exist, none stub).

### Key Link Verification

`gsd-tools query verify.key-links` run this pass: plans 02-10 verify fully (5/5, 3/3, 2/2, 2/2, 3/3, 2/2, 2/2, 3/3, 3/3); plan 01 verifies 2/3. The one miss is `tools/godot.sh -> tools/godot_version.txt`: `godot.sh` sources `_common.sh`, which reads the pin at `tools/_common.sh:23` (confirmed this pass). Wired; the plan named the wrong file.

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
| Dawn payout VFX "+X gold" | carried gold from per_spot | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (`dawn_income_by_spot`) | Yes | FLOWING |
| Start-night prompt / night banner | phase, night number | `RunManager.get_phase()` after `phase_changed` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, building count, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 31 scripts, 237/237, 1578 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 65 files unchanged, no problems | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshots on disk | `ls screenshots` | 6 PNGs (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label) | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (local artifact, older than fixes) | PASS |

I relied on the orchestrator's reported results for `tools/screenshot.sh` (6/6 non-blank PNGs), the headless screenshot guard (exit 2), `tools/prepush_check.sh` (PASSED) and the CR-01-reverted experiment (17/18 fail); I did not re-run them. Remote CI was not queried.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED.

### Requirements Coverage

The union of requirement IDs in the `requirements:` blocks across the ten PLAN frontmatters (extracted this pass; D-xx tokens are decision references, not requirements) is ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02: exactly the 15 ROADMAP Phase 1 IDs. All 15 are `[x]` and "Phase 1 / Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

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
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 237 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-8 files. No blocker anti-patterns. Open review warnings are advisories only.

### Human Verification Required

See the `human_verification` list in the frontmatter: 8 items, wording kept from the previous report (item 6 notes the "+X gold" label now shows the carried gold), matching the 8 pending items in 01-UAT.md. Non-UAT recommendation: push the local commits and confirm CI is green on the new HEAD, since DEV-02's remote evidence still comes from 981e4c8.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (237/237, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-30T08:50:17Z_
_Verifier: Claude (gsd-verifier)_
