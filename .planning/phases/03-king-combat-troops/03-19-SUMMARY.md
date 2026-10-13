---
phase: 03-king-combat-troops
plan: 19
subsystem: ui
tags: [godot, gdscript, hud, king-widget, contrast, wcag, copywriting, screenshot-probe, gap-closure]
gap_closure: true
gap_ids: [G-03-13, G-03-14]

requires:
  - phase: 03-king-combat-troops
    provides: "03-15's StartNightPlate in hud.tscn and hud.gd, the 33 real-window shots and ShotRunner's clear-centre check (03-12)"
provides:
  - "KingWidget knocked-out rule: bar, plate panel (self_modulate), sword icon and slam glyph dim to 0.4; the '0 / 50' count and the 'Slam' caption stay at alpha 1.0 on their opaque outline (G-03-13)"
  - "tools/contrast_probe.sh and tools/screenshot/contrast_probe.gd: a committed real-window contrast probe that exits non-zero below 4.5:1 (G-03-13)"
  - "Hud.enemy_count_text: '1 enemy' at one, 'N enemies' otherwise, used by the night banner and both preview patterns (G-03-14)"
  - "03-UI-SPEC.md rows for the knocked-out dimming rule, the contrast paragraph, the empty KingWidget state and the night copy"
affects: [03-17, phase-03-verification, 03-UAT-retest]

actuals:
  tokens: 6600
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Per-part alpha instead of a whole-widget modulate: dim non-text parts, keep text opaque on its own outline"
    - "Committed real-window probe behind a bounded wrapper (import warm-up, timeout, sentinel line, script-error guard), shown red on the unfixed capture before it is trusted green"
    - "RED with an inert skeleton: a plural-only enemy_count_text so the RED failures are assertions, not a parse error"

key-files:
  created:
    - tools/screenshot/contrast_probe.gd
    - tools/screenshot/contrast_probe.gd.uid
    - tools/contrast_probe.sh
  modified:
    - ui/hud/king_widget.gd
    - ui/hud/hud.gd
    - tests/e2e/test_king_widget.gd
    - tests/e2e/test_spawn_telegraph.gd
    - .planning/phases/03-king-combat-troops/03-UI-SPEC.md

key-decisions:
  - "Dim the bar, the plate's own self_modulate, the sword and the glyph; leave the widget, the count and the caption at alpha 1.0 (UI-REVIEW fix 1, first option; alpha 0.7 would composite #FF4040 to about 3.1:1)"
  - "The basis for legibility is the opaque, contiguous outline being the glyphs' immediate surround, not WCAG (which supplies only the luminance-ratio formula)"
  - "The wrapper defaults to the knocked-out count's command line when run with no arguments"

patterns-established:
  - "Probe rule: fill pixels key on r minus max(g, b) >= 0.15, backdrop is the non-fill 8-neighbour ring, text luminance is the 90th percentile of fill, backdrop luminance the median"
  - "Singular/plural copy through one static helper shared by every line that counts enemies"

requirements-completed: [UI-01]

coverage:
  - id: D1
    description: "A knocked-out king's '0 / 50' (#FF4040) and the Slam caption keep effective alpha 1.0 and their opaque black outline while the bar, plate panel, sword icon and slam glyph dim to 0.4; a respawn restores everything"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_widget.gd#test_a_knocked_out_king_keeps_the_count_and_caption_opaque_and_dims_the_rest"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fill over outline is at least 4.5:1 on both knocked-out texts (outline alpha 1.0, outline_size >= 6, effective alpha 1.0)"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_widget.gd#test_the_knocked_out_count_reads_at_least_4_5_to_1_on_its_opaque_outline"
        status: pass
    human_judgment: false
  - id: D3
    description: "Committed real-window contrast probe measures the knocked-out count on screenshots/hud_king_down.png at 5.88:1 (CONTRAST_OK), and 1.62:1 (CONTRAST_LOW) on the unfixed capture"
    requirement: UI-01
    verification:
      - kind: other
        ref: "bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5"
        status: pass
    human_judgment: false
  - id: D4
    description: "One enemy reads '1 enemy' on the day preview and the night banner; the plural everywhere else, through Hud.enemy_count_text"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_spawn_telegraph.gd#test_one_enemy_reads_in_the_singular_on_the_preview_and_the_banner"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_spawn_telegraph.gd#test_enemy_count_text_is_singular_only_for_one"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full suite green and all 33 real-window shots pass (clear-centre check included) with 03-15's StartNightPlate in place"
    requirement: UI-01
    verification:
      - kind: integration
        ref: "bash tools/test.sh (150 scripts, 1392 tests, 0 failing); bash tools/screenshot.sh (Saved 33 of 33)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The owner's by-eye read of the knocked-out count and the singular copy in the real game (UAT tests 13 and 14 re-test)"
    verification: []
    human_judgment: true
    rationale: "Readability at a glance is a judgment the probe and the tests approximate; the owner's UAT round re-test confirms it"

