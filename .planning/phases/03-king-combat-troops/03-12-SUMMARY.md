---
phase: 03-king-combat-troops
plan: 12
subsystem: testing
tags: [godot, gdscript, screenshots, ci, playtest-gate, hud, gamepad, mouse]

requires:
  - phase: 03-king-combat-troops
    provides: "squads, commands, HUD widgets, prompts and the balance retune (plans 03-01 to 03-11) that the shots and the packet cover"
provides:
  - "Eighteen scripted real-window screenshots of the army HUD and commands, 33 shots in all, each hud_ and cmd_ shot held to the clear centre by the shot runner"
  - "ShotRunner.protected_violations and PROTECTED_RECT (UI-SPEC D-21), with unit tests"
  - "A green CI run for the branch head on all four jobs with both replay goldens and 33 screenshots"
  - "A launch-checked Windows export and 03-PLAYTEST-GATE.md, the owner's Phase 3 gate packet"
affects: [phase-03-verification, phase-04-crowd-scale-battles, owner-playtest-gate]

actuals:
  tokens: 30400
  tasks: 3
  commits: 5
plan_head_before: 83949de31318171119d10ea9950750d8fc85be54
plan_head_after: ad29c2d0afa3b46f2a5a6a0362462431521f7bb1

tech-stack:
  added: []
  patterns:
    - "Shot scenes drive real input events (Input.parse_input_event for mouse and pad), Input Map actions and the bot-then-step replay loop; nothing writes simulation state"
    - "Scenes that depend on a short-lived effect (ping, slam ring, ready flash) are written for a frame that may last 150 ms on the CI software renderer"
    - "A shot-only copy of the king (regeneration off, 120 health) and of the map (twelve one-grunt nights), made by ShotScenarios.map_for and king_def_for"

key-files:
  created:
    - tools/screenshot/shot_army_scenarios.gd
    - tests/unit/test_shot_protected_centre.gd
    - .planning/phases/03-king-combat-troops/03-PLAYTEST-GATE.md
  modified:
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot/shot_runner.gd
    - tools/screenshot.sh
    - tests/unit/test_shot_list.gd
    - presentation/units/squad_plan_view.gd
    - .github/workflows/ci.yml

key-decisions:
  - "The eighteen scenes live in a new ShotArmyScenarios file (ShotScenarios would have passed gdlint's 1000-line cap); ShotScenarios still owns the names, the ALL_SHOTS list, map_for and king_def_for"
  - "Shots that hurt the king run on a king copy with regeneration off, so the health number the shot reaches is the one captured; the shipped king is untouched (pinned by a test)"
  - "The slot, ping and slam scenes read their short-lived effect at once after the click or press, so they hold on a slow renderer"
  - "The screenshots job keeps the 60-minute timeout the plan asked for although it needs 2 to 3 minutes"
  - "E6 (the longest toast inside x 384..896) is left human_needed: the line is 526 px wide, x 377..903, below the clear centre but 7 px past the literal band on each side"

patterns-established:
  - "A shot whose name starts with hud_ or cmd_ fails (exit 1) when a visible HUD control other than the exempt nodes sits in x 384..896, y 96..500"

requirements-completed: [UI-01, INPT-01, INPT-02, KING-04, KING-05, UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10]

