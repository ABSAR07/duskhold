class_name DebugOverlay
extends CanvasLayer
## Toggleable debug overlay (DEV-03): press toggle_debug_overlay (F3 / gamepad Back) to show or
## hide it. It is hidden by default and strictly read-only; every row comes from
## DebugOverlayModel, which only calls simulation getters. In Phase 1 it ships in every build,
## including release exports (threat T-01-15, accepted: it cannot change gameplay).

const TOGGLE_ACTION := &"toggle_debug_overlay"
const REFRESH_INTERVAL_S: float = 0.25
const REBIND_IGNORED_WARNING := "debug overlay bind_run ignored: already bound to another run"
const NO_CONTEXT_WARNING := "debug overlay bind_run ignored: no RunContext"

var _model: DebugOverlayModel
var _ctx: RunContext
var _since_refresh: float = 0.0
## Sections registered before bind_run, as {title, provider, owner: WeakRef or null}. Bind order
## across the run_bound group is not guaranteed, so a caller may register first; bind_run replays
## these in order, so registration never depends on who is bound first.
var _pending: Array[Dictionary] = []

@onready var _text: Label = %OverlayText


## Builds the model once. A repeat call is ignored (as in Hud.bind_run): a second model would
## discard every section registered so far. The overlay belongs to one run: MapRoot binds it once
## with its own RunContext, and it is recreated with the map, never rebound. A repeat call with a
## different context is therefore a caller mistake; it is named, because the overlay would go on
## reading the first run's phase, gold and counts without saying so.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	# Refused before _model is set, so the overlay stays unbound and a later valid bind still works.
	if ctx == null:
		push_warning(NO_CONTEXT_WARNING)
		return
	if _model != null:
		if ctx != _ctx:
			push_warning(REBIND_IGNORED_WARNING)
		return
	_ctx = ctx
	_model = DebugOverlayModel.new(ctx)
	for entry: Dictionary in _pending:
		var owner_weak: WeakRef = entry["owner"]
		var lifetime_owner: Object = owner_weak.get_ref() if owner_weak != null else null
		if owner_weak != null and lifetime_owner == null:
			DebugOverlayModel.warn_not_registered(
				entry["title"], DebugOverlayModel.OWNER_FREED_REASON + " before bind_run"
			)
			continue
		_model.register_section(entry["title"], entry["provider"], lifetime_owner)
	_pending.clear()


## Phase 2 and later add sections (wave state, enemy paths) through this, not by editing the model.
## Safe to call before bind_run: the section is held and added when the overlay is bound.
## Pass `lifetime_owner` when the provider reads an object that can be freed before the overlay (see
## DebugOverlayModel.register_section, which also says why `lifetime_owner` is a Variant and must be
## alive at registration, and why it only ends the section of an owner freed explicitly, such as a
## Node, not of a RefCounted that the provider captures).
func register_section(title: String, provider: Callable, lifetime_owner: Variant = null) -> void:
	if _model == null:
		# The same checks, in the same order, as DebugOverlayModel.register_section, so a mistake is
		# refused when it is made, not later at bind_run (or never, if the overlay is never bound).
		var problem: String = DebugOverlayModel.title_problem(title)
		if problem == "":
			problem = DebugOverlayModel.owner_problem(lifetime_owner)
		if problem != "":
			DebugOverlayModel.warn_not_registered(title, problem)
			return
		# A WeakRef, like the model's, so the pending entry's own reference never keeps its owner
		# alive. The stored provider still holds whatever it captured (see register_section).
		_pending.append(
			{
				"title": title,
				"provider": provider,
				"owner": DebugOverlayModel.owner_ref(lifetime_owner)
			}
		)
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
