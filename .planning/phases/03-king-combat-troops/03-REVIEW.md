---
phase: 03-king-combat-troops
reviewed: 2026-10-12T08:56:00Z
depth: standard
files_reviewed: 173
files_reviewed_list:
  - .claude/CLAUDE.md
  - .github/workflows/ci.yml
  - ASSETS.md
  - assets/attribution.json
  - data/buildings/archery_range.tres
  - data/buildings/barracks.tres
  - data/king/king.tres
  - data/king/sword.tres
  - data/maps/prototype_map.tres
  - data/units/archer.tres
  - data/units/footman.tres
  - input/ability_controller.gd
  - input/command_key_controller.gd
  - input/device_model.gd
  - input/ground_cursor.gd
  - input/ground_pick.gd
  - input/last_device_tracker.gd
  - input/pad_chords.gd
  - input/pad_cursor_controller.gd
  - input/selection_controller.gd
  - input/selection_math.gd
  - input/selection_model.gd
  - presentation/buildings/building_view_catalog.tres
  - presentation/buildings/building_views.gd
  - presentation/buildings/models/archery_range_t1.tscn
  - presentation/buildings/models/archery_range_t2.tscn
  - presentation/buildings/models/archery_range_t3.tscn
  - presentation/buildings/models/barracks_t1.tscn
  - presentation/buildings/models/barracks_t2.tscn
  - presentation/buildings/models/barracks_t3.tscn
  - presentation/camera/camera_rig.gd
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/order_markers.gd
  - presentation/units/pad_cursor_view.gd
  - presentation/units/selection_rings.gd
  - presentation/units/squad_plan_view.gd
  - presentation/units/unit_views.gd
  - presentation/vfx/projectile_vfx.gd
  - presentation/vfx/slam_vfx.gd
  - project.godot
  - simulation/commands/activate_ability_intent.gd
  - simulation/commands/command_processor.gd
  - simulation/commands/squad_order_intent.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/king_def.gd
  - simulation/defs/map_config.gd
  - simulation/defs/unit_def.gd
  - simulation/defs/weapon_def.gd
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/pending_hits.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/squad.gd
  - simulation/squads/squad_formation.gd
  - simulation/squads/squad_order.gd
  - simulation/squads/squad_orders.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_army_scenarios.gd
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_scenarios.gd
  - ui/hud/bow_icon.gd
  - ui/hud/command_hints.gd
  - ui/hud/day_counter.gd
  - ui/hud/drag_box.gd
  - ui/hud/glyph_resolver.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/hud/hud_root.gd
  - ui/hud/king_widget.gd
  - ui/hud/prompt_glyph.gd
  - ui/hud/squad_slot.gd
  - ui/hud/squad_slot.tscn
  - ui/hud/squad_strip.gd
  - ui/hud/stance_glyph.gd
  - ui/hud/sword_icon.gd
  - ui/hud/toast.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/night_overlay_sections.gd
  - ui/overlay/squad_overlay_sections.gd
  - ui/theme/hud_theme.tres
  - tests/e2e/test_ability_input.gd
  - tests/e2e/test_box_select.gd
  - tests/e2e/test_building_models.gd
  - tests/e2e/test_command_hints.gd
  - tests/e2e/test_command_keys.gd
  - tests/e2e/test_control_group_keys.gd
  - tests/e2e/test_hud_contract.gd
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_mouse_commands.gd
  - tests/e2e/test_order_markers.gd
  - tests/e2e/test_pad_commands.gd
  - tests/e2e/test_pad_cursor.gd
  - tests/e2e/test_prompt_switch.gd
  - tests/e2e/test_select_one_type.gd
  - tests/e2e/test_selection_steering.gd
  - tests/e2e/test_squad_selection.gd
  - tests/e2e/test_squad_strip.gd
  - tests/e2e/test_squad_tracer_scene.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/e2e/test_stretch_coordinates.gd
  - tests/e2e/test_unit_views.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/fixtures/fixture_king_replay_army.tres
  - tests/fixtures/fixture_king_replay_smoke.tres
  - tests/fixtures/fixture_map_replay_army.tres
  - tests/fixtures/fixture_map_squads.tres
  - tests/golden/army.json
  - tests/integration/test_army_replay_golden.gd
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_replay_golden.gd
  - tests/integration/test_squad_determinism.gd
  - tests/integration/test_squad_lifecycle.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_control_groups.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_debug_overlay_squad_section.gd
  - tests/unit/test_device_model.gd
  - tests/unit/test_enemy_targets_units.gd
  - tests/unit/test_glyph_resolver.gd
  - tests/unit/test_ground_cursor.gd
  - tests/unit/test_ground_pick.gd
  - tests/unit/test_input_capabilities.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_input_map_groups.gd
  - tests/unit/test_king_combat.gd
  - tests/unit/test_king_regen.gd
  - tests/unit/test_king_respawn.gd
  - tests/unit/test_king_selection_steering.gd
  - tests/unit/test_king_slam.gd
  - tests/unit/test_map_validate_squads.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_night_data_contract.gd
  - tests/unit/test_pad_chords.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_prompt_glyph.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_selection_math.gd
  - tests/unit/test_selection_model.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_protected_centre.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_squad_archers.gd
  - tests/unit/test_squad_guard.gd
  - tests/unit/test_squad_order_intent.gd
  - tests/unit/test_squad_orders.gd
  - tests/unit/test_squad_patrol.gd
  - tests/unit/test_squad_point_orders.gd
  - tests/unit/test_squad_point_validation.gd
  - tests/unit/test_squad_queue.gd
  - tests/unit/test_squad_respawn.gd
  - tests/unit/test_squad_stance_persistence.gd
  - tests/unit/test_stance_glyph.gd
  - tests/unit/test_weapon_def.gd
