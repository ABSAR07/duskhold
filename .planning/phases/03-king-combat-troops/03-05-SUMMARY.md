---
phase: 03-king-combat-troops
plan: 05
subsystem: ui
tags: [godot, gdscript, hud, squad-strip, stance-glyph, debug-overlay, units]

requires:
  - phase: 03-king-combat-troops
    provides: "03-02 SquadSystem life cycle with replacement_progress() and squad_restored; 03-03 HudRoot, hud_theme.tres four-size font scale, run_bound binding and the protected-centre contract; 03-04 SwordIcon and the king widget layout; 03-01 squads, unit types and UnitDef.projectile_speed"
provides:
  - "SquadStrip (bottom-centre, y 544..616) under HudRoot in group run_bound: one slot per squad in creation order, hidden with no squad, fade-in 0.15 s, uniform scale to 720 px past six slots"
  - "SquadSlot (scene and script, 136x72): code-drawn sword or bow icon, 'alive / max' Body 22 bold, StanceGlyph, hidden 20x20 GroupBadge, 4 px replacement fill, red 0 / N with dimmed icon and glyph, dawn border flash; set_selected and set_group exist for 03-06 and 03-08"
  - "StanceGlyph with five distinct code-drawn shapes plus a dot fallback, and BowIcon"
  - "SquadOrder verb and stance constants; SquadSystem.resting_stance(), executing_verb() (post and none until 03-06) and replacement_seconds_left()"
  - "SquadOverlaySections: the Squads section of the debug overlay, read-only, registered after the night sections"
affects: [03-06, 03-08, 03-10, 03-11, 03-12]

actuals:
  tokens: 13700
  tasks: 2
  commits: 4

plan_head_before: 0224d1379aae49e3f67c7721e385988234aea388
plan_head_after: 6400d120e9ae64179714246abb08b7535fa01c09
commits: 4

tech-stack:
  added: []
  patterns:
    - "A HUD widget that shows a list builds one child per simulation id from a polled getter (squad_ids) and never removes it; the slot keeps its place through 0 alive and rubble"
    - "A slot is a PanelContainer whose StyleBoxFlat content margins are 0 so the 2 px border is drawn inside the scene's own 8 px Margin; an overlay Control (FillHost) positions the 4 px fill absolutely"
    - "Overlay row labels carry a section prefix ('Squad ') so the toggle test's flattened dictionary never collides"
    - "A scratch SceneTree script run in a real window (non-headless) captures a screenshot of a configured scene for self-verification"

key-files:
  created:
    - simulation/squads/squad_order.gd
    - ui/hud/bow_icon.gd
    - ui/hud/stance_glyph.gd
    - ui/hud/squad_slot.gd
    - ui/hud/squad_slot.tscn
    - ui/hud/squad_strip.gd
    - ui/overlay/squad_overlay_sections.gd
    - tests/unit/test_stance_glyph.gd
    - tests/e2e/test_squad_strip.gd
    - tests/unit/test_debug_overlay_squad_section.gd
  modified:
    - simulation/squads/squad_system.gd
    - ui/hud/hud.tscn
    - ui/overlay/debug_overlay.gd
    - tests/unit/test_debug_overlay_night_sections.gd

key-decisions:
  - "The strip scales only past six slots (width above 856 px), to 720 px about the bottom centre, as the UI-SPEC and plan state; six slots stay at scale 1 and 856 px"
  - "Until orders exist (03-06) resting_stance returns post for a known squad and executing_verb returns none; both return the empty name for an unknown squad"
  - "Move and rally have no glyph among the UI-SPEC five; shape_for falls back to a dot for them, and 03-06 decides whether to map them when it makes executing_verb real"
  - "SquadSystem.replacement_seconds_left (ticks left times SimClock.STEP) feeds the overlay countdown instead of rebuilding seconds from replacement_progress and tier data, so no float round trip"
  - "A rubble Barracks shows 'rubble' in the overlay instead of a frozen countdown number"
  - "Slot hover styling is left to 03-06 with the click and selection work; this plan draws idle, 0 alive and the dawn flash only"

