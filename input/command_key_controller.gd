class_name CommandKeyController
extends Node
## Polled squad commands from the keyboard and the bare D-pad (D-15, INPT-01). F, H and R give the
## selection a follow, hold or rally order through the one command gate; Tab selects the next squad
## in creation order and F2 selects them all. A verb with nothing selected issues no order and
## reports "Select a squad first" through `feedback`, which the HUD toast shows.
##
## The presses are read in _process from Input.is_action_just_pressed with a per-action fallback on
## the action level: a scripted Input.action_press makes no input event, so the fallback keeps
## replays and tests working (Pitfall 6). A held key is one press, never a stream.

## Something to tell the player: `is_error` picks the 1.5 s error hold over the 1.2 s toast.
signal feedback(text: String, is_error: bool)

## Action to the order verb it gives the selection.
const VERB_ACTIONS: Dictionary = {
	&"squad_follow": SquadOrder.VERB_FOLLOW,
	&"squad_hold": SquadOrder.VERB_HOLD,
	&"squad_rally": SquadOrder.VERB_RALLY,
}
const CYCLE_ACTION: StringName = &"squad_cycle"
const SELECT_ALL_ACTION: StringName = &"select_all"

var _ctx: RunContext
var _selection: SelectionModel
var _was_pressed: Dictionary = {}


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	_ctx = ctx
	_selection = map_root.get_selection()


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
