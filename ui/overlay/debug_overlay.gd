class_name DebugOverlay
extends CanvasLayer
## Toggleable debug overlay (DEV-03): press toggle_debug_overlay (F3 / gamepad Back) to show or
## hide it. It is hidden by default and strictly read-only; every row comes from
## DebugOverlayModel, which only calls simulation getters. In Phase 1 it ships in every build,
## including release exports (threat T-01-15, accepted: it cannot change gameplay).

const TOGGLE_ACTION := &"toggle_debug_overlay"
const REFRESH_INTERVAL_S: float = 0.25

var _model: DebugOverlayModel
var _since_refresh: float = 0.0

@onready var _text: Label = %OverlayText


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_model = DebugOverlayModel.new(ctx)


## Phase 2 and later add sections (wave state, enemy paths) through this, not by editing the model.
## Pass `owner` when the provider reads an object that can be freed before the overlay (see
## DebugOverlayModel.register_section).
func register_section(title: String, provider: Callable, owner: Object = null) -> void:
	if _model != null:
		_model.register_section(title, provider, owner)


func is_overlay_visible() -> bool:
	return visible


func get_text() -> String:
	return _text.text


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(TOGGLE_ACTION):
		visible = not visible
		if visible:
			_refresh()
	elif visible:
		_since_refresh += delta
		if _since_refresh >= REFRESH_INTERVAL_S:
			_refresh()


func _refresh() -> void:
	_since_refresh = 0.0
	if _model == null:
		return
	var lines: PackedStringArray = []
	for section: Dictionary in _model.collect(Engine.get_frames_per_second()):
		lines.append(section["title"])
		for row: Array in section["rows"]:
			lines.append("  %s: %s" % [row[0], row[1]])
	_text.text = "\n".join(lines)
