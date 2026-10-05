---
phase: 02-night-defense-playtest-gate
plan: 08
subsystem: ui
tags: [godot, gdscript, hud, spawn-telegraph, debug-overlay, gizmo, loop-01, loop-02, gut]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: WaveSchedule.preview_counts, NightSim getters, EnemySystem.target_of, KingState getters, shipped eight-night map, DebugOverlay.register_section (plans 02-01 to 02-04 and Phase 1)
provides:
  - SpawnTelegraph (red disc with the night's enemy count over each spawn point, clamped to the screen edge with an arrow when off screen) and its pure placement helper
  - HUD night preview line under the start-night prompt and the real night banner "Night N of T — K enemies left"
  - LOOP-01 regression with real nights (no day timer, double start-night, build/night ordering)
  - NightOverlaySections (Wave, King, Paths) and EnemyPathGizmo (spawn roads and enemy-to-target lines), RunManager.is_timed_night()
affects: [02-09, 02-10, 02-11]

actuals:
  tokens: 15700
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Marker placement is a pure function (SpawnTelegraph.place): inclusive inset rectangle, ray-to-edge clamp, behind-camera point mirrored through the centre first"
    - "Overlay sections for the night are pure row builders over RunContext getters, registered with DebugOverlay.register_section after the defaults and the pre-bind registrations"
    - "Presentation debug node (EnemyPathGizmo) is bound by the overlay, follows overlay visibility and the NIGHT phase, and exposes refresh()/line_count() as test hooks"

key-files:
  created:
    - ui/world/spawn_telegraph.gd
    - ui/overlay/night_overlay_sections.gd
    - presentation/debug/enemy_path_gizmo.gd
    - tests/unit/test_wave_schedule.gd
    - tests/unit/test_spawn_telegraph_place.gd
    - tests/unit/test_debug_overlay_night_sections.gd
    - tests/e2e/test_spawn_telegraph.gd
    - tests/e2e/test_overlay_paths.gd
    - tests/integration/test_no_day_timer.gd
  modified:
    - ui/hud/hud.gd
    - ui/hud/hud.tscn
    - ui/overlay/debug_overlay.gd
    - ui/overlay/debug_overlay_model.gd
    - simulation/run/run_manager.gd
    - tests/e2e/test_start_night_hold.gd
    - tests/unit/test_debug_overlay_registration.gd

key-decisions:
  - "The Wave section's night row is labelled Nights, not Night: the existing toggle test parses every overlay row into one flat dictionary and a second Night row overwrote the Loop section's"
  - "Registration fixtures that used the section title Wave now use Probe, because the game owns that title now and a later in-place replacement would hide the fixture"
  - "SpawnTelegraph.edge_margin shrinks the 48 px margin to a quarter of the shorter side on a tiny window (the headless test window is 64 px square, where 48 px leaves no inset rectangle)"
  - "Markers are removed from the tree outside the day, so marker_count() is 0 at night rather than a count of hidden markers"
  - "The HUD decides banner copy with NightSim.has_authored_nights(); RunManager.is_timed_night() (added in Task 2) is the same predicate for the overlay and the phase clock"

patterns-established:
  - "New SimEvents signals go into SimSignals.ALL and SimRecorder.HANDLED in the same task (no new signal was added here)"
  - "TDD tasks commit a RED test commit carrying only stubs, then a GREEN feat commit (continued)"

requirements-completed: [LOOP-01, LOOP-02, DEV-05]

coverage:
  - id: D1
    description: "preview_counts sums every group of a spawn point, lists spawn points in MapConfig order identically on every call, and is empty for night 0, a night past the last and a waveless map; the preview adds up to the schedule that spawns"
    requirement: LOOP-02
    verification:
      - kind: unit
        ref: "tests/unit/test_wave_schedule.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "SpawnTelegraph.place keeps a point on the inset edge on screen (inclusive), clamps one pixel outside with an arrow, mirrors a behind-camera point before clamping and always lands inside the inset rectangle; markers_for lists markers in map order"
    requirement: LOOP-02
    verification:
      - kind: unit
        ref: "tests/unit/test_spawn_telegraph_place.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "In the real scene by day the west marker carries the night's count, is clamped while the king is at the castle, comes on screen within 1.5 s of riding to the spawn point, hides at night, and the next day shows the next night's count; waveless maps show no marker"
    requirement: LOOP-02
    verification:
      - kind: e2e
        ref: "tests/e2e/test_spawn_telegraph.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "The preview line reads 'Night N: K enemies from 1 direction' or '... from D directions' by day; the banner reads 'Night N of T — K enemies left' and falls as enemies die; a waveless map keeps 'Night N'"
    requirement: LOOP-02
    verification:
      - kind: e2e
        ref: "tests/e2e/test_spawn_telegraph.gd"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd#test_a_full_hold_starts_the_night_with_its_banner_and_mood"
        status: pass
    human_judgment: false
  - id: D5
    description: "No day timer: 18000 DAY steps on the shipped map leave DAY with no night_started; a double start-night starts one night (second returns not_day); build-then-night builds and starts, night-then-build starts and rejects the build"
    requirement: LOOP-01
    verification:
      - kind: integration
        ref: "tests/integration/test_no_day_timer.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "The Wave, King and Paths rows report wave progress, the king's state and enemy targets (summing to the alive count); collecting them emits no SimEvents signal and changes no tick, gold or health"
    requirement: DEV-05
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_night_sections.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "The Loop Timer row shows only on a timed night and at dawn; a real night reports no clock (is_timed_night, get_phase_time_remaining 0.0)"
    requirement: LOOP-01
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_night_sections.gd#test_the_loop_section_has_no_timer_row_during_a_real_night_but_keeps_it_at_dawn"
        status: pass
      - kind: unit
        ref: "tests/unit/test_debug_overlay_timed_phases.gd"
        status: pass
    human_judgment: false
  - id: D8
    description: "With the overlay open at night it lists Wave, King and Paths, its Enemies row follows the live count, and EnemyPathGizmo draws at least one road per used spawn point plus one line per targeted enemy; it hides when the overlay closes and by day"
    requirement: DEV-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_overlay_paths.gd"
        status: pass
    human_judgment: false
  - id: D9
    description: "Whether the red disc, count, edge arrow, preview line and gizmo lines read clearly at the default zoom"
    requirement: LOOP-02
    verification: []
    human_judgment: true
    rationale: "Readability is a visual judgement; the tests prove state and placement, not looks. The screenshot tool needs a real renderer and was not run here; plan 02-11's screenshot review and the owner at the playtest gate judge it."

duration: 38min
completed: 2026-10-05
status: complete
plan_head_before: 70626dc740a35b6ab5c8141f22dc8ab44e392019
plan_head_after: 9e9241d8f93e96de3a5bc5f638ddec47bd324125
commits: 4
---

# Phase 2 Plan 08: See the Night Coming, Read It in the Overlay Summary

**By day each spawn point that will send enemies wears a red marker with the night's count (over the point, or clamped to the screen edge with an arrow), the HUD says how many enemies from how many directions, the night banner counts what is left, and the debug overlay gains Wave, King and Paths sections plus a 3D enemy-path gizmo, while the day stays untimed.**

## Performance

- **Duration:** about 38 min
- **Started:** 2026-10-05T08:50:00Z (approximate; the start time was not recorded at launch)
- **Completed:** 2026-10-05T09:28:00Z
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 25 (including 9 `.gd.uid` files)

## Accomplishments

- **SpawnTelegraph** (`ui/world/spawn_telegraph.gd`, a full-rect mouse-ignoring Control in `hud.tscn`, group `run_bound`). `markers_for(map, n)` reads `WaveSchedule.preview_counts`; each marker is a red radial-gradient disc, a count label and an edge arrow shown only when clamped. Each frame by day it projects every spawn point through the current camera and calls the pure `place()`. Markers are rebuilt on `phase_changed` and `day_started` for night `get_night_number() + 1` and removed from the tree outside the day. Display only.
- **`place()`**: a point inside the viewport inset by 48 px (edges inclusive) is returned unchanged and on screen; otherwise the marker goes to the inset edge on the ray from the centre, with the angle of that ray; a point behind the camera is mirrored through the centre first and is never on screen; a zero direction points down the screen so no NaN escapes.
- **HUD**: `%NightPreview` under the start-night prompt ("Night 1: 5 enemies from 1 direction", or the plural form for several spawn points), visible by day when the coming night has markers. The banner reads "Night N of T — K enemies left" on maps with authored nights (refreshed on `night_started`, `enemy_spawned`, `enemy_died` and `phase_changed`) and the plain "Night N" on waveless maps.
- **LOOP-01 regression** (`tests/integration/test_no_day_timer.gd`): 18000 DAY steps leave the day untouched; a double StartNightIntent starts one night; build-then-night and night-then-build behave as the concurrency edge states.
- **`NightOverlaySections`**: `wave_rows` (Nights "1 of 8", Spawned, Alive, Next spawn, Cleared, Seed), `king_rows` (HP, State, Respawn, Knockouts "night / run"), `path_rows` (To king, To castle, To building, Marching) are pure reads; `register` adds the three sections after the defaults and after any pre-bind registration, and one `EnemyPathGizmo` under the map. `DebugOverlay.bind_run` calls it after replaying pending sections.
- **`EnemyPathGizmo`**: an `ImmediateMesh` of lines in an unshaded no-depth-test material. While the overlay is open and the phase is NIGHT it draws a dim road from each used spawn point to the castle and a bright line from each enemy to its target (gold for the king, red for the castle, blue for a building); hidden and cleared otherwise.
- **`RunManager.is_timed_night()`** (true when the map has no authored nights); the Loop section's Timer row now shows on a timed night and at dawn only, and `get_phase_time_remaining()` is 0.0 on a real night.

## Task Commits

1. **Task 1 RED:** failing tests for spawn markers, the preview, the banner and the untimed day - `93cb026` (test)
2. **Task 1 GREEN:** markers, preview line, night banner - `83ac24a` (feat)
3. **Task 2 RED:** failing tests for the overlay sections and the gizmo - `a9b9e56` (test)
4. **Task 2 GREEN:** sections, gizmo, `is_timed_night` - `9e9241d` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 2: 69 scripts, 568 tests, 0 failures (baseline 517 in 63 scripts); `bash tools/lint.sh` clean.
- `test_wave_schedule`, `test_spawn_telegraph_place`, `test_spawn_telegraph`, `test_no_day_timer`, `test_start_night_hold`, `test_debug_overlay_night_sections`, `test_overlay_paths`, `test_debug_overlay_registration` and `test_debug_overlay_timed_phases` are all present and green in the JUnit XML.
- RED runs failed on assertions for the planned behavior: Task 1, 247 asserts across 8 of 11 placement tests, 8 of 8 scene tests and the banner test; Task 2, 13 of 14 section tests and 4 of 4 scene tests. The tests that passed in RED guard behavior that already existed and is unchanged: `test_wave_schedule` (preview_counts already existed from 02-01) and `test_no_day_timer` (LOOP-01 already held; it is a regression guard), and the read-only test (a stub reads nothing).
- Mutation probe: changing the inclusive edge test in `SpawnTelegraph.place` from `<=` to `<` made `test_a_point_exactly_on_the_inset_edge_counts_as_on_screen` fail; the file was restored from a copy and `git status` showed it clean.
- Acceptance strings checked: `class_name SpawnTelegraph`, `static func place(`, `preview_counts(`, `SpawnTelegraph` and `NightPreview` in `hud.tscn`, `enemies left` and `enemies from %d directions` in `hud.gd`, `class_name NightOverlaySections` with the three titles, `NightOverlaySections.register(` in `debug_overlay.gd`, `class_name EnemyPathGizmo` and `ImmediateMesh`, `func is_timed_night() -> bool`, and 18000 DAY steps in `test_no_day_timer.gd`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Wave section's night row renamed from Night to Nights**
- **Found during:** Task 2, first full-suite run
- **Issue:** the plan names the row Night ("1 of 8"), but `tests/e2e/test_debug_overlay_toggle.gd` parses every overlay row into one flat dictionary; the Wave section's Night row overwrote the Loop section's Night row ("0 of 0" instead of "0"). The plan also requires every existing toggle test to stay green.
- **Fix:** the row is labelled `Nights` ("1 of 8"; "1 (timed)" on a waveless map). The value and meaning are as planned.
- **Files modified:** `ui/overlay/night_overlay_sections.gd`, `tests/unit/test_debug_overlay_night_sections.gd`
- **Commit:** `9e9241d`

**2. [Rule 3 - Blocking] Two registration fixtures moved off the title Wave**
- **Found during:** Task 2, first full-suite run
- **Issue:** `test_a_pending_section_replaced_before_bind_run_does_not_warn_about_the_old_owner` and `test_a_refused_pending_replacement_leaves_the_registered_section_alone` used the arbitrary title "Wave" for their own sections. The game now registers "Wave" after the pending replay, which replaces a same-titled section in place, so the fixtures' rows vanished. The plan fixes the title as Wave and asks that earlier registrations keep their order, so the fixtures had to yield.
- **Fix:** the fixtures use the title "Probe" (assertions and the warning text follow); nothing else in the file changed.
- **Files modified:** `tests/unit/test_debug_overlay_registration.gd`
- **Commit:** `9e9241d`

**3. [Rule 1 - Bug] Edge margin collapsed on a tiny window**
- **Found during:** Task 1 GREEN, first full run
- **Issue:** the headless test window is 64 px square, so the 48 px margin left no inset rectangle and `is_marker_on_screen` could never be true there; `test_riding_to_the_west_spawn_point_brings_its_marker_onto_the_screen` failed (a probe printed the 64x64 viewport and the spawn point projecting to (18, 32)).
- **Fix:** `SpawnTelegraph.edge_margin(viewport)` uses `EDGE_MARGIN_PX` or a quarter of the shorter side, whichever is smaller; `_process` uses it. A unit test pins both cases. `place()` itself keeps taking the margin as a parameter, so its pinned behavior is unchanged.
- **Files modified:** `ui/world/spawn_telegraph.gd`, `tests/unit/test_spawn_telegraph_place.gd`
- **Commit:** `83ac24a`

### Interface details that differ from the plan's sketch (no behavior change)

- **`EnemyPathGizmo.refresh()` and `bind(ctx, overlay)`** are public. `refresh()` is what `_process` calls each frame; tests call it to sync the lines with the simulation in the same frame. `bind` hands the gizmo its run and the overlay whose visibility it follows.
- **`marker_count()` is 0 outside the day** (markers are removed from the tree, not just hidden), so the "hide at night" behavior is observable as a count.
- **`SpawnTelegraph.markers_for`'s `world_position`** is the spawn point's own position; the disc is projected from there at ground level.
- **HUD banner predicate:** the HUD calls `ctx.night.has_authored_nights()` for the banner copy (Task 1 precedes `RunManager.is_timed_night()`, which exists for the overlay and the clock and is the same predicate).
- **`NightOverlaySections.NONE_TEXT`** is an em dash shown where a value does not apply.
- **The preview line is placed below the hold bar** inside `StartNightBox` (the box grows upward from its bottom anchor), so the prompt and its bar stay together.
- **Plural wording:** `NIGHT_PREVIEW` reads "enemies" for any count, including a night of one enemy (the copy constants are fixed by the plan).

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 bug) plus the interface details above.
**Impact on plan:** none on the behavior list; the Nights label and the Probe fixtures are consequences of the plan asking for both a fixed Wave title and untouched existing overlay tests.

