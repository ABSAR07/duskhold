---
phase: 03-king-combat-troops
plan: 04
subsystem: simulation
tags: [godot, gdscript, weapon-def, king-slam, regeneration, king-widget, hud, command-gate]

requires:
  - phase: 03-king-combat-troops
    provides: "03-02 squads and the SquadSystem the command gate now holds; 03-03 HudRoot, hud_theme.tres four-size font scale, run_bound binding and the protected-centre contract"
provides:
  - "WeaponDef (passive 3 m / 5 / 0.7 s, slam 4 m / 4 / 9 s in data/king/sword.tres) and KingDef.weapon with a defaults fallback; KingDef lost attack_range, attack_damage and attack_interval"
  - "KingState slam on a tick countdown: activate_ability, resolve_ability (enemy-only hits, king as attacker, inclusive radius, ascending id), tick_timers, ability_cooldown_ratio"
  - "ActivateAbilityIntent and CommandProcessor reasons RUN_OVER, NO_ABILITY, KING_DOWN, ABILITY_COOLING; submit dispatches through a Dictionary keyed by the intent script; trailing optional king and squads constructor arguments"
  - "King regeneration (D-20): 1 s after the last hit, 10 % of max health per second as whole points, by day and night, never while down; king_healed event"
  - "SimEvents.king_ability_used and king_healed with SimSignals.ALL and SimRecorder entries"
  - "Input Map action ability (Q / pad X), AbilityController (polled, denied signal) and SlamVfx (ring from the weapon radius, MAX_RINGS 4)"
  - "KingWidget (health bar, hp / max, clockwise sword cooldown, ready flash, denied shake, knocked-out look) and SwordIcon, under HudRoot"
affects: [03-05, 03-06, 03-07, 03-10, 03-11, 03-12]

actuals:
  tokens: 25600
  tasks: 3
  commits: 6

plan_head_before: 2ea9d4f76c44b29779c004d31fa139a967ee4524
plan_head_after: 12bdbaf68f2ad8037c22c5cc59a7f9d927d393ee
commits: 6

tech-stack:
  added: []
  patterns:
    - "Per-step king countdowns (slam cooldown, regeneration delay and progress) live in KingState.tick_timers, which RunContext.step calls once per step in every phase"
    - "CommandProcessor.submit looks the handler up by the intent's script in a Dictionary, one return path; each handler takes a RefCounted"
    - "A quantisation guard (REGEN_EPSILON 1e-6) on the floor of a float accumulator so 0.9999999999999999 of a point still heals"
    - "HUD widgets build their parts in _ready and expose read-only hooks (ready_flash_count, shake_count, get_*) for the layout and animation tests"

key-files:
  created:
    - simulation/defs/weapon_def.gd
    - data/king/sword.tres
    - simulation/commands/activate_ability_intent.gd
    - input/ability_controller.gd
    - presentation/vfx/slam_vfx.gd
    - ui/hud/sword_icon.gd
    - ui/hud/king_widget.gd
    - tests/unit/test_weapon_def.gd
    - tests/unit/test_king_slam.gd
    - tests/unit/test_king_regen.gd
    - tests/e2e/test_ability_input.gd
    - tests/e2e/test_king_widget.gd
  modified:
    - simulation/defs/king_def.gd
    - data/king/king.tres
    - tests/fixtures/fixture_king_replay_smoke.tres
    - simulation/king/king_state.gd
    - simulation/commands/command_processor.gd
    - simulation/run/run_context.gd
    - simulation/night/night_sim.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - tools/replay/playtest_bot.gd
    - presentation/map/prototype_map.tscn
    - project.godot
    - ui/hud/hud.tscn
    - tests/unit/test_input_map.gd
    - tests/unit/test_king_combat.gd
    - tests/unit/test_king_respawn.gd
    - tests/unit/test_squad_archers.gd
    - tests/integration/test_balance_acceptance.gd
    - tools/screenshot/shot_runner.gd
    - tools/screenshot/shot_scenarios.gd

key-decisions:
  - "The slam resolves inside KingState.step after the passive attack (night) and inside NightSim.step_day before the squads (day), so a day slam runs the same code and hits nothing; a king knocked out between the press and the step drops the slam"
  - "Regeneration counts the delay down inside tick_timers and returns until it is 0, so after a hit exactly SimClock.ticks(delay) steps pass with no heal and the next 30 steps add 5 whole points at 50 max health; a hit zeroes the progress, down or full health zeroes it too"
  - "A fraction that is zero, negative, NaN or infinite switches regeneration off; a NaN, negative or infinite delay counts as 0 (T-03-08)"
  - "KingState has exactly 20 public methods after this plan, the gdlint cap: any later king method must be private or live in a new file"
  - "The ability glyph (24x24 TextureRect in the UI-SPEC King widget table) is left to 03-10, which owns every action glyph and prompt; the widget carries the 'Slam' caption fallback the UI-SPEC specifies"

