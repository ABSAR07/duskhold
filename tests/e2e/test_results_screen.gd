extends GutTest
## LOOP-06, LOOP-07 and D-15 to D-17 on the real scene: a lost castle collapses and the action stays
## frozen for the loss beat before the Defeat screen appears, a won map shows Victory at once, the
## screen reads the run's stats, and Play again and Quit work from keyboard, gamepad and mouse.
## Every scene sets handle_results_actions to false (except the one that only checks the wiring), so
## no test can reload the scene or quit the game. Wait times derive from loop_tuning.tres.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const MAP_SCENE := "res://presentation/map/prototype_map.tscn"
const TUNING := "res://data/tuning/loop_tuning.tres"
const TOWER: StringName = &"tower_1"
const RICH_GOLD: int = 500
## Where the king stands to hold the west road: his passive attack reaches the grunts there.
const KING_AT := Vector3(-4.5, 0.0, 0.0)
const FAR_SPAWN := Vector3(-25.0, 0.0, 0.0)
const NEAR_SPAWN_X: float = -12.0
const DEFEAT_TIMEOUT_S: float = 4.0
const VICTORY_TIMEOUT_S: float = 20.0
## Real-time slack on top of the beat for the screen to be seen.
const BEAT_SLACK_S: float = 0.5
## Frame and timer granularity when checking that the beat was not cut short.
const EARLY_SLACK_S: float = 0.1
const FAST_BEAT_S: float = 0.1
## The tests' own grace window, far longer than the shipped 0.6 s so that a stalled runner (a GC
## pause, a loaded CI VM) cannot end it before a few taps are made inside it (review WR-02). It is
## also the cap on the grace, so it is never clamped.
const TEST_GRACE_S: float = 3.0
## A data typo far past the cap, for the test that the grace is clamped (review IN-04).
const HUGE_GRACE_S: float = 600.0
## Real-time slack on top of the grace for the screen to start accepting presses.
const GRACE_SLACK_S: float = 0.5
const SHOW_WITHIN_S: float = 0.5
const MOVE_TOLERANCE: float = 0.001
const PUPPET_IDS: int = 8

var _fell_at_ms: int = -1
var _ended_at_ms: int = -1


func before_each() -> void:
	_fell_at_ms = -1
	_ended_at_ms = -1


func after_each() -> void:
	E2eSupport.release_all_actions()


func _fixture_copy() -> MapConfig:
	var shipped: MapConfig = load(FIXTURE)
	return shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _group(spawn_point: StringName, count: int) -> SpawnGroupDef:
	var group: SpawnGroupDef = SpawnGroupDef.new()
	group.spawn_point_id = spawn_point
	group.enemy_id = &"grunt"
	group.count = count
	group.start_delay_seconds = 0.0
	group.interval_seconds = 1.0
	return group


## Night 1: one grunt standing at the castle's edge, which takes the castle's two hit points at
## once, and two more that start 25 m out and would march if the simulation were not frozen.
func _siege_map() -> MapConfig:
	var map: MapConfig = _fixture_copy()
	map.castle_max_health = map.enemies[0].attack_damage
	var west: SpawnPointDef = map.find_spawn_point(&"west")
	west.position = Vector3(-(map.castle_radius + map.enemies[0].attack_range), 0.0, 0.0)
	west.scatter_radius = 0.0
	var far: SpawnPointDef = SpawnPointDef.new()
	far.id = &"far"
	far.position = FAR_SPAWN
	map.spawn_points.append(far)
	map.nights[0].groups.clear()
	map.nights[0].groups.append(_group(&"west", 1))
	map.nights[0].groups.append(_group(&"far", 2))
	return map


## The fixture cut to its first night, spawning close to the king so the night is short, with gold
## for a Tower.
func _victory_map() -> MapConfig:
	var map: MapConfig = _fixture_copy()
	map.nights.remove_at(1)
	map.starting_gold = RICH_GOLD
	var west: SpawnPointDef = map.find_spawn_point(&"west")
	west.position = Vector3(NEAR_SPAWN_X, 0.0, 0.0)
	west.scatter_radius = 0.0
	map.nights[0].groups.clear()
	map.nights[0].groups.append(_group(&"west", 2))
	return map


## Shipped tuning with a different loss beat and no input grace, for the tests that press the
## buttons the moment the screen is up. The grace has its own tests below.
func _tuning_with_beat(seconds: float) -> LoopTuning:
	var tuning: LoopTuning = (load(TUNING) as LoopTuning).duplicate(true)
	tuning.loss_beat_seconds = seconds
	tuning.results_input_grace_seconds = 0.0
	return tuning


