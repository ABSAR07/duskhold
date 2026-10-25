---
phase: 05-castle-center-economy-depth
plan: 20
subsystem: ui
tags: [x100-rescale, king-widget, hud, screenshots, gap-closure, G-05-2, gut, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plan 05-19: the felling blows at the x100 scale (the last test group before the HUD)"
provides:
  - "The king widget's label holds 128 px (was 96), so the row reads '5000 / 5000' and Royal Training's '6250 / 6250' on one line without shifting; the row spans x 16 to 408"
  - "test_king_widget, test_king_knockout, test_squad_strip and test_shot_list pinned at the x100 scale, plus the Royal Training fit test (16 tests in test_king_widget)"
  - "The hurt-king and crowd-stress shot scenarios at the x100 scale; ten real-window shots captured and reviewed"
affects: [05-21, 05-24]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3

plan_head_before: 3318c956340d6b0e87d9989d1261f9d89c2c6fab
plan_head_after: 0a8b5ce3fe908c24aba4bf68cb17659059f39834

tech-stack:
  added: []
  patterns:
    - "Numbers are displayed as the simulation holds them (no hidden division); the one layout the larger numbers moved is a label's minimum width"

key-files:
  created: []
  modified:
    - ui/hud/king_widget.gd
    - tests/e2e/test_king_widget.gd
    - tests/e2e/test_king_knockout.gd
    - tests/e2e/test_squad_strip.gd
    - ui/world/spot_label_model.gd
    - ui/overlay/economy_overlay_sections.gd
    - tools/screenshot/shot_army_scenarios.gd
    - tools/screenshot/shot_crowd_scenarios.gd
    - tests/unit/test_shot_list.gd

key-decisions:
  - "LABEL_MIN_WIDTH is 128 px as planned; the real-window shot confirmed it fits, so no widening to 136 or 144 was needed"
  - "The numbers are shown as they are (Flagged Assumption of the plan, reversible by the owner at UAT: show them divided by 100 instead)"
  - "World labels and the shot-only long kings (12000 and 10000000 health) are not restyled; their extra width is recorded for the owner"

requirements-completed: []

coverage:
  - id: D1
    description: "The king widget's label holds 128 px and reads '5000 / 5000', '3800 / 5000', '0 / 5000' (red), '500 / 5000', '8700 / 12000' and Royal Training's '6250 / 6250' with the row inside x 16 to 408"
    requirement: "BLDG-08"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_widget.gd (16 of 16 passing, incl. test_royal_trainings_king_fits_the_label_without_moving_the_right_edge)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd (6 of 6) and tests/e2e/test_hud_contract.gd (15 of 15)"
        status: pass
      - kind: automated_ui
        ref: "screenshots/hud_day_squads.png (bash tools/screenshot.sh hud_day_squads)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The knockout, squad-strip and shot-list tests and the hurt-king and crowd-stress shot scenarios speak the x100 numbers; doc examples of the spot label and economy overlay show the scaled numbers"
    requirement: "META-08"
    verification:
      - kind: unit
        ref: "test_king_knockout 5/5, test_squad_strip 16/16, test_spot_label 29/29 (3 scripts), test_economy_overlay_sections 18/18, test_shot_list 23/23 (2 scripts)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Ten real-window shots read cleanly at the scaled numbers (king label, castle, wall and house labels, overlay HP row, crowd night)"
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh <ten shots> exit 0, every PNG read with the Read tool"
        status: pass
    human_judgment: true
    rationale: "Whether the scaled numbers look right (and whether the owner prefers them divided by 100) is the owner's call at the next UAT; Royal Training's card effect line was not on screen in any of the ten shots"

duration: 33min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 20: HUD at the x100 scale Summary

**The king widget's label widens from 96 to 128 px so the scaled health ('5000 / 5000', Royal Training's '6250 / 6250') sits on one line without shifting the row, the HUD tests and shot scenarios speak the x100 numbers, and ten real-window shots were captured and read.**

## Performance

