---
phase: 01-foundation-day-loop
plan: 08
subsystem: ui
tags: [godot, gdscript, debug-overlay, canvaslayer, gut, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "RunContext, RunManager.get_phase, Economy.get_gold, BuildingSystem getters, run_bound group binding, HUD scene, toggle_debug_overlay input action, E2eSupport"
provides:
  - "DebugOverlayModel: pure read-only section model (Perf, Loop, Agents) with register_section(title, provider) for extension"
  - "DebugOverlay: hidden-by-default CanvasLayer toggled by toggle_debug_overlay (F3 / gamepad Back), refreshing about 4 times per second"
  - "RunContext.get_unit_count() and get_enemy_count() (0 in Phase 1)"
  - "Overlay instanced in ui/hud/hud.tscn in group run_bound"
affects: [01-10 screenshot tooling, phase-02 wave state and enemy-path sections, phase-13 release gating of the overlay]

actuals:
  tokens: 9500
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Debug/tooling views are built from registered section providers that only call simulation getters"
    - "Overlay lives inside hud.tscn (group run_bound on the instance), so the map scene needs no edit"

key-files:
  created:
    - ui/overlay/debug_overlay_model.gd
    - ui/overlay/debug_overlay.gd
    - ui/overlay/debug_overlay.tscn
    - tests/unit/test_debug_overlay_readonly.gd
    - tests/e2e/test_debug_overlay_toggle.gd
  modified:
    - simulation/run/run_context.gd
    - ui/hud/hud.tscn

key-decisions:
  - "Overlay refresh renders immediately when shown, then every 0.25 s, so get_text() is populated the moment it becomes visible"
  - "Overlay ships in all builds in Phase 1 (T-01-15 accepted); gating revisited before Phase 13"
  - "DebugOverlay also exposes register_section forwarding to its model, so later phases extend it without touching the model class"

patterns-established:
  - "RED commits use signature-only stubs (wrong or empty return values, unattached script) so tests fail on assertions rather than parse errors"

requirements-completed: [DEV-03]

coverage:
  - id: D1
    description: "RunContext exposes unit and enemy counts (0 in Phase 1)"
    requirement: "DEV-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_readonly.gd#test_unit_and_enemy_counts_are_zero_in_phase_one"
        status: pass
    human_judgment: false
  - id: D2
    description: "Overlay model provides Perf/Loop/Agents sections with FPS, phase, gold, buildings, units, enemies and appends registered sections"
    requirement: "DEV-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_readonly.gd#test_default_rows_report_fps_phase_gold_buildings_units_enemies"
        status: pass
      - kind: unit
        ref: "tests/unit/test_debug_overlay_readonly.gd#test_registered_section_is_appended_last_and_reads_its_provider"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reading the overlay 200 times never changes gold, phase or buildings and emits no simulation event"
    requirement: "DEV-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_readonly.gd#test_collecting_200_times_changes_no_state_and_emits_no_events"
        status: pass
    human_judgment: false
  - id: D4
    description: "Overlay is hidden by default, toggles on the toggle_debug_overlay action, lists the required fields and refreshes the Buildings row within 0.5 s of a build"
    requirement: "DEV-03"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_debug_overlay_toggle.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "Overlay panel looks right in the top-right corner of the real window (layout, legibility, no clash with the gold label)"
    verification: []
    human_judgment: true
    rationale: "Headless tests assert text content and visibility, not on-screen layout or legibility"

duration: 5min
completed: 2026-09-29
status: complete
plan_head_before: 6e7634466f6d6386a582370235fd91be2e11ff08
commits: 4
plan_head_after: 86f04dc09e5d71ff037ffe6e4c38449355fa069e
---

# Phase 1 Plan 08: Debug Overlay Summary

**Read-only F3 / gamepad-Back debug overlay (FPS, phase, gold, buildings, units, enemies) built from extensible registered sections, proven read-only by a 200-collect state and signal snapshot test**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-29T10:31:58Z
- **Completed:** 2026-09-29T10:36:49Z
- **Tasks:** 2 (both TDD, RED then GREEN)
- **Files modified:** 7 (5 created, 2 modified, plus `.uid` files)

## Accomplishments

- `DebugOverlayModel` (`RefCounted`) collects "Perf", "Loop" and "Agents" sections purely from RunContext getters; `register_section(title, provider)` appends further sections in registration order, which is how Phase 2 will add wave state and enemy paths.
- `RunContext.get_unit_count()` / `get_enemy_count()` added with stable signatures (both 0 until Phase 2/3).
- `DebugOverlay` `CanvasLayer` (layer 100, hidden by default, monospace label in a top-right panel, mouse-transparent) toggles on `toggle_debug_overlay` and re-renders every 0.25 s while visible; instanced in `hud.tscn` so `prototype_map.tscn` is untouched.
- Read-only contract proven: 200 `collect()` calls leave gold, phase and every spot tier unchanged and emit none of the four SimEvents signals.

## Task Commits

1. **Task 1: Read-only overlay model + RunContext counts**
   - RED `3635381` (test) - contract test plus signature-only stubs
   - GREEN `f41a561` (feat) - model and getters implemented
2. **Task 2: Toggleable overlay UI in the HUD**
   - RED `634e722` (test) - e2e toggle test plus signature-only `DebugOverlay` stub
   - GREEN `86f04dc` (feat) - overlay script, scene and hud.tscn instance

No REFACTOR commits were needed. **Plan metadata:** committed separately as `docs(01-08)`.

## Files Created/Modified

- `ui/overlay/debug_overlay_model.gd` - pure read-only section model with `register_section` and `collect`
- `ui/overlay/debug_overlay.gd` - toggleable `CanvasLayer`; `is_overlay_visible()`, `get_text()`, `register_section()`
- `ui/overlay/debug_overlay.tscn` - layer 100, hidden, top-right `PanelContainer` with `%OverlayText`
- `ui/hud/hud.tscn` - instances the overlay in group `run_bound` (existing gold label untouched)
- `simulation/run/run_context.gd` - `get_unit_count()`, `get_enemy_count()`
- `tests/unit/test_debug_overlay_readonly.gd` - 7 tests (counts, section order/shape, rows, registration, 200-collect read-only)
- `tests/e2e/test_debug_overlay_toggle.gd` - 4 tests on the real scene (hidden at start, toggle, fields, buildings refresh after an input-path build)

## Decisions Made

- Render immediately on show, then every 0.25 s, so the overlay never flashes empty text.
- Kept the overlay in all builds per accepted threat T-01-15; revisit gating before Phase 13.
- Added a forwarding `DebugOverlay.register_section` so later phases can extend the live overlay without reaching into its model.

## Deviations from Plan

None - plan executed exactly as written. (The RED commits carry signature-only stubs so that failures are assertion failures rather than parse errors, which is required for a valid RED under `tdd.md`; this is a TDD mechanic, not a scope change.)

## TDD Gate Compliance

Both tasks have a `test(01-08)` RED commit before the `feat(01-08)` GREEN commit. RED runs failed on the target assertions (Task 1: 7 of 7 failing after tightening the vacuous tests; Task 2: 4 of 4 failing on "the HUD instances the debug overlay"). `gsd_run check tdd-red-evidence` was not run (no record file was persisted); the RED output was verified by hand as assertion failures on the planned behaviour.

## Issues Encountered

None. The full suite passes: 147/147 (was 136 before this plan), `bash tools/lint.sh` clean. A Python text-mode rewrite briefly converted one test file to CRLF; it was normalised back to LF (repo `.gitattributes` enforces LF) with no diff in the committed content.

## Known Stubs

None. The unit/enemy counts returning 0 are the intended Phase 1 value (no units or enemies exist), not a placeholder wired to nothing; Phase 2/3 fill them from their managers without changing signatures.

## Threat Flags

None. The overlay adds no network, auth or file surface; T-01-15 (release-build availability) is accepted and documented in the plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 01-09 (night transition) and 01-10 (screenshot tooling can toggle the overlay via the `toggle_debug_overlay` action). Note: the overlay's Phase row reads `RunManager.get_phase()` through the public getter, so it will reflect the night transition automatically.
- Human check pending (verify-work): run the game, press F3 or gamepad Back, confirm the top-right panel shows FPS, Phase DAY, Gold, Buildings, Units 0, Enemies 0 and updates after building a House.

## Self-Check: PASSED

- Created files exist: `ui/overlay/debug_overlay_model.gd`, `debug_overlay.gd`, `debug_overlay.tscn`, both test files (verified with `git ls-files` and test run).
- Commits found: `3635381`, `f41a561`, `634e722`, `86f04dc`.
- Acceptance criteria re-run: all greps pass; `bash tools/test.sh` 147/147; JUnit XML contains both `test_debug_overlay_readonly` and `test_debug_overlay_toggle`; `bash tools/lint.sh` clean.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*
