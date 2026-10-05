---
phase: 02-night-defense-playtest-gate
plan: 07
subsystem: simulation
tags: [godot, gdscript, run-end, results-screen, defeat, victory, run-stats, gut, loop-06, loop-07]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: CastleState.is_destroyed and castle_destroyed, NightSim, dawn rebuild and repair, HUD banner and is_timed_night, ReplayDriver and SimRecorder (plans 02-01 to 02-06 and 02-08)
provides:
  - RunManager WON and LOST terminal phases, end_run_in_defeat, is_run_over, get_total_nights (LOOP-06, LOOP-07)
  - Loss decided in the castle's own step and beating a same-step win; the last authored night wins with no last dawn payout
  - SimEvents.run_ended(outcome) in SimSignals.ALL and SimRecorder; RunStats (nights survived, gold earned, buildings lost, king knockouts, outcome)
  - ReplayDriver outcomes won and lost with a stats block, stopping at the terminal step
  - ResultsScreen (Victory/Defeat, the stats, Play again, Quit), the castle collapse and frozen loss beat, terminal lighting, king input freeze, MapRoot.handle_results_actions
affects: [02-09, 02-10, 02-11]

actuals:
  tokens: 13800
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A terminal phase is enforced in two places: RunContext.step returns at once and RunManager.tick does nothing, so neither the clock nor any system can change a finished run"
    - "Loss beats win by ordering, not by a flag: RunContext.step calls end_run_in_defeat after night.step and before run_manager.tick"
    - "A read-only stats listener (RunStats) counts from SimEvents only and is also the single source the results screen and ReplayDriver read"
    - "A presentation beat that must outlast a frozen simulation uses a real-time SceneTreeTimer (process_always, ignore_time_scale)"
    - "Menu actions the UI depends on (ui_accept, ui_left, ui_right) are bound explicitly in project.godot, not left to engine defaults"

key-files:
  created:
    - simulation/run/run_stats.gd
    - ui/results/results_screen.gd
    - ui/results/results_screen.tscn
    - tests/integration/test_run_outcomes.gd
    - tests/unit/test_run_stats.gd
    - tests/e2e/test_results_screen.gd
  modified:
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/night/night_sim.gd
    - simulation/events/sim_events.gd
    - simulation/defs/loop_tuning.gd
    - data/tuning/loop_tuning.tres
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - tools/replay/replay_driver.gd
    - presentation/map/map_root.gd
    - presentation/map/prototype_map.tscn
    - presentation/buildings/building_views.gd
    - presentation/environment/day_night_lighting.gd
    - presentation/king/king.gd
    - project.godot
    - tests/unit/test_input_map.gd
    - tests/e2e/test_king_knockout.gd

key-decisions:
  - "WON and LOST are terminal: RunManager.tick and RunContext.step do nothing once the run is over, so tick_count and the elapsed clock stop (the defeat step itself still counts one tick; the victory step ticks the clock)"
  - "The last authored night ends straight in WON with no dawn payout, rebuild or repair (RESEARCH Open Question 2); gold earned counts dawn payouts only, so a victory pays no last dawn"
  - "A map with no authored nights (the Phase 1 timed night) can never be won: the WON branch needs has_authored_nights and get_total_nights() > 0"
  - "NightSim gained total_nights() so RunManager can answer get_total_nights() without holding the map"
  - "ResultsScreen reads ctx.tuning.loss_beat_seconds and times the beat with a real-time SceneTreeTimer; a victory shows at once (no beat)"
  - "ui_accept, ui_left and ui_right are bound explicitly in project.godot (keyboard plus gamepad A, D-pad, left stick) because the engine's built-in ui_accept has no gamepad button in this build"

patterns-established:
  - "New SimEvents signals go into SimSignals.ALL and SimRecorder (handler plus HANDLED) in the same task (continued)"
  - "TDD tasks commit a RED test commit carrying only the stubs needed to fail on assertions, then a GREEN feat commit (continued)"

requirements-completed: [LOOP-06, LOOP-07]

