---
phase: 01-foundation-day-loop
verified: 2026-10-01T08:08:30Z
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
  - "export_presets.cfg"
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
covered_digest: "v2:sha256:13531c553308b89c553bf4dc3e6e52634b873861690808115833f1966bf17623"
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
  - finding: "Horse licence record (review WR-01, OPEN): the three records (ASSETS.md, License.txt, attribution.json notes) say the horse is 'used inside a game, not redistributed as a standalone asset'. The unmodified horse_animated.glb is tracked (Git LFS, `git check-attr filter` = lfs) in the public repo ABSAR07/duskhold and ships in the Windows export (export_presets.cfg `exclude_filter` is only 'tests/*, addons/gut/*, tools/*'), so the sentence is inaccurate for the repository and the build. The keep decision itself rests on the CC0 statements on the author's pack page and Poly Pizza at retrieval and on the irrevocability of an earlier CC0 dedication, which the records now state correctly (fixed in 6cdf386)."
    category: other
    reason: "Not a must-have failure: the horse is in the attribution log (ART-02 holds) and a licence verdict is a legal judgment I cannot make. It is a documentation-soundness warning on an owner-accepted risk. Confirmed in the tree. 01-REVIEW-FIX.md belongs to the previous review (pass 25) and does not cover it; 01-REVIEW-DISPOSITION.md records open: 3."
    evidence_status: "files read; git ls-files, git check-attr, export_presets.cfg; the reviewer's statements that the pack and Poly Pizza pages still state CC0 are not independently re-fetched by me"
  - finding: "ASSETS.md 'How to add an asset' step 4 (line 76, review IN-01, OPEN) still calls `sha256` the hash 'of the downloaded archive'"
    category: other
    reason: "Documentation accuracy only. The 'Archive checksums and download evidence' section (fixed in 1784ffe and 1ce2f94) now correctly says what each SHA256 covers; step 4 was not updated to match (the horse hash is of the GLB, GUT's is of the source zip). The log hashes are correct and test_attribution_log passes."
    evidence_status: "ASSETS.md line 76 read against the table and the checksum section"
  - finding: "The same source page is quoted two ways (review IN-02, OPEN): 'License CC0' (ASSETS.md line 45, License.txt, 2026-09-29 evidence) versus 'License: CC0' (ASSETS.md line 49, License.txt re-check, 2026-10-01)"
    category: other
    reason: "Confirmed in the tree. Cosmetic: the two quotes are not marked as a transcription difference, so a reader could take them for evidence the page changed."
    evidence_status: "ASSETS.md lines 44-49 and License.txt read"
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
  - test: "Owner confirmation of the Quaternius horse licence decision (review WR-06 / open review WR-01)"
    expected: "Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release. Current state: on 2026-10-01 the owner chose to keep the horse and accept the residual risk; the records now give the real basis (CC0 on the author's pack page and Poly Pizza at retrieval, irrevocable dedication). The open review finding WR-01 notes that the 'not redistributed as a standalone asset' sentence is inaccurate because the unmodified GLB is in the public repo and the export; the owner should confirm the decision knowing that"
    why_human: "Legal/licence risk against the project's CC0-only constraint; owner decision, already given in chat on 2026-10-01 but not recorded through UAT"
  - test: "Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): hold the bound physical key's position and read the on-screen prompt"
    expected: "The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position"
    why_human: "The prompt names the key via DisplayServer.keyboard_get_label_from_physical (ui/hud/hud.gd), which is unavailable headless; only a fake-layout resolver seam is unit-tested"
  - test: "Owner confirmation that the widened CI trigger satisfies DEV-02 'on every push'"
    expected: "Owner confirms the trigger (push to any branch or tag, plus pull_request and workflow_dispatch). Current state: the trigger is widened, the branch was pushed on 2026-10-01 and push-event run 36831792141 on 4a9b775 is green in all four jobs (lint, test 290/290, export, screenshots 6 of 6). Of the nine commits after 51c8736, three edit licence and checksum documentation (6cdf386, 1784ffe, 1ce2f94) and six are planning docs; all three documentation edits precede 4a9b775. The four commits after 4a9b775 (398dde5, 9a2782a, 2528873, 3fa5e48) are planning docs only and are not pushed, so the green run covers the last non-planning state but not the literal HEAD"
    why_human: "Owner policy decision; the owner delegated the CI trigger on 2026-10-01 but has not confirmed it through UAT"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-01T08:08:30Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is feel and visual judgment, a non-QWERTY layout check, and owner confirmation of the horse licence and CI trigger decisions)
**Re-verification:** Yes. The previous report (2026-10-01T07:19:49Z) was stale because covered files changed. Every verdict below was regenerated from the current tree at HEAD 3fa5e48; none was copied.

## Change audit since the previous report

`git rev-list --count 51c8736..HEAD` is 9. `git diff --stat 51c8736 HEAD -- . ':!.planning'` touches exactly three files: `ASSETS.md`, `assets/attribution.json` (horse `notes`, one line) and `assets/third_party/quaternius_horse/License.txt`. No game code, test, tool, `project.godot` or workflow file changed, so the behavioural evidence stands; I re-ran it anyway (below). The only working-tree modification is `.planning/config.json`.

