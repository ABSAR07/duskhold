---
phase: 03-king-combat-troops
plan: 15
subsystem: ui
tags: [godot, gdscript, hud, panelcontainer, ui-spec, gap-closure]
gap_closure: true
gap_ids: [G-03-14b]

requires:
  - phase: 03-king-combat-troops
    provides: SquadStrip at y 544..616 (03-05), the 18 Phase 3 shots and ShotRunner.protected_violations (03-12)
provides:
  - StartNightPlate (PanelContainer) behind the start-night prompt and fill bar, shown by day only
  - tests/e2e/test_start_night_plate.gd, the plate rect, inset, style, mouse and visibility contract
  - 03-UI-SPEC.md StartNightBox row, Focal points paragraph and Dominant 60% list updated for the plate
affects: [03-19 (knocked-out king widget and night copy, same hud.gd and UI-SPEC), phase 3 UAT re-check of test 14]

actuals:
  tokens: 4180
  tasks: 1
  commits: 2

plan_head_before: cfa730b8506ce55c57cdaef4b289b3c3859b2011
plan_head_after: 93aa4adf33305ed549ea3c05c51d0a67a9824b1b
commits: 2

tech-stack:
  added: []
  patterns:
    - "A HUD plate is a mouse_filter IGNORE PanelContainer with a StyleBoxFlat sub_resource (#14141A at 0.78, radius 8, margin 8) holding a mouse-ignoring VBox of rows; unique names keep every %lookup working after a reparent"

key-files:
  created:
    - tests/e2e/test_start_night_plate.gd
    - tests/e2e/test_start_night_plate.gd.uid
  modified:
    - ui/hud/hud.tscn
    - ui/hud/hud.gd
    - .planning/phases/03-king-combat-troops/03-UI-SPEC.md

key-decisions:
  - "StartNightBox separation 0 and offset_bottom -4 (y 624..716): the 26 px preview line only fits under the 66 px plate inside the 716 bound with no gap, and with the old offset_bottom -24 the box grew upward to y 600"

requirements-completed: [UI-01]

coverage:
  - id: D1
    description: "The start-night prompt and fill bar sit on a #14141A 0.78 plate (radius 8, 8 px inset) whose top is y 624 and bottom y 690, clear of the centre, the king widget and the hint row, with the 18 px preview unplated below it (bottom y 716)"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_plate_sits_between_the_strip_and_the_screen_bottom"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_prompt_and_the_fill_sit_8_px_inside_the_plate"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_preview_stays_below_the_plate_unplated_and_on_screen"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_plate_stays_clear_of_the_centre_the_king_widget_and_the_hint_row"
        status: pass
    human_judgment: false
  - id: D2
    description: "The plate ignores the mouse and hides outside the day (T-03-24)"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_plate_is_the_dominant_panel_colour_and_ignores_the_mouse"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_plate.gd#test_the_plate_shows_by_day_and_hides_at_night"
        status: pass
    human_judgment: false
  - id: D3
    description: "By day the plated start-night prompt reads as the focal point beside a cyan selected squad slot"
    requirement: UI-01
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh hud_day_squads hud_day_squads_1080p (clear-centre check passed)"
        status: pass
    human_judgment: true
    rationale: "Hierarchy and feel are a visual judgment; the owner judges at the UAT re-check of test 14"

duration: 19 min
completed: 2026-10-13
status: complete
---

# Phase 3 Plan 15: Start-night plate Summary