coverage:
  - id: D1
    description: "The run is lost in the very step the castle reaches 0: phase LOST, run_ended(defeat) once, castle_destroyed once; a castle at 1 hp keeps the run going; overkill clamps at 0; several hits in the same step still end it once"
    requirement: LOOP-06
    verification:
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_the_run_is_lost_in_the_step_the_castle_reaches_zero"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_a_castle_at_one_hit_point_keeps_the_run_going"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_several_hits_on_the_same_step_end_the_run_once"
        status: pass
    human_judgment: false
  - id: D2
    description: "Loss beats win: the last enemy dying in the step the castle falls ends LOST with no DAWN, no rebuild, no payout and no castle repair"
    requirement: LOOP-06
    verification:
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_the_last_enemy_dying_in_the_step_the_castle_falls_is_a_loss"
        status: pass
    human_judgment: false
  - id: D3
    description: "Clearing a night before the last enters DAWN; clearing the last authored night enters WON with run_ended(victory) and no further dawn payout or rebuild; the shipped map has 8 nights; a waveless map never wins"
    requirement: LOOP-07
    verification:
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_clearing_the_last_night_wins_with_no_last_dawn"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_clearing_a_night_before_the_last_enters_dawn"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_the_shipped_map_has_eight_nights_to_clear"
        status: pass
    human_judgment: false
  - id: D4
    description: "WON and LOST are terminal: steps and advance change nothing and emit nothing, StartNightIntent and BuildIntent return not_day, building is not allowed, end_run_in_defeat is legal only in NIGHT and fires once"
    requirement: LOOP-07
    verification:
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_a_lost_run_is_frozen_and_refuses_every_intent"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_a_won_run_is_frozen_and_refuses_every_intent"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_the_defeat_is_legal_only_during_the_night"
        status: pass
    human_judgment: false
  - id: D5
    description: "RunStats counts nights survived (n - 1 for a loss in night n, all nights on a win), gold earned (the sum of dawn totals), buildings lost, king knockouts and the outcome, from events only; ReplayDriver reports won or lost with the stats and the same digest on a replay"
    requirement: LOOP-07
    verification:
      - kind: unit
        ref: "tests/unit/test_run_stats.gd"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_a_lost_run_replays_to_the_same_lost_digest_and_stops_there"
        status: pass
      - kind: integration
        ref: "tests/integration/test_run_outcomes.gd#test_a_won_run_replays_to_won_with_the_nights_survived"
        status: pass
    human_judgment: false
  - id: D6
    description: "In the real scene a lost castle collapses into rubble at once, the enemy puppets stand still, the Defeat screen appears only after loss_beat_seconds (and within half a second after), a victory shows the screen within half a second, and the labels read the outcome, nights survived of total, gold earned, buildings lost and king knockouts"
    requirement: LOOP-06
    verification:
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_the_defeat_screen_waits_out_the_loss_beat_while_the_castle_collapses"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_victory_shows_the_screen_at_once_with_the_stats_of_the_run"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_the_defeat_screen_reads_the_run_and_a_second_run_ended_changes_nothing"
        status: pass
    human_judgment: false
  - id: D7
    description: "Play again has focus when the screen shows; Enter and the gamepad A button press the focused button, ui_right moves focus to Quit, a mouse press emits the same signals; MapRoot connects the two handlers only when handle_results_actions is true (the handlers are never invoked in a test)"
    requirement: LOOP-07
    verification:
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_play_again_has_focus_and_every_device_presses_the_buttons"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_map_root_wires_the_buttons_only_when_it_handles_the_results"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_the_menu_actions_have_keyboard_and_gamepad_bindings"
        status: pass
    human_judgment: false
  - id: D8
    description: "After the end the king ignores movement input (during the beat and after the screen shows) and the light is night after a defeat and dawn after a victory"
    requirement: LOOP-06
    verification:
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_after_a_defeat_the_king_ignores_input_and_the_light_stays_night"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_results_screen.gd#test_the_king_ignores_input_during_the_loss_beat_too"
        status: pass
    human_judgment: false
  - id: D9
    description: "Whether the castle collapse, the one-second frozen beat and the results screen read clearly and feel right on screen"
    requirement: LOOP-06
    verification: []
    human_judgment: true
    rationale: "Readability and feel are visual judgements; the tests prove state, timing and focus, not looks. The screenshot tool needs a real renderer and was not run here; the owner judges the beat and the screen at the playtest gate."

duration: about 80 min (the start time was not recorded at launch)
completed: 2026-10-05
status: complete
plan_head_before: 01b983d71e2309549ead329b109e456cdf50405d
plan_head_after: d645e8c83719c926a7e4e3f92709e5d80b2ded0d
commits: 4
---

# Phase 2 Plan 07: The Run Ends in Victory or Defeat Summary

**The castle falling loses the run in that very simulation step (and beats a same-step win), clearing the eighth night wins it with no last dawn, and either way the player lands on a results screen with the run's stats, Play again and Quit, after a frozen collapse beat on a defeat.**

## Performance

