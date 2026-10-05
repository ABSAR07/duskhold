class_name NightOverlaySections
extends RefCounted
## RED-phase shell: the real sections replace this in the GREEN commit.

const WAVE_TITLE := "Wave"
const KING_TITLE := "King"
const PATHS_TITLE := "Paths"


static func register(_overlay: DebugOverlay, _ctx: RunContext, _map_root: MapRoot) -> void:
	pass


static func wave_rows(_ctx: RunContext) -> Array:
	return []


static func king_rows(_ctx: RunContext) -> Array:
	return []


static func path_rows(_ctx: RunContext) -> Array:
	return []
