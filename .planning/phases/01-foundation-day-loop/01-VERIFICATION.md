---
phase: 01-foundation-day-loop
verified: 2026-10-01T07:19:49Z
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
  - "ASSETS.md"
  - "assets/attribution.json"
  - "assets/third_party/quaternius_horse/License.txt"
  - "input/build_hold_controller.gd"
  - "input/start_night_hold_controller.gd"
  - "presentation/buildings/building_views.gd"
  - "presentation/map/map_root.gd"
  - "project.godot"
  - "simulation/buildings/building_system.gd"
  - "simulation/commands/command_processor.gd"
  - "simulation/defs/map_config.gd"
  - "simulation/run/run_manager.gd"
  - "tests/e2e/test_debug_overlay_toggle.gd"
  - "tests/unit/test_debug_overlay_registration.gd"
  - "tools/lint.sh"
  - "tools/screenshot.sh"
  - "tools/test.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay.tscn"
  - "ui/overlay/debug_overlay_model.gd"
covered_digest: "v2:sha256:881f1a6046a2e4178a1d9264348ad1b7765ca016c31eecebd2c82ff5dc99c1ff"
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
  - finding: "Horse licence record (review WR-01, OPEN): the three records cite the QAL v1.0 clause 'the version in effect at the time you obtained the Assets governs your use of them' and justify CC0 by saying the model 'was obtained as CC0', but the same records date QAL v1.0 to 8/28/2026 and the retrieval to 2026-09-29, so the clause does not by itself favour CC0. The keep decision actually rests on the author's pack page and the Poly Pizza page both stating CC0 on the retrieval date plus the irrevocability of an earlier CC0 dedication, which the records never say. The reviewer asks for one honest sentence in each of ASSETS.md, License.txt and attribution.json."
    category: other
    reason: "Not a must-have failure: the asset is recorded in the attribution log (ART-02 holds) and a licence verdict is a legal judgment I cannot make. It is a documentation-soundness warning on an owner-accepted risk. Confirmed in the tree: ASSETS.md lines 29-44, License.txt lines 14-35 and attribution.json line 96 all carry the clause and the 'obtained under CC0' reasoning, with no sentence acknowledging the date ordering. 01-REVIEW-FIX.md belongs to the previous review and does not cover it; 01-REVIEW-DISPOSITION.md records it as open."
    evidence_status: "files read; 01-REVIEW.md WR-01; the reviewer's re-check statements (pack and Poly Pizza pages 'still state CC0') are not independently re-fetched by me"
  - finding: "ASSETS.md 'Archive checksums and download evidence' (review IN-01, OPEN) says every SHA256 is of an archive deleted after extraction"
    category: other
    reason: "Confirmed untrue for the horse (hash is of the GLB itself, as the table cell and the horse notes say) and for GUT (vendored under addons/gut/). Documentation accuracy only; the log hashes themselves are correct and test_attribution_log passes."
    evidence_status: "ASSETS.md lines 22-27 read against the table rows"
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
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release. Current state: on 2026-10-01 the keep decision was recorded (ASSETS.md, License.txt, attribution.json) but the owner has not run UAT, and open review finding WR-01 says the recorded reasoning cites a clause that does not favour CC0; the owner should confirm the keep decision on the corrected rationale (CC0 on the author's pack page and Poly Pizza at retrieval, irrevocable dedication, residual risk accepted)"
    why_human: "Legal/licence risk against the project's CC0-only constraint; the record's stated reasoning is flagged open in review"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical (ui/hud/hud.gd), which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD"
    expected: "Owner confirms the widened trigger (push to any branch or tag, plus pull_request and workflow_dispatch) satisfies 'on every push'. Current state: the trigger is widened (bfe3c97), the branch was pushed on 2026-10-01 (origin tip e6bbb47) and push-event run 36827944700 on e6bbb47 is green in all four jobs (lint, test 290/290, export, screenshots 6 of 6); the commits after e6bbb47 (four when this report was written, plus this report and the UAT file) are planning docs only, not pushed, so the green run covers the last code state but not the literal HEAD"
    why_human: "Owner policy decision; the owner has not yet confirmed it through UAT"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-01T07:19:49Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is feel and visual judgment, a non-QWERTY layout check, and owner confirmation of the horse licence and CI trigger decisions)
**Re-verification:** Yes. The previous report (2026-09-30T15:14:37Z) was stale because covered files changed. Every verdict below was regenerated from the current tree at HEAD e30b4cf; none was copied.

## Change audit since the previous report

`git diff f5cfdfe HEAD -- . ':!.planning'` touches exactly four files: `.github/workflows/ci.yml`, `ASSETS.md`, `assets/attribution.json` (horse `notes` only) and `assets/third_party/quaternius_horse/License.txt`. `git diff --stat f5cfdfe HEAD -- simulation presentation input ui tools project.godot tests` is empty, so no game code, test or tool changed and the previous behavioural evidence stands, and I re-ran it anyway (below). The only working-tree modification is `.planning/config.json`.

