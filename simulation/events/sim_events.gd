class_name SimEvents
extends RefCounted
## Per-run event bus. Owned by RunContext (not a global), so each headless test has its own.
## Presentation subscribes through bind_run; the simulation never listens to presentation.

## Emitted after every successful gold change. `delta` is signed.
signal gold_changed(new_amount: int, delta: int)
## `new_tier` 1 means constructed, greater than 1 means upgraded.
signal building_built(spot_id: StringName, building_id: StringName, new_tier: int)
## A command was refused; `reason` is one of the CommandProcessor reason constants.
signal command_rejected(command: StringName, spot_id: StringName, reason: StringName)
## Values are RunManager.RunPhase integers.
signal phase_changed(old_phase: int, new_phase: int)
## The night began (after NIGHT_TRANSITION); `night_number` is 1 for the first night.
signal night_started(night_number: int)
## Dawn income was paid. `per_spot` maps spot_id to amount in MapConfig order, amount > 0 only, then
## MapConfig.CASTLE_PAYOUT_KEY for the castle's base income when the map pays one (listed last).
signal dawn_payout(total: int, per_spot: Dictionary)
## A new day began; `day_number` is 2 for the first day after a night.
signal day_started(day_number: int)
## An enemy of the night appeared at its spawn point.
signal enemy_spawned(enemy_id: int, def_id: StringName, pos: Vector2)
## An enemy lost `amount` hit points and has `hp` left.
signal enemy_damaged(enemy_id: int, amount: int, hp: int)
## An enemy died and was removed; `killer_kind` is the attacker kind that landed the last hit.
signal enemy_died(enemy_id: int, def_id: StringName, pos: Vector2, killer_kind: StringName)
## An attacker started an attack; `flight_ticks` is 0 for a hit that lands this tick.
signal attack_fired(
	attacker_kind: StringName,
	attacker_id: int,
	target_kind: StringName,
	target_id: int,
	flight_ticks: int
)
## The castle lost `amount` hit points and has `hp` of `max_hp` left.
signal castle_damaged(amount: int, hp: int, max_hp: int)
## The castle fell to 0 hit points. Emitted exactly once.
signal castle_destroyed
## A building lost `amount` hit points and has `hp` of `max_hp` left.
signal building_damaged(spot_id: StringName, amount: int, hp: int, max_hp: int)
## A building fell to 0 hit points and stays down until dawn. Emitted exactly once per destruction.
signal building_destroyed(spot_id: StringName, building_id: StringName, tier: int)
## Dawn rebuilt the buildings that fell in the night, listed in MapConfig order (empty when nothing
## fell). Emitted once per dawn, after the repairs and before the payout.
signal buildings_rebuilt(spot_ids: Array)
## A wall segment lost `amount` hit points (the points actually lost) and has `hp` of `max_hp`
## left. `segment` is the global segment index; `spot_id` is the wall plot that owns it.
signal wall_damaged(spot_id: StringName, segment: int, amount: int, hp: int, max_hp: int)
## A wall segment fell to 0 hit points and is a hole open to everyone until dawn. Emitted exactly
## once per break.
signal wall_segment_broken(spot_id: StringName, segment: int)
## Dawn healed and rebuilt the wall runs that were hurt or broken, listed in MapConfig order (never
## emitted empty). Emitted once per dawn, after the repairs and before the buildings_rebuilt.
signal walls_restored(spot_ids: Array[StringName])
## The run ended: `outcome` is &"victory" (the last night was cleared) or &"defeat" (the castle
## fell). Emitted exactly once per run; nothing is emitted after it.
signal run_ended(outcome: StringName)
## The king lost `amount` hit points and has `hp` of `max_hp` left.
signal king_damaged(amount: int, hp: int, max_hp: int)
## The king's health reached 0: he is out of the fight for `respawn_ticks` ticks.
## `knockout_number` counts the knockouts of this night, starting at 1.
signal king_downed(respawn_ticks: int, knockout_number: int)
## The king is back at the castle with full health (the countdown ended, or dawn came).
signal king_respawned
## A friendly unit was raised in squad `squad_id` (the military spot id) at `pos`.
signal unit_spawned(unit_id: int, squad_id: StringName, def_id: StringName, pos: Vector2)
## A unit lost `amount` hit points and has `hp` left.
signal unit_damaged(unit_id: int, amount: int, hp: int)
## A unit died and was removed; `killer_kind` is the attacker kind that landed the last hit.
signal unit_died(unit_id: int, squad_id: StringName, pos: Vector2, killer_kind: StringName)
## Dawn made squad `squad_id` whole again: every survivor is back at full health and every missing
## seat is filled, so the squad has `alive` units. Emitted once per squad per dawn, after the
## rebuild and before the payout.
signal squad_restored(squad_id: StringName, alive: int)
## The king used his weapon's slam and it struck `hit_count` enemies (0 by day).
signal king_ability_used(hit_count: int)
## The king regenerated `amount` points (D-20) and now has `hp` of `max_hp`. Emitted only on a step
## where his whole-point health changed.
signal king_healed(amount: int, hp: int, max_hp: int)
## A squad order was accepted for squad `squad_id` (D-09). `verb` is a SquadOrder VERB_ name and
## `queued` says whether it was added to the squad queue instead of replacing it. `points` are the
## metres (Vector2) the simulation resolved for the verb: none for follow, the frozen anchor for
## hold, the king position for rally. The recorder quantises them like every other position.
signal squad_ordered(squad_id: StringName, verb: StringName, queued: bool, points: Array)
## A building tier with cards was bought with the card `choice_id` (BLDG-05). Emitted right after
## the building_built of the same purchase; the pick lasts the run.
signal choice_picked(spot_id: StringName, tier: int, choice_id: StringName)
## A Fishing Harbor gained a boat at dawn and now has `boats` (ECON-05). Emitted only when the
## count changes, never for a Harbor at its cap, a fallen one or one rebuilt this dawn; the boat
## views follow it and the replay digest records it.
signal harbor_boats_changed(spot_id: StringName, boats: int)
## A Shrine woke for good (ECON-06, D-12): the enemies that died within its wake radius reached its
## threshold. Emitted once per Shrine per run, never when it falls, and never again afterwards; the
## glow follows it and the replay digest records it.
signal shrine_woke(spot_id: StringName)