patterns-established:
  - "RED with an inert API skeleton (class names, signals and their SimSignals/recorder entries) so tests compile and fail on assertions"
  - "A scripted screenshot scenario that needs a behaviour a later feature removes (a knocked-out king) runs on its own deep-copied def (ShotScenarios.king_def_for)"

requirements-completed: [KING-04, KING-05, UI-01]

coverage:
  - id: D1
    description: "The king's weapon is data: sword.tres carries passive 3 m / 5 / 0.7 s and slam 4 m / 4 / 9 s, king.tres points at it, a WeaponDef or a KingDef with no weapon falls back to the old defaults, and is_slam_armed refuses NaN, infinite, non-positive, sub-step and over-an-hour numbers"
    requirement: KING-04
    verification:
      - kind: unit
        ref: "tests/unit/test_weapon_def.gd (10 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "An accepted ability press hits every living enemy within slam_radius inclusive in ascending id through PendingHits with the king as attacker, reports king_ability_used(count), starts the cooldown of SimClock.ticks(9.0), never touches squads, buildings or the castle, and works by day (hits nothing)"
    requirement: KING-04
    verification:
      - kind: unit
        ref: "tests/unit/test_king_slam.gd (16 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A rejected press returns NO_ABILITY, KING_DOWN, ABILITY_COOLING or RUN_OVER with command_rejected and changes nothing, with no push_error"
    requirement: KING-04
    verification:
      - kind: unit
        ref: "tests/unit/test_king_slam.gd (reason tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Q and pad X bind the ability action; in the real scene a press by day slams once and shows a ring, a second press in the cooldown emits denied(ABILITY_COOLING), and a held key is one press"
    requirement: KING-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_ability_input.gd (4 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd (ability keys, buttons, deadzone, no shared binding)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The king heals 1 s after the last hit at 10 % of max health per second as whole points, by day and night, stops at full, restarts on every hit, never heals while down, respawn and dawn still return full health, and bad data switches it off"
    requirement: KING-05
    verification:
      - kind: unit
        ref: "tests/unit/test_king_regen.gd (16 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_king_respawn.gd#test_with_regeneration_off_by_data_health_stays_put_through_a_night"
        status: pass
    human_judgment: false
  - id: D6
    description: "The smoke replay golden is byte-identical (inline weapon with the old numbers and no slam, regeneration off by data default)"
    requirement: KING-04
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (digest 2599c7c2...)"
        status: pass
    human_judgment: false
  - id: D7
    description: "The bottom-left KingWidget shows 'hp / max' beside a 192x24 bar, a 56x56 sword icon that fills clockwise over the cooldown with one ready flash per cooldown and a 'Slam' caption, shakes on a denied press, dims with a red '0 / 50' when knocked out, stays inside x 16..376 / y 624..704 and outside the protected centre, and grows right for a 120 health king"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_widget.gd (14 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_hud_contract.gd (font-size set and protected-rectangle tests cover the new labels)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Whether the slam's radius, damage and 9 s cooldown, the regeneration pace and the look of the ring and widget feel right"
    verification: []
    human_judgment: true
    rationale: "Feel and look are the owner's to judge at the Phase 3 UAT (RESEARCH A6, the KING-04 and KING-05 flagged assumptions); plan 03-12 captures the hud_king_120 and slam screenshots and 03-11 retunes"

duration: 60min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 04: The King's Sword, Slam, Regeneration and Widget Summary

**The king's passive moves into a WeaponDef without moving a digest, gains a 4 m slam on Q / pad X with a 9 s cooldown, heals 10 % of his health per second a second after the last hit, and a bottom-left widget shows his health and the slam's clockwise cooldown**

## Performance

- **Duration:** 60 min
- **Started:** 2026-10-10T10:09:28Z
- **Completed:** 2026-10-10T11:09:53Z (code); SUMMARY and tracking follow
- **Tasks:** 3 (all TDD: RED then GREEN each)
- **Files modified:** 32 plus 12 `.uid` files (12 created, 20 modified, per `git diff --name-only 2ea9d4f HEAD`)

## Accomplishments

- **D-18 weapon as data:** `WeaponDef` holds the passive and the slam; `data/king/sword.tres` carries the signed-off numbers; `KingDef` points at it and lost its three attack fields. The smoke fixture carries an inline weapon with the old 3 / 3 / 0.8 and no slam, so the smoke golden digest `2599c7c2...` did not move. `full_idle` stayed `bb9059c8...` (ticks 5140) after Task 1, and moved to `91db5112...` after Task 2 only because regeneration is on in `king.tres` (it is not pinned by any test or the golden file).
- **KING-04 slam (D-17, D-19):** `ActivateAbilityIntent` through a command gate that now dispatches by intent script and returns `RUN_OVER`, `NO_ABILITY`, `KING_DOWN` or `ABILITY_COOLING` with `command_rejected`. The slam resolves on the next step (night inside `KingState.step`, day inside `NightSim.step_day`), hits only enemies, pays nothing and emits `king_ability_used(count)`. `AbilityController` polls the new `ability` action with the scripted-press edge fallback; `SlamVfx` grows a ring to the weapon's own radius.
- **KING-05 regeneration (D-20):** whole points from a float accumulator after `SimClock.ticks(1.0)` steps, by day and night, never while down, restarted by every hit, `king_healed` per gain; bad data switches it off.
- **UI-01 widget (D-22):** `KingWidget` and a code-drawn `SwordIcon` under `HudRoot`; checked in a real-renderer screenshot (ready state and knocked-out state).
- Suite: 107 scripts / 929 tests at baseline to 112 scripts / 990 tests, all passing (11461 asserts); lint clean; all fifteen screenshot scenarios still capture.

## Task Commits

1. **Task 1 RED: weapon, slam and input tests + inert skeleton** - `f9e3123` (test)
2. **Task 1 GREEN: sword as data, slam, gate, input, ring** - `2552472` (feat)
3. **Task 2 RED: regeneration tests, regen fields and king_healed entries** - `8bd7f28` (test)
4. **Task 2 GREEN: regeneration + balance re-pin** - `d5c3370` (feat)
5. **Task 3 RED: king widget tests + inert skeleton** - `bd8c79b` (test)
6. **Task 3 GREEN: KingWidget, SwordIcon, hud.tscn, shot scenario fix** - `12bdbaf` (feat)

RED evidence for all three tasks: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`) for `test_a_second_press_during_the_cooldown_is_refused_and_changes_nothing` (Task 1), `test_after_the_delay_he_regains_five_points_in_the_next_thirty_steps` (Task 2) and `test_the_widget_lives_under_the_hud_root_and_ignores_the_mouse` (Task 3).

## TDD Gate Compliance

RED (`test(03-04)`) precedes GREEN (`feat(03-04)`) for every task. Each RED commit carries an inert API skeleton (class names, signals with their SimSignals and recorder entries, stub methods) so the tests compile and the target test fails on an assertion. In the Task 3 RED, only the first test fails on an assertion; the others fail on null-widget script errors because the widget node does not exist yet, which is the expected state of a missing node. In Task 2's RED the replaced `test_king_respawn` case and `test_a_fresh_king_def_has_regeneration_off` passed immediately: they pin a data default and the off-by-data rule rather than driven behaviour. No REFACTOR commit was needed.

## Files Created/Modified

See `key-files` above. Notable: `simulation/king/king_state.gd` (slam, cooldown, regeneration; 20 public methods, the gdlint cap), `simulation/commands/command_processor.gd` (dispatch table and the ability gate), `ui/hud/king_widget.gd` (the polled widget).

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Another read of a removed KingDef field**
- **Found during:** Task 1 (full suite)
- **Issue:** `tests/unit/test_squad_archers.gd` read `king.attack_damage` through a variable named `king`, so the plan's grep for the three fields missed it; the suite caught it (`Invalid access to property 'attack_damage'`).
- **Fix:** read `king.weapon.attack_damage` instead.
- **Files modified:** `tests/unit/test_squad_archers.gd`
- **Verification:** `test_squad_archers` 6/6, then the full suite 960/960
- **Committed in:** `2552472`

**2. [Rule 1 - Bug] The king_down_countdown screenshot scenario could no longer knock the king out**
- **Found during:** Task 3 (self-verification with `bash tools/screenshot.sh`, not covered by the test suite)
- **Issue:** with D-20 regeneration on in `king.tres`, the balanced bot holding a spawn point never lost the king in eight nights (`the king was never knocked out`).
- **Fix:** `ShotScenarios.king_def_for(shot)` returns a deep copy of the shipped king with regeneration off for that one shot and `ShotRunner._spawn_map` assigns it before `_ready`.
- **Files modified:** `tools/screenshot/shot_runner.gd`, `tools/screenshot/shot_scenarios.gd`
- **Verification:** all fifteen shots captured; the knocked-out widget visible in `king_down_countdown.png`
- **Committed in:** `12bdbaf`

**3. [Rule 1 - Expected measurement change] test_balance_acceptance re-pinned (the plan's own instruction)**
- **Found during:** Task 2 (full suite)
- **Issue:** regeneration changed a measured outcome: `test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three` failed with `[9] != [3, 9]`.
- **Fix:** re-pinned `BALANCED_LOST_SEEDS` to `[9]` with a comment "Re-measured after D-20 regeneration (plan 03-04); plan 03-11 re-pins after the army retune"; the test was renamed `test_balanced_loses_only_seed_nine_and_never_before_night_three` and the win count message reads 9 of 10. No assertion changed shape.
- **Old and new values:** balanced bot on seeds 1 to 10: lost seeds `[3, 9]` (8 of 10 won) became `[9]` (9 of 10 won). The other strategies (greedy economy, no_build, towers_first) and `test_king_sturdiness` were unchanged.
- **Files modified:** `tests/integration/test_balance_acceptance.gd`
- **Verification:** `test_balance_acceptance` 8/8
- **Committed in:** `d5c3370`

---

**Total deviations:** 3 auto-fixed (3 Rule 1)
**Impact on plan:** none on scope. Note for 03-11: the owner's G-02-15 target was 2 or 3 losses in 10 balanced runs; regeneration alone brings it to 1.

## Authentication Gates

None.

## Known Stubs

None. The 24x24 ability glyph from the UI-SPEC King widget table is deliberately not built here: 03-10 owns every action glyph and prompt, and the widget carries the specified "Slam" caption as the glyph-free fallback.

## Threat Flags

None. T-03-07 (mitigate) is pinned by `test_king_slam` for each gate reason; T-03-08 (mitigate) by `is_slam_armed` plus the regeneration off-by-data and bad-delay tests; T-03-SC (accept): no packages, no third-party asset, the sword is drawn in code. T-03-06 holds: every KingWidget part is `mouse_filter` IGNORE, asserted.

## Issues Encountered

- `KingState` is at exactly 20 public methods (the gdlint cap) and `UnitSystem` was already at its cap; later plans must put any new king or unit method in a new file.
- `requirements.ready-ids` reported 0 of 3 ready (KING-04, KING-05 and UI-01 are declared by later plans of this phase too), so REQUIREMENTS.md is unchanged by the shared-ID gate.
- The slam ring and the ready flash were verified by counters and by the real-renderer widget screenshots, not by a screenshot of the ring itself; plan 03-12 owns the slam and `hud_king_120` captures.

## Next Phase Readiness

Ready for 03-05 (squad strip, HudRoot child bottom-centre, clear of the KingWidget's x 16..376). `CommandProcessor` already takes `squads` for 03-06's squad commands, `AbilityController` and the `denied` pattern are the template for the command inputs, and `king_healed`/`king_ability_used` are in SimSignals and the recorder. 03-11 should expect the king to be sturdier than the Phase 2 pins assumed.

## Self-Check: PASSED

- Files exist: all twelve created files (`weapon_def.gd`, `sword.tres`, `activate_ability_intent.gd`, `ability_controller.gd`, `slam_vfx.gd`, `sword_icon.gd`, `king_widget.gd` and the five test files)
- Commits exist: `f9e3123`, `2552472`, `8bd7f28`, `d5c3370`, `bd8c79b`, `12bdbaf`
- Acceptance criteria re-run: `class_name WeaponDef` and `is_slam_armed`, `var weapon: WeaponDef` and no `var attack_range` in `king_def.gd`, the five sword numbers, `ABILITY_COOLING` and `ActivateAbilityIntent` in the gate, `king.tick_timers()` in `run_context.gd`, `"physical_keycode":81` and `"button_index":2` in `project.godot`, `regen_delay_seconds = 1.0` / `regen_fraction_per_second = 0.1`, `king_healed` in all three signal files, the old no-regeneration test gone, `FILL_CLOCKWISE`, `HEALTH_TEXT`, `ABILITY_CAPTION`, `make_texture(` and a `KingWidget` node under `HudRoot`
- Plan verification: `bash tools/test.sh` exit 0 (990/990) with `test_weapon_def`, `test_king_slam`, `test_ability_input`, `test_king_regen`, `test_king_widget`, `test_hud_contract`, `test_king_knockout` in the JUnit XML; smoke replay `REPLAY_OK` digest `2599c7c2...`; `bash tools/lint.sh` clean
