class_name SelectionController
extends Node
## Mouse selection of squads and the mouse point commands (D-10, D-11, D-13, D-25, UNIT-09,
## UNIT-10). A left press and release within CLICK_SLOP_PX of each other is a click: within
## CLICK_RADIUS_PX of a unit it selects that unit's squad (Ctrl adds or removes it, a double-click
## selects every squad of the same unit type); on empty ground it clears the selection (Ctrl keeps
## it). With squads selected a right click on the visible ground orders a move (Shift queues it);
## the attack-move key arms attack-move for the next left click; holding the patrol key and
## right-clicking collects patrol points that commit when the key is released; Escape (or a right
## click) cancels an armed command and, with nothing armed, clears the selection. A ground point
## is the camera ray against the ground plane, quantised once to whole centimetres by GroundPick
## and checked against the ground bounds of the map; the mouse never builds, upgrades, starts the
## night or aims the king, never moves the camera (D-13), and a selection never reaches the
## simulation: an order carries explicit ids and centimetre points.
##
## Pointer input is event-driven and lives in _unhandled_input, so a HUD control set to STOP (the
## squad slots) swallows the click before it gets here (Pitfall 8). Plan 03-08 adds the drag box
## beyond CLICK_SLOP_PX. The keys that arm and release commands are polled by CommandKeyController,
## which calls arm_attack_move, begin_patrol, commit_patrol and escape here.

## Text for the HUD toast.
signal feedback(text: String, is_error: bool)
## The persistent line of the hint slot while a point command waits for its click; "" clears it.
signal prompt(text: String)

## What a click does next.
enum Armed { NONE, ATTACK_MOVE, PATROL }

## Pixels around a unit's projected ground point that count as a hit (UI-SPEC click select).
const CLICK_RADIUS_PX := 32.0
## Motion farther than this from a press starts a drag box.
const DRAG_THRESHOLD_PX := 8.0
## A release farther than this from the press is not a click.
const CLICK_SLOP_PX: float = DRAG_THRESHOLD_PX

var _ctx: RunContext
var _selection: SelectionModel
var _views: UnitViews
var _armed: Armed = Armed.NONE
var _cursor: Input.CursorShape = Input.CURSOR_ARROW
var _patrol_points: Array[Vector2i] = []
var _pressing: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _press_ctrl: bool = false
var _press_double: bool = false
var _hovered: StringName = &""
var _hover_position: Vector2 = Vector2.ZERO
var _has_hover: bool = false


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()
	_views = map_root.get_node_or_null("UnitViews") as UnitViews
	_selection.changed.connect(_on_selection_changed)


## The unselected squad the mouse is over (within CLICK_RADIUS_PX of one of its units), or &"" when
## none, or while a drag is in progress. Test hook for the hover preview rings.
func hovered_squad() -> StringName:
	if _selection != null and _selection.is_selected(_hovered):
		return &""
	return _hovered


## True while attack-move waits for its click or patrol points are being collected. Test hook.
func is_armed() -> bool:
	return _armed != Armed.NONE


## The cursor shape this controller asked for: a cross while a point command waits, else the arrow.
## Test hook; the headless display keeps no cursor to read back.
func cursor_shape() -> Input.CursorShape:
	return _cursor


## The attack-move key: with a selection, the next left click orders an attack-move there. With
## nothing selected the key is still the king's move_left (D-15, amended 2026-10-10), so it does
## nothing and says nothing.
func arm_attack_move() -> void:
	if _ctx == null or _selection.selected().is_empty():
		return
	_arm(Armed.ATTACK_MOVE, Toast.ARMED_ATTACK)


## The patrol key went down: right clicks now collect patrol points until it is released.
func begin_patrol() -> void:
	if _ctx == null:
		return
	if _selection.selected().is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	_arm(Armed.PATROL, Toast.ARMED_PATROL)


## The patrol key went up: the collected points become one patrol order (queued when the queue key
## is held); with no point collected nothing is ordered.
func commit_patrol() -> void:
	if _armed != Armed.PATROL:
		return
	var points: Array[Vector2i] = _patrol_points.duplicate()
	_disarm()
	if points.is_empty():
		return
	_order(SquadOrder.VERB_PATROL, points)


## Escape: cancels an armed command; with nothing armed it clears the selection, which hands the
## movement keys back to the king (D-15, amended 2026-10-10).
func escape() -> void:
	if _armed != Armed.NONE:
		_disarm()
	elif _selection != null:
		_selection.clear()