patterns-established:
  - "RED with an inert API skeleton: class names and stub methods land with the failing tests so the tests compile and the target test fails on an assertion"
  - "A HUD e2e test lays the real hud.tscn out in a 1280x720 SubViewport, binds the widget to a RunContext it owns, and steps the simulation by hand on a map copy whose enemies crawl, so the test decides every death"

requirements-completed: [UI-01, UNIT-07]

coverage:
  - id: D1
    description: "A bottom-centre SquadStrip shows one 136x72 slot per squad in creation order (y 544..616, x 500..780 for two), hidden with no squad and no placeholder text, clear of the king widget, 8 px above the start-night box and outside the protected centre"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd (hidden empty, one centred slot, two slots layout, creation order, strip under HudRoot, real-scene binding)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each slot reads its unit icon (sword for melee, bow for ranged), 'alive / max', the post stance glyph, and a 4 px replacement fill that rises while the squad is short; 0 alive turns the count #FF4040 and dims icon and glyph to #7A808C; a squad keeps its slot at 0 alive and as rubble with the fill stopped"
    requirement: UNIT-07
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd (4 / 4 sword, 4 / 4 bow, 2 / 4 with rising fill, 0 / 4 red dimmed, rubble Barracks keeps its place with a stopped fill)"
        status: pass
    human_judgment: false
  - id: D3
    description: "At dawn the border flashes #8CEBFF once for 0.3 s and the count jumps to full; an upgrade raises the cap at once and '14 / 14' fits on one line inside the 136 px slot"
    requirement: UNIT-07
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd#test_at_dawn_the_count_jumps_to_full_and_the_border_flashes_once"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd#test_upgraded_twice_by_day_the_slot_reads_14_of_14_on_one_line_and_keeps_its_width"
        status: pass
    human_judgment: false
  - id: D4
    description: "StanceGlyph draws five distinct shapes plus a fallback and BowIcon draws a white bow distinct from the sword; SquadOrder holds the verb and stance names; SquadSystem reports post and no verb before any order exists"
    requirement: UI-01
    verification:
      - kind: unit
        ref: "tests/unit/test_stance_glyph.gd (8 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd#test_building_the_barracks_adds_one_slot_reading_4_of_4"
        status: pass
    human_judgment: false
  - id: D5
    description: "More than six slots scale the strip uniformly to at most 720 px about its bottom centre; six slots stay 856 px at scale 1; the GroupBadge is a hidden fixed 20x20 box"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd (six slots, seven slots, group badge)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The debug overlay lists a Squads section: one 'Squad <id>' row per squad with alive/max, stance and whole seconds to the next replacement (rubble when the building fell, a dash when none), a dash row with no squad, read-only and collision-free with the other sections"
    requirement: UNIT-07
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_squad_section.gd (10 tests, including the SimSignals.ALL read-only guard and the bound-overlay order test)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the slot look reads well in the real game: icon weight, stance glyph legibility at 20x20, the replacement fill and the dawn flash against the 3D scene"
    verification: []
    human_judgment: true
    rationale: "Look and legibility are the owner's to judge at the Phase 3 UAT; a real-window capture shows the strip clear of the king widget and the start-night prompt, and plan 03-12 captures the hud_rubble_squad and squad strip screenshots"

duration: 36min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 05: Squad Strip and Debug Squads Section Summary

**A bottom-centre strip shows every squad as a 136x72 slot with a code-drawn sword or bow, "alive / max", a five-shape stance glyph and a replacement fill, and the debug overlay gains a read-only Squads section**

## Performance

- **Duration:** 36 min
- **Started:** 2026-10-10T11:22:31Z
- **Completed:** 2026-10-10T11:58:00Z (code); SUMMARY and tracking follow
- **Tasks:** 2 (both TDD: RED then GREEN each)
- **Files modified:** 23 (14 source and test files plus 9 `.uid` files, per `git diff --name-only 0224d13 HEAD`)

