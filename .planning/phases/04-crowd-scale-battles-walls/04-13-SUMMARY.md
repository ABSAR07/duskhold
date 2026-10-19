---
phase: 04-crowd-scale-battles-walls
plan: 13
subsystem: ui
tags: [godot, gdscript, debug-overlay, hud-layout, gut-e2e, screenshots, gap-closure]
gap_closure: true
gap_ids: [G-04-6]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: "plan 04-08: the two-column F3 overlay and the overlay_field_gate shot; plan 04-11 (depends_on)"
provides:
  - "The F3 overlay panel starts at y 104, the bottom of the night banner box, so the banner is never covered at the 1280x720 base size (every 16:9, 16:10 and 4:3 window)"
  - "Line spacing 0 on both overlay labels: a stress-night row set ends near y 614 locally (about 17 px a line), above 720"
  - "tests/e2e/test_overlay_banner_layout.gd: a y-only 1280x720 SubViewport layout regression test (4 tests)"
  - "overlay_paths reopens the overlay after the fast-forward, so it shows the night it captures, not the day before it"
affects: [04-16 (CI run proves the Linux fallback font layout), 04-verify-work (UAT test 6 re-check)]

actuals:
  tokens: 2050
  tasks: 2
  commits: 3
plan_head_before: 724eefc8f35960c3bfa066a122604285eabb2a0e
plan_head_after: a01748993a39ba2a34d4cb614689355625503f2c
commits: 3

tech-stack:
  added: []
  patterns:
    - "Y-only layout assertions for a UI element whose width depends on the font: the CI fallback for Consolas changes glyph widths but barely moves line height"
    - "Stress row set built by registering one two-line section at a time and refreshing on synthetic time (_advance_refresh) until the left and right columns hold 30 and 19 lines"

key-files:
  created:
    - tests/e2e/test_overlay_banner_layout.gd
    - tests/e2e/test_overlay_banner_layout.gd.uid
  modified:
    - ui/overlay/debug_overlay.tscn
    - tools/screenshot/shot_scenarios.gd

key-decisions:
  - "Fix direction A of the diagnosis: move the panel below the banner box (offset_top 104, offset_bottom 144) rather than the banner or a width cap; it removes the shared rows whatever the column widths grow to"
  - "Line spacing 0 on both labels bought back the height; the 16 px font was kept and hud.tscn was not touched"
  - "overlay_paths closes and reopens the overlay (renders at once) rather than waiting one 0.25 s real-time refresh, so the shot does not depend on frame times"

requirements-completed: [ENMY-04]

coverage:
  - id: D1
    description: "The overlay panel starts at or below the bottom of the night banner box, never overlaps the fast-forward label on y, and a full stress-night row set ends at or above y 720 at 1280x720"
    requirement: "ENMY-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_overlay_banner_layout.gd (4 tests: shape under test, panel below banner box, no overlap with the fast-forward label, bottom at or above 720)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The three overlay screenshots re-captured in a real window show the banner whole, the panel below it, its last row on screen, and overlay_paths shows Night rows"
    requirement: "ENMY-04"
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh overlay_on overlay_paths overlay_field_gate (3 of 3 saved, no script error)"
        status: pass
    human_judgment: true
    rationale: "Whether the banner reads whole above the panel and nothing that matters is hidden is a visual judgment; the owner re-checks UAT test 6 with F3 on a night at /gsd-verify-work 4"

duration: 45min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 13: Overlay Below the Night Banner Summary

**The F3 overlay panel moves to y 104, below the night banner box, with line spacing 0, pinned by a y-only 1280x720 GUT layout test that went red first (G-04-6 closed)**

## Performance

- **Duration:** about 45 min
- **Started:** 2026-10-19T08:55:00Z (approximate; the start clock was not captured in a file)
- **Completed:** 2026-10-19T09:46:00Z
- **Tasks:** 2
- **Files modified:** 3 (plus 1 new .uid)

## Accomplishments

- At the 1280x720 base size the overlay panel top is y 104, the banner box bottom, so "Night 1 of 1 — 300 enemies left" is whole on the stress night in the real window (G-04-6).
- The two-column stress-night row set (30 left, 19 right) ends at about y 614 in a real window (last row "Marching: 300" at y 604), above 720, with the 16 px font kept.
- tests/e2e/test_overlay_banner_layout.gd lays the real map out in a 1280x720 SubViewport and asserts on y only, so the CI font substitution cannot move it.
- overlay_paths now shows its night: the three re-captured shots read Phase: NIGHT (overlay_paths, overlay_field_gate) and Phase: DAY (overlay_on, a day shot by design).

## RED / GREEN (TDD, Task 1)

- **RED** (`d7b29be`, test): on today's scene, 2 of 4 tests failed on the planned assertions. Assertion 1 failed with the measured panel top: `[12.0] expected to be >= than [100.0]: the panel top is not above the banner box bottom` (the diagnosis measured y 12). The fast-forward-label test failed too (the panel and the label share rows on y). The bottom-at-or-above-720 test already passed on the old scene (597 px tall from y 12), as expected: it is a guard against the new offset, and the shape test passed.
- **GREEN** (`9392d81`, fix): ui/overlay/debug_overlay.tscn only: Panel offset_top 104 and offset_bottom 144, `theme_override_constants/line_spacing = 0` on OverlayText and OverlayTextRight. 4 of 4 pass (13 asserts). The commit lists no ui/hud/hud.tscn.
- No REFACTOR commit (nothing to clean).