coverage:
  - id: D1
    description: "Eighteen scripted real-window screenshots (seven UI-SPEC scenarios, 1080p and 16:10 variants, five backstop shots, four command runs), all non-blank, 33 shots in the wrapper and the scenario list"
    requirement: "UI-01"
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh (Saved 33 of 33 screenshots, exit 0, local Forward+) and CI run 38219154906 (33 of 33)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_shot_list.gd (both lists identical, 33 names, the eighteen listed last)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The runner's protected-centre check: no visible HUD control other than the exempt nodes inside x 384..896, y 96..500 on any hud_ or cmd_ shot, at 1280x720, 1920x1080 and 16:10"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_shot_protected_centre.gd (11 tests)"
        status: pass
      - kind: automated_ui
        ref: "the 18 new shots exit 0 locally and on CI, which they cannot do with an offender"
        status: pass
    human_judgment: false
  - id: D3
    description: "Six of the seven UI-SPEC backstop rows (E1, E2, E3, E5, E7, E9) confirmed by named shots"
    verification:
      - kind: automated_ui
        ref: "hud_day_counter_long, hud_king_120, hud_rubble_squad (fill stopped 0.223 / 0.223), hud_day_squads and hud_night_squad_down_16x10, hud_keycap_backspace, cmd_queue_ten (9 kept, 6 discs)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Backstop row E6: the longest toast on one line inside x 384..896"
    verification:
      - kind: automated_ui
        ref: "hud_long_toast (one line, y 504..536, 526 px wide at x 377..903)"
        status: unknown
    human_judgment: true
    rationale: "The line is below the clear centre and on one line, but it is 526 px wide, 7 px past the literal x band on each side; whether that is acceptable is the owner's call"
  - id: D5
    description: "The latest CI run on the branch head succeeded on lint, test, export and screenshots with both replay goldens"
    verification:
      - kind: integration
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/38219154906 on c418b6c (REPLAY_OK smoke, army and full_idle; 33 of 33 screenshots)"
        status: pass
    human_judgment: false
  - id: D6
    description: "A fresh Windows export that launches and exits inside 90 s, and the owner's gate packet with the five required sections and fifteen assumptions"
    verification:
      - kind: other
        ref: "bash tools/export.sh; timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (exit 0 in 3 s)"
        status: pass
    human_judgment: true
    rationale: "The packet opens the owner's feel gate (ROADMAP success criteria 1 to 5, D-08); only the owner can judge squad feel, command feel, the slam, regeneration and night readability, and sign-off is recorded through /gsd-verify-work"

duration: 2h 13m
completed: 2026-10-12
status: complete
---

# Phase 3 Plan 12: The Phase 3 Gate Summary

**Eighteen real-window shots of the army HUD and commands, each held to the clear centre by the runner, a green CI run with both replay goldens and 33 screenshots, and a launch-checked build with the owner's gate packet of fifteen assumptions**

## Performance

- **Duration:** 2h 13m
- **Started:** 2026-10-12T05:44:23Z
- **Completed:** 2026-10-12T07:58:00Z
- **Tasks:** 3 (all type="auto", no checkpoints)
- **Files modified:** 11 (3 created, 6 modified in the commits below, plus the packet and this summary)
- **Commits:** 5 production and packet commits (measured from the persisted head ledger)

## Accomplishments

- `ShotArmyScenarios` holds the eighteen Phase 3 scenes and `ShotScenarios` lists them (33 names, kept identical in `tools/screenshot.sh`, whose resolution follows the name suffix: 1920x1080 for `_1080p`, 1600x1000 for `_16x10`, 1280x720 otherwise; the xvfb screen is now 1920x1080).
- `ShotRunner.protected_violations` and `PROTECTED_RECT` fail any `hud_` or `cmd_` shot with a visible HUD control in x 384..896, y 96..500, apart from the banner, the knocked-out label, the drag box while dragging and the world-marker layers; 11 unit tests pin the rule.
- CI on the branch head `c418b6c` is green on all four jobs with `REPLAY_OK` for smoke, army and full_idle and 33 of 33 screenshots.
- A fresh Windows export that exits 0 in 3 s under `--headless --quit-after 120`, and `03-PLAYTEST-GATE.md` with How to play (both devices), What to judge, What Claude already checked, 15 assumptions and the owner's decision.

## Task Commits

1. **Task 1: Eighteen real-window screenshots with the clear-centre check and the readability review** - `e7c3319` (feat)
2. **Task 2: Push and CI green** - `549e53c` (ci: screenshots job timeout 60 minutes), then two CI-driven fixes `85990e9` and `c418b6c` (fix)
3. **Task 3: Launch-checked build and the owner packet** - `ad29c2d` (docs)

**Plan metadata:** the commit that carries this summary, STATE.md, ROADMAP.md and REQUIREMENTS.md (docs: complete plan)

## Verification run