**A StartNightPlate (#14141A at 0.78, radius 8, 8 px inset, mouse ignored, day only) now sits behind the start-night prompt and fill bar at y 624..690 between the SquadStrip and the screen bottom, pinned by six measured scene tests, recorded in the UI-SPEC and seen in re-captured real-window shots.**

## Performance

- **Duration:** about 19 min (started about 2026-10-13T16:16Z, the start time was not captured at the first step; completed 2026-10-13T16:35Z)
- **Tasks:** 1 (tracer, tdd)
- **Files modified:** 5 (3 modified, 2 created counting the test's .uid)

## Accomplishments

- Closed G-03-14b: the unplated start-night prompt no longer sits on the bare 3D scene under a cyan selected slot; it has its own plate in the Dominant 60% colour.
- The StartNightBox keeps its top at y 624 even with the preview showing (before, the preview made the box grow upward over the strip gap).
- The `_refresh_loop` now hides the plate with the prompt and fill outside the day; the plate and its rows are mouse IGNORE so ground clicks and drags still reach the SelectionController (T-03-24 mitigated and pinned).

### Measured rects at 1280x720 (preview showing "Night 8: 99 enemies from 3 directions")

| Node | Position | Size | y range |
|------|----------|------|---------|
| SquadStrip | (640, 544) | 0 x 72 (empty in the probe) | 544..616 |
| StartNightBox | (440, 624) | 400 x 92 | 624..716 |
| StartNightPlate | (440, 624) | 400 x 66 | 624..690 |
| StartNightRows | (448, 632) | 384 x 50 | 632..682 |
| StartNightPrompt | (448, 632) | 384 x 32 | 632..664 |
| StartNightFill | (448, 668) | 384 x 14 | 668..682 |
| NightPreview | (440, 690) | 400 x 26 | 690..716 |

The plate is 8 px below the strip, the prompt is 8 px below the plate top, the fill is 8 px inside left, right and bottom, the plate bottom (690) is under the 700 bound and the preview bottom (716) meets the 716 bound exactly.

### Real-window look (hud_day_squads.png)

In the captured 1280x720 shot the plated prompt "Hold [N] to start Night 1" with its bar reads as a clear dark panel directly under the strip, wider (400 px) and taller than the cyan selected slot (136 px), with white 22 px text and a glyph. The cyan 4 px border of the selected slot is still the single most saturated accent on screen, but the prompt now has the same plate treatment and the larger footprint, so it no longer reads as text floating on the ground beneath a highlighted slot. Whether the prompt leads is the owner's feel judgment at the UAT re-check (D3, human_judgment). Both shots passed ShotRunner's clear-centre check.

## Task Commits

1. **Task 1 RED:** `b1c2cae` test(03-15): failing contract for the start-night plate (6 tests, assertion failures, no StartNightPlate yet)
2. **Task 1 GREEN:** `93aa4ad` fix(03-15): plate the start-night prompt below the squad strip (G-03-14b)

**Plan metadata:** the docs(03-15) commit following this file.

## Files Created/Modified

- `tests/e2e/test_start_night_plate.gd` - six tests: plate rect, 8 px inset, preview unplated below, clear of centre/king widget/hint row, style and mouse filters, shown by day and hidden at night
- `ui/hud/hud.tscn` - StyleBoxFlat sub_resource, StartNightPlate and StartNightRows under StartNightBox, prompt and fill reparented, box offset_bottom -4 and separation 0
- `ui/hud/hud.gd` - `_start_night_plate` onready and `_start_night_plate.visible = by_day` in `_refresh_loop`, doc comment updated
- `.planning/phases/03-king-combat-troops/03-UI-SPEC.md` - StartNightBox Layout row, Focal points paragraph, Dominant 60% usage list

## Decisions Made

- The box offset_bottom moved from -24 to -4 and its separation to 0 so the box top stays at y 624 with the 26 px preview showing; the preview then ends at exactly y 716 (the plan's bound). Measured by the new test and a probe, not estimated.

## Deviations from Plan

None - plan executed exactly as written. (The `separation 0` and `offset_bottom` change is the plan's own instruction: "Change StartNightBox's offset_bottom (and its separation, 0 if the preview does not otherwise fit)".)

## Issues Encountered

- First GREEN run failed one test: with the old offset_bottom -24 the 96 px of content grew the box upward to y 600 (grow_vertical BEGIN). Fixed by the offset and separation change above.
- The full-suite run also prints `4 orphans` style warnings from other suites; they were present before this plan and are not failures.

## Verification Results

- `bash tools/test.sh -gselect=test_start_night_plate.gd`: 6 of 6 pass (44 asserts); RED run failed all 6 first on assertions.
- `bash tools/test.sh -gselect=test_squad_strip.gd`: 16 of 16 (147 asserts), its 624 and 8 px pins hold.
- `bash tools/test.sh -gselect=test_start_night_hold.gd`: 16 of 16 (103 asserts).
- `bash tools/screenshot.sh hud_day_squads hud_day_squads_1080p`: saved 2 of 2, clear-centre check passed.
- `bash tools/lint.sh`: 263 files unchanged, no problems.
- Full suite `bash tools/test.sh`: 149 scripts, 1384 tests, 1384 passing, 15504 asserts, exit 0 (baseline 148 scripts, 1378 tests; plus the 6 new tests); test_start_night_plate and test_hud_contract are in the JUnit XML.
- Acceptance criteria: StartNightPlate and StartNightRows in hud.tscn (2 blocks parented under StartNightRows), `_start_night_plate.visible = by_day` in hud.gd, six tests passing, UI-SPEC contains StartNightPlate: all PASS.

## Known Stubs

None.

## Threat Flags

None. T-03-24 (plate swallowing ground clicks) is mitigated by mouse_filter IGNORE on the plate and rows and pinned by a test.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-19 (knocked-out widget G-03-13, night copy G-03-14) can now edit `ui/hud/hud.gd` and 03-UI-SPEC.md; it re-captures all 33 shots.
- The owner re-checks UAT test 14 hierarchy feel on the fixed build.

## TDD Gate Compliance

RED `test(03-15)` b1c2cae precedes GREEN `fix(03-15)` 93aa4ad. The GREEN commit type is `fix` (a gap closure) rather than `feat`; the sequence is intact. No refactor commit.

## Self-Check: PASSED

- FOUND: tests/e2e/test_start_night_plate.gd, ui/hud/hud.tscn, ui/hud/hud.gd, 03-UI-SPEC.md edits
- FOUND commits: b1c2cae, 93aa4ad (`git log`)
- commits measured from the ledger: 2 (cfa730b..93aa4ad)

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
