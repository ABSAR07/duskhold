class_name SimRecorder
extends RefCounted
## Canonical event log of a run and its sha256 digest (DEV-05). One explicit handler per SimEvents
## signal, each appending "<tick> <signal_name> <args>". Only integers, ids and names are written:
## positions are quantized with roundi(x * 100.0), so no raw float reaches the digest and the log
## is the same on every machine that runs the same engine build. Attach it before the first step
## (DR-11) so the line order equals the emission order.
## Every later plan that adds a SimEvents signal adds its handler and its HANDLED entry in the same
## task; test_determinism.gd fails when one is missing. tools/ is excluded from the export.

## Every signal this recorder handles. Compared with SimEvents and SimSignals by a drift test.
const HANDLED: Array[String] = [
	"gold_changed",
	"building_built",
	"command_rejected",
	"phase_changed",
	"night_started",
	"dawn_payout",
	"day_started",
	"enemy_spawned",
	"enemy_damaged",
	"enemy_died",
	"attack_fired",
	"castle_damaged",
	"castle_destroyed",
	"building_damaged",
	"building_destroyed",
	"king_damaged",
	"king_downed",
	"king_respawned",
]
## Written in place of an empty id so every token is non-empty.
const EMPTY_TOKEN := "-"
const POSITION_SCALE: float = 100.0

var _ctx: RunContext
var _lines: PackedStringArray = PackedStringArray()


## Starts recording `ctx`'s events. Call before the first step.
static func attach(ctx: RunContext) -> SimRecorder:
	var recorder: SimRecorder = SimRecorder.new()
	recorder._ctx = ctx
	var events: SimEvents = ctx.events
	events.gold_changed.connect(recorder._on_gold_changed)
	events.building_built.connect(recorder._on_building_built)
	events.command_rejected.connect(recorder._on_command_rejected)
	events.phase_changed.connect(recorder._on_phase_changed)
	events.night_started.connect(recorder._on_night_started)
	events.dawn_payout.connect(recorder._on_dawn_payout)
	events.day_started.connect(recorder._on_day_started)
	events.enemy_spawned.connect(recorder._on_enemy_spawned)
	events.enemy_damaged.connect(recorder._on_enemy_damaged)
	events.enemy_died.connect(recorder._on_enemy_died)
	events.attack_fired.connect(recorder._on_attack_fired)
	events.castle_damaged.connect(recorder._on_castle_damaged)
	events.castle_destroyed.connect(recorder._on_castle_destroyed)
	events.building_damaged.connect(recorder._on_building_damaged)
	events.building_destroyed.connect(recorder._on_building_destroyed)
	events.king_damaged.connect(recorder._on_king_damaged)
	events.king_downed.connect(recorder._on_king_downed)
	events.king_respawned.connect(recorder._on_king_respawned)
	return recorder


## The recorded lines, in emission order. A copy.
func lines() -> PackedStringArray:
	return _lines.duplicate()


## Appends the final state of the run: tick, phase, gold, enemies alive, day and night number.
func append_final_state(ctx: RunContext) -> void:
	_record(
		"final",
		[
			ctx.run_manager.get_phase(),
			ctx.economy.get_gold(),
			ctx.get_enemy_count(),
			ctx.run_manager.get_day_number(),
			ctx.run_manager.get_night_number(),
		]
	)


## sha256 of the log, lines joined by newlines.
func digest() -> String:
	return "\n".join(_lines).sha256_text()


func _record(event_name: String, tokens: Array) -> void:
	var parts: PackedStringArray = PackedStringArray([str(_ctx.tick_count), event_name])
	for token: Variant in tokens:
		var text: String = _token(token)
		if not text.is_empty():
			parts.append(text)
	_lines.append(" ".join(parts))


## One log token. Ints and StringNames, booleans as 0/1, and a Vector2 as two quantized ints; a
## Dictionary becomes key=value tokens in insertion order (nothing when empty). A raw float is
## never formatted.
func _token(value: Variant) -> String:
	if value is Vector2:
		var pos: Vector2 = value
		return "%d %d" % [roundi(pos.x * POSITION_SCALE), roundi(pos.y * POSITION_SCALE)]
	if value is Dictionary:
		var pairs: PackedStringArray = PackedStringArray()
		var table: Dictionary = value
		for key: Variant in table.keys():
			pairs.append("%s=%d" % [str(key), int(table[key])])
		return " ".join(pairs)
	if value is bool:
		return "1" if value else "0"
	if value is StringName:
		var text: String = String(value)
		return text if not text.is_empty() else EMPTY_TOKEN
	return str(int(value))


func _on_gold_changed(new_amount: int, delta: int) -> void:
	_record("gold_changed", [new_amount, delta])


func _on_building_built(spot_id: StringName, building_id: StringName, new_tier: int) -> void:
	_record("building_built", [spot_id, building_id, new_tier])


func _on_command_rejected(command: StringName, spot_id: StringName, reason: StringName) -> void:
	_record("command_rejected", [command, spot_id, reason])


func _on_phase_changed(old_phase: int, new_phase: int) -> void:
	_record("phase_changed", [old_phase, new_phase])


func _on_night_started(night_number: int) -> void:
	_record("night_started", [night_number])


func _on_dawn_payout(total: int, per_spot: Dictionary) -> void:
	_record("dawn_payout", [total, per_spot])


func _on_day_started(day_number: int) -> void:
	_record("day_started", [day_number])


func _on_enemy_spawned(enemy_id: int, def_id: StringName, pos: Vector2) -> void:
	_record("enemy_spawned", [enemy_id, def_id, pos])


func _on_enemy_damaged(enemy_id: int, amount: int, hp: int) -> void:
	_record("enemy_damaged", [enemy_id, amount, hp])


func _on_enemy_died(
	enemy_id: int, def_id: StringName, pos: Vector2, killer_kind: StringName
) -> void:
	_record("enemy_died", [enemy_id, def_id, pos, killer_kind])


func _on_attack_fired(
	attacker_kind: StringName,
	attacker_id: int,
	target_kind: StringName,
	target_id: int,
	flight_ticks: int
) -> void:
	_record("attack_fired", [attacker_kind, attacker_id, target_kind, target_id, flight_ticks])


func _on_castle_damaged(amount: int, hp: int, max_hp: int) -> void:
	_record("castle_damaged", [amount, hp, max_hp])


func _on_castle_destroyed() -> void:
	_record("castle_destroyed", [])


func _on_building_damaged(spot_id: StringName, amount: int, hp: int, max_hp: int) -> void:
	_record("building_damaged", [spot_id, amount, hp, max_hp])


func _on_building_destroyed(spot_id: StringName, building_id: StringName, tier: int) -> void:
	_record("building_destroyed", [spot_id, building_id, tier])


func _on_king_damaged(amount: int, hp: int, max_hp: int) -> void:
	_record("king_damaged", [amount, hp, max_hp])


func _on_king_downed(respawn_ticks: int, knockout_number: int) -> void:
	_record("king_downed", [respawn_ticks, knockout_number])


func _on_king_respawned() -> void:
	_record("king_respawned", [])