- `bash tools/screenshot.sh` locally: "Saved 33 of 33 screenshots", exit 0; the wrapper's `ALL_SHOTS` holds 33 names; every one of the eighteen new PNGs is non-empty.
- `bash tools/test.sh`: 1373 tests in 148 scripts, all passing, 15364 asserts, exit 0 (630 s); `test_shot_list`, `test_shot_blank_check` and `test_shot_protected_centre` are in the JUnit XML. `bash tools/lint.sh`: clean.
- Replays: `REPLAY_OK scenario=smoke ... digest=2599c7c2...` and `REPLAY_OK scenario=army ... digest=f7a967ed...`, both twice, goldens unchanged.
- CI run https://github.com/ABSAR07/duskhold/actions/runs/38219154906 on `c418b6c` (HEAD at the time of the check): lint, test, export and screenshots all success; the log has `REPLAY_OK scenario=smoke`, `scenario=army` and `scenario=full_idle`; the downloaded `duskhold-screenshots` artifact holds 33 PNGs. `.github/workflows/ci.yml` has `timeout-minutes: 60` on the screenshots job and still `contents: read`.
- `bash tools/export.sh` then `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120`: exit 0 in 3 s; the packet has all five sections and names A1, A2, A4, A5, A6, A7, A8, A11, A12 and A14; its balance table is the 03-BALANCE-REPORT.md table cell for cell.

## Screenshot review (local Forward+ and the CI artifact)

Every image was opened with the Read tool. CI images (Compatibility renderer under Mesa) are flatter and paler; the content is the same.

| Shot | Local review | CI note |
|---|---|---|
| `hud_day_squads` | Both slots 4 / 4, Barracks outlined, 7-item hint row at y 504..536, rings under the four footmen, king widget bottom-left, start-night prompt below the slots; the centre is empty | Same content, paler ground |
| `hud_night_squad_down` | Night 7 of 8, 9 left: red 0 / 4 slot with a fill on its way, Range 3 / 4, king 36 / 50, cyan X-ray silhouette behind the keep; text reads on the dark ground | Same |
| `hud_drag_box` | Cyan drag box (fill and 2 px border) across the keep, slots unselected, no hint row | Same |
| `hud_pad_cursor` | Y and X tiles on the prompts, cursor ring and line toward the east, "Aim with the right stick, release to confirm" in the hint slot | Same |
| `hud_king_down` | Widget at alpha 0.4 with a red 0 / 50, "Knocked out - back in 6 s" under the banner, slots intact | Same |
| `hud_ability_ready` | Ready flash: plate border, caption and glyph tinted cyan; no slam ring left in frame | The flash is not caught on the slower frame; the border is cyan |
| `hud_long_toast` | One line at y 504..536, 526 px wide, x 377..903 (7 px past the literal band), dark void right of the ground | Same, identical width |
| `hud_day_squads_1080p` | 1920x1050 locally (title bar), HUD scaled uniformly, nothing overlaps | Exactly 1920x1080, same layout |
| `hud_night_squad_down_16x10` | 1600x1000, hint row 398..1205 px clears the king widget and slots, banner centred | Same |
| `hud_day_counter_long` | "Night 12 of 12" on one centred line | Same |
| `hud_king_120` | 90 / 120 beside the bar; the bar keeps its x, the label grows right | Same |
| `hud_keycap_backspace` | "Backspace" keycap plate, wider than the 24 px tiles, not clipped, row still centred | Same |
| `cmd_queue_ten` | Six numbered discs 1 to 6 joined by a line (nine orders kept), readable after the label fix | Same, digits legible |
| `hud_rubble_squad` | Night 5: Barracks slot selected with a dimmed icon and a red 0 / 4, rubble on the plot; fill frozen at 0.223 | Same |
| `cmd_box_select` | Both slots outlined, rings under all eight units, hint row shown, box gone | Same |
| `cmd_move_ping` | Small cyan ping ring near the click, footmen moving | Ring fainter, same place |
| `cmd_patrol` | Dashed beige line from the squad to a gold end disc, double-arrow stance glyph | Same |
| `cmd_slam` | White slam ring about 2.5 m out amid the footmen and a grunt, tower arrows | Ring now caught (it was missing in run 2) |

### Backstop rows, one by one

