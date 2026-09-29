class_name DebugOverlayModel
extends RefCounted
## Read-only view model of the debug overlay (DEV-03).


func _init(_ctx: RunContext) -> void:
	pass


func register_section(_title: String, _provider: Callable) -> void:
	pass


func collect(_fps: float) -> Array:
	return []
