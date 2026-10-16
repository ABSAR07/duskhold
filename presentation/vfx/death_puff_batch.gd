class_name DeathPuffBatch
extends CrowdBatch
## RED stub: the real batch lands with the GREEN commit.

const MAX_PUFFS: int = 128


func setup_puffs() -> bool:
	return false


func spawn(_origin: Vector3, _now_s: float, _color: Color = Color.WHITE) -> void:
	pass


func refresh(_now_s: float) -> void:
	pass


func active_count() -> int:
	return 0