| Row | Shot | Result |
|---|---|---|
| E1 long-text, "Night 12 of 12" on one centred line | `hud_day_counter_long` | Confirmed |
| E2 long-text, a 120 health king, label grows right without reflow | `hud_king_120` | Confirmed |
| E3 partial, Barracks rubble: slot kept, "0 / N" dimmed, fill stopped | `hud_rubble_squad` | Confirmed (image, and 0.223 then 0.223 half a second apart) |
| E5 overflow, the 7 hint items clear the king widget and the slots | `hud_day_squads` and `hud_night_squad_down_16x10` | Confirmed (row about 646 px, not the 610 estimated) |
| E6 long-text, the longest toast inside x 384..896 | `hud_long_toast` | **human_needed**: one line, below the clear centre, 526 px wide at x 377..903 |
| E7 long-text, "Backspace" widens the keycap without clipping | `hud_keycap_backspace` | Confirmed |
| E9 overflow, the queue capped at 9 and one-digit discs | `cmd_queue_ten` | Confirmed (nine kept, six discs, digits 1 to 6) |

[edge UI-01] adjacency: every `hud_` and `cmd_` shot passes the runner's clear-centre check at 1280x720, at 1920x1080 (1920x1050 locally) and at 16:10; the widgets stand apart on all of them. The hint row shows only on the shots with a squad selected, and the two shots with no squads at all (`hud_king_120`, `hud_day_counter_long`) show neither strip nor hints.

RESEARCH A9: confirmed by a one-off probe (not in the repository). In a real window at 1280x720, 1920x1050 and 1600x1000 a left click at the window position of an archer puppet's projected point selected the archery squad; the canvas-to-window transform scales by 1, 1.459 and 1.25.

## Decisions Made

- Eighteen scenes in a new `ShotArmyScenarios` file, because adding them to `shot_scenarios.gd` would pass the 1000-line gdlint cap; the names, `ALL_SHOTS`, `map_for` and `king_def_for` stay in `ShotScenarios`.
- Shots that hurt the king (`hud_night_squad_down`, its 16:10 twin, `hud_king_down`, `hud_king_120`) use a shot-only king copy with regeneration off, like `king_down_countdown`; the shipped king is pinned unchanged by `test_shot_list`.
- Night scenes for an army with no towers: the bot builds the Barracks, the Range and two Houses, both squads hold at the start of every night, and the king idles at the keep until night 4 and then defends the nearest threat. That reaches "a squad at 0 alive and the king at 36 / 50" on night 7 (a squad at 0 on night 5 with the king at 50 was the other candidate).
- The 60-minute screenshots timeout the plan asked for stays although the job needs 2 to 3 minutes.
- E6 and the 526 px toast are left to the owner rather than passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The scenes live in a new file**
- **Found during:** Task 1
- **Issue:** The plan's file list has only `shot_scenarios.gd`; 564 lines plus about 690 would pass the 1000-line gdlint cap.
- **Fix:** `tools/screenshot/shot_army_scenarios.gd` (class `ShotArmyScenarios`) holds the scenes; `ShotScenarios` keeps the names and dispatches to it.
- **Files modified:** tools/screenshot/shot_army_scenarios.gd, tools/screenshot/shot_scenarios.gd
- **Committed in:** e7c3319

**2. [Rule 2 - Missing critical] A unit test for the clear-centre check**
- **Found during:** Task 1
- **Issue:** The plan names `test_shot_list` only, but the check that decides a shot passes or fails needs its own proof.
- **Fix:** `tests/unit/test_shot_protected_centre.gd` (11 tests on stand-in layers); the first full run failed one test (a geometry slip in the test, not the check), fixed before the commit.
- **Committed in:** e7c3319

**3. [Rule 2 - Presentation fix] Queued-order disc numbers enlarged and raised**
- **Found during:** Task 1 readability review (`cmd_queue_ten`)
- **Issue:** The digits were about 9 px high on a 1280x720 frame, white on a light-cyan disc, hard to read.
- **Fix:** `LABEL_PIXEL_SIZE` 0.02 to 0.032 and `LABEL_HEIGHT` 0.15 to 0.45 in `presentation/units/squad_plan_view.gd`, a file outside the plan's list but the same kind of marker size and height fix it permits. No test pinned either constant; the suite stays green and both goldens are unchanged.
- **Committed in:** e7c3319