- **Duration:** about 80 min (start time not recorded at launch; estimated from the work)
- **Completed:** 2026-10-05
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 28 (including `.gd.uid` files)

## Accomplishments

- **RunManager:** `RunPhase` gains `WON` and `LOST` (existing integers unchanged). `end_run_in_defeat()` is legal only in NIGHT and emits `run_ended(&"defeat")`; `is_run_over()` and `get_total_nights()` (via the new `NightSim.total_nights()`) round out the interface. The NIGHT branch of `tick` calls `_end_night`: on a map with authored nights, finishing night `get_total_nights()` goes to WON (after `night.end_night()`) with `run_ended(&"victory")` and no payout, rebuild or repair; any earlier night goes to DAWN as before. `tick` does nothing once the run is over.
- **RunContext.step:** returns at once when the run is over; after `night.step` a destroyed castle calls `end_run_in_defeat()` before `run_manager.tick`, so the loss is decided in the castle's own step and beats a win the same step would have made. `stats = RunStats.new(events)` is created right after `events`.
- **RunStats:** a read-only listener counting nights survived (NIGHT to DAWN or WON), gold earned (dawn_payout totals), buildings lost, king knockouts and the outcome.
- **Replays:** `run_ended` is in `SimEvents`, `SimSignals.ALL` and `SimRecorder` (handler plus HANDLED); the final-state line adds the castle's health; `ReplayDriver` returns `won` or `lost`, stops at the terminal step and adds a `stats` block.
- **ResultsScreen:** a CanvasLayer (layer 10, hidden until shown) with the outcome and four stat labels and focusable Play again and Quit buttons. A victory shows at once; a defeat shows after `loss_beat_seconds` (1.2, data) of real time, measured by an ignore-time-scale timer. It shows at most once per run and ignores a repeat bind. No score or reward anywhere (D-15).
- **MapRoot:** `handle_results_actions` (default true) connects Play again to `reload_current_scene()` (a fresh run from day 1 with a fresh seed, D-16) and Quit to `quit()`; tests set it false.
- **Presentation:** `BuildingViews` collapses the keep (sink and squash, 0.9 s) and settles a keep-sized `RubbleView` when `castle_destroyed` fires, hiding the castle bar; `DayNightLighting` maps LOST to night and WON to dawn; `King` ignores movement input once the run is over. EnemyViews already stops interpolating outside NIGHT, so the field stands still.

## Task Commits

1. **Task 1 RED:** failing tests for the run ending in a win or a loss - `db01a57` (test)
2. **Task 1 GREEN:** castle falling loses the run, last night wins it, stats counted - `cc0f426` (feat)
3. **Task 2 RED:** failing tests for the loss beat and the results screen - `8e32ea4` (test)
4. **Task 2 GREEN:** castle collapses, action freezes for a beat, results screen offers Play again or Quit - `d645e8c` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 2: 78 scripts, 663 tests, 0 failures (base 631 in 75 scripts at dispatch); `bash tools/lint.sh` clean.
- `test_run_outcomes` (14 tests), `test_run_stats` (10), `test_run_manager`, `test_determinism`, `test_results_screen` and `test_start_night_hold` are present and passing in the JUnit XML; the phase-writer scan (`test_only_the_run_manager_assigns_the_loop_phase`) stays green.
- RED runs failed on assertions for the planned behavior: Task 1, 8 of 10 stats tests and 11 of 14 outcome tests (the 3 outcome tests and 2 stats tests that passed in RED guard behavior that already held on the stubs: a castle at 1 hp keeps going, a night before the last enters dawn, a waveless map never wins, a fresh run has counted nothing, counting emits nothing); Task 2, 7 of 7 scene tests.
- Acceptance strings checked: `WON, LOST`, `func end_run_in_defeat() -> bool` and `run_ended.emit` in run_manager.gd; `end_run_in_defeat()` and `RunStats.new(` in run_context.gd; `class_name RunStats` and `func gold_earned() -> int`; `"run_ended"` in sim_signals.gd; `class_name ResultsScreen`, both signals and `grab_focus()`; `PlayAgainButton` and `QuitButton` in the scene; `handle_results_actions` and `reload_current_scene()` in map_root.gd; `ResultsScreen` in prototype_map.tscn; `loss_beat_seconds = 1.2` in loop_tuning.tres.
- Not run: the screenshot tool (needs a real renderer), so the collapse and the screen are verified by state, timing and focus, not by eye. No mutation probe was run on this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] An existing e2e test's premise broke once the castle's fall ends the run**
- **Found during:** Task 1, first full-suite run
- **Issue:** `tests/e2e/test_king_knockout.gd` ambushes the king with eight grunts. While he is down they hit the 40 hp castle, which now falls, ends the run and freezes the king's respawn countdown, so "he respawns" never happened.
- **Fix:** the ambush map gives the castle 10000 hp so it outlasts the ambush; the test's own subject (the knockout and respawn) is unchanged.
- **Files modified:** tests/e2e/test_king_knockout.gd
- **Commit:** `cc0f426`

