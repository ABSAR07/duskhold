class_name DeviceModel
extends RefCounted
## Inert skeleton, replaced by the real rule in the GREEN step of plan 03-10.

const SWITCH_MIN_INTERVAL_S: float = 0.25
const AXIS_THRESHOLD: float = 0.5
const MOTION_THRESHOLD_PX: float = 8.0


func device() -> int:
	return GlyphResolver.DEVICE_KEYBOARD


func feed(_event: InputEvent, _now_s: float) -> bool:
	return false


func on_pad_disconnected(_now_s: float) -> bool:
	return false