## Issues Encountered

- A `-gselect` partial run overwrote `build/test-results/gut-junit.xml`; the full suite was re-run last so the JUnit file the verify command greps is the full one.
- gdformat rewrites some files to CRLF in the working tree; scripted edits normalise to LF on write and `git` reports no content difference.

## Known Stubs

None. The RED-phase shells (`SpawnTelegraph`, `NightOverlaySections`, `EnemyPathGizmo`, `is_timed_night`) were replaced by the GREEN commits.

## Threat Flags

None. T-02-15 (overlay and gizmo read only) is mitigated as planned: `test_collecting_the_night_sections_changes_no_state_and_emits_no_events` watches every name in `SimSignals.ALL` and compares tick count, gold, king health, castle health and enemy count across 100 collections of each builder. T-02-16 (overlay ships in release builds) stays accepted as T-01-15; T-02-SC: no packages installed. The plan's two prohibitions hold: nothing adds a day timer or any countdown that pressures the player, and no mouse input drives any marker, overlay or start-night action.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 02-09 to 02-11 can read the overlay's Wave, King and Paths sections and the gizmo in screenshots; the screenshot tool and a real renderer were not run here, so the telegraph's look (red disc, count, edge arrow), the preview line and the gizmo colours are verified by state and placement, not by eye. Plan 02-11's screenshot review and the owner at the playtest gate judge readability at the default zoom.
- The night ramp counts shown by the telegraph come from the map data (`WaveSchedule.preview_counts`), so 02-10's retune changes them with no test edits.
- If a later plan registers a section titled Wave, King or Paths, it replaces the night section in place (the overlay's replace-in-place rule).

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: spawn_telegraph.gd, night_overlay_sections.gd, enemy_path_gizmo.gd and the six new test suites.
- Commits `93cb026`, `83ac24a`, `a9b9e56`, `9e9241d` exist; `git rev-list --count 70626dc..HEAD` is 4.
- Full suite: 69 scripts, 568 tests, all passing; lint clean; no Godot process left running.
