extends GutTest
## INPT-02, D-12 (RESEARCH Open Question 3): PadChords resolves the D-pad twins. A D-pad press fires
## a bare action and its LB-layer twin on the same button, so both are just-pressed together and
## that pair is the pad; the layer picks the member. A lone member is a keyboard key or the right
## mouse button and resolves to itself. While the Start group mode is held the D-pad verbs resolve
## to nothing, because group mode reads the raw D-pad itself.

const FOLLOW: StringName = &"squad_follow"
const MOVE: StringName = &"squad_move"
const HOLD: StringName = &"squad_hold"
const PATROL: StringName = &"squad_patrol"
const CYCLE: StringName = &"squad_cycle"
const ATTACK_MOVE: StringName = &"squad_attack_move"
const RALLY: StringName = &"squad_rally"
const SELECT_ALL: StringName = &"select_all"
const SELECT_TYPE: StringName = &"select_type"


func _resolve(
	pressed: Array[StringName], layer: bool = false, group_mode: bool = false
) -> Array[StringName]:
	return PadChords.resolve(pressed, layer, group_mode)


func test_the_bare_d_pad_gives_the_bare_verb_and_the_layer_gives_its_twin() -> void:
	var pairs: Array[Array] = [
		[FOLLOW, MOVE], [HOLD, PATROL], [CYCLE, ATTACK_MOVE], [SELECT_ALL, SELECT_TYPE]
	]
	for pair: Array in pairs:
		var pressed: Array[StringName] = [pair[0], pair[1]]
		assert_eq(_resolve(pressed, false), [pair[0]] as Array[StringName], "bare: %s" % pair[0])
		assert_eq(_resolve(pressed, true), [pair[1]] as Array[StringName], "layer: %s" % pair[1])


func test_the_order_of_the_pair_does_not_matter() -> void:
	var pressed: Array[StringName] = [MOVE, FOLLOW]
	assert_eq(_resolve(pressed, false), [FOLLOW] as Array[StringName], "bare")
	assert_eq(_resolve(pressed, true), [MOVE] as Array[StringName], "layer")


func test_a_lone_keyboard_action_resolves_to_itself_whatever_the_layer() -> void:
	for action: StringName in [FOLLOW, PATROL, MOVE, HOLD, ATTACK_MOVE, CYCLE, SELECT_ALL]:
		var pressed: Array[StringName] = [action]
		assert_eq(_resolve(pressed, false), pressed, "%s without the layer" % action)
		assert_eq(_resolve(pressed, true), pressed, "%s with the layer" % action)


func test_rally_has_no_twin_and_resolves_to_itself() -> void:
	var pressed: Array[StringName] = [RALLY]
	assert_eq(_resolve(pressed, false), pressed, "bare")
	assert_eq(_resolve(pressed, true), pressed, "with the layer")


func test_two_pad_presses_in_one_frame_both_resolve() -> void:
	var pressed: Array[StringName] = [FOLLOW, MOVE, RALLY]
	var resolved: Array[StringName] = _resolve(pressed, true)
	assert_eq(resolved.size(), 2, "the pair and the rally")
	assert_true(resolved.has(MOVE), "the layer move")
	assert_true(resolved.has(RALLY), "and the rally")


func test_nothing_pressed_resolves_to_nothing() -> void:
	assert_eq(_resolve([] as Array[StringName], true, true), [] as Array[StringName], "nothing")


func test_group_mode_silences_every_bare_d_pad_verb() -> void:
	var pairs: Array[Array] = [[FOLLOW, MOVE], [HOLD, PATROL], [CYCLE, ATTACK_MOVE]]
	for pair: Array in pairs:
		var pressed: Array[StringName] = [pair[0], pair[1]]
		assert_eq(_resolve(pressed, false, true), [] as Array[StringName], "%s" % pair[0])
		assert_eq(
			_resolve(pressed, true, true), [] as Array[StringName], "%s on the layer" % pair[0]
		)
	var rally: Array[StringName] = [RALLY]
	assert_eq(
		_resolve(rally, false, true), [] as Array[StringName], "rally has no twin and is silent"
	)


func test_group_mode_leaves_a_lone_keyboard_key_and_the_stick_click_alone() -> void:
	var follow: Array[StringName] = [FOLLOW]
	assert_eq(_resolve(follow, false, true), follow, "a keyboard F still follows")
	var both: Array[StringName] = [SELECT_ALL, SELECT_TYPE]
	assert_eq(_resolve(both, false, true), [SELECT_ALL] as Array[StringName], "R3 is not the D-pad")


func test_is_pad_press_needs_the_twin_in_the_same_frame() -> void:
	var pressed: Array[StringName] = [FOLLOW, MOVE]
	assert_true(PadChords.is_pad_press(MOVE, pressed), "the layer twin of a pair")
	assert_true(PadChords.is_pad_press(FOLLOW, pressed), "the bare member of a pair")
	var lone: Array[StringName] = [MOVE]
	assert_false(PadChords.is_pad_press(MOVE, lone), "a lone right click")
	assert_false(PadChords.is_pad_press(RALLY, [RALLY] as Array[StringName]), "rally has no twin")