func _tuning_with_grace(seconds: float) -> LoopTuning:
	var tuning: LoopTuning = _tuning_with_beat(FAST_BEAT_S)
	tuning.results_input_grace_seconds = seconds
	return tuning


func _spawn(map: MapConfig, tuning: LoopTuning = null, handle_actions: bool = false) -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = 1
	map_root.handle_results_actions = handle_actions
	if tuning != null:
		map_root.loop_tuning = tuning
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _results(map_root: MapRoot) -> ResultsScreen:
	return map_root.get_node("ResultsScreen") as ResultsScreen


func _label_text(results: ResultsScreen, label_name: String) -> String:
	return (results.get_node("%" + label_name) as Label).text


func _start_night(map_root: MapRoot) -> void:
	var result: StringName = map_root.get_context().commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func _on_castle_destroyed() -> void:
	_fell_at_ms = Time.get_ticks_msec()


func _on_run_ended(_outcome: StringName) -> void:
	_ended_at_ms = Time.get_ticks_msec()


func _puppet_positions(map_root: MapRoot) -> Array[Vector3]:
	var views: EnemyViews = map_root.get_node("EnemyViews") as EnemyViews
	var found: Array[Vector3] = []
	for enemy_id: int in range(1, PUPPET_IDS):
		var view: Node3D = views.get_view(enemy_id)
		if view != null:
			found.append(view.position)
	return found


## Starts the siege and waits until the castle has fallen; returns the run's scene.
func _siege(tuning: LoopTuning = null) -> MapRoot:
	var map_root: MapRoot = await _spawn(_siege_map(), tuning)
	var ctx: RunContext = map_root.get_context()
	ctx.events.castle_destroyed.connect(_on_castle_destroyed)
	ctx.events.run_ended.connect(_on_run_ended)
	_start_night(map_root)
	var fell: Callable = func() -> bool: return _fell_at_ms >= 0
	assert_true(await E2eSupport.wait_until(self, fell, DEFEAT_TIMEOUT_S), "the castle falls")
	return map_root