## Accomplishments

- **D-23 / UI-01 SquadStrip and SquadSlot:** the strip sits under `HudRoot` (anchors 0.5/1.0, offsets -176/-104, separation 8), polls `squad_ids()` each frame and adds a slot, fading in over 0.15 s, for each new squad in creation order. A slot shows the sword (melee) or bow (`projectile_speed` above 0) icon, `alive / max` in Body 22 bold, the stance glyph, a hidden 20x20 group badge and a 4 px fill driven by `replacement_progress()`. At 0 alive the count turns #FF4040 and the icon and glyph are modulated #7A808C; a rubble Barracks keeps its slot with the fill stopped. At dawn `squad_restored` refreshes the count and flashes the border #8CEBFF for 0.3 s once.
- **Layout contract:** with two squads the slots span x 500..780, y 544..616, 8 px above the start-night box (y 624), clear of the king widget footprint and the protected centre; "14 / 14" stays on one line in a 136 px slot; past six slots the strip scales uniformly to 720 px about its bottom centre.
- **StanceGlyph, BowIcon, SquadOrder:** five code-drawn shapes (post, follow, hold, patrol, attack-move) plus a dot fallback, a bow drawn pixel by pixel on the 48 unit grid the sword uses, and the verb and stance names 03-06 builds on. `SquadSystem.resting_stance()` and `executing_verb()` report post and none until orders exist.
- **Debug overlay:** `SquadOverlaySections` adds a Squads section after Paths, one `Squad <id>` row per squad (`4/4  post  —`, `2/4  post  8 s`, `rubble`), read-only, with a new `SquadSystem.replacement_seconds_left()` feeding the countdown.
- **Self-verification:** a real-window capture (Forward+, RTX 3060) of the squad fixture by day and at night confirmed both slots read `4 / 4`, then `2 / 4` and a red dimmed `0 / 4` with the fill rising, sitting clear of the king widget and the start-night prompt; a rendered enlargement confirmed the bow icon reads as a bow with a nocked arrow.
- Suite: 112 scripts / 990 tests at baseline to 115 scripts / 1024 tests, all passing (11975 asserts, exit 0); lint clean; the smoke replay digest `2599c7c2...` is byte-identical.

## Task Commits

1. **Task 1 RED: strip and glyph tests + inert skeleton** - `3313489` (test)
2. **Task 1 GREEN: SquadStrip, SquadSlot, StanceGlyph, BowIcon, stance getters, hud.tscn** - `7db45b7` (feat)
3. **Task 2 RED: Squads section tests + inert skeleton** - `8f33927` (test)
4. **Task 2 GREEN: SquadOverlaySections, replacement_seconds_left, registration, order-test update** - `6400d12` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md (see `git log --grep "docs(03-05)"`).

RED evidence: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`) for `test_every_stance_has_a_shape_of_its_own` and `test_building_the_barracks_adds_one_slot_reading_4_of_4` (Task 1) and `test_with_no_squad_the_section_shows_one_dash_row` (Task 2).

## TDD Gate Compliance

RED (`test(03-05)`) precedes GREEN (`feat(03-05)`) for both tasks. Each RED commit carries an inert API skeleton (class names and stub methods) so the tests compile. In the Task 1 RED the SquadStrip node is not yet in `hud.tscn`, so every strip test fails at its first assertion ("the HUD has a SquadStrip") and the stance-glyph target fails on a shape assertion; in the Task 2 RED several tests fail on null-value script errors because the stub returns no rows, the expected state of a missing section. Two of the eight glyph tests and two of the ten Squads-section tests passed immediately in RED (the glyph and the stub already satisfied a default); the failing target of each task is named in the RED evidence line above. No REFACTOR commit was needed.

## Files Created/Modified

See `key-files` above. Notable: `ui/hud/squad_strip.gd` (the polled strip and its fit rule), `ui/hud/squad_slot.gd` and `ui/hud/squad_slot.tscn` (the slot tree of the UI-SPEC), `ui/overlay/squad_overlay_sections.gd`.

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The overlay section-order test pinned the old section list**
- **Found during:** Task 2 (full suite)
- **Issue:** `test_debug_overlay_night_sections#test_the_overlay_lists_wave_king_and_paths_after_the_defaults_and_earlier_sections` asserted the exact list `[Perf, Loop, Agents, Early, Wave, King, Paths]`; registering the new Squads section makes it `[..., Paths, Squads]`.
- **Fix:** the expected list now ends with `Squads` and the message says so; no other assertion changed.
- **Files modified:** `tests/unit/test_debug_overlay_night_sections.gd`
- **Verification:** the suite re-run was 1024/1024
- **Committed in:** `6400d12`

