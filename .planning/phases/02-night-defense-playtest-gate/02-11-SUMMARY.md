---
phase: 02-night-defense-playtest-gate
plan: 11
subsystem: testing
tags: [godot, gdscript, screenshots, ci, playtest-gate, readability, dev-04, dev-05]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: PlaytestStrategies and PlaytestBot (02-10), the night presentation to be looked at (02-03 to 02-08), the replay checks and the push routine (02-09), the balance report (02-10)
provides:
  - fifteen scripted screenshot scenes (the seven Phase 1 shots plus eight night shots), each failing with exit 1 when its scene was not reached
  - ShotScenarios.map_for, giving each shot its own deep-copied map, and the shot-list drift guard test_shot_list.gd
  - a Claude readability review of every new night visual, with one presentation fix and a list of open points for the owner
  - a green CI run for the final phase state (lint, test with the replay checks, export, screenshots with 15 PNGs)
  - a launch-checked Windows build and 02-PLAYTEST-GATE.md, the owner's packet with the 13 assumptions made on their behalf
affects: [phase-2-verification, phase-3, playtest-gate, ci]

actuals:
  tokens: 9700
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Night screenshots reach their state by the same bot-then-step loop as a headless replay (ShotScenarios._fast_forward), then finish in real time; they still never write simulation state"
    - "A shot whose scene would be over in a second of real time places the king node, and so the camera, before the fast-forward and runs the bot's king in hold-point mode at that spot"
    - "A scenario that fails prints one line of run state (tick, phase, night, enemies, king and castle hp) before exiting 1"

key-files:
  created:
    - tests/unit/test_shot_list.gd
    - tests/unit/test_shot_list.gd.uid
    - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
  modified:
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot/shot_runner.gd
    - tools/screenshot.sh
    - presentation/vfx/projectile_vfx.gd
    - .github/workflows/ci.yml

key-decisions:
  - "Projectile arrows are 0.15 m by 1 m (were 0.07 m by 0.8 m): a skirmisher arrow read as a 2-pixel sliver at game camera distance; colours and emission unchanged, no asset added"
  - "The night shots use named bots: balanced for night_combat, king_down_countdown, results_victory and overlay_paths; greedy_economy for building_destroyed and dawn_rebuilt (it builds only Houses, so night 3 costs it one); no_build for results_defeat"
  - "Readability points that sit outside this plan's files (results screen layout, debug path line width, dawn coin size) are recorded in the owner packet, not changed"
  - "The screenshots job timeout is 30 minutes; nothing else in ci.yml changed (permissions contents: read, no secrets, every uses: SHA as before)"

patterns-established:
  - "ShotScenarios.map_for owns every shot's map copy; ShotRunner only adds fixed_run_seed = 1 and handle_results_actions = false"
  - "Presentation fixes in a review plan are limited to colours, emission, sizes and outlines of the existing primitives"

requirements-completed: [LOOP-01, LOOP-02, LOOP-03, LOOP-04, LOOP-05, LOOP-06, LOOP-07, KING-03, KING-06, BLDG-07, DEV-05]

coverage:
  - id: D1
    description: "bash tools/screenshot.sh captures 15 scripted scenes, each failing (exit 1) when its scene did not reach the state it shows, and the bash and GDScript shot lists agree"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "rm -f screenshots/*.png && bash tools/screenshot.sh saved 15 of 15 PNGs, every new one non-empty and past the blank check"
        status: pass
      - kind: unit
        ref: "tests/unit/test_shot_list.gd (5 tests: list equality and order, 15 distinct names, map_for for every name, deep copies, per-shot map)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Claude opened every new night screenshot (local and from CI) against a readability checklist and fixed what it could inside the allowed files"
    requirement: KING-03
    verification:
      - kind: other
        ref: "the screenshot review lines in this SUMMARY and in 02-PLAYTEST-GATE.md; arrows thickened in presentation/vfx/projectile_vfx.gd"
        status: pass
    human_judgment: true
    rationale: "Whether the night looks readable and good is the owner's judgment; the open points (results layout, hairline path lines, small coins) are listed for them"
  - id: D3
    description: "The final phase state is pushed and CI is green on lint, test (with the replay checks), export and screenshots, with 15 PNGs in the artifact"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/37325147907 on dd5428c: lint, test, export, screenshots all success; artifacts duskhold-windows and duskhold-screenshots (15 PNGs) present"
        status: pass
    human_judgment: false
  - id: D4
    description: "A locally exported Windows build launches"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "bash tools/export.sh then timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 exited 0 in 7.6 s"
        status: pass
    human_judgment: false
  - id: D5
    description: "The playtest gate packet lists how to play, what to judge, what Claude checked, the balance summary, the screenshot review and the 13 assumptions made on the owner's behalf"
    requirement: LOOP-07
    verification:
      - kind: other
        ref: ".planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md contains the five sections; its balance table equals the summary table in 02-BALANCE-REPORT.md"
        status: pass
    human_judgment: false
  - id: D6
    description: "The owner plays one or two full runs and either signs off that gold trade-offs feel meaningful and nights feel tense and readable, or names the fixes that must land before Phase 3 (ROADMAP success criterion 4, D-18)"
    requirement: LOOP-07
    verification:
      - kind: other
        ref: "02-PLAYTEST-GATE.md Your decision section; recorded through /gsd-verify-work"
        status: unknown
    human_judgment: true
    rationale: "Fun, tension and fairness are the owner's call; the bots' results and Claude's screenshot review are not the sign-off (D-18)"

