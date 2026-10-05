class_name ProjectileVfx
extends Node3D
## Cosmetic projectiles and the king's slash. RED-phase shell: the behavior lands in the GREEN
## commit.

const MAX_PROJECTILES: int = 128
const ARC_PER_METRE: float = 0.12
const MAX_ARC_HEIGHT: float = 2.5
const SKIRMISHER_COLOR := Color(0.6, 0.3, 0.9)


static func flight_seconds(_flight_ticks: int) -> float:
	return 0.0


static func arc_height(_t: float, _distance: float) -> float:
	return 0.0


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func live_count() -> int:
	return 0


func slash_count() -> int:
	return 0
