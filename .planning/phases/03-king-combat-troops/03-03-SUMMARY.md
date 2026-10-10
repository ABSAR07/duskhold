---
phase: 03-king-combat-troops
plan: 03
subsystem: ui
tags: [godot, gdscript, hud, theme, stretch, canvas-items, day-counter]

requires:
  - phase: 02-night-combat-loop
    provides: "Hud CanvasLayer (GoldLabel, PhaseBanner, RespawnLabel, FastForwardLabel, PayoutTotal), RunManager night numbering, run_bound binding through MapRoot"
provides:
  - "display/window/stretch/mode canvas_items and aspect expand on the 1280x720 base: one coordinate space for HUD, mouse, unproject_position and project_ray_*"
  - "ui/theme/hud_theme.tres: white Label text, black outline 6, HudBoldLabel type variation (FontVariation embolden 0.5)"
  - "HudRoot: the single full-rect, mouse_filter IGNORE, themed container every Phase 3 HUD widget lives under"
  - "DayCounter: top-centre 'Night N of T' (next night out of the total), shown by day and dawn"
  - "Four-size font scale 36/28/22/18 and the black outline rule, plus the protected-rectangle contract in test_hud_contract.gd"
affects: [03-04, 03-05, 03-06, 03-10, 03-12]

actuals:
  tokens: 6200
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "HUD contract test lays the real hud.tscn out in a 1280x720 SubViewport so rects are measured in the base space whatever the headless window is"
    - "Every new HUD node is a child of HudRoot, mouse_filter IGNORE, in group run_bound when it needs the run"

key-files:
  created:
    - ui/theme/hud_theme.tres
    - ui/hud/hud_root.gd
    - ui/hud/day_counter.gd
    - tests/e2e/test_stretch_coordinates.gd
    - tests/e2e/test_hud_contract.gd
  modified:
    - project.godot
    - ui/hud/hud.tscn

key-decisions:
  - "Task 1's stretch setting broke no existing suite: the 64 px headless window now reports a 1280x1280 visible rect, but every presentation script and e2e test already tolerated it, so none of the Pitfall 7 candidate files needed a change"
  - "DayCounter hides on WON and LOST as well as at night: it shows only in DAY and DAWN, so the results screen is never crowded and the clamp to the total only matters for the day after a final night"
  - "The font-size contract covers the scene-defined labels of the player HUD; the dev-only DebugOverlay (16 px) and labels created at runtime by SpawnTelegraph (20 px) are outside it, as they were before this plan"

patterns-established:
  - "A night is cleared in a test by killing each enemy as it appears while stepping RunContext.step() (EnemySystem.damage), not by emptying a night's groups: MapConfig validation logs an engine error for a night with no enemies and GUT counts it as a failure"
  - "A RED commit for a test that references not-yet-existing class_names is a parse failure (types not found, exit 1), recorded by temporarily moving the implementation aside"

requirements-completed: [UI-01]

coverage:
  - id: D1
    description: "The project stretches the 1280x720 base with canvas_items and aspect expand, the visible rect is 1280 wide, and a ground point survives Camera3D.unproject_position then project_ray_origin/normal then Plane intersect within 0.01 m"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_stretch_coordinates.gd (3 tests)"
        status: pass
      - kind: other
        ref: "bash tools/test.sh (full suite 873/873 immediately after the setting landed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "HudRoot is a full-rect, IGNORE, hud_theme.tres-themed Control under the HUD; DayCounter is an IGNORE run_bound child of it"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd#test_hud_root_is_a_full_rect_ignore_control_with_the_hud_theme"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd#test_the_day_counter_is_ignore_and_a_child_of_the_hud_root"
        status: pass
    human_judgment: false
  - id: D3
    description: "DayCounter reads 'Night 1 of 8' by day one, 'Night 2 of 8' at dawn and by day after a cleared night, is hidden while the night banner shows and on a waveless map, and clamps to the total"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd (by_day_one, hides_while_the_night_banner_shows, after_a_cleared_night, hidden_on_a_map_without_authored_nights, clamped_to_the_total)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every player-HUD label uses a size in {36, 28, 22, 18}; RespawnLabel 28, FastForwardLabel 22, PayoutTotal 22 with positions untouched; GoldLabel and the DayCounter label carry a black outline of 6; the theme sets the same"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd (font set, remapped sizes, positions, outline, theme tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No new HUD node enters the protected rectangle x 384..896, y 96..500; the DayCounter sits within y 16..56; 'Night 12 of 12' stays on one line centred on x 640 inside 0..1280"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd#test_the_day_counter_sits_in_the_top_band_clear_of_the_protected_rectangle"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd#test_two_digit_night_numbers_stay_on_one_centred_line"
        status: pass
    human_judgment: false
  - id: D6
    description: "The stretch coordinate agreement also holds in a real window at 1920x1080 and 16:10, and the counter reads well over the 3D scene"
    verification: []
    human_judgment: true
    rationale: "RESEARCH A9 real-window half and the screenshot hud_day_counter_long are plan 03-12 scenarios; headless proves only the 1280-wide base space"

duration: 17min
completed: 2026-10-10
status: complete
plan_head_before: 5b9c22e8ca810496dc2a8fb7e4afca12f19e1528
plan_head_after: 20e9ef53a4f6b624c2b710737f4382d0d967160e
commits: 3
---

