class_name GlyphResolver
extends RefCounted
## Inert skeleton, replaced by the real resolver in the GREEN step of plan 03-10.

const DEVICE_KEYBOARD: int = 0
const DEVICE_PAD: int = 1
const TILE_ROOT := "res://assets/third_party/kenney_input_prompts"
const UNBOUND_TEXT := "(unbound)"


static func first_event(_action: StringName, _device: int) -> InputEvent:
	return null


static func tile_path(_event: InputEvent, _label_resolver: Callable) -> String:
	return ""


static func keycap_text(_event: InputEvent, _label_resolver: Callable) -> String:
	return ""
