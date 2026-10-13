class_name CommandKeyController
extends Node
## Polled squad commands from the keyboard and the gamepad (D-12, D-15, INPT-01, INPT-02), and the
## control group digits (D-10): Ctrl + 1..9 / 0 stores the selection, the bare digit recalls it. F,
## H and R give the selection a follow, hold or rally order through the one command gate; Tab
## selects the next squad in creation order and F2 selects them all. A verb with nothing selected
## issues no order and reports "Select a squad first" through `feedback`, which the HUD toast shows.
## Holding the queue key (Shift on the keyboard, RT on the pad) while pressing F, H or R appends the
## verb behind the selection's queued walks instead of replacing them, so "move here, then hold" is
## one gesture (D-09); the key is read at the moment of the press, as the pointer and pad cursor
## read it. Without it the verb replaces the queue; a verb behind a terminal order is refused by
## the command gate and the refusal is shown as a toast.
##
## The point-command keys are polled here too and handed to the SelectionController, which owns
## the pointer: the attack-move key arms attack-move (it does nothing with nothing selected, since
## A is also the king movement key move_left), the patrol key going down and up opens and commits
## a patrol, and the cancel key cancels an armed command or clears the selection. None of them
## moves the king or touches move_left.
##
## The gamepad shares its D-pad buttons between a bare verb and the point verb of the LB layer, so
## one D-pad press makes two actions just-pressed together. PadChords resolves that pair from the LB
## layer and the Start group mode before anything acts; a lone action is a keyboard key and keeps
## its meaning whatever the pad is holding. A pad press of a point verb (move, attack-move, patrol)
## is handed to the PadCursorController through `pad_point_verb`. Holding Start is the group mode:
## D-pad left / right steps the group number 1..9, 0 on the selected squad's badge, D-pad up recalls
## the shown group, and releasing Start stores the selection in it.
##
## The presses are read in _process from Input.is_action_just_pressed with a per-action fallback on
## the action level: a scripted Input.action_press makes no input event, so the fallback keeps
## replays and tests working (Pitfall 6). A held key is one press, never a stream.

## Something to tell the player: `is_error` picks the 1.5 s error hold over the 1.2 s toast.
signal feedback(text: String, is_error: bool)
## A pad press resolved to a point verb (move, attack-move or patrol) that needs a ground point; the
## PadCursorController aims it. `action` is the held Input Map action whose release confirms it.
signal pad_point_verb(verb: StringName, action: StringName)

## Action to the order verb it gives the selection.
const VERB_ACTIONS: Dictionary = {
	&"squad_follow": SquadOrder.VERB_FOLLOW,
	&"squad_hold": SquadOrder.VERB_HOLD,
	&"squad_rally": SquadOrder.VERB_RALLY,
}
## The point verbs: the action that starts each to the order verb it gives.
const POINT_ACTIONS: Dictionary = {
	&"squad_move": SquadOrder.VERB_MOVE,
	&"squad_attack_move": SquadOrder.VERB_ATTACK_MOVE,
	&"squad_patrol": SquadOrder.VERB_PATROL,
}
const CYCLE_ACTION: StringName = &"squad_cycle"
const SELECT_ALL_ACTION: StringName = &"select_all"
const SELECT_TYPE_ACTION: StringName = &"select_type"
const ATTACK_MOVE_ACTION: StringName = &"squad_attack_move"
const PATROL_ACTION: StringName = &"squad_patrol"
const CANCEL_ACTION: StringName = &"command_cancel"
const QUEUE_ACTION: StringName = &"command_queue"
## The LB layer and the Start group mode of the gamepad.
const LAYER_ACTION: StringName = &"command_layer"
const GROUP_MODE_ACTION: StringName = &"group_mode"
## Every action whose press PadChords resolves, the twins included.
const CHORD_ACTIONS: Array[StringName] = [
	&"squad_follow",
	&"squad_hold",
	&"squad_rally",
	&"squad_cycle",
	&"select_all",
	&"select_type",
	&"squad_move",
	&"squad_attack_move",
	&"squad_patrol",
]
## Control-group digit actions to the group they address; key 0 is group 10.
const GROUP_ACTIONS: Dictionary = {
	&"group_1": 1,
	&"group_2": 2,
	&"group_3": 3,
	&"group_4": 4,
	&"group_5": 5,
	&"group_6": 6,
	&"group_7": 7,
	&"group_8": 8,
	&"group_9": 9,
	&"group_0": 10,
}
const MODIFIER_ACTION: StringName = &"selection_modifier"