func _key_event(keycode: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_event(button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap_key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		_key_event(keycode, pressed)
		await wait_process_frames(2)


func _tap_pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		_pad_event(button, pressed)
		await wait_process_frames(2)


## A mouse click on a button as the engine delivers it: `button_down` when the press starts and
## `pressed` when it is released. Emitting both keeps the results screen's press-start gate in play
## (review WR-01); a bare `pressed.emit()` would skip the stamp a real click always leaves.
func _click(button: Button) -> void:
	button.button_down.emit()
	button.pressed.emit()


func test_the_defeat_screen_waits_out_the_loss_beat_while_the_castle_collapses() -> void:
	var tuning: LoopTuning = load(TUNING)
	var map_root: MapRoot = await _siege()
	var results: ResultsScreen = _results(map_root)
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	assert_not_null(views.get_castle_rubble(), "the keep is already collapsing into rubble")
	assert_false(results.is_showing(), "the screen waits for the beat")
	await wait_process_frames(2)
	var frozen: Array[Vector3] = _puppet_positions(map_root)
	assert_gt(frozen.size(), 1, "enemies stand on the field")
	await wait_seconds(tuning.loss_beat_seconds * 0.5)
	assert_false(results.is_showing(), "still waiting halfway through the beat")
	assert_eq(_puppet_positions(map_root), frozen, "the action is frozen: no puppet moved")
	var shown: Callable = func() -> bool: return results.is_showing()
	var in_time: bool = await E2eSupport.wait_until(
		self, shown, tuning.loss_beat_seconds + BEAT_SLACK_S
	)
	assert_true(in_time, "the screen appears within the beat plus half a second")
	var waited_s: float = float(Time.get_ticks_msec() - _fell_at_ms) / 1000.0
	assert_gte(
		waited_s, tuning.loss_beat_seconds - EARLY_SLACK_S, "and not before the beat is over"
	)
	assert_eq(_label_text(results, "OutcomeLabel"), "Defeat", "it reads Defeat")
	assert_eq(_puppet_positions(map_root), frozen, "the field stayed frozen after the screen came")


func test_the_defeat_screen_reads_the_run_and_a_second_run_ended_changes_nothing() -> void:
	var map_root: MapRoot = await _siege(_tuning_with_beat(FAST_BEAT_S))
	var ctx: RunContext = map_root.get_context()
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	var total: int = ctx.run_manager.get_total_nights()
	assert_eq(total, 2, "the fixture has two nights")
	assert_eq(_label_text(results, "NightsLabel"), "Nights survived: %d of %d" % [0, total])
	assert_eq(_label_text(results, "GoldLabel"), "Gold earned: %d" % ctx.stats.gold_earned())
	assert_eq(
		_label_text(results, "BuildingsLostLabel"),
		"Buildings lost: %d" % ctx.stats.buildings_lost()
	)
	assert_eq(
		_label_text(results, "KnockoutsLabel"), "King knockouts: %d" % ctx.stats.king_knockouts()
	)
	ctx.events.run_ended.emit(&"victory")
	await wait_process_frames(2)
	assert_eq(
		_label_text(results, "OutcomeLabel"), "Defeat", "a repeat run_ended does not rewrite it"
	)
	var connections: int = ctx.events.run_ended.get_connections().size()
	results.bind_run(ctx, map_root)
	assert_eq(
		ctx.events.run_ended.get_connections().size(), connections, "a repeat bind is ignored"
	)


func test_victory_shows_the_screen_at_once_with_the_stats_of_the_run() -> void:
	var map_root: MapRoot = await _spawn(_victory_map())
	var ctx: RunContext = map_root.get_context()
	var results: ResultsScreen = _results(map_root)
	ctx.events.run_ended.connect(_on_run_ended)
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "a Tower")
	E2eSupport.teleport_king(map_root, KING_AT)
	_start_night(map_root)
	ctx.buildings.damage_building(TOWER, RICH_GOLD * 100)
	var over: Callable = func() -> bool: return ctx.run_manager.is_run_over()
	assert_true(await E2eSupport.wait_until(self, over, VICTORY_TIMEOUT_S), "the night is cleared")
	assert_eq(ctx.stats.outcome(), &"victory", "the run was won")
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, SHOW_WITHIN_S), "the screen is up at once")
	var waited_s: float = float(Time.get_ticks_msec() - _ended_at_ms) / 1000.0
	assert_lt(waited_s, SHOW_WITHIN_S + EARLY_SLACK_S, "within half a second of run_ended")
	assert_eq(_label_text(results, "OutcomeLabel"), "Victory", "it reads Victory")
	assert_eq(_label_text(results, "NightsLabel"), "Nights survived: 1 of 1")
	assert_eq(_label_text(results, "GoldLabel"), "Gold earned: 0", "the last night pays no dawn")
	assert_eq(_label_text(results, "BuildingsLostLabel"), "Buildings lost: 1", "the Tower fell")
	assert_eq(_label_text(results, "KnockoutsLabel"), "King knockouts: 0")
	var lighting: DayNightLighting = map_root.get_node("Lighting") as DayNightLighting
	assert_eq(lighting.get_mood(), &"dawn", "the light is dawn after a victory")


func test_play_again_has_focus_and_every_device_presses_the_buttons() -> void:
	var map_root: MapRoot = await _siege(_tuning_with_beat(FAST_BEAT_S))
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	var play_again: Button = results.get_node("%PlayAgainButton") as Button
	var quit: Button = results.get_node("%QuitButton") as Button
	assert_eq(play_again.text, "Play again")
	assert_eq(quit.text, "Quit")
	assert_true(play_again.has_focus(), "Play again has focus when the screen shows")
	watch_signals(results)
	await _tap_key(KEY_ENTER)
	assert_signal_emit_count(results, "play_again_pressed", 1, "accept presses the focused button")
	await _tap_key(KEY_RIGHT)
	assert_true(quit.has_focus(), "ui_right moves the focus to Quit")
	assert_signal_not_emitted(results, "quit_pressed", "moving the focus presses nothing")
	await _tap_key(KEY_ENTER)
	assert_signal_emit_count(results, "quit_pressed", 1, "accept on Quit")
	await _tap_pad(JOY_BUTTON_A)
	assert_signal_emit_count(results, "quit_pressed", 2, "the gamepad accept button presses it too")
	_click(play_again)
	assert_signal_emit_count(
		results, "play_again_pressed", 2, "a mouse press emits the same signal"
	)
	_click(quit)
	assert_signal_emit_count(results, "quit_pressed", 3, "and so for Quit")