# Phase 3 Plan 03: HUD Ground Rules and the Night Counter Summary

**canvas_items stretch on the 1280x720 base, a themed HudRoot with the four-size font scale and black outline, and a top-centre "Night N of T" counter, all pinned by a SubViewport layout contract test**

## Performance

- **Duration:** 17 min
- **Started:** 2026-10-10T09:05:26Z
- **Completed:** 2026-10-10T09:22:35Z
- **Tasks:** 2 (Task 1 auto; Task 2 TDD: RED then GREEN)
- **Files modified:** 8 (5 new, 2 modified, plus 2 `.uid` files)

## Accomplishments

- The stretch setting landed alone and the full suite (873 tests) passed before anything built on it. The Pitfall 7 candidate files (`dawn_payout_vfx.gd`, `dawn_no_income_marker.gd`, `spot_label.gd`, the dawn payout, king ride and camera zoom tests) needed no edit.
- `test_stretch_coordinates.gd` proves the visible rect is 1280 wide in the real scene and that four ground points round-trip through `unproject_position` and the camera ray within 0.01 m.
- `hud_theme.tres`, `HudRoot` and `DayCounter` give every later HUD plan its container, theme and clear-centre rule; `RespawnLabel` 30 to 28, `FastForwardLabel` 26 to 22, `PayoutTotal` 24 to 22, and `GoldLabel` gains the outline of 6 (night legibility).
- Suite: 101 scripts / 870 tests at baseline to 103 scripts / 888 tests, all passing (10421 asserts), lint clean, smoke replay digest `2599c7c2...` unchanged.

## Task Commits

1. **Task 1: canvas_items stretch + coordinate round trip** - `a5f457e` (feat)
2. **Task 2 RED: failing HUD contract tests** - `c5ff826` (test)
3. **Task 2 GREEN: DayCounter on a themed HudRoot, font scale, outline** - `20e9ef5` (feat)

RED evidence for Task 2: `bash tools/test.sh -gselect=test_hud_contract` exited 1 with `Could not find type "DayCounter"` / `"HudRoot"` parse errors while the implementation was moved aside, then 15/15 passed once restored.

**Plan metadata:** recorded in the following docs commit.

## Files Created/Modified

- `project.godot` - `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"` under `[display]`
- `ui/theme/hud_theme.tres` - Label white, outline black 6; `HudBoldLabel` type variation with a `FontVariation` embolden 0.5
- `ui/hud/hud_root.gd` - documentation-only `HudRoot` (no logic)
- `ui/hud/day_counter.gd` - `DayCounter`, `DAY_COUNTER_TEXT`, `text_for()`, `get_label()`, reacts to `phase_changed`
- `ui/hud/hud.tscn` - `HudRoot` and `DayCounter` nodes, three font remaps, GoldLabel outline
- `tests/e2e/test_stretch_coordinates.gd`, `tests/e2e/test_hud_contract.gd` - 3 and 15 tests

## Decisions Made

See `key-decisions` above. `hud.gd` needed no change: the counter binds itself through `run_bound`, so the file listed in the plan was left untouched.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written. Two notes that are not deviations:

- The first draft of the dawn test emptied night 1's groups; `MapConfig` validation logs an engine error for a night with no enemies (GUT counts it as a failure), so the test instead steps the real sim and kills each enemy as it appears. Caught in the test's own first run, before any commit.
- Task 2's RED is a parse failure (the new class names do not exist yet), not an assertion failure; the implementation files were moved to the scratchpad for the RED run and restored for GREEN.

**Total deviations:** 0 auto-fixed. **Impact:** none on scope.

## Authentication Gates

None.

## Known Stubs

None. `DayCounter` and `HudRoot` are wired to real data and the scene; no placeholder values flow to the UI.

## Threat Flags

None. T-03-06 (mitigate) is pinned: `HudRoot` and `DayCounter` are `mouse_filter` IGNORE and `test_hud_contract` asserts both. T-03-SC (accept): no packages, no new third-party asset.

## Issues Encountered

None.

## Next Phase Readiness

Ready for 03-04 (king widget), 03-05 (squad strip), 03-06 (toast) and 03-10 (prompts): each adds its node under `HudRoot` and extends `test_hud_contract.gd` or adds a sibling contract file (the script holds 15 of its 20-test cap). Plan 03-12 owns the real-window half of A9 (1920x1080 and 16:10 screenshots) and the `hud_day_counter_long` shot.

## Self-Check: PASSED

- Files exist: `ui/theme/hud_theme.tres`, `ui/hud/hud_root.gd`, `ui/hud/day_counter.gd`, `tests/e2e/test_stretch_coordinates.gd`, `tests/e2e/test_hud_contract.gd`
- Commits exist: `a5f457e`, `c5ff826`, `20e9ef5`
- Acceptance criteria re-run: stretch keys present, `DAY_COUNTER_TEXT` and `get_total_nights()` in `day_counter.gd`, `HudRoot` and `DayCounter` with `mouse_filter = 2` in `hud.tscn`, no `font_size = 30/26/24` line, theme outline size 6, long-text test present, `bash tools/test.sh` exit 0 (888/888), `bash tools/lint.sh` clean, smoke replay `REPLAY_OK`
