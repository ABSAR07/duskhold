class_name SquadOrderIntent
extends RefCounted
## Request to give whole squads a verb (D-09). Carries only ids, a SquadOrder VERB_ name, ground
## points in whole centimetres and the queue flag: never a Vector2, a camera or an input event, so
## nothing a mouse produced reaches the simulation raw (Pattern 6). Like BuildIntent it carries no
## tick: CommandProcessor applies it at submit, between two steps, and re-validates everything.

var squad_ids: Array[StringName] = []
var verb: StringName = &""
## Ground points in centimetres (metres times 100, rounded). Follow, hold and rally take none.
var points: Array[Vector2i] = []
var queued: bool = false


func _init(
	ids: Array[StringName],
	order_verb: StringName,
	cm_points: Array[Vector2i] = [],
	is_queued: bool = false
) -> void:
	squad_ids = ids.duplicate()
	verb = order_verb
	points = cm_points.duplicate()
	queued = is_queued
