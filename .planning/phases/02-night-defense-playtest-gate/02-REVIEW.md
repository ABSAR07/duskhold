---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-05T15:13:47Z
depth: standard
files_reviewed: 127
files_reviewed_list:
  - .github/workflows/ci.yml
  - data/buildings/house.tres
  - data/buildings/tower.tres
  - data/enemies/grunt.tres
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - presentation/buildings/building_views.gd
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/enemies/enemy_views.gd
  - presentation/environment/day_night_lighting.gd
  - presentation/king/king.gd
  - presentation/king/king.tscn
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/vfx/health_bar_3d.gd
  - presentation/vfx/projectile_vfx.gd
  - presentation/vfx/rubble_view.gd
  - project.godot
  - simulation/buildings/building_instance.gd
  - simulation/buildings/building_system.gd
  - simulation/castle/castle_state.gd
  - simulation/clock/sim_clock.gd
  - simulation/clock/sim_rng.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/enemy_def.gd
  - simulation/defs/king_def.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/defs/night_def.gd
  - simulation/defs/spawn_group_def.gd
  - simulation/defs/spawn_point_def.gd
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/pending_hits.gd
  - simulation/night/target_query.gd
  - simulation/night/tower_system.gd
  - simulation/night/wave_schedule.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/run/run_stats.gd
  - tools/playtest.sh
  - tools/playtest/playtest_cli.gd
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_cli.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_scenarios.gd
  - ui/hud/dawn_no_income_marker.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
  - ui/overlay/night_overlay_sections.gd
  - ui/results/results_screen.gd
  - ui/results/results_screen.tscn
  - ui/world/spawn_telegraph.gd
  - ui/world/spot_label_model.gd
  - "plus the 58 files under tests/ listed in the scratchpad review_files.txt (see Coverage for which were read)"
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-10-05T15:13:47Z
**Depth:** standard
**Files Reviewed:** 127 (69 source, 58 test)
**Status:** issues_found

## Summary

The night simulation is in good shape. I traced the full step order (spawn, king, towers, enemies,
resolve, remove) and found no ordering or determinism bug: every `sort_custom` has a total order
(`seq`, group index and index), every iteration is in ascending id or MapConfig order, the splitmix
masks in `SimRng` are the correct logical-shift masks for 64-bit, and the seeded stream is the only
randomness in `simulation/`. The one `pow` call in `loop_tuning.gd` is reached only through
`coin_interval` and its callers, and a grep shows nothing under `simulation/` (outside the def itself)
or `tools/` calls them, so it cannot reach the digest. Loss-beats-win is correctly ordered in
`RunContext.step`. Replay CLI path handling is fail-closed (`..` segments rejected before
`localize_path`, root prefix compared with a trailing slash, allowlisted scenario names) and every
loop is bounded.

No BLOCKER was found. The three warnings are a data-validation gap that can hang a real night with
no safety net, a runtime "resource guard" that only logs, and an input collision that can restart
the run by accident from the results screen. The info items are consistency gaps and small
fidelity issues.

Known items checked: the optional trailing arguments (`EnemySystem.step`'s `buildings`,
`NightSim._init`'s `castle` and `buildings`, `KingState`'s `tuning`, `RunManager`'s `night`, `king`,
`castle`) are all null-guarded, and `RunContext` always passes the real objects, so they only matter
to hand-built tests. `KingState` falls back to `LoopTuning.new()` (code defaults, not the shipped
`.tres`), which equals the shipped respawn numbers today but would silently diverge on a retune in a
test that builds the king by hand. Nothing found beyond what was already known.

## Warnings

### WR-01: MapConfig.validate() cannot catch enemy data that makes a night impossible to end, and a real night has no clock