**2. [Rule 2 - Missing critical functionality] Gamepad accept did not work on the results screen**
- **Found during:** Task 2 GREEN, first scene run
- **Issue:** D-16 requires the buttons to work from the gamepad. A probe showed this build's built-in `ui_accept` holds only Enter, KP Enter and Space, so the gamepad A button pressed nothing.
- **Fix:** `project.godot` binds `ui_accept` (Enter, KP Enter, Space, gamepad A), `ui_left` (Left arrow, D-pad left, left stick) and `ui_right` explicitly. `test_input_map.gd` gains a test that pins the keyboard and gamepad bindings and the absence of a mouse binding on accept. The existing input-map tests exempt `ui_` actions, so they are unaffected.
- **Files modified:** project.godot, tests/unit/test_input_map.gd
- **Commit:** `d645e8c`

### Interface details that differ from the plan's sketch (no behavior change)

- **`NightSim.total_nights()`** was added (not in the plan's file list) so `RunManager.get_total_nights()` can read the map's night count without RunManager holding the map.
- **`BuildingViews.get_castle_rubble()`** was added for the scene test (the plan lists no castle accessor).
- **The RED commit for Task 1** carries the signal, the SimSignals and recorder entries, the enum values and stubs for RunManager and RunStats; the ReplayDriver and NightSim changes are GREEN-only (the replay tests failed on a missing `stats` key and outcome).
- **Terminal clock:** the defeat step counts one tick but does not advance the elapsed clock (RunManager.tick returns at once), while the victory step ticks the clock; both stop changing afterwards.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing functionality) plus the interface details above.
**Impact on plan:** none on the behavior list; every case holds.

## Issues Encountered

- A first scripted edit used a shell heredoc with mixed quotes and did not run; the edits were redone from a script file with no partial application.
- `-gselect` takes a single name; the two Task 1 suites were selected with the shared `test_run_` prefix.

## Known Stubs

None. The RED-phase stubs (RunManager methods, RunStats, ResultsScreen, `get_castle_rubble`) were replaced by the GREEN commits.

## Threat Flags

None. T-02-13 is mitigated as planned: ResultsScreen only emits signals, MapRoot acts on them only when `handle_results_actions` is true, and every scene in `test_results_screen.gd` sets it false except the wiring test, which only inspects the connections. T-02-14 is mitigated: WON and LOST are written only by RunManager (the phase-writer scan passes), terminal steps are no-ops and every intent is rejected. T-02-SC: no packages installed. The three prohibitions hold: the screen shows only the outcome and the five stats (no score or reward), the mouse can only press the two results buttons (which also work by keyboard and gamepad), and no reference-game wording is used.

## Flagged Assumptions for the Owner

- Open Question 2: the final night ends straight on Victory with no last dawn payout (gold earned counts dawn payouts only).
- The Victory screen has no beat; D-17's beat is for the loss only. To be confirmed at the playtest gate.
- The collapse look (keep sinks and squashes into a keep-sized rubble pile over 0.9 s inside a 1.2 s beat) and the results screen layout are untested by eye.
- Play again reloads the whole scene, so a fresh run starts from day 1 with a new random seed (D-16).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 02-09 to 02-11 can rely on: `RunManager.RunPhase.WON` and `LOST`, `is_run_over()`, `get_total_nights()`, `SimEvents.run_ended`, `RunContext.stats`, ReplayDriver outcomes `won` and `lost` with a `stats` block, and the shipped map ending in victory after night 8 (balance bots that ran past night 8 will now stop at the win).
- A lost run never enters `_enter_dawn`, so the dawn castle repair does not run for it (the 02-06 follow-up is resolved by ordering).
- Not run: the screenshot tool; the owner judges the beat and the screen at the playtest gate.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: run_stats.gd, results_screen.gd, results_screen.tscn, test_run_outcomes.gd, test_run_stats.gd, test_results_screen.gd.
- Commits `db01a57`, `cc0f426`, `8e32ea4`, `d645e8c` exist; `git rev-list --count 01b983d..HEAD` is 4.
- Full suite: 78 scripts, 663 tests, all passing; lint clean; no Godot process left running.
