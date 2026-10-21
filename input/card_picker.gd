class_name CardPicker
extends Node
## Which card of the world-space row is highlighted, and when the row shows (UI-02, D-05, D-06). The
## cards show for the focused spot while it is day, the king stands in range and the next tier of
## that spot offers cards and is affordable: exactly the case in which the command gate answers
## CHOICE_REQUIRED to a purchase with no card. Keys 1 to 4 (the group_1 to group_4 actions, which
## CommandKeyController hands over while the cards show) highlight card 1 to 4; no card is
## pre-highlighted, so a hold with no highlight is refused with choice_required and the denied bump
## (research A7). The highlight resets when the row hides, when the spot or its tier changes, and
## cannot change while a hold is under way, so the card shown raised is the card being bought.
## Presentation state only: nothing here reaches the simulation; BuildHoldController reads
## highlighted() at hold start and the choice rides the one BuildIntent.
##
## The presses are read in _process from Input.is_action_just_pressed with the same action-level
## fallback CommandKeyController uses, so scripted Input.action_press works in tests and replays.

## The highlighted card changed; `index` is -1 when none is highlighted.
signal highlight_changed(index: int)

## The digit actions, in card order: key n addresses card n.
const DIGIT_ACTIONS: Array[StringName] = [&"group_1", &"group_2", &"group_3", &"group_4"]

var _ctx: RunContext
var _hold: BuildHoldController
var _showing: bool = false
var _spot: StringName = &""
var _tier: int = 0
var _ids: Array[StringName] = []
var _highlight: int = -1
var _was_pressed: Dictionary = {}


func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_hold = map_root.get_build_hold()
	_hold.focus_changed.connect(_on_state_changed)
	ctx.events.building_built.connect(_on_building_built)
	ctx.events.phase_changed.connect(_on_phase_changed)
	ctx.events.gold_changed.connect(_on_gold_changed)
	_refresh()


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	_refresh()
	for index: int in range(DIGIT_ACTIONS.size()):
		if _pressed_now(DIGIT_ACTIONS[index]) and _showing:
			set_highlight(CardRowModel.index_for_digit(index + 1, _ids.size()))


## True while the cards are on show: the digit keys 1 to 4 pick cards and recall no control group.
func is_showing() -> bool:
	return _showing


## The spot the cards are shown for; empty while they are hidden.
func shown_spot() -> StringName:
	return _spot


## The ids of the shown cards, left to right in the authored order; empty while hidden.
func card_ids() -> Array[StringName]:
	return _ids.duplicate()


## The highlighted card's position, 0-based; -1 when none is highlighted or the cards are hidden.
func highlighted_index() -> int:
	return _highlight if _showing else -1


## The highlighted card's id; empty when none is highlighted or the cards are hidden.
func highlighted() -> StringName:
	if not _showing or _highlight < 0 or _highlight >= _ids.size():
		return &""
	return _ids[_highlight]


## Highlights the card at `index` (-1 clears it). Ignored while the cards are hidden, while a hold
## is under way, and for an index that addresses no shown card.
func set_highlight(index: int) -> void:
	if not _showing or (_hold != null and _hold.is_holding()):
		return
	if index < -1 or index >= _ids.size() or index == _highlight:
		return
	_highlight = index
	highlight_changed.emit(_highlight)


## Works out whether the cards show now, and for which spot and tier; a change of any of the three
## (or hiding) puts the highlight back to none.
func _refresh() -> void:
	var spot: StringName = _hold.get_focused_spot() if _hold != null else &""
	var show_row: bool = (
		spot != &"" and _ctx.commands.validate_build(spot) == CommandProcessor.CHOICE_REQUIRED
	)
	var tier: int = _ctx.buildings.current_tier(spot) if show_row else 0
	var shown_spot_id: StringName = spot if show_row else &""
	if not show_row or shown_spot_id != _spot or tier != _tier:
		_clear_highlight()
	_showing = show_row
	_spot = shown_spot_id
	_tier = tier
	_ids.clear()
	if show_row:
		for card: Dictionary in CardRowModel.cards(_ctx, spot, -1):
			_ids.append(card["id"] as StringName)


func _clear_highlight() -> void:
	if _highlight == -1:
		return
	_highlight = -1
	highlight_changed.emit(-1)


## True on the frame `action` goes down, whether the engine reports the edge or only the level.
func _pressed_now(action: StringName) -> bool:
	var pressed: bool = Input.is_action_pressed(action)
	var edge: bool = (
		Input.is_action_just_pressed(action)
		or (pressed and not bool(_was_pressed.get(action, false)))
	)
	_was_pressed[action] = pressed
	return edge


func _on_state_changed(_spot_id: StringName) -> void:
	_refresh()


func _on_building_built(_spot_id: StringName, _building_id: StringName, _new_tier: int) -> void:
	_refresh()


func _on_phase_changed(_old_phase: int, _new_phase: int) -> void:
	_refresh()


func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_refresh()