**File:** `simulation/defs/map_config.gd:123-128` (with `simulation/night/enemy_system.gd:280-287`,
`simulation/run/run_manager.gd:79-87,146-151`)
**Issue:** An enemy only starts attacking once it has a target, and it only gets a target when the
castle (or a building, or the king) is within `aggro_range`. It stops walking at `radius +
attack_range` from the castle centre. If an enemy's `aggro_range` is smaller than its
`attack_range`, it halts at its stop distance with `castle_edge = attack_range > aggro_range`, never
acquires a target, `attacking` stays false and it stands there forever. Traced with a ranged def at
`aggro_range = 1.0`, `attack_range = 5.0`: `_pick_nearest_structure` never selects the castle,
`_advance_and_strike` returns at line 287, the enemy never dies, `NightSim.is_cleared()` stays false.
A real (authored) night has no clock (`get_phase_time_remaining` returns 0.0 and
`_night_should_end` only asks `is_cleared`), so the run hangs in NIGHT. `validate()` checks only
`max_health`, `move_speed` and `attack_interval` per enemy, so the bad def passes it (and
`RunContext` only `push_error`s anyway). Shipped data is fine (grunt 6.0 > 1.2, ranged 9.0 > 7.0);
`test_every_night_ends` only covers the shipped numbers. The same gap lets `radius`, `attack_range`,
`aggro_range`, `leash_range`, `retarget_interval_seconds`, `castle_radius` and a tower tier's
`attack_interval` and `projectile_speed` go negative or zero unreported.
**Fix:** Add the relations to `_validate_night_data` (and a hard stop in the CLI/test tooling):
```gdscript
if enemy.aggro_range < enemy.attack_range:
    errors.append("enemy '%s' aggro_range (%s) is below attack_range (%s): it would never attack"
        % [enemy.id, enemy.aggro_range, enemy.attack_range])
if enemy.leash_range < enemy.aggro_range:
    errors.append("enemy '%s' leash_range is below aggro_range" % enemy.id)
if enemy.radius <= 0.0 or enemy.attack_range < 0.0:
    errors.append("enemy '%s' has a non-positive radius or negative attack_range" % enemy.id)
```
and add a test that builds each bad def and asserts `validate()` is non-empty. Consider an optional
per-night tick ceiling in `RunManager` so a stuck night degrades into a loss instead of a hang.

### WR-02: The per-night enemy cap is advisory only; at runtime it is not enforced

**File:** `simulation/defs/map_config.gd:7,173-179`; `simulation/night/wave_schedule.gd:8,26`;
`simulation/run/run_context.gd:31-32`
**Issue:** `MAX_ENEMIES_PER_NIGHT = 300` is described as a resource-exhaustion guard (T-02-04), but
the only enforcement is a `validate()` error that `RunContext._init` turns into `push_error` and then
carries on. `WaveSchedule` caps a single group at 500, which is above the 300 night limit, so a
single group of 500 spawns 500 enemies, and 20 groups of 500 spawn 10,000 with a clean run. The two
constants also disagree, so one of them is wrong. A bad or hostile data file gets the exact outcome
the guard names.
**Fix:** Make the schedule enforce the night limit, not only the group limit:
```gdscript
var budget: int = MapConfig.MAX_ENEMIES_PER_NIGHT
...
for index: int in range(mini(group.count, mini(MAX_GROUP_COUNT, budget))):
    ...
budget -= mini(group.count, MAX_GROUP_COUNT)
```
(do the same in `preview_counts` so the telegraph agrees), and drop `MAX_GROUP_COUNT` to the same
value or derive it from the map constant. The audit already notes the 500-per-group cap has no test;
add one that feeds 20 groups of 500 and asserts `total_count() <= 300`.

### WR-03: The action key is also the menu accept key, so mashing it at the end of a run restarts the game

**File:** `project.godot:66-100` (`action_build` and `ui_accept`), `ui/results/results_screen.gd:68-81`
**Issue:** `action_build` is Space, E and gamepad A. `ui_accept` is Enter, Space and gamepad A. The
results screen grabs focus on "Play again" in `_show_results` and a victory shows it in the same
step the last enemy dies (`_on_run_ended` calls `_show_results` directly, no beat). A player who is
tapping the action key or A when the last enemy falls (or when the 1.2 s defeat beat ends) presses
"Play again", which calls `reload_current_scene`, so the Victory or Defeat screen and its stats are
gone before the player reads them. A key that was already held when focus arrived is safe (no press
edge reaches the button), but a fresh tap is not. `test_input_map.gd` pins that build and
start_night share no key or button, but nothing covers build against `ui_accept`.
**Fix:** Ignore menu accept for a short grace window after the screen appears, for example:
```gdscript
const INPUT_GRACE_S: float = 0.6
func _show_results(outcome: StringName) -> void:
    ...
    _play_again_button.disabled = true
    visible = true
    get_tree().create_timer(INPUT_GRACE_S, true, false, true).timeout.connect(_arm_buttons)

func _arm_buttons() -> void:
    _play_again_button.disabled = false
    _play_again_button.grab_focus()
```
or focus "Quit"-neutral content first. Add an e2e assertion that an accept press inside the grace
window emits neither signal.

