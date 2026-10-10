class_name LastDeviceTracker
extends Node
## Inert skeleton, replaced by the real tracker in the GREEN step of plan 03-10.

signal device_changed(device: int)

var time_source: Callable = _real_seconds


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass


func device() -> int:
	return GlyphResolver.DEVICE_KEYBOARD


func cursor_hidden() -> bool:
	return false


func _real_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