duration: 51 min
completed: 2026-10-05
status: complete
plan_head_before: db554e6f67af9a6a8ec7dae4ec8ad8176d423f02
plan_head_after: b7fb6fbeeb4fdcff6af3dc3ffe636d2456b1a56e
---

# Phase 2 Plan 11: Night screenshots, final push and the playtest gate Summary

**Eight scripted night screenshots driven by named bots and a shot-list drift guard, a first readability review of every night visual with arrows thickened, a green CI run with 15 screenshots, a launch-checked Windows export and the owner's playtest packet with the 13 assumptions made for them**

## Performance

- **Duration:** about 51 min (the work started right after the 02-10 close-out at 18:45 local)
- **Completed:** 2026-10-05T14:38Z
- **Tasks:** 3
- **Files:** 8 changed in git by the plan (3 created including a `.uid`, 5 modified)

## Accomplishments

- `bash tools/screenshot.sh` now captures 15 scenes. The eight new ones fast-forward the simulation with a named bot through `ctx.step()` (the loop a headless replay runs) and finish in real time; each returns false, prints a line of run state and exits 1 when its scene was not reached.
- `ShotScenarios.map_for` gives every shot its own deep-copied map (results_victory is cut to one night, results_defeat has a castle of 1 hp, the timed-night shots keep their waveless copy); `ShotRunner` fixes `fixed_run_seed = 1` and turns the results buttons off.
- `tests/unit/test_shot_list.gd` fails when the `ALL_SHOTS` list in `tools/screenshot.sh` and `ShotScenarios.ALL_SHOTS` differ in names or order, and checks the per-shot map copies.
- CI run https://github.com/ABSAR07/duskhold/actions/runs/37325147907 (head `dd5428c`) is green on lint, test (with the replay checks), export and screenshots; the screenshots artifact holds 15 PNGs.
- `build/windows/Duskhold.exe` exports and exits 0 under `--headless --quit-after 120` in 7.6 s.
- `02-PLAYTEST-GATE.md` is the owner's packet: how to play, what to judge, what Claude checked (tests, replays, CI, export, the balance table from 02-BALANCE-REPORT.md, the screenshot review), the 13 assumptions and the decision section.

## Screenshot review (read by Claude after capture; first real look at these visuals)

Local captures (Forward+, RTX 3060 laptop) were opened with the Read tool; the CI captures (Compatibility renderer, Mesa) look flatter and lighter with the same content.

| Shot | What it shows | Result |
|---|---|---|
| spawn_telegraph | Day, tower_1 standing; a red disc with "5" over the west road's spawn, hold-N prompt and "Night 1: 5 enemies from 1 direction" | Pass; disc is small (44 px) but legible |
| night_combat | Night 5 beside the west tower: red grunts and taller violet skirmishers clearly stand out from the ground and from each other; a violet arrow in flight (visible after the thickening); "Night 5 of 8 - 16 enemies left" | Pass; enemy bars show only on hurt enemies and none were hurt in this frame |
| building_destroyed | Night 3: dark rubble slabs on a pale plot disc, castle top left, grunts with health bars, the king's bar, "+13 gold" | Pass; rubble is dark on the dark ground and relies on the disc beneath it |
| dawn_rebuilt | Dawn: two rebuilt Houses, each with a gold coin crossed out in red | Pass; coin is small (26 px) and sits on the red roof |
| king_down_countdown | Night 7: cyan ghost king capsule, "Knocked out - back in 6 s" in cyan, a violet skirmisher, yellow tower arrows | Pass; the arrow cluster is a fast-forward artifact |
| results_victory | "Victory", Nights survived 1 of 1, three more stat rows, Play again (outlined) and Quit | Pass; layout issue below |
| results_defeat | "Defeat", Nights survived 0 of 8, the fallen castle and grunts behind the panel | Pass; layout issue below |
| overlay_paths | F3 overlay on the right (Perf, Loop, Agents, Wave, King, Paths), king, tower, a grunt, path lines | Pass; the lines are 1 px hairlines |