func test_after_a_defeat_the_king_ignores_input_and_the_light_stays_night() -> void:
	var map_root: MapRoot = await _siege(_tuning_with_beat(FAST_BEAT_S))
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	var king: King = map_root.get_king()
	var stood_at: Vector3 = king.global_position
	Input.action_press(&"move_right")
	await wait_seconds(0.4)
	Input.action_release(&"move_right")
	assert_almost_eq(king.global_position.x, stood_at.x, MOVE_TOLERANCE, "x unchanged")
	assert_almost_eq(king.global_position.z, stood_at.z, MOVE_TOLERANCE, "z unchanged")
	var lighting: DayNightLighting = map_root.get_node("Lighting") as DayNightLighting
	assert_eq(lighting.get_mood(), &"night", "the light is night after a defeat")


func test_the_king_ignores_input_during_the_loss_beat_too() -> void:
	var map_root: MapRoot = await _siege()
	var results: ResultsScreen = _results(map_root)
	var king: King = map_root.get_king()
	var stood_at: Vector3 = king.global_position
	Input.action_press(&"move_right")
	await wait_seconds(0.3)
	Input.action_release(&"move_right")
	assert_false(results.is_showing(), "still inside the beat")
	assert_almost_eq(king.global_position.x, stood_at.x, MOVE_TOLERANCE, "x unchanged")


func test_map_root_wires_the_buttons_only_when_it_handles_the_results() -> void:
	var wired: MapRoot = await _spawn(_fixture_copy(), null, true)
	var wired_results: ResultsScreen = _results(wired)
	for signal_name: String in ["play_again_pressed", "quit_pressed"]:
		var connections: Array[Dictionary] = wired_results.get_signal_connection_list(signal_name)
		assert_eq(connections.size(), 1, "%s has one handler" % signal_name)
		if connections.size() == 1:
			var handler: Callable = connections[0]["callable"]
			assert_eq(handler.get_object(), wired, "and it belongs to the map")
	var quiet: MapRoot = await _spawn(_fixture_copy())
	var quiet_results: ResultsScreen = _results(quiet)
	for signal_name: String in ["play_again_pressed", "quit_pressed"]:
		var found: int = quiet_results.get_signal_connection_list(signal_name).size()
		assert_eq(found, 0, "a test map leaves %s unhandled" % signal_name)


## WR-03: the build key (Space, gamepad A) is also ui_accept, so a player tapping it as the run
## ends would press the focused Play again and lose the screen. Presses inside the grace window do
## nothing; the same press after it works. The window is the test's own long one, and "inside" is
## decided after the taps: accepts_input() never goes back to false, so if it is still false then
## every tap was inside, and if the runner stalled past the window the test says so (WR-02).
func test_a_defeat_ignores_accept_inside_the_grace_window_and_takes_it_after() -> void:
	var map_root: MapRoot = await _siege(_tuning_with_grace(TEST_GRACE_S))
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	assert_true(
		(results.get_node("%PlayAgainButton") as Button).has_focus(), "focus is on Play again"
	)
	watch_signals(results)
	await _tap_pad(JOY_BUTTON_A)
	await _tap_key(KEY_SPACE)
	await _tap_key(KEY_ENTER)
	_click(results.get_node("%PlayAgainButton") as Button)
	_click(results.get_node("%QuitButton") as Button)
	if results.accepts_input():
		pending("the runner stalled past the grace window, so 'inside it' cannot be judged")
		return
	assert_signal_not_emitted(results, "play_again_pressed", "no accept inside the window restarts")
	assert_signal_not_emitted(results, "quit_pressed", "and none quits")
	var armed: Callable = func() -> bool: return results.accepts_input()
	assert_true(await E2eSupport.wait_until(self, armed, TEST_GRACE_S + GRACE_SLACK_S), "it arms")
	await _tap_key(KEY_SPACE)
	assert_signal_emit_count(results, "play_again_pressed", 1, "the same press works after it")
	_click(results.get_node("%QuitButton") as Button)
	assert_signal_emit_count(results, "quit_pressed", 1, "and so does a mouse press on Quit")


## The Victory screen is up at once, so it is where a player is most likely still tapping the key.
## Returns the screen once Victory shows, on a scene that has its own long grace window.
func _victory_scene() -> ResultsScreen:
	var map_root: MapRoot = await _spawn(_victory_map(), _tuning_with_grace(TEST_GRACE_S))
	var ctx: RunContext = map_root.get_context()
	var results: ResultsScreen = _results(map_root)
	assert_eq(ctx.commands.submit(BuildIntent.new(TOWER)), CommandProcessor.OK, "a Tower")
	E2eSupport.teleport_king(map_root, KING_AT)
	_start_night(map_root)
	ctx.buildings.damage_building(TOWER, RICH_GOLD * 100)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, VICTORY_TIMEOUT_S), "Victory shows")
	return results