## Info

### IN-01: `preview_counts` counts groups that `WaveSchedule` skips

**File:** `simulation/night/wave_schedule.gd:20-23` versus `48-50`
**Issue:** The constructor drops a group whose spawn point or enemy id is unknown, but
`preview_counts` only checks the spawn point id (it matches against `map.spawn_points`), not the
enemy id. A group with an unknown `enemy_id` is therefore telegraphed ("7 enemies from 2 directions"
on the HUD, red discs on the map) and never spawns. `validate()` reports that data error and
`test_the_preview_adds_up_to_the_schedule_the_night_will_play` covers only valid shipped data, so it
is a UI-versus-schedule mismatch only on bad data.
**Fix:** Skip a group whose `map.find_enemy(group.enemy_id) == null` in `preview_counts`, and add a
test for the unknown-enemy case (the audit already lists the unknown-id skip as untested).

### IN-02: An arrow in flight when the last enemy dies is dropped, though it is drawn landing

**File:** `simulation/run/run_manager.gd:156-162,167-170`, `simulation/night/night_sim.gd:120-122`
**Issue:** Hits are queued by id and survive their attacker's death, but `_end_night` and
`_enter_dawn` call `NightSim.end_night()`, which clears `PendingHits`. A skirmisher arrow already in
the air when the last enemy dies is still animated by `ProjectileVfx` (it finishes at the target's
last position) but its damage never lands. At dawn buildings and the castle are healed anyway, so the
only effect is that a building that would have fallen to that arrow stays up and pays income. This
is probably acceptable, but it is an unstated rule; say so in the `NightSim` header or let the night
end only when `_hits.size() == 0` as well as `enemy_count() == 0`.
**Fix:** Document it, or add `_hits.size() == 0` to `is_cleared()` and a test.

### IN-03: `BuildingViews.bind_run` and `DayNightLighting.bind_run` have no repeat-bind guard

**File:** `presentation/buildings/building_views.gd:57-65`, `presentation/environment/day_night_lighting.gd:36-38`
**Issue:** Every other run-bound node (`King`, `EnemyViews`, `ProjectileVfx`, `Hud`, `ResultsScreen`,
`SpawnTelegraph`, `DawnNoIncomeMarker`, `DawnPayoutVfx`) opens `bind_run` with
`if _ctx != null: return` so a second call cannot connect a signal twice. These two do not. A second
`BuildingViews.bind_run` would add a second castle, duplicate every marker and connect
`building_built` twice (two views per spot). `MapRoot` binds once, so nothing is wrong today.
**Fix:** Add the same guard to both.

### IN-04: replay.sh and playtest.sh do not fail on `push_error` output

**File:** `tools/replay.sh:63`, `tools/playtest.sh:63`
**Issue:** The "script error" grep matches `SCRIPT ERROR`, `Parse Error` and `Failed to load script`
only. `RunContext._init` reports a bad map with `push_error("MapConfig '...': ...")`, which prints
`ERROR:` and is not matched, so a replay on a map that fails validation still prints `REPLAY_OK`
(and `playtest.sh` would write a report for it). Both wrappers also share one log name per tool, so
the second `replay.sh` call in CI overwrites the first call's `build/replay/replay.log`.
**Fix:** Add `MapConfig '.*':` (or `^ERROR:`) to the pattern; give the log a scenario-based name.

### IN-05: Some end-to-end tests budget real seconds against a clamped simulation clock

**File:** `tests/e2e/test_night_tracer_scene.gd:7,28-34`, `tests/e2e/test_building_rubble.gd:16`,
`tests/e2e/test_projectiles_visible.gd:13`, `tests/e2e/e2e_support.gd:91-96`
**Issue:** The scene's simulation advances from frame delta and `RunContext.advance` clamps a frame
at 0.25 s, so below 4 fps the game clock runs slower than the wall clock. Tests such as the 30 s
tracer night, the 8 s House-hit wait and the 12 s first-tower-shot wait are real-time ceilings over
simulated events. They pass with margin on the current machine and I found no tight one, but they
are the likeliest source of CI-only flakes (the CI test job runs under Xvfb or no GPU).
**Fix:** Where the test needs a result (not rendering), step `ctx.step()` directly or give the wait
a generous floor tied to simulated seconds; keep real-time waits for what is actually visual.

