class_name CommandKeyController
extends Node
## Polled squad commands from the keyboard and the bare D-pad (D-15, INPT-01), and the control
## group digits (D-10): Ctrl + 1..9 / 0 stores the selection, the bare digit recalls it. F, H and R
## give the selection a follow, hold or rally order through the one command gate; Tab selects the
## next squad in creation order and F2 selects them all. A verb with nothing selected issues no
## order and reports "Select a squad first" through `feedback`, which the HUD toast shows.
##
## The point-command keys are polled here too and handed to the SelectionController, which owns
## the pointer: the attack-move key arms attack-move (it does nothing with nothing selected, since
## A is also the king movement key move_left), the patrol key going down and up opens and commits
## a patrol, and the cancel key cancels an armed command or clears the selection. None of them
## moves the king or touches move_left.
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
const CYCLE_ACTION: StringName = &"squad_cycle"
const SELECT_ALL_ACTION: StringName = &"select_all"
const ATTACK_MOVE_ACTION: StringName = &"squad_attack_move"
const PATROL_ACTION: StringName = &"squad_patrol"
const CANCEL_ACTION: StringName = &"command_cancel"
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
var _was_pressed: Dictionary = {}


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()
	_pointer = map_root.get_node_or_null("SelectionController") as SelectionController


func _process(_delta: float) -> void:
	if _ctx == null or _selection == null:
		return
	for action: StringName in VERB_ACTIONS:
		if _pressed_now(action):
			_give(VERB_ACTIONS[action])
	if _pressed_now(CYCLE_ACTION):
		_selection.cycle_next(_ctx.squads.squad_ids())
	if _pressed_now(SELECT_ALL_ACTION):
		_selection.select_all(_ctx.squads.squad_ids())
	_poll_point_commands()
	for action: StringName in GROUP_ACTIONS:
		if _pressed_now(action):
			_group_key(GROUP_ACTIONS[action])


## The attack-move, patrol and cancel keys, passed to the pointer controller.
func _poll_point_commands() -> void:
	if _pointer == null:
		return
	if _pressed_now(ATTACK_MOVE_ACTION):
		_pointer.arm_attack_move()
	var patrol_down: bool = Input.is_action_pressed(PATROL_ACTION)
	var patrol_was_down: bool = bool(_was_pressed.get(PATROL_ACTION, false))
	_was_pressed[PATROL_ACTION] = patrol_down
	if patrol_down and not patrol_was_down:
		_pointer.begin_patrol()
	elif patrol_was_down and not patrol_down:
		_pointer.commit_patrol()
	if _pressed_now(CANCEL_ACTION):
		_pointer.escape()


## True on the frame `action` goes down, whether the engine reports the edge or only the level.
func _pressed_now(action: StringName) -> bool:
	var pressed: bool = Input.is_action_pressed(action)
	var edge: bool = (
		Input.is_action_just_pressed(action)
		or (pressed and not bool(_was_pressed.get(action, false)))
	)
	_was_pressed[action] = pressed
	return edge


## Orders the whole selection; with nothing selected it submits nothing and says so.
func _give(verb: StringName) -> void:
	var ids: Array[StringName] = _selection.selected()
	if ids.is_empty():
		feedback.emit(Toast.SELECT_FIRST, true)
		return
	_ctx.commands.submit(SquadOrderIntent.new(ids, verb))


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