findings:
  critical: 1
  warning: 3
  info: 6
  total: 10
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-10-12T08:56:00Z
**Depth:** standard
**Files Reviewed:** 173
**Status:** issues_found

## Summary

The production code in the list was read in full, with these exceptions: `tools/screenshot/shot_scenarios.gd`
(only lines 140-330 read; the other Phase 1 and 2 shot scenes were not), and the `.tscn` and `.tres` files
(prototype map, HUD scenes, building models, catalog), which were read structurally or by targeted
search. That covers the squad, unit, king, enemy, command and run simulation; the input controllers; the
presentation and HUD nodes; the data files, the input map, the CI workflow and the replay, playtest and
screenshot tooling. The tests and fixtures were read selectively,
not in full. What I read: `test_squad_tracer_scene`, `test_start_night_hold` (head), `test_pad_cursor`,
`test_order_markers` (flash and queue tests), `test_command_keys` (toast tests),
`test_balance_acceptance`, `test_squad_patrol`, `test_squad_guard` (head), `test_map_validate_squads`
(the RunContext test), `test_sim_rules_guard`, `test_shot_list`, `test_king_selection_steering`, both
king fixtures, `sim_signals.gd` and the army golden. The rest was only scanned for assertion density (every file
that declares tests asserts something) and for skip, pending or vacuous-pass patterns (none found).

The simulation core is in good shape. I traced the squad order queue, patrol ping-pong, follow and hold
anchors, the dawn restore, the king's slam, regeneration and knockout paths, enemy target choice against
units, the pending-hit queue and the gate's check order, and found them consistent with their
documentation. The source scan finds no forbidden engine API under `res://simulation` (only `sqrt`). The
input map's JoyButton, JoyAxis and keycode integers, and the Kenney tile names, all match what
`GlyphResolver` and `PadChords` expect. The asset table counts match `ASSETS.md`.

One real defect stands out: a guard that the threat register calls closed (T-03-04 and T-03-05) fails
open and hangs the game on a bad unit file (CR-01). The three warnings are a stale in-world king health
bar, a CI screenshot wrapper that cannot see script errors, and gate rejections that no player-facing
code reports. The info items are dead assignments, duplicated math and unused scene references. None of
the "known and accepted" items listed in the review brief was re-reported.

## Critical Issues

### CR-01: A unit with `max_health <= 0` hangs the game in an unbounded spawn loop; the validation only reports it

**File:** `simulation/squads/squad_system.gd:147-148` and `:456-458` (loops), `simulation/squads/unit_system.gd:29` (cause), `simulation/run/run_context.gd:32-34` (no refusal)
**Issue:** `MapConfig._validate_unit` reports `unit.max_health <= 0` (`map_config.gd:288-289`), but
`RunContext._init` only calls `push_error` and carries on, and `tests/unit/test_map_validate_squads.gd:171-185`
pins exactly that ("a run context still builds on bad squad data"). That test never builds a military
building, so it does not reach the consequence. `UnitSystem.spawn` stores `health = def.max_health`
unclamped, and `is_alive` is `health > 0`. `SquadSystem._fill` and `restore_for_dawn` then loop
`while _living_count(squad) < squad.cap` and spawn through `_raise_unit`. A unit that is born dead never
counts as living, so the loop never ends. Each pass appends to `squad.unit_ids`, to `UnitSystem._records`
and `_order`, and emits `unit_spawned`. The first day step after the player builds a Barracks (or the
first dawn) freezes the main thread and grows memory until the OS kills the process. A negative
`max_health` does the same.

