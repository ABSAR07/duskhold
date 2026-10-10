class_name SelectionController
extends Node
## Mouse selection of squads (D-10, D-11, UNIT-09). A left press and release within CLICK_SLOP_PX of
## each other is a click: within CLICK_RADIUS_PX of a unit it selects that unit's squad (Ctrl adds
## or removes it, a double-click selects every squad of the same unit type); on empty ground it
## clears the selection (Ctrl keeps it). The mouse never builds, upgrades, starts the night or
## aims the king, and a selection never reaches the simulation: an order carries explicit ids.
##
## Pointer input is event-driven and lives in _unhandled_input, so a HUD control set to STOP (the
## squad slots) swallows the click before it gets here (Pitfall 8). Plan 03-08 adds the drag box
## beyond CLICK_SLOP_PX.

## Text for the HUD toast; declared for later plans, nothing here reports yet.
signal feedback(text: String, is_error: bool)

## Pixels around a unit's projected ground point that count as a hit (UI-SPEC click select).
const CLICK_RADIUS_PX := 32.0
## A release farther than this from the press is not a click.
const CLICK_SLOP_PX: float = 8.0

var _ctx: RunContext
var _selection: SelectionModel
var _views: UnitViews
var _pressing: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _press_ctrl: bool = false
var _press_double: bool = false


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()
	_views = map_root.get_node_or_null("UnitViews") as UnitViews


func _unhandled_input(event: InputEvent) -> void:
	if _ctx == null or _selection == null:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_pressing = true
		_press_position = button.position
		_press_ctrl = button.ctrl_pressed
		_press_double = button.double_click
		get_viewport().set_input_as_handled()
		return
	if not _pressing:
		return
	_pressing = false
	get_viewport().set_input_as_handled()
	if button.position.distance_to(_press_position) <= CLICK_SLOP_PX:
		_click(button.position)


## Applies a click at `position` (viewport pixels) using the modifiers of its press.
func _click(position: Vector2) -> void:
	var all_ids: Array[StringName] = _ctx.squads.squad_ids()
	var hit: StringName = SelectionMath.nearest_squad_at(
		_unit_points(all_ids), position, CLICK_RADIUS_PX
	)
	if hit == &"":
		if not _press_ctrl:
			_selection.clear()
		return
	if _press_ctrl:
		_selection.toggle(hit, all_ids)
	elif _press_double:
		_selection.select_same_type(hit, all_ids, _unit_type_of)
	else:
		_selection.select_only([hit] as Array[StringName], all_ids)


## Screen points of every shown unit, keyed by squad id in creation order.
func _unit_points(all_ids: Array[StringName]) -> Dictionary:
	var by_squad: Dictionary = {}
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or _views == null:
		return by_squad
	for squad_id: StringName in all_ids:
		var points: PackedVector2Array = PackedVector2Array()
		for unit_id: int in _ctx.squads.unit_ids_of(squad_id):
			if _views.get_view(unit_id) == null:
				continue
			var ground: Vector3 = _views.puppet_position(unit_id)
			if camera.is_position_behind(ground):
				continue
			points.append(camera.unproject_position(ground))
		by_squad[squad_id] = points
	return by_squad


## The unit type id of a squad, the key of "select every squad of this type".
func _unit_type_of(squad_id: StringName) -> StringName:
	var def: UnitDef = _ctx.squads.unit_def_of(squad_id)
	return def.id if def != null else &""