**4. [Rule 1 - Bug] Two shots failed on the CI software renderer**
- **Found during:** Task 2, run 38215930089 (31 of 33 saved)
- **Issue:** `cmd_queue_ten` kept 7 orders instead of 9 (the first leg ended while ten clicks were given over about 40 slow frames) and `cmd_move_ping` found no ping (it lives half a second).
- **Fix:** the queue shot holds the map's simulation still (`map_root.set_process(false)`) while the clicks go in; the ping shot reads the ping one frame after the click. `Input.parse_input_event` is delivered at the frame boundary, so the burst-without-frames idea was tried and dropped.
- **Committed in:** 85990e9

**5. [Rule 1 - Bug] The CI slam shot showed no ring**
- **Found during:** Task 2, review of the run-2 artifact
- **Issue:** Three frames of key hold took longer than the ring's quarter second on CI.
- **Fix:** the key is held only until the ring exists and the shot follows a 0.1 s timer.
- **Committed in:** c418b6c

**Total deviations:** 5 auto-fixed (2 bugs, 2 missing critical or presentation, 1 blocking). **Impact on plan:** none on scope; CI needed three runs, the plan's limit.

### Other differences worth knowing

- The local 1080p shot is 1920x1050 (the title bar leaves no room for 1080 rows on this laptop); CI's is exactly 1920x1080.
- `hud_king_down` plays the balanced build with both squads built first and holding, and the king held at the busiest spawn; the army bot's king never fell, so it could not be used.

## Issues Encountered

- A first attempt at this plan stopped on a provider quota limit before any commit; nothing needed reconciling.
- The first push of the plan went to CI with the 33-shot set and failed two shots (above); the plan's three-cycle fix limit was used (runs 38215930089 red, 38217462543 green, 38219154906 green on the final head).
- `hud_pad_cursor` failed once locally because the desktop mouse nudged the device tracker back to keyboard; the scene now repeats a pad button press until the tracker agrees.
- The probe patch for RESEARCH A9 was reverted before any commit (the tree was clean afterwards).

## Open points for the owner (also in the packet)

- E6: the longest toast is 526 px, x 377..903, 7 px past x 384..896 on each side.
- Copy: "1 enemies left" and "Night 12: 1 enemies from 1 direction" at a count of one (Phase 2 strings in `hud.gd`, outside this plan).
- A "+2 gold" payout line stays under the gold counter through the day and the next night (Phase 1 label).
- The patrol line is thin beige dashes at 80 % alpha on the green ground.
- Every pad event was synthetic; feel on a physical pad, the 900 px/s cursor and the squads' behaviour in motion are untested.
- The squads are not stronger than towers per gold under the bots, and the balanced bot still loses 1 of 10, not 2 or 3 (03-BALANCE-REPORT.md).

## Known Stubs

None. Nothing in this plan renders hardcoded or placeholder data.

## Threat Flags

None. The only change at a trust boundary is the screenshots job timeout (T-03-20 mitigated: `permissions: contents: read`, no secrets and every pinned `uses:` SHA unchanged, the YAML validated, `tools/prepush_check.sh` passed before each push). T-03-21 (unsigned build) accepted, T-03-SC: no packages and no assets.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The owner's gate is open: `build/windows/Duskhold.exe` and `03-PLAYTEST-GATE.md`. The decision (sign off, or a fix list, and which balance bar the nights serve) is recorded through `/gsd-verify-work`; no Phase 4 work starts before it.
- The branch head `c418b6c` is pushed and CI-green; the commits made after it (the packet, this summary and the tracking files) are local until the orchestrator pushes.

## Self-Check: PASSED

- Created files exist: `tools/screenshot/shot_army_scenarios.gd` (and `.uid`), `tests/unit/test_shot_protected_centre.gd` (and `.uid`), `03-PLAYTEST-GATE.md`, `build/windows/Duskhold.exe` (all FOUND)
- Commits exist: `e7c3319`, `549e53c`, `85990e9`, `c418b6c`, `ad29c2d` (all FOUND); `git log --grep=03-12` returns them
- Acceptance criteria re-run: both shot lists name `hud_day_squads` and `cmd_slam` (33 each), `shot_runner.gd` has `PROTECTED_RECT` and `func protected_violations(`, `screenshots/` holds 33 PNGs, the latest CI run on `c418b6c` concluded success with REPLAY_OK for smoke and army, `ci.yml` has `timeout-minutes: 60` and `contents: read`, the packet has its five sections and the assumptions A1, A2, A4, A5, A6, A7, A8, A11, A12, A14

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-12*