The code's own header says a corrupted file "must not ... allocate without bound" (`map_config.gd`,
comment on `_validate_squads`), and `03-SECURITY.md` closes T-03-04 and T-03-05 on the strength of that
validation. Phase 2 solved the same problem on the consumer side: `WaveSchedule._allowances` caps the
spawn budget itself and does not rely on `validate()` having been heeded. The squad path has no
equivalent. This is the project's data trust boundary (hand-edited `.tres`), and the failure is a hard
hang, not a rejected value.
**Fix:** Bound the loops by the number of missing seats, so a bad definition can never loop on a
condition it cannot satisfy, and floor the stored health:
```gdscript
# squad_system.gd
func _fill(squad: Squad) -> void:
	for _seat: int in range(maxi(squad.cap - _living_count(squad), 0)):
		_raise_unit(squad, false)

# in restore_for_dawn, replace the while loop:
		for _seat: int in range(maxi(squad.cap - _living_count(squad), 0)):
			_raise_unit(squad, false)

# unit_system.gd, spawn():
	record.health = maxi(def.max_health, 1)
```
Optionally also make `RunContext` stop treating `validate()` errors in the army fields as advisory, and
add a test that builds a Barracks over a `max_health = 0` footman and expects the step to return.

## Warnings

### WR-01: The king's in-world health bar never follows regeneration

**File:** `presentation/king/king.gd:51-54` and `:94-95`
**Issue:** `King.bind_run` connects `king_damaged`, `king_downed`, `king_respawned` and `dawn_payout`
but not `king_healed`. Regeneration (D-20, shipped at 0.1 of max health per second after a 1 s delay)
heals the king whole points at a time and emits `king_healed` only; nothing on the presentation side
listens (a search for `king_healed` finds only the simulation and the recorder). After a hit, the
floating `HealthBar3D` therefore freezes at the damaged value and stays visible while the HUD
`KingWidget`, which polls, climbs back to full. The bar corrects itself only at the next hit, the next
respawn or the dawn payout. Mid-night the player sees two disagreeing health readouts, and a king who is
back at full health still wears a "hurt" bar.
**Fix:**
```gdscript
# king.gd, in bind_run:
	ctx.events.king_healed.connect(_on_king_healed)

func _on_king_healed(_amount: int, hp: int, max_hp: int) -> void:
	_health_bar.set_health(hp, max_hp)
```
`HealthBar3D.set_health` already hides the bar at full health. Add an e2e assertion beside
`tests/e2e/test_king_knockout.gd:155` that the bar hides again after regeneration.

### WR-02: `tools/screenshot.sh` cannot see script errors, unlike the replay and playtest wrappers

**File:** `tools/screenshot.sh:97-116` (compare `tools/replay.sh:63-65`, `tools/playtest.sh:63-65`)
**Issue:** `replay.sh` and `playtest.sh` tee the Godot output and fail on `SCRIPT ERROR|Parse Error|Failed
to load script`, because (as both headers state) a runtime script error in Godot still exits 0. The
screenshot wrapper runs Godot straight to the terminal and passes a shot when the exit status is 0 and a
PNG that is not blank exists. A script error inside a `_process` or signal handler of any HUD node (a
broken `SquadSlot` refresh, a failing `KingWidget` sync) is logged and ignored while the frame still
renders, so the `screenshots` CI job stays green over a broken scene. The 33 shots cover exactly the
Phase 3 HUD code where such errors would be easy to introduce.
**Fix:** Capture each run's output and apply the same filter the other two wrappers use:
```bash
shot_log="${DUSKHOLD_ROOT}/build/screenshot-${shot}.log"
${wrapper[@]+"${wrapper[@]}"} timeout "${RUN_TIMEOUT_S}" "${GODOT_BIN}" ... 2>&1 | tee "${shot_log}"
status="${PIPESTATUS[0]}"
if grep -hE 'SCRIPT ERROR|Parse Error|Failed to load script' "${shot_log}" | grep -v 'addons/gut' | grep -q .; then
  echo "FAIL: script errors while capturing ${shot}" >&2
  fail=1
  continue
fi
```
Add `build/screenshot-*.log` to the uploaded artifact paths in `ci.yml`.

### WR-03: A refused squad order is silent; nothing in the player-facing code reports it