### IN-06: Screenshot job worst-case time equals the job timeout

**File:** `.github/workflows/ci.yml:130`, `tools/screenshot.sh:26`
**Issue:** `RUN_TIMEOUT_S=120` per shot over 15 shots is 30 minutes in the worst case, and the
screenshots job `timeout-minutes` is 30, with the import and install steps on top. Normal runs are
far shorter, but a run where several shots time out is cancelled by the job limit instead of
reporting which shots failed (the upload step is `if: always()` so artifacts survive).
**Fix:** Raise the job timeout (for example 45) or cut `RUN_TIMEOUT_S` to 60.

## Coverage

**Read in full:** every `simulation/` file in scope; `data/enemies/*.tres`, `data/king/king.tres`,
`data/buildings/*.tres`, `data/tuning/loop_tuning.tres`; `tools/replay.sh`, `tools/playtest.sh`,
`tools/screenshot.sh`, and all of `tools/replay/*.gd`, `tools/playtest/playtest_cli.gd`,
`tools/screenshot/*.gd`; `.github/workflows/ci.yml`; `presentation/map/map_root.gd`,
`king/king.gd`, `enemies/enemy_views.gd`, `buildings/building_views.gd`, `debug/enemy_path_gizmo.gd`,
`environment/day_night_lighting.gd`, `vfx/*.gd`; `ui/hud/hud.gd`, `dawn_payout_vfx.gd`,
`dawn_no_income_marker.gd`, `ui/overlay/*.gd`, `ui/results/results_screen.gd` and `.tscn`,
`ui/world/spawn_telegraph.gd`, `spot_label_model.gd`; tests `e2e_support.gd`, `test_determinism`,
`test_replay_golden`, `test_sim_rules_guard`, `test_every_night_ends`, `test_king_sturdiness`,
`test_night_loop`, `test_replay_cli_args`, `test_king_knockout`, `test_building_rubble`,
`test_projectiles_visible`, `test_night_tracer_scene`, `test_enemy_targeting`, `test_shot_list`,
`test_playtest_strategies`, `tests/golden/smoke.json`.

**Skimmed (partial or diff only):** `data/maps/prototype_map.tres` (first 120 lines plus a grep of
spawn, count and enemy fields, enough to confirm ids and counts but not every group delay);
`project.godot` (input section and the diff); `king.tscn`, `prototype_map.tscn` and `hud.tscn`
(diffs); `test_wave_schedule` (first 150 lines), `test_run_outcomes` (first 200 of 321 lines),
`test_balance_report` (first 150 of 278 lines), `test_walking_skeleton` (diff only); `test_tower_combat`,
`test_ranged_enemy`, `test_king_respawn`, `test_building_damage`, `test_building_targeting`,
`test_dawn_rebuild` and `test_run_manager` (test names only, to confirm the behaviours the code
review raised are exercised).

**Not opened:** `tests/e2e/test_dawn_payout.gd`, `test_dawn_rebuilt_marker.gd`,
`test_overlay_paths.gd`, `test_results_screen.gd`, `test_spawn_telegraph.gd`,
`test_start_night_hold.gd`; `tests/integration/test_loop_gold_carryover.gd`, `test_no_day_timer.gd`,
`test_prototype_nights.gd`, `test_upgrade_flow.gd`; `tests/support/*`; `tests/fixtures/*`; the
remaining unit tests (health bar, input map beyond the menu-action block, loop tuning contract, map
validation, night data contract, projectile vfx, run stats, sim clock, sim rng, spawn telegraph
placement, wave schedule remainder, debug overlay suites, replay and the rest of the Phase 2 unit
files not named above). I did not run any test or Godot process.

**Test-quality note:** in the tests I read I found no assertion that cannot fail, and no
wall-clock dependence beyond the real-time ceilings in IN-05. The `test_walking_skeleton` tolerance
change (0.0001 to one step) is justified by the accumulator and still rejects 6 or 9 steps. Items
already known and not repeated: no test for `MAX_VIEWS` / `MAX_PUFFS`, no test for the unknown-id
skip or the 500-per-group cap (WR-02 and IN-01 add the reason to write them), the `--import` warm-up
without a timeout, the class public-method cap.

---

_Reviewed: 2026-10-05T15:13:47Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