## Screenshot review (real window, Vulkan Forward+, 1280x720)

- **overlay_on** (day, 0 enemies, a short row set): the banner area shows the day counter "Night 1 of 8" at the top; the panel starts at y 104 at the right, well below it, and its last row "Marching: 0" is on screen at y 604; the field arrows and wall crosses are not part of this shot.
- **overlay_paths** (the shipped map, first night, "Night 1 of 8 — 2 enemies left"): the banner is whole and centred at y 72, the panel starts at y 104 below it, the overlay reads Phase: NIGHT, Night: 1, Spawned: 4 of 5, Alive: 1 (not Day), the last row "Marching: 1" is at y 604; the field arrows, the wall crosses, the path line and the tower are all readable.
- **overlay_field_gate** (the 300-enemy stress night): "Night 1 of 1 — 300 enemies left" reads whole including "left" (it was hidden by the panel before), the panel starts at y 104 under it, its last row "Marching: 300" is at y 604 with the panel ending near y 614, and the field arrows and the wall crosses on the fence line are still readable beside and below it.

screenshots/ stays untracked; the three PNGs are in /c/Users/burha/Desktop/Projects/Thronefall-like Game/screenshots/ (138 KB, 160 KB, 213 KB).

## Task Commits

1. **Task 1 (tracer): y-only layout test red, then the panel below the banner box** - `d7b29be` (test, RED), `9392d81` (fix, GREEN)
2. **Task 2: overlay_paths reopens the overlay, three shots re-captured** - `a017489` (chore)

**Plan metadata:** recorded in the docs commit that follows this file.

## Files Created/Modified

- `tests/e2e/test_overlay_banner_layout.gd` - the 4-test y-only layout regression at 1280x720 (map in a SubViewport, night started, banner text and fast-forward label set, overlay opened and grown to the stress shape)
- `tests/e2e/test_overlay_banner_layout.gd.uid` - its Godot uid file
- `ui/overlay/debug_overlay.tscn` - Panel offsets (+92 px down) and line_spacing 0 on both labels (4 insertions, 2 deletions)
- `tools/screenshot/shot_scenarios.gd` - `_toggle_overlay` helper; `_overlay_paths` closes and reopens the overlay before the capture

## Verification

- `bash tools/test.sh -gselect=test_overlay_banner_layout`: 4/4 passing, 13 asserts, and `grep -q test_overlay_banner_layout build/test-results/gut-junit.xml` succeeded in the same chain.
- One script per call, all green: test_hud_contract 15/15, test_debug_overlay_toggle 7/7, test_debug_overlay_crowd_sections 12/12, test_debug_overlay_readonly 8/8, test_overlay_field 5/5, test_overlay_paths 4/4, test_shot_list 14/14.
- `bash tools/lint.sh`: clean ("338 files would be left unchanged", "Success: no problems found"), before and after each .gd change.
- `bash tools/screenshot.sh overlay_on overlay_paths overlay_field_gate`: "Saved 3 of 3", exit 0, no script error in build/screenshot-overlay_*.log; all three PNGs non-empty.
- Full suite after the plan: **194 scripts, 1815 tests, 1815 passing, 30118 asserts**, exit 0, 973 s (baseline 193 scripts, 1811 tests; +1 script, +4 tests as written). The assert total is 32 below the dispatch baseline of 30150 although this plan adds 13: the difference comes from timing-dependent polling tests (their per-frame asserts vary with frame time) and is not a failure.
- No replay, digest or golden was run or touched: nothing under simulation/ changed.

## Decisions Made

- Fix direction A (panel below the banner), as planned; line spacing 0 gave about 17 px a line in the local font (Consolas, the 16 px size kept).
- The test grows the row set until 30 left and 19 right lines instead of hard-coding a section count, so it keeps the stress-night shape if the default sections change.

## Deviations from Plan

None - plan executed exactly as written. (Task 1 produced two commits, RED and GREEN, as the TDD reference prescribes for `tdd="true"`, rather than one; no plan statement forbids it.)

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. A layout-only scene change and a tools scenario; no row, provider or simulation call changed (T-04-33 accepted; test_debug_overlay_readonly stays green).

## Flagged assumptions carried forward

- The Linux CI fallback font for Consolas (assumed DejaVu Sans Mono, about 18.6 px a line at 16 px with spacing 0) is not measured here: 30 lines would end near y 104 + 558 = 662, under 720. Plan 04-16's CI run proves it.

## Human check (harvested by the verifier, UAT test 6)

Owner, at /gsd-verify-work 4: press F3 on a night (the stress night or a prototype night with walls) and confirm the night banner reads whole above the overlay panel and nothing that matters is hidden.

## Self-Check: PASSED

- FOUND: tests/e2e/test_overlay_banner_layout.gd and its .gd.uid, ui/overlay/debug_overlay.tscn (`offset_top = 104.0`, two `line_spacing = 0` lines), tools/screenshot/shot_scenarios.gd (`_toggle_overlay` called twice in `_overlay_paths`)
- FOUND commits: d7b29be, 9392d81, a017489 (`git rev-list --count` from the ledger base: 3)
- ui/hud/hud.tscn unchanged by every task commit
- Acceptance criteria re-run: all pass (see Verification)

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*
