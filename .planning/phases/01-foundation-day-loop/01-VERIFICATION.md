---
phase: 01-foundation-day-loop
verified: 2026-09-30T06:53:21Z
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
covered_digest: "v2:sha256:3acc786dae281b6c96f8fd73ce63e8d5855502b7c67101cb3de62853a5d09cd1"
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
  - finding: "Review 4 WR-05 (test strength): test_a_real_payout_lands_every_coin_inside_a_short_dawn_window in tests/e2e/test_dawn_payout.gd no longer detects the CR-01 regression. Review-fix pass 4 (32c62fa) removed its wall-clock bound; it emits dawn_payout synthetically during DAY and only waits for the end state, so it passes even if ui/hud/dawn_payout_vfx.gd line 117 schedules with STAGGER_SECONDS instead of the computed `stagger`. Orchestrator confirmed all 11 tests in the file still pass with the bug reverted. The only remaining guard is the launch_stagger() unit test, which proves the schedule math but not that _on_dawn_payout uses it."
    category: other
    reason: "Production code is correct (line 117 uses `float(index) * stagger`, read this run). No ROADMAP SC or PLAN must-have requires a wall-clock landing bound; SC3 (dawn payout with carryover) is still proven by test_dawn_income, test_loop_gold_carryover and the payout landing/total tests. Test-strength regression only. Recorded open in 01-REVIEW-DISPOSITION.md. Fix: assert that the last coin's scheduled launch delay is (n-1)*launch_stagger(n), or restore a measured elapsed bound."
    evidence_status: "source read (ui/hud/dawn_payout_vfx.gd lines 96-121, tests/e2e/test_dawn_payout.gd lines 216-245); orchestrator ran the reverted-bug experiment"
  - finding: "Review 4 WR-01: Hud._start_night_hint reports '(unbound)' for start_night bindings that are joypad-motion or mouse-button events, and drops key modifiers"
    category: other
    reason: "No rebinding UI exists until Phase 13; default bindings (N / gamepad Y) render correctly and are test-covered. No SC covers it."
    evidence_status: "review text; source read (ui/hud/hud.gd)"
  - finding: "Review 4 WR-02: Hud derives _payout_pending independently of DawnPayoutVfx (unenforced invariant, no backstop reset on day_started)"
    category: other
    reason: "Holds with the shipped VFX (coin shares always sum to the per-spot amount, HUD clamps covered by tests); only a future VFX change could break it."
    evidence_status: "review text; source read (ui/hud/hud.gd, ui/hud/dawn_payout_vfx.gd)"
  - finding: "Review 4 WR-03: MAX_COINS is a soft cap (each paying spot gets at least one coin) and launch_stagger cannot fit a dawn window shorter than TRIP_SECONDS"
    category: other
    reason: "Shipped tuning (dawn_seconds 2.0, 12 coins, max 8 spots) is inside the guarantee; a rebalance could break it silently."
    evidence_status: "review text; source read (ui/hud/dawn_payout_vfx.gd)"
  - finding: "Review 4 WR-04: BuildingSystem keeps a spot with an empty id and apply_next_tier is unguarded against a missing tier/def"
    category: other
    reason: "Both are data errors that MapConfig.validate() reports; the shipped prototype map is valid and test-covered, and only CommandProcessor calls apply_next_tier after validate_build."
    evidence_status: "review text; source read (simulation/buildings/building_system.gd)"
  - finding: "Review 4 IN-01..IN-05 (orphaned comment, Xbox-only pad names, float integer division, default-binding test order dependence, duplicate overlay titles)"
    category: other
    reason: "Info-level; none touches a success criterion."
    evidence_status: "review text"
  - finding: "Earlier open items: DawnPayoutVfx idempotency was fixed in pass 4 (2d8dd35, read this run); IN-03 CI double-run of a gsd/** branch once a PR is open is a pending owner decision"
    category: other
    reason: "ci.yml untouched"
    evidence_status: "source read (.github/workflows/ci.yml lines 9-12)"
  - finding: "CI trigger is main, master and gsd/** pushes plus all PRs, not literally every push"
    category: other
    reason: "ROADMAP SC4 / DEV-02 say 'on every push'; pushes to other branch names are covered only via a PR. Acceptable for a solo repo; owner may record an override."
    evidence_status: ".github/workflows/ci.yml lines 9-12"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
  - finding: "build/windows/Duskhold.exe is a local artifact older than the latest fix commits, and origin's last green CI run (981e4c8) is 80 commits behind HEAD (8fc0d5f)"
    category: other
    reason: "CI rebuilds the export from the pushed tree; push and confirm CI green on the final HEAD before treating DEV-02's remote evidence as current."
    evidence_status: "file listing; git rev-list --count 981e4c8..HEAD = 80"
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
**Verified:** 2026-09-30T06:55:00Z
**Status:** human_needed (every automated check passes and no must-have fails; the remaining items are visual/feel judgments plus one owner licence decision)
**Re-verification:** Yes. The previous report went stale after review-fix pass 4 (8 fix commits 2d8dd35..2fe6dc1, touching `simulation/buildings/building_system.gd`, `ui/hud/dawn_payout_vfx.gd`, `ui/hud/hud.gd`, `ui/overlay/debug_overlay_model.gd` plus tests). I read the full source diff of that pass (`git diff 2d8dd35^..2fe6dc1 -- simulation ui presentation input`) and re-checked every truth against the current tree (HEAD 8fc0d5f; only docs commits follow 2fe6dc1). No regressions.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player rides the mounted king (WASD/stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its cost | VERIFIED (feel: human) | King, camera rig and spot-label sources are not touched by pass 4. `MapRoot` builds the `RunContext` and binds the `run_bound` nodes. King, camera and spot-label tests are in the 218/218 run. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds/upgrades; only when affordable, only on spots, never at night | VERIFIED | `command_processor.gd` and `build_hold_controller.gd` unchanged. The pass-4 `BuildingSystem` change only keeps the first def on a duplicate id and returns a copy from `spot_ids()`. Build-hold, refund, phase-guard, upgrade and denied tests pass. |
| 3 | Gold is the only currency and is on the HUD; ending the day through the placeholder night leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` unchanged. `DawnPayoutVfx._on_dawn_payout` (read this run) computes `stagger = launch_stagger(coin_total)` and schedules every coin with `float(index) * stagger` at line 117, so the CR-01 fix is intact in production code. `bind_run` is now idempotent. HUD start-night prompt rebuilds when the InputMap events change. Dawn income, payout, carryover and start-night hold tests pass. |
| 4 | From CLI and in CI on every push: lint + headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (CI on final HEAD not yet run, see advisory) | I ran `bash tools/lint.sh`: 65 files unchanged, no problems. I ran `bash tools/test.sh` once: 31 scripts, 218/218, 1447 asserts, exit 0. `ci.yml` has lint, test, export (`needs: [lint, test]`) and screenshots jobs. `screenshots/` holds 6 PNGs; `build/windows/Duskhold.exe` and `.pck` exist. Last green CI on origin is 981e4c8; 80 local commits are unpushed. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | `debug_overlay_model.gd` (pass 4) skips invalid providers and providers that need arguments, and uses `RunPhase.find_key` for the phase name. Overlay model/toggle/read-only tests and `test_attribution_log` pass; `assets/attribution.json` present. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing, carryover) are exercised by named GUT tests that passed in the run above.

**Test-strength note (review WR-05, advisory).** One behavioral guard is weaker than it appears: `test_a_real_payout_lands_every_coin_inside_a_short_dawn_window` emits `dawn_payout` synthetically during DAY, waits for the end state only, and its own comment says it "checks the end state, not the wall-clock time". The coin flight (0.08 s stagger x 11 + 0.6 s trip = 1.48 s) still finishes inside its `dawn_seconds + SETTLED_S` wait, so it would pass with the stagger bug. The schedule math is proven by the `launch_stagger` unit test in the same file, and the production wiring was verified by direct source read. This does not defeat any must-have (no roadmap SC or plan truth requires a measured landing time), so it is recorded as an advisory, not a gap.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (open review findings, not must-have failures)

See the `advisory` frontmatter list. Fresh review 01-REVIEW.md (0 critical, 5 warnings, 5 info, all recorded open) was cross-checked against the code; none breaks a ROADMAP success criterion or a PLAN must-have. Most notable: the weakened CR-01 regression test (WR-05), the start-night hint's handling of non-key/pad-button rebinds (WR-01, no rebind UI yet), and CI narrowing to `main`, `master`, `gsd/**` pushes plus PRs versus the literal "every push".

### Required Artifacts

`gsd_run query verify.artifacts` on all ten PLAN frontmatters, re-run this pass: 01: 10/10, 02: 8/8, 03: 4/4, 04: 5/5, 05: 5/5, 06: 4/4, 07: 5/5, 08: 3/3, 09: 5/5, 10: 5/5 (all exist, none stub). Source files touched by pass 4 were read in full diff.

### Key Link Verification

`gsd_run query verify.key-links`: 29 of 30 verified. The one miss is plan 01's `tools/godot.sh -> tools/godot_version.txt`: `godot.sh` sources `_common.sh`, which reads the pin (`_common.sh:23`, `tr -d '\r\n' < .../tools/godot_version.txt`). Wired; the plan named the wrong file.

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` | WIRED |
| run_manager | economy | dawn payout `grant` | WIRED |
| map_root | run_bound nodes | `RunContext.new`, then `bind_run` | WIRED |
| hud | sim_events / dawn_payout_vfx | `dawn_payout`, `coin_landed` (bind guarded by `_ctx`) | WIRED |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins | `Economy.get_gold()`, `coin_landed` | Yes | FLOWING |
| Dawn payout VFX | per_spot amounts | `SimEvents.dawn_payout` from `dawn_income_by_spot()` | Yes | FLOWING |
| Start-night prompt | key names | `InputMap.action_get_events(&"start_night")` | Yes | FLOWING |
| Debug overlay | FPS, phase, gold, counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 31 scripts, 218/218, 1447 asserts, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 65 files unchanged, no problems | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, .github | none | PASS |
| Screenshots on disk | `ls screenshots` | 6 PNGs (build_in_progress, dawn_payout, day_overview, night_banner, overlay_on, spot_label) | PASS |
| Windows export on disk | `ls build/windows` | Duskhold.exe + Duskhold.pck (local artifact, older than fixes) | PASS |

I relied on the orchestrator's reported results for `tools/screenshot.sh` (6/6 non-blank PNGs), the headless screenshot guard (exit 2), `tools/prepush_check.sh` (PASSED) and the CR-01-reverted experiment; I did not re-run them. Remote CI was not queried this run; its last known green run is 981e4c8.

### Probe Execution

No `probe-*.sh` scripts declared or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is exactly the 15 ROADMAP Phase 1 IDs. All 15 are `[x]` / "Complete" in REQUIREMENTS.md. No orphaned Phase 1 requirements.

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
| ECON-02 | 01-09, 01-10 | SATISFIED | tier-scaled dawn income and payout tests |
| ECON-07 | 01-09 | SATISFIED | gold carryover test |
| ART-02 | 01-07 | SATISFIED (licence note: horse decision pending) | attribution.json, coverage test |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 218 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED (trigger narrowed; CI on HEAD pending) | ci.yml lint/test/export/screenshots |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, shot_runner, CI job, 6 PNGs |

### Anti-Patterns Found

No debt markers in the phase's source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the pass-4 files. No blocker anti-patterns. Warning-level items (weakened regression test WR-05 and the other open review findings) are listed as advisories.

### Human Verification Required

See the `human_verification` list in the frontmatter (7 items, identical to the 7 pending items in 01-UAT.md). Non-UAT recommendation: push the 80 local commits and confirm CI is green on the new HEAD, since DEV-02's remote CI evidence still comes from 981e4c8. Recommend restoring a real guard for the stagger wiring (WR-05) before relying on CI as a hard gate.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read and by a full passing suite I ran (218/218, lint clean). Status is `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX feel and the Quaternius horse licence cannot be verified programmatically.

---

_Verified: 2026-09-30T06:55:00Z_
_Verifier: Claude (gsd-verifier)_