- 6cdf386: the three horse records now give the real basis for keeping the horse as CC0 (author's 2021 pack page and Poly Pizza both stated CC0 at retrieval; an earlier CC0 dedication is irrevocable) and record that the owner accepts the residual risk. They also state that the QAL v1.0 date precedes the retrieval, so the "time you obtained" clause does not favour CC0.
- 1784ffe and 1ce2f94: the ASSETS.md "Archive checksums and download evidence" section says what each SHA256 covers (read; correct against the table rows) and keeps the `curl --fail` evidence for the plan 01-07 downloads.
- The remaining six commits are planning docs (REVIEW-FIX, ledger, VALIDATION, SECURITY, a new REVIEW and its ledger).

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | `project.godot` `[input]` defines move, `sprint`, `action_build`, `start_night`, `toggle_debug_overlay`. King, camera-rig and spot-label tests pass in this pass's full run (290/290). CI `overlay_on.png` from run 36831792141 (downloaded and viewed) shows the mounted king (rider in T-pose on a small horse), the castle, two empty build plots, HUD `Gold: 30`. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | `command_processor.gd` `validate_build` (read) checks `is_build_allowed()` (NOT_DAY), then UNKNOWN_SPOT, then MAX_TIER, then CANNOT_AFFORD; `_submit_build` calls `try_spend` before `apply_next_tier` and emits `command_rejected` otherwise. `run_manager.is_build_allowed()` is `_phase == RunPhase.DAY`. Build, upgrade, affordability, range, NOT_DAY and refund tests pass in the full run. |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager._apply_dawn_payout` (read) grants the summed per-spot income via `_economy.grant(total)` when positive and emits `dawn_payout(total, per_spot)`; nothing resets gold. CI `dawn_payout.png` (viewed) shows two built Houses, gold coins in flight and the lagged HUD `Gold: 23`. Dawn income, payout VFX, HUD lag release, carryover and start-night hold tests pass. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED | Local: `bash tools/lint.sh` exit 0 (72 files unchanged, no problems); `bash tools/test.sh` run once, exit 0 (36 scripts, 290/290, 1881 asserts, 92.1 s). Trigger: `ci.yml` `on:` is `push:` (no filter), `pull_request:`, `workflow_dispatch:` (read, lines 12-15). Remote: `gh run view 36831792141` shows event `push`, head 4a9b775, conclusion success; jobs test, lint, export and screenshots all success; its log shows `Tests 290`, `Passing Tests 290`, `Asserts 1881` and `Saved 6 of 6 screenshots`; artifacts `duskhold-windows` (39.8 MB), `duskhold-screenshots` and `gut-results` are unexpired. `git ls-remote --heads origin` returns 4a9b775 for the phase branch. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | CI `overlay_on.png` (viewed) shows Perf (FPS), Loop (Phase DAY, Day 1, Night 0, Gold 30, Buildings 0) and Agents (Units 0, Enemies 0); low FPS is a software-render artifact. Overlay toggle, cadence, registration and bind tests pass in the 290/290 run. `assets/attribution.json` and `ASSETS.md` list the engine, GUT, three Kenney packs and the Quaternius horse; `test_attribution_log` passes. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

Behavior-dependent invariants (phase gating, refund on cancel, gold never negative, dawn payout landing inside the window, HUD lag release, carryover, start-night prompt follows rebinds, snapshot isolation, payout clamp, overlay registration and cadence) each have a named GUT test inside the 290/290 run. Only the real `DisplayServer.keyboard_get_label_from_physical` call cannot run headless and stays a human item.

Coincidental-reliance check: no truth holds on an undeclared precondition, unenforced ordering or fixture-only setup; `coincidental_reliance_items` is empty.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Advisory (not must-have failures)

The current 01-REVIEW.md (commit 2528873) has 3 OPEN findings, recorded `open: 3` in 01-REVIEW-DISPOSITION.md. None is addressed: 01-REVIEW-FIX.md belongs to the previous review (pass 25) and the IDs WR-01 and IN-01 are reused for different findings. I confirmed all three against the tree (see the `advisory` frontmatter):

- WR-01 (warning): the three horse records say the model is "not redistributed as a standalone asset", but `horse_animated.glb` is tracked via Git LFS in the public repo and ships in the export (`exclude_filter="tests/*, addons/gut/*, tools/*"`).
- IN-01 (info): ASSETS.md line 76 still says `sha256` is "of the downloaded archive".
- IN-02 (info): the 2021 pack page is quoted "License CC0" and "License: CC0" without noting a transcription difference.

None fails a roadmap success criterion or a requirement: every asset is in the log and the logged hashes are correct. They are surfaced because the owner's licence confirmation (UAT item 7) depends on the horse record. The reviewer's statements that the pack and Poly Pizza pages still state CC0 are not independently re-fetched by me.

### Required Artifacts

Plan frontmatter artifacts were verified in earlier passes for all ten plans (all present, none stub). No file under `simulation/`, `presentation/`, `input/`, `ui/`, `tools/`, `tests/`, `project.godot` or `.github/` changed since the last report; I re-read the load-bearing ones (command_processor, run_manager, ci.yml, export_presets.cfg, attribution docs) and the full suite exercises the rest: 290/290.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| build_hold_controller | command_processor | `submit(BuildIntent)` | WIRED (unchanged; covered by tests) |
| command_processor | economy / building_system | `try_spend`, `apply_next_tier` (read) | WIRED |
| start_night_hold_controller | command_processor | `submit(StartNightIntent)` -> `start_night()` (read) | WIRED |
| run_manager | economy | dawn payout `grant` (read) | WIRED |
| hud | dawn_payout_vfx / run_manager | `payout_started`, `coin_landed`, `phase_changed` | WIRED (dawn_payout.png shows lagged counter) |
| debug_overlay | debug_overlay_model | `bind_run` / `_refresh` | WIRED (overlay_on.png) |
| ci.yml | tools/*.sh, bootstrap.py | same wrappers as local | WIRED (run 36831792141 green) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| HUD gold label | economy gold minus in-flight coins minus payout lag | `Economy.get_gold()`, `payout_started`, `coin_landed` | Yes (`dawn_payout.png`: Gold 23 with coins in flight) | FLOWING |
| Dawn payout "+X gold" | per_spot sum | `SimEvents.dawn_payout` from `RunManager._apply_dawn_payout` (the label sum equals the granted sum) | Yes | FLOWING |
| Start-night prompt | phase, night number | `RunManager.get_phase()` | Yes (`overlay_on.png`: "Hold N / (Y) to start Night 1") | FLOWING |
| Debug overlay | FPS, phase, day, night, gold, buildings, agent counts | Engine + RunContext (units/enemies honestly 0 until Phase 2) | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full headless GUT suite (run once) | `bash tools/test.sh` | 36 scripts, 290/290, 1881 asserts, 92.1 s, exit 0 | PASS |
| Lint and format | `bash tools/lint.sh` | 72 files unchanged, no problems, exit 0 | PASS |
| Debt markers | grep `TBD\|FIXME\|XXX\|TODO\|HACK` over simulation, presentation, ui, input, tools, tests, data, .github | no matches | PASS |
| Remote CI on pushed tip | `gh run view 36831792141`; artifacts API | push event, 4a9b775, success; four jobs green; test 290/290; 6 of 6 screenshots; 3 artifacts unexpired | PASS |
| Screenshots | downloaded `duskhold-screenshots` (scratchpad, outside the repo); viewed `overlay_on.png` and `dawn_payout.png` | six PNGs; both viewed are real renders of the running game | PASS |
| Remote branch tip | `git ls-remote --heads origin` | 4a9b775 | PASS |

I did not re-run `tools/screenshot.sh` or `tools/export.sh` locally; the CI run on 4a9b775 produced both outputs. No Godot process was left running and the working tree holds only the pre-existing `.planning/config.json` modification (build output is git-ignored).

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
| ART-02 | 01-07 | SATISFIED (horse documentation flagged open, see Advisory; owner confirmation pending) | attribution.json, ASSETS.md, `test_attribution_log` |
| DEV-01 | 01-01, 01-02 | SATISFIED | headless RunContext, 290 tests |
| DEV-02 | 01-01, 01-03, 01-10 | SATISFIED | unfiltered `push:` trigger; push-event run green on 4a9b775 |
| DEV-03 | 01-08 | SATISFIED for Phase 1 scope | overlay tests, `overlay_on.png`; wave/pathing deferred to Phase 2 |
| DEV-04 | 01-10 | SATISFIED | screenshot.sh, CI job, 6 of 6 PNGs |

### Anti-Patterns Found

No debt markers in source, tests, tools or workflow. No stubs, hollow props or static-return data paths in the files I read. Open review findings: WR-01 (warning), IN-01 and IN-02 (info), all documentation soundness (see Advisory).

### Human Verification Required

See the `human_verification` list in the frontmatter: 9 items, matching 01-UAT.md by position. Items 7 and 9 have refreshed `expected:` text recording the 2026-10-01 owner decisions and the current CI state; 01-UAT.md still has 9 pending items and the owner has not run it.

### Gaps Summary

No must-have gaps. Every ROADMAP success criterion is backed by source I read, a full passing suite I ran (290/290, lint clean), and a green push-event CI run on 4a9b775 whose log and artifacts I inspected; no commit after it changes a non-planning file (the three non-planning commits precede 4a9b775). Status stays `human_needed` because riding feel, map and label readability, model look, overlay look, night/dawn VFX and HUD-lag feel, the non-QWERTY key label, and the owner's confirmation of the horse licence and CI trigger decisions cannot be verified programmatically. Three review findings remain open and are not fixed by this verification.

---

_Verified: 2026-10-01T08:08:30Z_
_Verifier: Claude (gsd-verifier)_
