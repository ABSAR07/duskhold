class_name PadCursorController
extends Node
## The pad's right-stick ground cursor for the point verbs move, attack-move and patrol (D-12,
## INPT-02, RESEARCH Pattern 6). CommandKeyController resolves a pad press of a point verb (the
## D-pad with the LB layer held) and hands it here through `pad_point_verb`. The cursor starts on
## the king's projected ground point, moves with the right stick at `cursor_speed_px_per_s`, stays
## inside the visible rect by SpawnTelegraph.EDGE_MARGIN_PX, and confirms when the D-pad button is
## let go: the screen point is turned into a ground point by GroundPick, checked against the ground
## of the map, quantised to whole centimetres by GroundPick.to_centimetres, and submitted as one
## SquadOrderIntent for the selected squads (queued while the right trigger is held). A point on no
## ground gives no order and the "Can't go there" toast. B or Escape cancels, through `cancel`, with
## no order. While the cursor is up the camera zoom is suppressed (the right stick is zoom too) and
## the toast slot shows how to aim. A pad patrol takes one point; its path starts where the squad
## stands. Nothing here reaches the simulation but the one intent.

## Text for the HUD toast.
signal feedback(text: String, is_error: bool)
## The persistent line of the hint slot while the cursor is up; "" clears it.
signal prompt(text: String)

## Cursor speed across the screen at full stick, in pixels per second. A presentation constant.
@export var cursor_speed_px_per_s: float = 900.0

var _ctx: RunContext
var _selection: SelectionModel
var _king: King
var _rig: CameraRig
var _view: PadCursorView
var _cursor: GroundCursor = GroundCursor.new()
var _verb: StringName = &""
var _action: StringName = &""


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()
	_king = map_root.get_king()
	_rig = map_root.get_node_or_null("CameraRig") as CameraRig
	_view = map_root.get_node_or_null("PadCursorView") as PadCursorView
	var keys: CommandKeyController = (
		map_root.get_node_or_null("CommandKeyController") as CommandKeyController
	)
	if keys != null:
		keys.pad_point_verb.connect(_on_pad_point_verb)


## True while the cursor is up.
func is_active() -> bool:
	return _cursor.is_active()


## The cursor in viewport pixels. Test hook.
func cursor_position() -> Vector2:
	return _cursor.position()


## Puts the cursor away with no order. True if it was up (the cancel key then does nothing else).
func cancel() -> bool:
	if not _cursor.is_active():
		return false
	_stop()
	return true


func _process(delta: float) -> void:
	if not _cursor.is_active():
		return
	var stick: Vector2 = Input.get_vector(
		&"cursor_left", &"cursor_right", &"cursor_up", &"cursor_down"
	)
	_cursor.move(stick, delta, cursor_speed_px_per_s)
	_cursor.clamp_to(get_viewport().get_visible_rect(), SpawnTelegraph.EDGE_MARGIN_PX)
	_draw_cursor()
	if not Input.is_action_pressed(_action):
		_confirm()


## A pad press of a point verb: start aiming it, unless something is already being aimed.
func _on_pad_point_verb(verb: StringName, action: StringName) -> void:
	if _ctx == null or _cursor.is_active():
		return
	if _selection.selected().is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or _king == null:
		return
	var king: Vector3 = _king.global_position
	_cursor.start(camera.unproject_position(Vector3(king.x, 0.0, king.z)))
	_cursor.clamp_to(get_viewport().get_visible_rect(), SpawnTelegraph.EDGE_MARGIN_PX)
	_verb = verb
	_action = action
	if _rig != null:
		_rig.set_zoom_suppressed(true)
	prompt.emit(Toast.ARMED_PAD)
	_draw_cursor()


## The button was let go: one order at the cursor, or the "Can't go there" toast.
func _confirm() -> void:
	var cm: Variant = _ground_cm(_cursor.position())
	var verb: StringName = _verb
	var queued: bool = Input.is_action_pressed(SelectionController.QUEUE_ACTION)
	_stop()
	if cm == null:
		feedback.emit(Toast.CANT_GO_THERE, true)
		return
	var ids: Array[StringName] = _selection.selected()
	if ids.is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	var points: Array[Vector2i] = [cm as Vector2i]
	var reason: StringName = _ctx.commands.submit(SquadOrderIntent.new(ids, verb, points, queued))
	var refusal: String = Toast.refusal_text(reason)
	if not refusal.is_empty():
		feedback.emit(refusal, true)


## The ground point under `screen` in whole centimetres, or null when the ray misses the ground or
## the point lies outside the ground of the map. The same checks as a mouse click.
func _ground_cm(screen: Vector2) -> Variant:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ground: Variant = GroundPick.ground_point(camera, screen)
	if ground == null:
		return null
	var cm: Vector2i = GroundPick.to_centimetres(ground as Vector3)
	if not GroundPick.in_bounds(cm, _ctx.map.ground_half_extent):
		return null
	return cm


func _draw_cursor() -> void:
	if _view == null or _king == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var ground: Variant = GroundPick.ground_point(camera, _cursor.position())
	if ground == null:
		_view.hide_cursor()
		return
	_view.show_cursor(_king.global_position, ground as Vector3)


func _stop() -> void:
	_cursor.stop()
	_verb = &""
	_action = &""
	if _view != null:
		_view.hide_cursor()
	if _rig != null:
		_rig.set_zoom_suppressed(false)
	prompt.emit("")
