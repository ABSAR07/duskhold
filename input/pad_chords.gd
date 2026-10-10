class_name PadChords
extends RefCounted
## Pure resolution of the gamepad twin presses (D-12, RESEARCH Open Question 3). A D-pad button is
## bound to a bare verb and to the point verb of the LB layer (up follow / move, down hold / patrol,
## right cycle / attack-move), and R3 to select all and select one type, so one press makes both
## actions just-pressed in the same frame: that pair is a pad press, and the LB layer picks the
## member. A lone member is a keyboard key (or the right mouse button) and resolves to itself, so
## a keyboard key keeps its meaning whatever the pad is holding. While the Start group mode is held
## the D-pad verbs resolve to nothing, because the group mode reads the raw D-pad itself. Rally
## (D-pad left) has no twin and is silenced in group mode too. Pure: no Input, no node.

const RALLY: StringName = &"squad_rally"
## [bare action, LB-layer action, whether the pair rides on the D-pad].
const PAIRS: Array[Array] = [
	[&"squad_follow", &"squad_move", true],
	[&"squad_hold", &"squad_patrol", true],
	[&"squad_cycle", &"squad_attack_move", true],
	[&"select_all", &"select_type", false],
]


## The commands to run for the actions `just_pressed` this frame. `layer_held` is the LB layer and
## `group_mode_held` the Start group mode. Pad pairs come first, then the lone presses.
static func resolve(
	just_pressed: Array[StringName], layer_held: bool, group_mode_held: bool
) -> Array[StringName]:
	var resolved: Array[StringName] = []
	var consumed: Array[StringName] = []
	for pair: Array in PAIRS:
		var bare: StringName = pair[0]
		var layered: StringName = pair[1]
		if not (just_pressed.has(bare) and just_pressed.has(layered)):
			continue
		consumed.append(bare)
		consumed.append(layered)
		if group_mode_held and bool(pair[2]):
			continue
		resolved.append(layered if layer_held else bare)
	for action: StringName in just_pressed:
		if consumed.has(action) or resolved.has(action):
			continue
		if action == RALLY and group_mode_held:
			continue
		resolved.append(action)
	return resolved


## True when `action` is one half of a twin pair whose other half went down in the same frame: a
## pad press and not a keyboard key or the right mouse button.
static func is_pad_press(action: StringName, just_pressed: Array[StringName]) -> bool:
	for pair: Array in PAIRS:
		if action == pair[0] or action == pair[1]:
			return just_pressed.has(pair[0]) and just_pressed.has(pair[1])
	return false
