class_name OrderMarkers
extends Node3D
## Pings the ground where a move, attack-move or rally order lands (UI-SPEC "Move", "Attack-move").
## Display only.

## Most pings alive at once.
const MAX_PINGS: int = 16


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


## Pings showing right now. Test hook, read-only.
func active_ping_count() -> int:
	return 0