**File:** `input/selection_controller.gd:279-281`, `input/pad_cursor_controller.gd:113`, `simulation/commands/command_processor.gd:135-136, 190-195`
**Issue:** The gate returns `QUEUE_CLOSED`, `TOO_MANY_POINTS`, `BAD_POINT` and the other reasons and
emits `command_rejected`, but `SelectionController._order` and `PadCursorController._confirm` drop the
returned reason, and no node under `input/`, `presentation/` or `ui/` connects `command_rejected` (a
search finds no consumer). One reachable case: hold Shift, collect a patrol with P and the right mouse
button, release P (the patrol waits in the queue behind the running walk and is drawn as a numbered
disc), then Shift + right click a move. `_queue_is_closed` refuses it and the player sees no toast and no
ping, with the patrol disc on the ground suggesting the queue is open. The refusal is also all-or-nothing
for the selection: with one closed squad and one open squad selected, the queued order is refused for
both (`_queue_is_closed` returns true if any squad is closed), so the per-squad skip at
`squad_system.gd:240-245` is never reached through the gate. UI-SPEC defines no copy for this case, so
this is a spec gap that the implementation inherits.
**Fix:** Have the two controllers read the result of `submit` and emit `feedback` for the player-visible
reasons (a short error toast for `QUEUE_CLOSED`, for example "Nothing can be queued after Hold, Follow
or Patrol"), and have `_queue_is_closed` look only at the squads that are closed instead of refusing the
whole order. Add the copy to UI-SPEC and to `Toast`'s constants.

## Info

### IN-01: Patrol leg budget is assigned and immediately overwritten

**File:** `simulation/squads/squad_system.gd:368` and `:339-340`
**Issue:** `_begin` sets `squad.moving_ticks_left = _walk_budget_ticks(squad)` for a patrol, but the only
caller, `_run_queue`, pops the non-walk head and then, with the queue empty, runs
`squad.moving_ticks_left = 0`. The assignment never takes effect. The first `_advance_patrol` therefore
finds `moving_ticks_left <= 0`, ends leg 0 at once and moves the anchor to the first waypoint, even if
units are engaged. The visible behaviour is acceptable (leg 0 runs from the centroid to the centroid, and
`test_squad_patrol` pins the resulting sequence), but the line reads as a budget for leg 0 and is dead.
**Fix:** Delete line 368, or set the first budget explicitly after `_run_queue` and make it leave a
patrol's counters alone.

### IN-02: The ground-bounds rule exists twice

**File:** `simulation/commands/command_processor.gd:179-185` and `input/ground_pick.gd:22-28`
**Issue:** Both compute `roundi(minf(extent, MapConfig.MAX_GROUND_HALF_EXTENT) * 100.0)` and both treat a
non-finite or non-positive extent as "bounds nothing". The input-side copy exists so the toast never
shows a point the gate would refuse, so a change to the rule in one place silently desynchronises the
toast from the gate.
**Fix:** Move the centimetre limit into one static helper on `MapConfig` (`ground_limit_cm(extent)`) and
call it from both.

### IN-03: `UnitSystem.separate` and `EnemySystem._separate` are the same 35 lines

**File:** `simulation/squads/unit_system.gd:168-203`, `simulation/night/enemy_system.gd:349-384`
**Issue:** The push-apart pass is duplicated except for the record type. A determinism-sensitive routine
that must stay byte-identical in two places is a drift hazard (the goldens would catch a divergence only
after the fact).
**Fix:** Extract one static function over positions, radii and ids that returns the displacements, and
have both systems apply them.

### IN-04: Test-only accessors on production classes

**File:** `simulation/squads/squad_system.gd:132` (`anchor_of`), `simulation/squads/unit_system.gd:76` (`squad_of`)
**Issue:** Neither has a caller outside `tests/`. `SquadSystem` sits at 19 of the 20 public methods the
lint allows, so each unused one spends headroom that Phase 4 will want.
**Fix:** Keep them if the tests need them, but say "test hook" in the doc comment (as the controllers
do), or move the read into a test helper.

### IN-05: Unused `ext_resource` entries in three building scenes

**File:** `presentation/buildings/models/barracks_t1.tscn:5`, `barracks_t2.tscn:5` (`tower-square-base.glb`, id `2_base`), `archery_range_t1.tscn:5` (`wall-door.glb`, id `2_door`)
**Issue:** The resources are declared and counted in `load_steps` but no node instances them in these
tiers. They make the scene load the GLB for nothing, and Godot drops them the next time the scene is
saved in the editor, producing a spurious diff.
**Fix:** Remove the three lines and lower `load_steps` by one in each file.

### IN-06: The eighth patrol click is dropped without a word

**File:** `input/selection_controller.gd:259-262`
**Issue:** While patrol is armed, a right click past `MAX_PATROL_POINTS - 1` (7) points is ignored with no
feedback, no ping and no disc, although the gate has a `TOO_MANY_POINTS` reason for it. The player cannot
tell whether the click missed or the limit was hit.
**Fix:** Emit `feedback` with a one-line error when the cap is reached ("A patrol takes up to 7 points"),
and add the copy to UI-SPEC.

---

_Reviewed: 2026-10-12T08:56:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