**2. [Rule 2 - Missing critical] SquadSystem.replacement_seconds_left()**
- **Found during:** Task 2 (design)
- **Issue:** the plan names only `resting_stance` and `executing_verb` as new SquadSystem getters, but the overlay's "seconds to the next replacement" can only be derived from `replacement_progress` plus tier data, which loses the exact tick count to float rounding at the ceiling.
- **Fix:** one read-only getter returning `replacement_ticks_left * SimClock.STEP`, 0.0 when no countdown runs; SquadSystem is at 16 public methods, below the cap of 20.
- **Files modified:** `simulation/squads/squad_system.gd`
- **Verification:** `test_debug_overlay_squad_section` (two direct tests of the getter and the row text)
- **Committed in:** `8f33927` (skeleton), `6400d12` (implementation)

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2)
**Impact on plan:** none on scope. One extra read getter and one expected-list edit in an existing test that the plan's own registration made stale.

## Authentication Gates

None.

## Known Stubs

None that block the plan's goal. By the plan's design, `SquadSlot.set_selected()` and `set_group()` only remember their value and the GroupBadge stays hidden until plans 03-06 and 03-08; `SquadSystem.resting_stance()` always reports post and `executing_verb()` none until 03-06 adds orders. These are documented in code and in the plan's Flagged Assumptions, and each is lifted by a named later plan.

## Threat Flags

None. T-03-09 (mitigate) holds: the strip, slot and overlay section call only read getters; `test_debug_overlay_squad_section` watches every `SimSignals.ALL` signal and the tick count, gold and squad state across 100 reads, and the existing read-only drift guard covers new signals. T-03-SC (accept): no package and no asset, icons and glyphs are drawn in code.

## Issues Encountered

- A shell heredoc containing an apostrophe in a comment ("tier's") made one multi-file command fail to parse as a whole; the files were re-written with the Write tool and the edit script moved to a file, nothing was half-applied.
- The first run of the six-slot test showed a scale of 0.84: the strip scaled as soon as it passed 720 px. The UI-SPEC and plan say six slots (856 px) fit and only more than six scale to 720 px, so the threshold became 856 px.
- `SquadSlot` is at 13 public methods and `SquadSystem` at 16, both below the gdlint cap of 20; `KingState` and `UnitSystem` were not touched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 03-06 can light the selection border through `SquadSlot.set_selected`, make `SquadSystem.resting_stance` and `executing_verb` real, and decide whether move and rally get a glyph (they fall back to a dot now); slot hover and click styling are still to do.
- 03-08 fills the hidden GroupBadge through `set_group`.
- 03-12 owns the `hud_rubble_squad` and strip screenshots; the owner-judged look of the slots is covered by coverage item D7.

## Self-Check: PASSED

All created files exist on disk, commits `3313489`, `7db45b7`, `8f33927` and `6400d12` are in `git log`, the plan acceptance criteria pass (greps, `bash tools/test.sh` exit 0 with 1024/1024, `bash tools/lint.sh` clean, the three required suite names and the HUD contract suites in the JUnit XML), and the smoke replay digest is unchanged.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