func test_a_victory_ignores_the_action_key_tapped_as_it_appears() -> void:
	var results: ResultsScreen = await _victory_scene()
	watch_signals(results)
	await _tap_key(KEY_SPACE)
	if results.accepts_input():
		pending("the runner stalled past the grace window, so 'inside it' cannot be judged")
		return
	assert_signal_not_emitted(results, "play_again_pressed", "the action key does not restart")
	var armed: Callable = func() -> bool: return results.accepts_input()
	assert_true(await E2eSupport.wait_until(self, armed, TEST_GRACE_S + GRACE_SLACK_S), "it arms")
	await _tap_key(KEY_SPACE)
	assert_signal_emit_count(results, "play_again_pressed", 1, "and works once the grace is over")


## WR-01: a Button emits `pressed` when the press is RELEASED, so gating the release is not enough.
## A press that starts inside the grace window and is let go after it must do nothing, and a fresh
## press that starts after the window must work. `press` and `release` are the device's two halves.
func _assert_a_straddling_press_is_ignored(
	results: ResultsScreen, signal_name: String, press: Callable, release: Callable
) -> void:
	watch_signals(results)
	press.call()
	await wait_process_frames(2)
	if results.accepts_input():
		release.call()
		pending("the runner stalled past the grace window, so 'inside it' cannot be judged")
		return
	var armed: Callable = func() -> bool: return results.accepts_input()
	assert_true(await E2eSupport.wait_until(self, armed, TEST_GRACE_S + GRACE_SLACK_S), "it arms")
	release.call()
	await wait_process_frames(2)
	assert_signal_not_emitted(results, signal_name, "a press begun inside the window does nothing")
	press.call()
	await wait_process_frames(2)
	release.call()
	await wait_process_frames(2)
	assert_signal_emit_count(results, signal_name, 1, "a fresh press after the window works")


func _defeat_scene() -> ResultsScreen:
	var map_root: MapRoot = await _siege(_tuning_with_grace(TEST_GRACE_S))
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	return results


func test_a_defeat_key_press_begun_inside_the_grace_and_released_after_it_does_nothing() -> void:
	var results: ResultsScreen = await _defeat_scene()
	await _assert_a_straddling_press_is_ignored(
		results,
		"play_again_pressed",
		_key_event.bind(KEY_SPACE, true),
		_key_event.bind(KEY_SPACE, false)
	)


func test_a_defeat_gamepad_press_begun_inside_the_grace_and_released_after_it_does_nothing(
) -> void:
	var results: ResultsScreen = await _defeat_scene()
	await _assert_a_straddling_press_is_ignored(
		results,
		"play_again_pressed",
		_pad_event.bind(JOY_BUTTON_A, true),
		_pad_event.bind(JOY_BUTTON_A, false)
	)


func test_a_defeat_mouse_press_begun_inside_the_grace_and_released_after_it_does_nothing() -> void:
	var results: ResultsScreen = await _defeat_scene()
	var quit: Button = results.get_node("%QuitButton") as Button
	await _assert_a_straddling_press_is_ignored(
		results,
		"quit_pressed",
		func() -> void: quit.button_down.emit(),
		func() -> void: quit.pressed.emit()
	)


func test_a_victory_key_press_begun_inside_the_grace_and_released_after_it_does_nothing() -> void:
	var results: ResultsScreen = await _victory_scene()
	await _assert_a_straddling_press_is_ignored(
		results,
		"play_again_pressed",
		_key_event.bind(KEY_SPACE, true),
		_key_event.bind(KEY_SPACE, false)
	)


## IN-04: a typo in the data (60 for 0.6, here far more) must not leave both buttons dead for that
## long with nothing on screen to say why; the window is capped.
func test_a_huge_grace_value_is_capped_so_the_buttons_still_work() -> void:
	var map_root: MapRoot = await _siege(_tuning_with_grace(HUGE_GRACE_S))
	var results: ResultsScreen = _results(map_root)
	var shown: Callable = func() -> bool: return results.is_showing()
	assert_true(await E2eSupport.wait_until(self, shown, FAST_BEAT_S + BEAT_SLACK_S), "it shows")
	watch_signals(results)
	var armed: Callable = func() -> bool: return results.accepts_input()
	var in_time: bool = await E2eSupport.wait_until(
		self, armed, ResultsScreen.MAX_GRACE_S + GRACE_SLACK_S
	)
	assert_true(in_time, "the buttons accept presses once the capped window is over")
	await _tap_key(KEY_SPACE)
	assert_signal_emit_count(results, "play_again_pressed", 1, "and a press works")
