---
phase: 01-foundation-day-loop
plan: 09
subsystem: gameplay-loop
tags: [godot, gdscript, gut, state-machine, day-night, dawn-income, hold-input, lighting, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-02 RunManager, CommandProcessor, RunContext, Input Map start_night; 01-06 BuildHoldController (cancels when building stops being allowed) and SpotLabel; 01-08 DebugOverlayModel with sections"
provides:
  - "RunManager Day -> Night -> Dawn -> Day state machine: start_night only from DAY, one transition per tick, tuned placeholder night and dawn timers, day and night counters"
  - "StartNightIntent through CommandProcessor (not_day outside DAY), build and upgrade locked outside DAY"
  - "Dawn income: BuildingSystem.dawn_income_by_spot in MapConfig order, paid once per dawn entry, dawn_payout emitted even at 0, gold never reset (ECON-02, ECON-07)"
  - "StartNightHoldController: hold N / gamepad Y for 1.5 s anywhere on the map, HUD prompt with fill bar, release resets"
  - "HUD night banner 'Night N — no enemies yet' and DayNightLighting day, night and dawn moods driven by phase_changed"
  - "Overlay Loop rows Day, Night and Timer"
affects: [01-10, phase-02-nights-waves, phase-02-dawn-rebuild, phase-08-audio-visual-polish]

actuals:
  tokens: 26500
  tasks: 3
  commits: 6
plan_head_before: 8439c010dcec44fd4783ba0fef5b28f0c3282569
plan_head_after: da006309ea7c3b29da3e2d9b406296684f3fe94e

tech-stack:
  added: []
  patterns:
    - "RunManager is the only writer of the loop phase; a test scans simulation, input, ui and presentation sources for any other phase assignment"
    - "Phase 2 extension points are exactly two function bodies: RunManager._night_should_end and RunManager._apply_dawn_payout"
    - "Presentation moods are exported properties in the text scene; the scene-shared Environment is duplicated per instance"
    - "Hold-to-confirm input ignores everything outside DAY and requires a release before it can fire again"

key-files:
  created:
    - simulation/commands/start_night_intent.gd
    - input/start_night_hold_controller.gd
    - presentation/environment/day_night_lighting.gd
    - tests/unit/test_run_manager.gd
    - tests/unit/test_build_phase_guard.gd
    - tests/unit/test_dawn_income.gd
    - tests/integration/test_loop_gold_carryover.gd
    - tests/e2e/test_start_night_hold.gd
  modified:
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/commands/command_processor.gd
    - simulation/events/sim_events.gd
    - simulation/defs/loop_tuning.gd
    - data/tuning/loop_tuning.tres
    - simulation/buildings/building_system.gd
    - ui/overlay/debug_overlay_model.gd
    - ui/hud/hud.gd
    - ui/hud/hud.tscn
    - presentation/map/prototype_map.tscn
    - tests/integration/test_build_flow.gd
    - tests/integration/test_build_hold_refund.gd
    - tests/e2e/test_build_denied.gd
    - tests/e2e/test_spot_label.gd

key-decisions:
  - "start_night increments night_number before the NIGHT_TRANSITION step, so any phase_changed listener (banner, prompt) already sees the correct number"
  - "start_night_hold_controller sets await-release every frame it sees the key down outside DAY, so holding N through the night and dawn never auto-starts the next night"
  - "DayNightLighting snaps to the current phase's mood in bind_run and duplicates the scene-shared Environment sub-resource before tweening"
  - "Prompt label and fill bar toggle their own visible flags (not just a container), so both node.visible and is_visible_in_tree read correctly"
  - "The overlay Timer row appears only in NIGHT and DAWN, formatted to one decimal from get_phase_time_remaining"

patterns-established:
  - "RED commits carry signature-only stubs (refusing start_night, empty dawn_income_by_spot, unattached controller and lighting scripts) so typed tests fail on assertions, not parse errors"
  - "Python edits of files containing an em dash must open with encoding='utf-8' on Windows (cp1252 wrote 0x97 and broke the script load)"

requirements-completed: [BLDG-06, ECON-01, ECON-02, ECON-07]

coverage:
  - id: D1
    description: "The day ends only through start_night; the loop runs DAY, NIGHT_TRANSITION, NIGHT (placeholder timer), DAWN, then the next DAY, one transition per tick, numbered days and nights"
    requirement: "BLDG-06"
    verification:
      - kind: unit
        ref: "tests/unit/test_run_manager.gd (11 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "validate_build and submit(BuildIntent) return not_day in NIGHT and DAWN with gold and buildings unchanged; a build hold in progress is cancelled when the night starts"
    requirement: "BLDG-06"
    verification:
      - kind: unit
        ref: "tests/unit/test_build_phase_guard.gd (4 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd#test_a_build_hold_is_cancelled_when_the_night_starts"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dawn pays each House its current tier income once, in MapConfig order; upgraded, tier-equal, tower and empty cases behave as specified"
    requirement: "ECON-02"
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd (9 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Unspent gold carries over unchanged across three full cycles with exact expected totals derived from the .tres data; the payout is the only gold change over a night"
    requirement: "ECON-07"
    verification:
      - kind: integration
        ref: "tests/integration/test_loop_gold_carryover.gd (2 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Gold is the only currency in the HUD and its label is always visible"
    requirement: "ECON-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd#test_the_night_hands_back_to_a_new_day_through_dawn (HUD gold equals Economy gold)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Hold-to-confirm input: tap keeps the day and resets the fill, a full hold starts one night, input is ignored outside the day and after a held-through night, banner text and prompt visibility follow the phase"
    requirement: "BLDG-06"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "The scene reads correctly in a real window: bottom prompt, filling bar over about 1.5 s, cool blue night under the banner, orange dawn, return to day with the prompt reading Night 2"
    verification: []
    human_judgment: true
    rationale: "Tests assert mood names, sun and ambient values, node visibility and text, not how the colours, layout and easing look on screen"

duration: 20min
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 09: Day, Night, Dawn Loop Summary

**Deliberate hold-to-confirm start-night input drives a tick-driven DAY, NIGHT, DAWN, DAY state machine that pays House tier income at dawn, carries gold over exactly, locks building outside the day, and shows a night banner with day, night and dawn lighting moods.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-29T10:40:09Z
- **Completed:** 2026-09-29T11:00:38Z
- **Tasks:** 3 (all TDD, RED then GREEN, no refactor commits)
- **Files modified:** 23 first-party files (15 modified, 8 created), plus `.gd.uid` files

## Accomplishments

- `RunManager` now owns the whole loop with the new `(events, economy, buildings, tuning)` constructor: `start_night()` only from DAY, at most one phase change per `tick`, day and night counters, `get_phase_time_remaining()`. `_night_should_end()` (placeholder timer) and `_apply_dawn_payout()` are the two bodies Phase 2 replaces.
- `StartNightIntent` goes through `CommandProcessor`, which answers `not_day` and emits `command_rejected(start_night, "", not_day)` outside DAY. Build and upgrade are `not_day` in NIGHT and DAWN.
- Dawn income (`BuildingSystem.dawn_income_by_spot`) pays each House its current tier once per dawn entry, in MapConfig order, emits `dawn_payout` even at 0, and nothing resets gold. Three full cycles on the prototype map land on the exact expected total.
- `StartNightHoldController` (N / gamepad Y, 1.5 s, anywhere), the HUD prompt with fill bar, the "Night N — no enemies yet" banner, and `DayNightLighting` (day, night, dawn moods, 1 s ease) are wired into the real scene. The overlay Loop section gains Day, Night and Timer rows.
- The four 01-06 tests and the 01-02 test that forced `RunManager._phase` now use the real `StartNightIntent` transition, as the orchestrator requested.

## Task Commits

1. **Task 1: Loop state machine, StartNightIntent, build phase guard** - RED `30c5f01` (test), GREEN `f602904` (feat)
2. **Task 2: Dawn income, gold carryover, overlay loop rows** - RED `df4b460` (test), GREEN `8a240ec` (feat)
3. **Task 3: Start-night hold, HUD prompt and banner, lighting moods** - RED `3f1b1db` (test), GREEN `da00630` (feat)

**Plan metadata:** committed separately as `docs(01-09)` after this file.

## Files Created/Modified

- `simulation/run/run_manager.gd` - the loop state machine and dawn payout
- `simulation/commands/start_night_intent.gd`, `command_processor.gd` - the intent and its gate
- `simulation/events/sim_events.gd`, `simulation/defs/loop_tuning.gd`, `data/tuning/loop_tuning.tres` - night_started, dawn_payout, day_started; hold, night and dawn seconds
- `simulation/buildings/building_system.gd` - `dawn_income_by_spot`
- `ui/overlay/debug_overlay_model.gd` - Day, Night, Timer rows
- `input/start_night_hold_controller.gd` - hold-to-confirm input
- `ui/hud/hud.gd`, `hud.tscn` - prompt, fill bar, banner (DebugOverlay child untouched)
- `presentation/environment/day_night_lighting.gd`, `presentation/map/prototype_map.tscn` - moods, `StartNightHold` node, script on `Lighting`
- `tests/unit/test_run_manager.gd` (11), `test_build_phase_guard.gd` (4), `test_dawn_income.gd` (9), `tests/integration/test_loop_gold_carryover.gd` (2), `tests/e2e/test_start_night_hold.gd` (8) - 34 new tests; suite is 181/181

## Decisions Made

See `key-decisions` in the frontmatter. In short: the night number increments before the transition step, the hold controller requires a fresh press after a held-through night, lighting snaps to the current phase on bind and duplicates the shared Environment, and the prompt label and bar toggle their own visibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Em dash written as a non-UTF-8 byte in hud.gd and hud.tscn**
- **Found during:** Task 3 (first GREEN run: "Script 'res://ui/hud/hud.gd' contains invalid unicode")
- **Issue:** A Python edit on Windows opened the files with the default cp1252 encoding and wrote the banner's em dash as byte 0x97.
- **Fix:** Replaced the byte with the UTF-8 em dash and confirmed every modified `.gd`, `.tscn` and `.tres` decodes as UTF-8. Recorded as a pattern for later plans.
- **Files modified:** `ui/hud/hud.gd`, `ui/hud/hud.tscn`
- **Verification:** full suite 181/181, lint clean
- **Committed in:** da00630 (never committed in the broken form)

**2. [Rule 1 - Bug] Test read a property from a freed node**
- **Found during:** Task 3 (GREEN run: "Invalid access ... on a base object of type 'previously freed'")
- **Issue:** `test_a_fresh_run_starts_in_day_lighting_even_after_a_night` read `lighting.day_ambient_energy` after freeing the first map.
- **Fix:** Capture the day mood values before freeing the map.
- **Files modified:** `tests/e2e/test_start_night_hold.gd`
- **Committed in:** da00630

---

**Total deviations:** 2 auto-fixed (2 bug fixes, both in code written during this plan)
**Impact on plan:** No scope change. Nothing in the plan's file list was skipped or added beyond `.gd.uid` files.

## TDD Gate Compliance

Every task has a `test(01-09)` RED commit before its `feat(01-09)` GREEN commit. RED runs failed on the planned assertions with no parse or script errors (Task 1: 15 of 15 new tests failing; Task 2: 10 of 10; Task 3: 7 of 8). `gsd_run check tdd-red-evidence` was not run (no record file persisted); the RED output was checked by hand.

Notes on two RED cases:
- Task 3's `test_a_build_hold_is_cancelled_when_the_night_starts` passed in RED. `BuildHoldController` has cancelled on `is_build_allowed()` since 01-06, and that behaviour is now proven against the real night transition, so it is kept as a regression test rather than a new-behaviour test.
- Task 3's `test_a_fresh_run_starts_in_day_lighting_even_after_a_night` also passes without the `Environment.duplicate()` (a mutation check showed the per-instance snap to day in `_ready` already covers a fresh run). The duplicate remains to avoid mutating the cached scene resource; the test guards the user-visible behaviour, not the duplicate itself.

## Issues Encountered

- One long multi-file shell heredoc was rejected by the shell tool; the files were written with the Write tool instead. No effect on the result.
- Working copies of several test files are CRLF on disk (repo `.gitattributes` normalises to LF on commit); git prints a CRLF warning but the committed content is LF.

## Known Stubs

None. The RED-commit stubs (refusing `start_night`, empty `dawn_income_by_spot`, unattached controller and lighting) were replaced in the GREEN commits.

## Threat Flags

None. No new network, auth or file surface. T-01-14 is mitigated as planned: single phase owner (scan test), `start_night` only from DAY, one transition per tick, payout once per DAWN entry, `StartNightIntent` and `BuildIntent` rejected outside DAY.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 01-10 (CI, screenshots, export). The screenshot tooling can drive the loop with the `start_night` action or `StartNightIntent`.
- Phase 2 fills the same loop: replace `RunManager._night_should_end` with "all enemies dead" (LOOP-03) and extend `_apply_dawn_payout` with the dawn rebuild (LOOP-04) and the rebuilt-pays-nothing rule (LOOP-05). `phase_changed`, `night_started`, `dawn_payout` and `day_started` are stable hooks for wave UI.
- Human check pending at verify-work (D7): run the game and confirm the prompt, the fill over about 1.5 s, the cool blue night under the banner, the orange dawn, and the return to day reading Night 2, with gold as the only currency on screen. The end-to-end feel of the 4 s placeholder night and 2 s dawn is untuned (Phase 2 playtest gate).

## Self-Check: PASSED

- Files: `simulation/commands/start_night_intent.gd`, `input/start_night_hold_controller.gd`, `presentation/environment/day_night_lighting.gd` and all five test files exist.
- Commits: `30c5f01`, `f602904`, `df4b460`, `8a240ec`, `3f1b1db`, `da00630` are in `git log`; `git rev-list --count 8439c01..HEAD` reports 6.
- Acceptance criteria re-run for all three tasks: every grep passes; `bash tools/test.sh` 181/181 with test_run_manager, test_build_phase_guard, test_dawn_income, test_loop_gold_carryover and test_start_night_hold in the JUnit XML; `bash tools/lint.sh` clean.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*