duration: 33min
completed: 2026-10-13
status: complete
plan_head_before: 2841128a9fbd188c78789be3b5e27a3cdc6132e6
plan_head_after: 87cbf5dae0081aecc7dc7086914ad8cbdc8431fb
commits: 4
---

# Phase 3 Plan 19: Knocked-out King Count and Singular Night Copy Summary

**The knocked-out king's "0 / 50" now stays opaque on its own outline (5.88:1 measured on the real capture, was 1.62:1) while the bar and icon dim, and one enemy reads "1 enemy" on the night banner and the day preview, backed by a committed real-window contrast probe.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-10-13T17:14:40Z
- **Completed:** 2026-10-13T17:47:29Z
- **Tasks:** 2 (both TDD; Task 1 is the plan's tracer)
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments

- **G-03-13 fixed.** `KingWidget._apply_knocked_out` no longer assigns the widget's `modulate.a`. It sets alpha 0.4 on the health bar (`modulate`), the plate panel (`self_modulate`, so its children the caption and the glyph are not tinted by it), the sword icon bar and the slam glyph, and 1.0 otherwise. The HealthLabel and the caption keep full alpha and their opaque black outline (outline_size 6), which is their immediate surround because neither sits on a panel.
- **Real-window contrast probe.** `tools/contrast_probe.sh` runs `tools/screenshot/contrast_probe.gd` headless against one PNG under `screenshots/`, measures a text's fill pixels against their immediate surround inside a rect with WCAG relative luminance, prints one `CONTRAST_OK` / `CONTRAST_LOW` / `CONTRAST_FAILED` / `CONTRAST_USAGE` line and exits non-zero below the bar. It was shown red on the unfixed capture before it was trusted green.
- **G-03-14 fixed.** `Hud.enemy_count_text` (`ENEMY_ONE` "%d enemy", `ENEMY_MANY` "%d enemies"); `NIGHT_BANNER`, `NIGHT_PREVIEW` and `NIGHT_PREVIEW_ONE` take the count through `%s`. The re-captured hud_king_down shot reads "Night 7 of 8 — 1 enemy left".
- **03-UI-SPEC.md amended**: Ability caption and Knocked out rows, the Color contrast paragraph, the empty KingWidget row, and a new Copywriting Contract row for the night counts.
- **Whole HUD re-checked** with 03-15's plate in place: full suite 150 scripts, 1392 tests, all passing; all 33 real-window shots pass; lint clean (265 files).

## Probe measurements (G-03-13, real-window hud_king_down, 1280x720, rect 280,648,96,56)

| Capture | Probe line | Method |
|---------|-----------|--------|
| UAT p13, unfixed | contrast_p90 **1.09:1** (text luminance 0.077 against 0.067) | digits against the ground beside them |
| Unfixed, re-captured in Task 1 | `CONTRAST_LOW ratio=1.62 min=4.50 text_luminance=0.0782 backdrop_luminance=0.0292 fill_pixels=355 backdrop_pixels=320 image=res://screenshots/hud_king_down.png rect=280,648,96,56` (exit 1) | digits against their immediate surround |
| Fixed | `CONTRAST_OK ratio=5.88 min=4.50 text_luminance=0.2530 backdrop_luminance=0.0015 fill_pixels=443 backdrop_pixels=323 image=res://screenshots/hud_king_down.png rect=280,648,96,56` (exit 0; re-run on the full 33-shot capture gave the same line) | digits against their immediate surround |

The two pre-fix figures differ in method, not in verdict: p13 compared the digits with the ground beside them, the probe compares them with their own outline. The unfixed probe figure is 1.62, a hair above the plan's "about 1.5 to 1.6" estimate; it is recorded as measured. The backdrop the fixed capture shows is the count's own opaque near-black outline (median luminance 0.0015) with the night ground beyond it, sampled at (63, 82, 77) / #3F524D at (8, 620) and (390, 690), the plan's "about #3E524C". Cropping and zooming the widget (x 0..420, y 590..720) shows a bright red "0 / 50" with a crisp black halo and a white "Slam" caption, against a dimmed bar and sword plate; the unfixed crop shows all of it washed to the ground. The count's text luminance 0.2530 is exactly the #FF4040 core, so the 90th-percentile rule lands on undimmed fill.

## Task Commits

1. **Task 1 (tracer): knocked-out count and caption stay opaque**
   - RED: `5052f5e` test(03-19): failing legibility checks and a real-window contrast probe for the knocked-out king widget
   - GREEN: `80262a7` fix(03-19): keep the knocked-out king count and caption opaque (G-03-13)
2. **Task 2: singular night copy, then the whole-HUD re-check**
   - RED: `5e99041` test(03-19): failing singular copy for one enemy
   - GREEN: `87cbf5d` fix(03-19): singular night copy for one enemy (G-03-14)

**Plan metadata:** the `docs(03-19)` commit that carries this SUMMARY and the STATE, ROADMAP and REQUIREMENTS updates.

## Files Created/Modified

- `tools/screenshot/contrast_probe.gd` (+ `.gd.uid`) - the probe: `parse_args`, `measure`, `luminance`, `contrast_ratio`; allowlisted arguments, `..` rejected, only a .png under `screenshots/`
- `tools/contrast_probe.sh` - bounded wrapper (import warm-up, `CONTRAST_TIMEOUT_S` default 60, `CONTRAST_OK` sentinel, SCRIPT ERROR guard); no arguments runs the knocked-out count's command line
- `ui/hud/king_widget.gd` - the per-part knocked-out dimming and the updated class doc
- `ui/hud/hud.gd` - `ENEMY_ONE`, `ENEMY_MANY`, `enemy_count_text`, the three `%s` copy constants and the two refresh calls
- `tests/e2e/test_king_widget.gd` - the opacity/dimming test and the 4.5:1 fill-over-outline test (14 functions to 15), with the blend, luminance and contrast helpers kept in the test file
- `tests/e2e/test_spawn_telegraph.gd` - the helper test and the singular-copy test (8 functions to 10); `_banner_text` follows the singular rule
- `.planning/phases/03-king-combat-troops/03-UI-SPEC.md` - the amended rows

## TDD Gate Compliance

Both tasks followed RED then GREEN with a `test(03-19)` commit before each `feat`/`fix` commit and no REFACTOR commit (nothing to clean up). RED evidence, each on an assertion for the planned behaviour and not a script error: Task 1, `bash tools/test.sh -gselect=test_king_widget.gd` gave 15 tests, 13 passing, 2 failing, with the count's composite at 1.72:1 and the caption's at 3.66:1 under the whole-widget 0.4, and the probe `CONTRAST_LOW ratio=1.62`; Task 2, `-gselect=test_spawn_telegraph.gd` gave 10 tests, 8 passing, 2 failing on "1 enemies" against "1 enemy" (the inert plural-only skeleton kept it from being a parse error).

## Decisions Made

- Followed UI-REVIEW fix 1's first option (per-part alpha, text opaque) rather than a raised whole-widget alpha, because 0.7 composites #FF4040 to about 3.1:1.
- The plate keeps its 0.4 `self_modulate` because it sits behind neither text; the ready-flash and slam-pulse tweens still drive `_plate.modulate`, which does not collide with `self_modulate`.
- The probe's thresholds (4.5, FILL_KEY 0.15, 90th percentile, 8-neighbour ring) were not tuned to pass; the same unmodified probe read 1.62 red and 5.88 green.

## Deviations from Plan

None - plan executed exactly as written. (Two incidental points, neither a deviation: the unfixed probe figure is 1.62 against the plan's "about 1.5 to 1.6" estimate; and gdformat plus the 100-column gdlint rule rewrapped several header-comment lines in the probe, a lint-compliance edit made before the RED commit.)

**Total deviations:** 0.

## Issues Encountered

- hud_night_squad_down.png reads "Night 7 of 8 — 9 enemies left", so the plan's "confirm the banner says '1 enemy' where one is left" is shown by hud_king_down.png ("Night 7 of 8 — 1 enemy left"); the other shot has nine enemies left and correctly stays plural. Pointing the probe at hud_night_squad_down's count rect returns `CONTRAST_FAILED no fill pixels in the rect` (the king is alive there, so there is no red count), the probe's designed behaviour for a rect with no fill.
- `git` prints "CRLF will be replaced by LF" for a gdformat-rewritten test file; the repository's eol=lf attributes normalise it and the diff is clean.

## Known Stubs

None. No placeholder text, hardcoded empty values or unwired data in the files created or modified.

## Threat Flags

None. The probe reads one .png under `screenshots/` (argument normalised, `..` and non-PNG rejected, usage errors exit 64) and writes only `build/contrast/`; tools/ is excluded from the export. T-03-31 and T-03-SC stand as accepted: the widget and the helper are read-only views of the simulation, and the replay goldens passed inside the full suite.

## Verification Results

- `bash tools/test.sh -gselect=test_king_widget.gd`: 15 tests, 15 passing, 106 asserts; `-gselect=test_ability_input.gd`: 4/4; `-gselect=test_spawn_telegraph.gd`: 10/10, 48 asserts
- Full suite `bash tools/test.sh`: **150 scripts, 1392 tests, 1392 passing**, 15611 asserts, exit 0 (baseline 1389; +3 = one widget test, two telegraph tests). test_one_enemy_reads_in_the_singular_on_the_preview_and_the_banner, test_start_night_plate, test_king_widget, test_hud_contract and test_squad_strip all appear in the JUnit XML
- `bash tools/screenshot.sh`: **Saved 33 of 33**, no clear-centre or blank failure; hud_day_squads, hud_day_squads_1080p and hud_king_down present
- `bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5`: `CONTRAST_OK ratio=5.88`
- `bash tools/lint.sh`: clean, 265 files
- Task 1's tracer `<verify>` chain re-run end to end after its commit: exit 0
- Acceptance criteria re-checked: `_apply_knocked_out` no longer assigns `modulate.a` on the widget (grep `modulate.a = KNOCKED` returns 0); both knocked-out tests present and in the JUnit XML; probe, its `.gd.uid` and wrapper committed; `enemy_count_text(` is called by `_refresh_banner` and `_refresh_preview`; the G-03-14 UI-SPEC row matches `G-03-14([^b]|$)`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- G-03-13 and G-03-14 are closed in code, tests, UI-SPEC and real-window shots; UAT tests 13 and 14 are ready for the owner's re-test (D6 is the one human-judgment item).
- Plan 03-17 may now start: its first task commits red balance tests that would have failed this plan's full-suite gate.
- UAT test 12 (the "Can't go there" toast, E6) was untouched, as the plan prohibits; it remains a pending owner decision.

## Self-Check: PASSED

All created files exist on disk (`tools/contrast_probe.sh`, `tools/screenshot/contrast_probe.gd`, its `.gd.uid`); commits `5052f5e`, `80262a7`, `5e99041` and `87cbf5d` exist; `git rev-list --count 2841128..HEAD` is 4; every task acceptance criterion and the plan-level verification re-ran green.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
