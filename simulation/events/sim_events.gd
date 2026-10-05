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
## Dawn income was paid. `per_spot` maps spot_id to amount in MapConfig order, amount > 0 only.
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
