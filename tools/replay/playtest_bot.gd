class_name PlaytestBot
extends RefCounted
## RED stub: replaced by the real bot in the GREEN commit.

const KING_IDLE_AT_CASTLE := &"idle_at_castle"
const KING_HOLD_POINT := &"hold_point"

var build_order: Array[StringName] = []
var king_mode: StringName = KING_IDLE_AT_CASTLE
var hold_point: Vector2 = Vector2.ZERO
var start_nights: bool = true


func think(_ctx: RunContext) -> void:
	pass