- `ci.yml`: the `push:` trigger lost its `branches: [main, master, "gsd/**"]` filter. `on:` now reads `push:`, `pull_request:`, `workflow_dispatch:` (read, lines 12-15), which fires for a push to any branch or tag. Permissions, concurrency and jobs are unchanged.
- Horse licence record: the keep decision is written into the three records.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | `project.godot` `[input]` defines `move_left/right/forward/back`, `sprint`, `action_build`, `start_night`, `toggle_debug_overlay`. King, camera rig and spot-label sources are unchanged since the last verification and their tests pass in this pass's full run (290/290). The CI-produced `overlay_on.png` (downloaded from run 36827944700 and viewed) shows the mounted king (rider in T-pose on a small horse), the castle, two empty build plots, HUD `Gold: 30` and the prompt "Hold N / (Y) to start Night 1". |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (lines 29-39, read) checks NOT_DAY, then UNKNOWN_SPOT, then MAX_TIER, then CANNOT_AFFORD; `_submit_build` spends via `try_spend` before `apply_next_tier` and emits `command_rejected` otherwise. `run_manager.gd` `is_build_allowed()` (line 35). Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager.gd` `_apply_dawn_payout` (lines 111-118, read) grants the summed per-spot income via `_economy.grant(total)` when positive and emits `dawn_payout(total, per_spot)`; nothing resets gold at day start. CI `dawn_payout.png` (viewed) shows two built Houses, gold coins in flight and the lagged HUD `Gold: 23`. Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED | Local: `bash tools/lint.sh` exit 0 (72 files unchanged, no problems); `bash tools/test.sh` run once, exit 0 (36 scripts, 290/290, 1881 asserts, 92.2 s). Trigger: `ci.yml` `on: push:` unfiltered plus `pull_request` and `workflow_dispatch`, which matches "on every push". Remote: `gh run view 36827944700` shows event `push`, head_sha e6bbb47dc0ff6154f9a74a346b13c091139c09b4, conclusion success; jobs test (1m43s), lint (15s), screenshots (54s) and export (30s) are all green; its log shows `Tests 290`, `Passing Tests 290`, `Asserts 1881` and `Saved 6 of 6 screenshots`; artifacts `duskhold-windows` (39.8 MB), `gut-results` and `duskhold-screenshots` are unexpired. `git ls-remote --heads origin` returns e6bbb47 for the phase branch. HEAD was four docs-only commits past e6bbb47 when this report was written (not pushed); the green run covers the last code state. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | CI `overlay_on.png` (viewed) shows the overlay with Perf (FPS), Loop (Phase DAY, Day 1, Night 0, Gold 30, Buildings 0) and Agents (Units 0, Enemies 0); low FPS is a software-render artifact. Overlay toggle, refresh cadence, pause, time-scale-zero, registration and bind-while-visible tests pass in the 290/290 run. `assets/attribution.json` and `ASSETS.md` list the engine, GUT, three Kenney packs and the Quaternius horse, and `test_attribution_log` passes. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, payout clamp, overlay registration and cadence) each have a named GUT test inside the 290/290 run. Only the real `DisplayServer.keyboard_get_label_from_physical` call cannot run headless and stays a human item.

Coincidental-reliance check: no truth holds on an undeclared precondition, unenforced ordering or fixture-only setup; `coincidental_reliance_items` is empty.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (not must-have failures)

Two review findings are OPEN and are not addressed by any fix: WR-01 (warning) and IN-01 (info) from 01-REVIEW.md, recorded `open: 2` in 01-REVIEW-DISPOSITION.md. 01-REVIEW-FIX.md belongs to the previous review and does not cover them. I confirmed both against the tree (see the `advisory` frontmatter). Neither fails a roadmap success criterion or a requirement: the horse and every other asset are in the log, and the hashes in the log are correct. They are surfaced because a later reader or itch.io reviewer would find the horse rationale unsound as written, and because the owner's licence confirmation (UAT item 7) depends on it. The reviewer's statements that the pack and Poly Pizza pages still say CC0 are not independently re-fetched by me.

### Required Artifacts

Plan frontmatter artifacts were verified in the previous pass for all ten plans (all present, none stub). No file under `simulation/`, `presentation/`, `input/`, `ui/`, `tools/`, `tests/` or `project.godot` changed since, so I re-checked existence and wiring of the load-bearing ones (command_processor, run_manager, building_system, hud, debug_overlay, attribution log, ci.yml) and the full suite exercises them: 290/290.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED (unchanged; covered by tests) |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` (read lines 62-67) | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` -> `start_night()` (read lines 54-55) | WIRED |
| run_manager | economy | dawn payout `grant` (read line 117) | WIRED |
| hud | dawn_payout_vfx / run_manager | `payout_started`, `coin_landed`, `phase_changed` | WIRED (dawn_payout.png shows lagged counter) |
| debug_overlay | debug_overlay_model | `bind_run` / `_refresh` | WIRED (overlay_on.png) |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED (run 36827944700 green) |

