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
## Sections registered before bind_run, as {title, provider, owner: WeakRef or null}. Bind order
## across the run_bound group is not guaranteed, so a caller may register first; bind_run replays
## these in order, so registration never depends on who is bound first.
var _pending: Array[Dictionary] = []

@onready var _text: Label = %OverlayText


## Builds the model once. A repeat call is ignored (as in Hud.bind_run): a second model would
## discard every section registered so far.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _model != null:
		return
	_model = DebugOverlayModel.new(ctx)
	for entry: Dictionary in _pending:
		var owner_ref: WeakRef = entry["owner"]
		var lifetime_owner: Object = owner_ref.get_ref() if owner_ref != null else null
		if owner_ref != null and lifetime_owner == null:
			push_warning(
				(
					"debug overlay section '%s' not registered: its owner was freed before bind_run"
					% entry["title"]
				)
			)
			continue
		_model.register_section(entry["title"], entry["provider"], lifetime_owner)
	_pending.clear()


## Phase 2 and later add sections (wave state, enemy paths) through this, not by editing the model.
## Safe to call before bind_run: the section is held and added when the overlay is bound.
## Pass `lifetime_owner` when the provider reads an object that can be freed before the overlay (see
## DebugOverlayModel.register_section, which also says why `lifetime_owner` is a Variant and must be
## alive at registration).
func register_section(title: String, provider: Callable, lifetime_owner: Variant = null) -> void:
	if _model == null:
		var has_owner: bool = typeof(lifetime_owner) != TYPE_NIL
		if has_owner and not is_instance_valid(lifetime_owner):
			push_warning("debug overlay section '%s' not registered: its owner was freed" % title)
			return
		# A WeakRef, like the model's, so a pending section never keeps its owner alive.
		var owner_ref: WeakRef = weakref(lifetime_owner) if has_owner else null
		_pending.append({"title": title, "provider": provider, "owner": owner_ref})
		return
	_model.register_section(title, provider, lifetime_owner)


func is_overlay_visible() -> bool:
	return visible


## The overlay's current text, or "" before it has entered the tree (the label is @onready).
func get_text() -> String:
	return _text.text if _text != null else ""


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