var _ctx: RunContext
var _selection: SelectionModel
var _pointer: SelectionController
var _strip: SquadStrip
var _cursor: PadCursorController
var _was_pressed: Dictionary = {}
## True from the keyboard patrol key going down until it comes up again.
var _patrol_key_held: bool = false
var _group_mode_was_held: bool = false
## The group the pad group mode is showing, as an index 0..9 (group 1..10); -1 before any step.
var _edit_index: int = -1
var _edit_squad: StringName = &""


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()
	_pointer = map_root.get_node_or_null("SelectionController") as SelectionController
	_strip = map_root.find_child("SquadStrip", true, false) as SquadStrip
	_cursor = map_root.get_node_or_null("PadCursorController") as PadCursorController


func _process(_delta: float) -> void:
	if _ctx == null or _selection == null:
		return
	var just: Array[StringName] = _just_pressed()
	var group_mode: bool = Input.is_action_pressed(GROUP_MODE_ACTION)
	if group_mode:
		_group_mode_presses(just)
	elif _group_mode_was_held:
		_group_mode_released()
	_group_mode_was_held = group_mode
	var layer: bool = Input.is_action_pressed(LAYER_ACTION)
	for action: StringName in PadChords.resolve(just, layer, group_mode):
		_run(action, just)
	_poll_patrol_release()
	if _pressed_now(CANCEL_ACTION):
		_cancel()
	for action: StringName in GROUP_ACTIONS:
		if _pressed_now(action):
			_group_key(GROUP_ACTIONS[action])


## The chord actions that went down this frame, whether the engine reports the edge or the level.
func _just_pressed() -> Array[StringName]:
	var just: Array[StringName] = []
	for action: StringName in CHORD_ACTIONS:
		if _pressed_now(action):
			just.append(action)
	return just


## Acts on one resolved command. `just` tells a pad press from a keyboard key for the point verbs.
func _run(action: StringName, just: Array[StringName]) -> void:
	if VERB_ACTIONS.has(action):
		_give(VERB_ACTIONS[action])
	elif action == CYCLE_ACTION:
		_selection.cycle_next(_ctx.squads.squad_ids())
	elif action == SELECT_ALL_ACTION:
		_selection.select_all(_ctx.squads.squad_ids())
	elif action == SELECT_TYPE_ACTION:
		_select_type()
	elif POINT_ACTIONS.has(action):
		_point_command(action, just)


## A point verb: a pad press is aimed with the ground cursor; the attack-move and patrol keys go to
## the pointer controller; the right mouse button is handled by the pointer through its events.
func _point_command(action: StringName, just: Array[StringName]) -> void:
	if PadChords.is_pad_press(action, just):
		pad_point_verb.emit(POINT_ACTIONS[action], action)
	elif _pointer == null:
		return
	elif action == ATTACK_MOVE_ACTION:
		_pointer.arm_attack_move()
	elif action == PATROL_ACTION:
		_patrol_key_held = true
		_pointer.begin_patrol()


## The cancel key: it puts the pad's ground cursor away if that is up, else cancels an armed point
## command or clears the selection through the pointer controller.
func _cancel() -> void:
	if _cursor != null and _cursor.cancel():
		return
	if _pointer != null:
		_pointer.escape()


## The patrol key going up commits the points collected with it held.
func _poll_patrol_release() -> void:
	if _patrol_key_held and not Input.is_action_pressed(PATROL_ACTION):
		_patrol_key_held = false
		if _pointer != null:
			_pointer.commit_patrol()


## True on the frame `action` goes down, whether the engine reports the edge or only the level.
func _pressed_now(action: StringName) -> bool:
	var pressed: bool = Input.is_action_pressed(action)
	var edge: bool = (
		Input.is_action_just_pressed(action)
		or (pressed and not bool(_was_pressed.get(action, false)))
	)
	_was_pressed[action] = pressed
	return edge