The plan-01 link `tools/godot.sh -> tools/godot_version.txt` is wired through `tools/_common.sh`; the plan named the wrong file. Not a gap.

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started`, `coin_landed` | Yes (`dawn_payout.png`: Gold 23 with coins in flight) | FLOWING |
| Dawn payout "+X gold" | per_spot sum | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (sums the same per-spot amounts it grants, so the label equals the real payout) | Yes | FLOWING |
| Start-night prompt | phase, night number | `RunManager.get_phase()` | Yes (`overlay_on.png`) | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, buildings, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 36 scripts, 290/290, 1881 asserts, 92.2 s, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 72 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, data, .github | no matches | PASS |
| Remote CI on pushed tip | `gh run view 36827944700`; `gh api .../runs/36827944700` | push event, e6bbb47, success; four jobs green; test 290/290; 6 of 6 screenshots; 3 artifacts unexpired | PASS |
| Screenshots | downloaded `duskhold-screenshots` artifact; viewed `overlay_on.png` and `dawn_payout.png` | six PNGs; both viewed are real renders of the running game | PASS |
| Remote branch tip | `git ls-remote --heads origin` | e6bbb47 | PASS |

I did not re-run `tools/screenshot.sh` or `tools/export.sh` locally; the CI run on e6bbb47 produced both outputs. The local `build/windows/Duskhold.exe` (Sep 29 21:57) and local `screenshots/` (Sep 30) are stale local copies and were not relied on. No Godot process was left running (`tasklist` clean).

### Probe Execution

No `probe-*.sh` scripts are declared by any PLAN or present; SKIPPED.

### Requirements Coverage

The union of `requirements:` across the ten PLAN frontmatters is ART-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, DEV-01, DEV-02, DEV-03, DEV-04, ECON-01, ECON-02, ECON-07, KING-01, KING-02: exactly the 15 IDs given for this verification. All 15 are `[x]` and `Phase 1 | Complete` in REQUIREMENTS.md. No orphaned Phase 1 requirements; BLDG-05 belongs to Phase 5.

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| KING-01 | 01-02, 01-04 | SATISFIED | input map in project.godot; king ride tests |
| KING-02 | 01-04 | SATISFIED | fixed-offset camera rig tests |
| BLDG-01 | 01-02, 01-05 | SATISFIED | `validate_build` UNKNOWN_SPOT for any non-spot id |
| BLDG-02 | 01-05, 01-06 | SATISFIED | spot label model and world label tests |
| BLDG-03 | 01-02, 01-06 | SATISFIED | hold controller, coin drip, refund tests |
| BLDG-04 | 01-05 | SATISFIED | upgrade flow and MAX_TIER rejection tests |
| BLDG-06 | 01-09 | SATISFIED | `is_build_allowed()` DAY-only; NOT_DAY rejection tests |
| ECON-01 | 01-02, 01-09 | SATISFIED | HUD gold label; gold never negative |
| ECON-02 | 01-09, 01-10 | SATISFIED | `_apply_dawn_payout` and tier-scaled income tests |
| ECON-07 | 01-09 | SATISFIED | no gold reset at dawn or day start; carryover test |
| ART-02 | 01-07 | SATISFIED (horse rationale flagged open, see advisory; owner confirmation pending) | attribution.json, ASSETS.md, `test_attribution_log` |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 290 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED | unfiltered `push:` trigger; push-event run green on e6bbb47 |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests, `overlay_on.png`; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, CI job, 6 of 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the files I read. Open review findings: WR-01 (warning) and IN-01 (info), documentation soundness only (see Advisory).

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position with `test:` wording unchanged. Items 7 and 9 have refreshed `expected:` text recording that the owner decisions of 2026-10-01 (keep the horse, widen the trigger, push) were made but not yet confirmed through UAT; 01-UAT.md still has 9 pending items.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read, a full passing suite I ran (290/290, lint clean), and a green push-event CI run on the last code state (e6bbb47) whose artifacts I inspected. The two items that were owner-pending in the previous report as advisories (trigger narrower than "every push", branch not pushed) are now resolved in the tree and on origin. Status stays `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, and the owner's confirmation of the horse licence and CI trigger decisions cannot be verified programmatically; two review findings remain open and are not fixed by this verification.

---

_Verified: 2026-10-01T07:19:49Z_
_Verifier: Claude (gsd-verifier)_
