---
phase: 02-night-defense-playtest-gate
plan: 14
subsystem: ui
tags: [godot, results-screen, layout, margin-container, gap-closure, g-02-2]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: the results screen scene (02-07), the owner UAT finding G-02-2 and its diagnosis in .planning/debug/results-screen-button-gap.md
provides:
  - An 11 px ButtonsMargin (MarginContainer, margin_top 11) around the results Buttons row, so the visible gap from the last stat row to the buttons equals the gap between stat rows
  - tests/e2e/test_results_layout.gd, a layout test pinning the stat-row gaps, the gap above the buttons and the 2 px focus-outline reach
affects: [phase-2-verification, playtest-gate]

requirements-completed: [LOOP-06, LOOP-07]

actuals:
  tokens: 2600
  tasks: 2
  commits: 2

plan_head_before: 93cac43829090ffb3d132271046c35715670e025
plan_head_after: 7f30fedc5bd421492c7a00ff07557db6318ecddc

tech-stack:
  added: []
  patterns:
    - "A layout test measures global rects of a scene instantiated on its own and reads the separation from the container's theme constant instead of hard-coding it"
    - "A magic padding is a named constant with its derivation in a comment, plus an assertion on the theme value it depends on, so a theme change points at the number to recompute"

key-files:
  created:
    - tests/e2e/test_results_layout.gd
    - tests/e2e/test_results_layout.gd.uid
  modified:
    - ui/results/results_screen.tscn

key-decisions:
  - "The 11 px is added above the Buttons row only (9 px of font leading above a 26 px stat label's capitals plus the 2 px the focused button's outline reaches above its rect); the Column separation of 12, the stat labels and fonts, the button sizes and the Quit look are untouched"
  - "No script change: results_screen.gd reaches the buttons by unique name, so moving them under ButtonsMargin changes only their scene parent paths"

duration: 8 min
completed: 2026-10-06
---

# Phase 2 Plan 14: Results button gap Summary

**An 11 px MarginContainer above the results Buttons row makes the gap from the last stat row to the buttons equal the gap between stat rows (G-02-2), pinned by a four-test layout suite and checked on real Victory and Defeat screenshots.**

## Performance

- **Duration:** 8 min (2026-10-06T12:58:51Z to 2026-10-06T13:06:54Z, approximately)
- **Tasks:** 2
- **Files:** 3 (1 modified, 2 created)

## Accomplishments

- `ButtonsMargin` (MarginContainer, `margin_top = 11`) is Column's last child and holds Buttons, PlayAgainButton and QuitButton; only their parent paths changed.
- `tests/e2e/test_results_layout.gd` measures the scene on its own with realistic stat text: every consecutive stat pair is exactly the Column separation apart, Play again's top lies separation + `BUTTON_ROW_EXTRA_PX` (11) below the Knockouts label's bottom, Quit shares Play again's row, and the focus stylebox still expands 2 px above the button.
- The Victory and Defeat screens were rendered in a real window and looked at (see below).

## Task Commits

1. **Task 1 RED:** `94bad83` - test(02-14): add failing layout test for the gap above the results buttons
2. **Task 1 GREEN:** `7f30fed` - feat(02-14): add 11 px above the results buttons so the gap matches the stat rows
3. **Task 2:** no commit (screenshots are git-ignored); this SUMMARY records the look.

## TDD Gate Compliance

- RED: `test_buttons_sit_the_row_gap_plus_the_leading_below_the_last_stat` failed on the planned assertion before the scene change (`[148.5] expected to equal [159.5]`: Play again was one separation, not separation + 11, below the last stat label); the other three tests passed, as intended (stat rows and focus expand were already correct).
- GREEN: all 4 layout tests pass after the scene change.
- REFACTOR: none needed.

## Mutation probe

With `margin_top` set from 11 to 0 in results_screen.tscn, `bash tools/test.sh -gselect=test_results_layout.gd` failed with 3/4 passing: `[148.5] expected to equal [159.5] +/- [0.01]: Play again starts Column separation + 11 px below the last stat label`. Restored to 11 (confirmed by grep and by the diff against HEAD), 4/4 pass again.

## Real-window screenshots (read with the Read tool)

- **results_victory.png:** Victory panel with "Nights survived: 1 of 1", Gold 0, Buildings lost 0, King knockouts 0; the four stat rows are evenly spaced and the Play again button (focused, white outline) sits one even step below King knockouts, with Quit beside it fully inside the panel. Pass: the gap above the buttons reads the same as between stat rows (about 28 px baseline to next cap top between stat rows, about 29 px from the last baseline to the Play again outline by eye).
- **results_defeat.png:** Defeat panel with "Nights survived: 0 of 8" and the same three zero stats; same even spacing and the buttons are inside the panel. Pass.
- Quit's face is still faint against the panel; that is out of scope (the owner passed the Quit-visibility check and the plan prohibits changing it).

## Verification

- `bash tools/test.sh`: 784 tests, 0 failures (baseline 780 plus the 4 new layout tests); `test_results_layout` and `test_results_screen` both present in `build/test-results/gut-junit.xml`; the one run warning is the existing push_warning output of other suites.
- `bash tools/lint.sh`: clean (162 files).
- Acceptance criteria: `name="ButtonsMargin"` and `margin_top = 11` present; `separation = 12` still present once; `BUTTON_ROW_EXTRA_PX` present in the test; `bash tools/test.sh` exited 0. Both PNGs exist and are non-empty after the scripted run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. A scene layout change only; no input, data or network path changed (T-02-32 accepted: the existing keyboard, gamepad and mouse tests in test_results_screen.gd still pass).

## Next Phase Readiness

G-02-1 and G-02-2 are closed in code; the owner judges the even spacing at the replay. Ready for the next gap plan (02-15).

## Self-Check: PASSED

- FOUND: tests/e2e/test_results_layout.gd, tests/e2e/test_results_layout.gd.uid, ui/results/results_screen.tscn (with ButtonsMargin)
- FOUND commits: 94bad83, 7f30fed