- **Duration:** about 33 min
- **Started:** about 2026-10-25T18:25Z (not recorded at start; estimated from the previous plan's commit)
- **Completed:** 2026-10-25T18:58Z
- **Tasks:** 3
- **Files modified:** 9 (the plan's nine; nothing else)

## Accomplishments

- Label width as built: `LABEL_MIN_WIDTH: float = 128.0` in ui/hud/king_widget.gd (no widening to 136 or 144 was needed). The row spans x 16 to 408; the real-window shot shows "5000 / 5000" ending near x 403, 37 px short of the start-night plate (x 440).
- test_king_widget re-pinned and grown to 16 tests; the knockout, squad-strip and shot-list tests and two doc comments moved to the scaled numbers.
- Ten shots captured in a real window and read (review lines below). The shot names and the shot list order are unchanged.

## Numbers changed (old to new), per file

- ui/hud/king_widget.gd: LABEL_MIN_WIDTH 96.0 to 128.0 (new `##` line); header "x 16..376" to "x 16..408" and "0 / 50" to "0 / 5000". No other line changed.
- tests/e2e/test_king_widget.gd: WIDGET_RIGHT 376.0 to 408.0; "50 / 50" to "5000 / 5000" (3x); take_damage(12) to 1200 and "38 / 50" to "3800 / 5000" (bar target 38/50 to 3800/5000, same 0.76); "0 / 50" to "0 / 5000" (2x plus the comment); take_damage(45) to 4500 and "5 / 50" to "500 / 5000"; LONG_MAX_HEALTH 120 to 12000, LONG_HURT_TO 87 to 8700, "87 / 120" to "8700 / 12000"; custom_minimum_size.x 96.0 to 128.0; header "x 16..376" to "x 16..408" plus a G-05-2 note; three renames (..._reads_3800_of_5000_..., test_a_nearly_empty_and_a_full_label_do_not_shift_the_row, test_a_king_of_12000_health_grows_the_label_...); new test_royal_trainings_king_fits_the_label_without_moving_the_right_edge (16 tests).
- tests/e2e/test_king_knockout.gd: HEAL_DAMAGE 10 to 1000 (KING_HEALTH 4 and CASTLE_HEALTH 10000 stay), G-05-2 header note.
- tests/e2e/test_squad_strip.gd: KILL_DAMAGE 1000 to 100000, G-05-2 header note.
- ui/world/spot_label_model.gd (doc comments only): "12 segments, 3000 health each", "Health 10000 · Arrow 300 · 2 gold at dawn", "Asleep: 3000 of 10000 enemy health". `git diff ce3fcea` shows only `##` lines changed in this file and in economy_overlay_sections.gd.
- ui/overlay/economy_overlay_sections.gd (doc comment only): "asleep 3000 of 10000", "awake 11200" (wrapped to a second `##` line for the 100-character cap).
- tools/screenshot/shot_army_scenarios.gd: KING_120_HEALTH 120 to 12000, HURT_MIN 34 to 3400, HURT_MAX 42 to 4200, HURT_120_MIN 84 to 8400, HURT_120_MAX 90 to 9000; doc lines say what they hold now and that the name hud_king_120 predates the scale; the "never hurt into the eighties" error text now names 8400 to 9000.
- tools/screenshot/shot_crowd_scenarios.gd: STRESS_NIGHT_KING_HEALTH 100000 to 10000000.
- tests/unit/test_shot_list.gd: hud_king_120 pin 120 to 12000 (wrapped over three lines), shipped king 50 to 5000 (3 pins), G-05-2 header note. Test count unchanged (23 across the two shot-list scripts).

## Shot reviews (PNG paths under C:/Users/burha/Desktop/Projects/Thronefall-like Game/screenshots/, git-ignored)

1. hud_day_squads.png: king label "5000 / 5000" on one line beside the 192 px bar, outlined, ends near x 403, clear of the start-night plate and the squad strip; the castle label "Castle II / Health 10000 · Arrow 300 · 2 gold at dawn" reads on one line.
2. hud_night_squad_down.png: label "3600 / 5000" (inside the 3400 to 4200 window), bar about 72 percent, fits; squad strip shows the down squad "0 / 4" in red.
3. hud_king_down.png: "0 / 5000" in red beside the emptied, dimmed bar, count stays opaque, fits; "Knocked out — back in 6 s" shows.
4. hud_king_120.png: "9000 / 12000" (inside 8400 to 9000; the bar keeps x 80 and 192 px, the label grows right and ends near x 416, past the shipped game's 408 edge but only for this shot-only 12000-health king; still clear of the centre and of the squad strip). Recorded for the owner, not restyled.
5. overlay_on.png: the F3 overlay's King section reads "HP: 5000 / 5000" with State, Respawn and Knockouts rows intact; the king label reads "5000 / 5000" and fits.
6. castle_cards.png: castle label "Castle II / Health 10000 · Arrow 300 · 2 gold at dawn" on one line; the hovered card's line "+25% unit health, +25% unit damage" wraps to two lines and stays inside its card. Royal Training's "+25% king health, +100 king damage" is not on screen in this capture (the cards sit partly above the frame), so its fit is inferred from the same-length Commander line, not observed.
7. castle_tier_four.png: "Castle IV / Max tier / Royal Training · Engineers · Golden Age" each on one line and readable; the king label reads "6250 / 6250" (Royal Training armed) and fits in 128 px, ending near x 403.
8. walls_day.png: "Wall II / 12 segments, 6000 health each" on one line (the shot shows the second wall tier, so 6000, not 3000); king label "6250 / 6250" fits.
9. spot_label.png: "House I / +1 gold at dawn" reads on one line; king label "5000 / 5000" fits. No Tower "Damage 300" line is on screen in this capture (the tower's line was not part of the framing).
10. crowd_stress_night.png: the night runs with 300 enemies and the king standing; label "9989600 / 10000000" (a tool-only king) ends near x 492, 8 px short of the squad strip (x 500), still on one line. Recorded for the owner, not restyled.

## Task Commits

1. **Task 1 (tracer): the king widget's label widens to 128 px** - `82d66e1` (feat)
2. **Task 2: knockout and squad-strip tests and label doc examples** - `8b0b2ea` (test)
3. **Task 3: shot scenarios and the shot list** - `0a8b5ce` (chore)

**Plan metadata:** the docs commit following this SUMMARY.

## Verification

- test_king_widget 16/16 (1 script); test_start_night_plate 6/6; test_hud_contract 15/15; test_king_knockout 5/5; test_squad_strip 16/16; test_spot_label 29/29 (3 scripts, test_spot_label_model in the XML); test_economy_overlay_sections 18/18; test_shot_list 23/23 (2 scripts, test_shot_list_gate in the XML). Each run its own invocation, names confirmed in build/test-results/gut-junit.xml or the run log. No flake, no rerun needed.
- `bash tools/lint.sh` exit 0 ("446 files would be left unchanged", "no problems found") after one wrap fix.
- Tracer gate: Task 1's verify was automated-only (suites plus the capture), re-run clean, so the plan expanded to Tasks 2 and 3.
- The full suite was not run (the orchestrator's gate owns it). No replay, golden or full_idle run was in scope: no simulation, data or native file changed.

## Decisions Made

- 128 px confirmed by the real window (no widening); WIDGET_RIGHT 408 as planned.
- The Flagged Assumption stands: numbers shown as they are; the owner can ask for them divided by 100 at the next UAT (plan 05-24 lists it).

## Deviations from Plan

None - plan executed exactly as written. Differences from the planner's scratch diff, plan wins: the diff has no header notes, no doc-comment edits for spot_label_model.gd and economy_overlay_sections.gd, nothing in the shot scenarios' doc lines, and keeps the bar-settle assertion as `38.0 / 50.0` and its message "38 / 50"; this run wrote `3800.0 / 5000.0` and "3800 / 5000" there (same 0.76), plus the header notes and doc lines the plan asks for.

## Issues Encountered

- One lint failure (an over-long `##` line in economy_overlay_sections.gd, 101 characters); wrapped by hand, lint clean.
- An unplanned observation for the owner: the plan's truth about Royal Training's card line fitting its card could not be seen in any of the ten shots (see shot 6). This is why `requirements-completed` is left empty here: BLDG-08 and META-08 were satisfied in round 1 and no requirement state is changed by this plan.

## Known Stubs

None.

## Threat Flags

None. T-05-37 (the wider row covering other HUD) is mitigated as planned: the footprint pin (x 16 to 408, y 624 to 704, outside the protected centre), test_start_night_plate and test_hud_contract pass, and the shots show the row clear of the plate and the strip.

## Next Phase Readiness

- The rescale is finished for the HUD, the tests and the shots; the orchestrator's gate expects the full suite green (279 scripts / 2656 tests with the new test). Plan 05-21 (the card recut) is next.
- For the owner: the long shot-only kings ("9000 / 12000", "9989600 / 10000000") grow the label past x 408; the shipped game's widest label is "6250 / 6250".

## Self-Check: PASSED

- Files exist: all nine modified files and this SUMMARY.
- Commits exist: 82d66e1, 8b0b2ea, 0a8b5ce on gsd/phase-01-foundation-day-loop; `git rev-list --count 3318c95..HEAD` printed 3 before this docs commit.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