func _process(_delta: float) -> void:
	if _has_hover:
		_hovered = _squad_near(_hover_position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_has_hover = false
		_hovered = &""


func _unhandled_input(event: InputEvent) -> void:
	if _ctx == null or _selection == null:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_hover_position = motion.position
		_has_hover = true
		_hovered = _squad_near(_hover_position)
		return
	if event.is_action_pressed(&"squad_move"):
		_right_click(event as InputEventMouseButton)
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_left_button(button)


## The left button: pressed it either lands an armed attack-move or starts a press; released it ends
## the press, and a press and release within CLICK_SLOP_PX of each other is a click.
func _left_button(button: InputEventMouseButton) -> void:
	if button.pressed and _armed == Armed.ATTACK_MOVE:
		get_viewport().set_input_as_handled()
		_attack_move_click(button.position)
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


## A right click on the ground: a move; while attack-move is armed it only cancels; while patrol
## points are being collected it adds a point.
func _right_click(button: InputEventMouseButton) -> void:
	if button == null:
		return
	get_viewport().set_input_as_handled()
	if _armed == Armed.ATTACK_MOVE:
		_disarm()
		return
	if _selection.selected().is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	var cm: Variant = _ground_cm(button.position)
	if cm == null:
		feedback.emit(Toast.CANT_GO_THERE, true)
		return
	if _armed == Armed.PATROL:
		if _patrol_points.size() < SquadOrder.MAX_PATROL_POINTS - 1:
			_patrol_points.append(cm as Vector2i)
		return
	var points: Array[Vector2i] = [cm as Vector2i]
	_order(SquadOrder.VERB_MOVE, points)


## The armed attack-move meets its left click: one order, the selection kept, the command spent.
func _attack_move_click(position: Vector2) -> void:
	var cm: Variant = _ground_cm(position)
	if cm == null:
		feedback.emit(Toast.CANT_GO_THERE, true)
		return
	_disarm()
	var points: Array[Vector2i] = [cm as Vector2i]
	_order(SquadOrder.VERB_ATTACK_MOVE, points)


## Gives the selection `verb` at `points`, queued when the queue key is held as the order is given.
func _order(verb: StringName, points: Array[Vector2i]) -> void:
	var queued: bool = Input.is_action_pressed(&"command_queue")
	_ctx.commands.submit(SquadOrderIntent.new(_selection.selected(), verb, points, queued))


## The ground point under `position` in whole centimetres, or null when the ray misses the ground
## or the point lies outside the ground of the map. Every command point goes through this.
func _ground_cm(position: Vector2) -> Variant:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ground: Variant = GroundPick.ground_point(camera, position)
	if ground == null:
		return null
	var cm: Vector2i = GroundPick.to_centimetres(ground as Vector3)
	if not GroundPick.in_bounds(cm, _ctx.map.ground_half_extent):
		return null
	return cm


func _arm(mode: Armed, line: String) -> void:
	_patrol_points.clear()
	_armed = mode
	_set_cursor(Input.CURSOR_CROSS)
	prompt.emit(line)


func _disarm() -> void:
	_armed = Armed.NONE
	_patrol_points.clear()
	_set_cursor(Input.CURSOR_ARROW)
	prompt.emit("")


func _set_cursor(shape: Input.CursorShape) -> void:
	_cursor = shape
	Input.set_default_cursor_shape(shape)


## Nothing selected means nobody to command: an armed command lapses.
func _on_selection_changed() -> void:
	if _armed != Armed.NONE and _selection.selected().is_empty():
		_disarm()


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


## The unselected squad with a unit within CLICK_RADIUS_PX of `position`, or &"" when none.
func _squad_near(position: Vector2) -> StringName:
	if _ctx == null or _selection == null:
		return &""
	var unselected: Array[StringName] = []
	for squad_id: StringName in _ctx.squads.squad_ids():
		if not _selection.is_selected(squad_id):
			unselected.append(squad_id)
	return SelectionMath.nearest_squad_at(_unit_points(unselected), position, CLICK_RADIUS_PX)


## The unit type id of a squad, the key of "select every squad of this type".
func _unit_type_of(squad_id: StringName) -> StringName:
	var def: UnitDef = _ctx.squads.unit_def_of(squad_id)
	return def.id if def != null else &""