## Orders the whole selection; with nothing selected it submits nothing and says so. The queue key
## is read now, at the press, so a held Shift queues the verb behind the walks (D-09).
func _give(verb: StringName) -> void:
	var ids: Array[StringName] = _selection.selected()
	if ids.is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	var no_points: Array[Vector2i] = []
	var reason: StringName = _ctx.commands.submit(
		SquadOrderIntent.new(ids, verb, no_points, Input.is_action_pressed(QUEUE_ACTION))
	)
	var refusal: String = Toast.refusal_text(reason)
	if not refusal.is_empty():
		feedback.emit(refusal, true)


## Select one type: every squad of the type of the squad cycled last (else the first selected).
func _select_type() -> void:
	var ids: Array[StringName] = _selection.selected()
	if ids.is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	var anchor: StringName = _selection.last_cycled()
	if not ids.has(anchor):
		anchor = ids[0]
	_selection.select_same_type(anchor, _ctx.squads.squad_ids(), _unit_type_of)


func _unit_type_of(squad_id: StringName) -> StringName:
	var def: UnitDef = _ctx.squads.unit_def_of(squad_id)
	return def.id if def != null else &""


## A digit went down. With the modifier (Ctrl) held it stores the selection as `group`; bare, it
## recalls the group. The modifier is read here, at the moment of the press, because the engine
## matches a bare-digit action for Ctrl + digit too (Pitfall 5). The toast names the key digit.
func _group_key(group: int) -> void:
	var digit: int = SelectionModel.badge_digit(group)
	if Input.is_action_pressed(MODIFIER_ACTION):
		if _selection.store_group(group):
			feedback.emit(Toast.GROUP_SAVED % digit, false)
		else:
			feedback.emit(Toast.SELECT_FIRST, true)
	elif not _selection.recall_group(group, _ctx.squads.squad_ids()):
		feedback.emit(Toast.GROUP_EMPTY % digit, false)


## The raw D-pad while Start is held: left / right step the group number, up recalls the shown one.
## A pad press is a twin pair; rally (D-pad left) has no twin.
func _group_mode_presses(just: Array[StringName]) -> void:
	if just.has(PadChords.RALLY):
		_edit_step(-1)
	if PadChords.is_pad_press(CYCLE_ACTION, just):
		_edit_step(1)
	if PadChords.is_pad_press(&"squad_follow", just):
		_edit_recall()


## Steps the group number shown on the first selected squad's badge: 1..9 then 0, wrapping. The
## first step from nothing goes to 1 forwards and to 0 backwards.
func _edit_step(direction: int) -> void:
	var ids: Array[StringName] = _selection.selected()
	if ids.is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	if direction > 0:
		_edit_index = (_edit_index + 1) % SelectionModel.GROUP_COUNT
	elif _edit_index <= 0:
		_edit_index = SelectionModel.GROUP_COUNT - 1
	else:
		_edit_index -= 1
	_edit_squad = ids[0]
	if _strip != null:
		_strip.set_group_edit(_edit_squad, SelectionModel.badge_digit(_edit_index + 1))


## Recalls the group being shown; with none shown nothing happens. A recall ends the edit, so
## releasing Start stores nothing more.
func _edit_recall() -> void:
	if _edit_index < 0:
		return
	var group: int = _edit_index + 1
	if _selection.recall_group(group, _ctx.squads.squad_ids()):
		_end_edit()
	else:
		feedback.emit(Toast.GROUP_EMPTY % SelectionModel.badge_digit(group), false)


## Start went up: the group number that was stepped to takes the selection.
func _group_mode_released() -> void:
	var group: int = _edit_index + 1
	var had_step: bool = _edit_index >= 0
	_end_edit()
	if not had_step:
		return
	if _selection.store_group(group):
		feedback.emit(Toast.GROUP_SAVED % SelectionModel.badge_digit(group), false)
	else:
		feedback.emit(Toast.SELECT_FIRST, true)


func _end_edit() -> void:
	if _strip != null and _edit_squad != &"":
		_strip.set_group_edit(_edit_squad, -1)
	_edit_squad = &""
	_edit_index = -1