Open points left for the owner (outside this plan's files): the results screen stat rows sit directly on the buttons and Quit has almost no contrast against the panel; the overlay's path lines are faint hairlines; the dawn crossed-out coin is small. The overlay FPS row (18 to 24) is distorted by each shot's single long fast-forward frame and is not a performance reading.

## Task Commits

1. **Task 1: Eight night screenshots, shot-list guard, readability review** - `7948901` (feat)
2. **Task 2: screenshots job timeout 30 minutes, final push, green CI** - `dd5428c` (chore); push `0b66929..dd5428c`, CI run 37325147907 success
3. **Task 3: playtest packet and launch check** - `b7fb6fb` (docs)

**Plan metadata:** recorded in the docs commit that carries this summary.

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] First night_combat design could never show a crowd**
- **Found during:** Task 1 (first capture)
- **Issue:** Stopping when 3 enemies stood near tower_1 and then moving the king there left 1.2 s of real time for the camera; the tower and king killed the grunts in that time (no enemy near, no arrow), and on the shipped data a crowd of 3 only forms on night 5.
- **Fix:** The king node (and the bot's hold point) goes to the tower's road side before the fast-forward, so the camera is already there when the scene is reached. The same ordering is used for king_down_countdown and overlay_paths.
- **Files modified:** tools/screenshot/shot_scenarios.gd
- **Verification:** 15 of 15 screenshots saved locally and in CI
- **Committed in:** 7948901

**2. [Rule 1 - Bug] Overlay toggle missed after a timer wait**
- **Found during:** Task 1 (overlay_paths)
- **Issue:** `Input.action_press` right after a timer wait lands after the overlay's `_process` in that frame, so its `is_action_just_pressed` check never fires.
- **Fix:** One extra frame is waited before pressing (commented in the scenario).
- **Files modified:** tools/screenshot/shot_scenarios.gd
- **Committed in:** 7948901

**3. [Rule 2 - Missing critical] Failure diagnostics in the new scenarios**
- **Found during:** Task 1
- **Issue:** A scenario that failed silently exit 1 gave no way to tell which condition missed.
- **Fix:** Each night scenario prints a one-line run state (`_state_line`) when it fails.
- **Files modified:** tools/screenshot/shot_scenarios.gd
- **Committed in:** 7948901

**4. Scenario bot choices differ slightly from the plan's wording**
- `building_destroyed` and `dawn_rebuilt` use `greedy_economy` (Houses only, so night 3 costs it Houses) rather than a generic "fast-forward"; `king_down_countdown` runs the balanced bot with the king at the busiest spawn point and the camera placed first, since the greedy bot's castle falls on night 3 before the king goes down. `night_combat` is reached on night 5, not night 1, because a night-1 crowd never forms on the tuned data.

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical) plus the bot choices above.
**Impact on plan:** None on scope. Additions beyond the plan: `ShotScenarios.SHOT_STARTING_GOLD` and `MAP_DATA_PATH` moved from ShotRunner into ShotScenarios (`map_for` needs them); `test_shot_list.gd` also covers the per-shot map copies.

## Issues Encountered

- A bulk Python edit of `shot_scenarios.gd` did nothing once because the working tree has CRLF line endings; later edits normalised line endings before replacing.
- Nothing visual from plans 02-03 to 02-08 had been seen before this plan; the review above is the first look. Only the arrow thickness failed the checklist inside the allowed files.

## Known Stubs

None.

## Authentication Gates

None. `gh auth status` was already logged in as ABSAR07.

## User Setup Required

None.

## Threat Surface

No new surface beyond the plan's threat model. `tools/prepush_check.sh` passed before the single push (T-02-24); the ci.yml change is only `timeout-minutes` (T-02-26: `contents: read`, no secrets, action SHAs untouched); the screenshots artifact holds only the game's own images (T-02-25).

## Next Phase Readiness

- The owner's gate is open: read `02-PLAYTEST-GATE.md`, play one or two runs, then sign off or list fixes through `/gsd-verify-work`. Under `human_verify_mode` end-of-phase the orchestrator collects that at the end of the phase. No Phase 3 work starts before the decision.
- If the owner asks for readability fixes, the candidates are `ui/results/results_screen.tscn` (spacing and a Quit border), `presentation/debug/enemy_path_gizmo.gd` (line visibility), `ui/hud/dawn_no_income_marker.gd` (mark size) and `ui/world/spawn_telegraph.gd` (disc size).

## Self-Check: PASSED

- Files exist: tools/screenshot/shot_scenarios.gd, tests/unit/test_shot_list.gd, 02-PLAYTEST-GATE.md, build/windows/Duskhold.exe (checked with `[ -f ]`).
- Commits exist: 7948901, dd5428c, b7fb6fb (`git rev-list --count db554e6..HEAD` is 3 before this summary's commit).
- Plan-level verification: `bash tools/screenshot.sh` saved 15 of 15; `bash tools/test.sh` 719 passing in 85 scripts with test_shot_list and test_shot_blank_check in the JUnit XML; `bash tools/lint.sh` clean; CI run 37325147907 for the pushed head concluded success with both artifacts and 15 PNGs; the packet has its five sections.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*
