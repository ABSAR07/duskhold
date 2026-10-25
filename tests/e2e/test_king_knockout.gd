extends GutTest
## KING-06 on the real scene: eight grunts spawned beside a four-hit-point king knock him out; the
## model gives way to a ghost that cannot move, the HUD counts down, and he reappears at the castle.
## Health bars show only what is hurt (D-12 rule). Wait times derive from loop_tuning.tres.
## Gap round G-05-2 (the x100 rescale): the heal hit is 1000 because the shipped king now
## heals 500 a second, so a hit of 10 healed inside one step and hid the bar unseen.

const FIXTURE := "res://tests/fixtures/fixture_map_one_night.tres"
const MAP_SCENE := "res://presentation/map/prototype_map.tscn"
const TUNING := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const KING_HEALTH: int = 4
## The heal case keeps the shipped king (no max_health override) and hurts him by this much.
const HEAL_DAMAGE: int = 1000
## Real-time slack on top of the derived regeneration waits.
const HEAL_SLACK_S: float = 3.0
const HEALTH_TEXT := "%d / %d"
const GRUNTS: int = 8
const CASTLE_HEALTH: int = 10000
const KO_TIMEOUT_S: float = 6.0
const PUSH_SECONDS: float = 0.5
const POSITION_TOLERANCE: float = 0.05
## Real-time slack on top of the countdown for the respawn to be seen.
const RESPAWN_SLACK_S: float = 3.0
const LABEL_PATTERN := "^Knocked out — back in (\\d+) s$"

var _tuning: LoopTuning
var _respawn_seen: bool = false
var _at_respawn: Dictionary = {}


func before_each() -> void:
	_tuning = load(TUNING)
	_respawn_seen = false
	_at_respawn = {}


func after_each() -> void:
	E2eSupport.release_all_actions()


## The fixture map with night 1 reduced to one group of eight grunts spawning at once beside the
## king (DR-12: a deep copy, so nothing leaks into the cached resource).
func _ambush_map() -> MapConfig:
	var map: MapConfig = (load(FIXTURE) as MapConfig).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var spawn_point: SpawnPointDef = map.spawn_points[0]
	spawn_point.position = Vector3(map.king_spawn.x + 2.5, 0.0, map.king_spawn.z)
	spawn_point.scatter_radius = 0.5
	var group: SpawnGroupDef = map.nights[0].groups[0]
	group.count = GRUNTS
	group.start_delay_seconds = 0.0
	group.interval_seconds = 0.0
	# A fallen castle now ends the run (LOOP-06) and freezes the king's respawn countdown, so the
	# castle outlasts the eight grunts that are free to hit it while the king is down.
	map.castle_max_health = CASTLE_HEALTH
	return map


## Spawns the map scene. `king_health` replaces the king's max_health; 0 keeps the shipped king.
func _spawn(map: MapConfig, king_health: int = KING_HEALTH) -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = map
	map_root.fixed_run_seed = 1
	var king: King = map_root.get_node("King") as King
	var def: KingDef = (load(KING_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if king_health > 0:
		def.max_health = king_health
	king.def = def
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


func _start_night(map_root: MapRoot) -> void:
	var result: StringName = map_root.get_context().commands.submit(StartNightIntent.new())
	assert_eq(result, CommandProcessor.OK, "the night starts")


func _hud(map_root: MapRoot) -> Hud:
	return map_root.get_node("HUD") as Hud


func _respawn_label(map_root: MapRoot) -> Label:
	return _hud(map_root).find_child("RespawnLabel", true, false) as Label


func _model_visible(king: King) -> bool:
	return (king.get_node("Model") as Node3D).visible


func _on_respawned(king: King, map_root: MapRoot) -> void:
	_respawn_seen = true
	_at_respawn = {
		"position": king.global_position,
		"model": _model_visible(king),
		"ghost": king.is_ghost_shown(),
		"bar": king.get_health_bar() != null and king.get_health_bar().visible,
		"health": map_root.get_context().king.get_health(),
	}


func test_a_knockout_shows_the_ghost_and_the_countdown_and_the_king_cannot_move() -> void:
	var map_root: MapRoot = await _spawn(_ambush_map())
	var ctx: RunContext = map_root.get_context()
	var king: King = map_root.get_king()
	var label: Label = _respawn_label(map_root)
	assert_not_null(label, "the HUD has a RespawnLabel")
	if label == null:
		return
	assert_false(label.visible, "no countdown while he is up")
	assert_true(_model_visible(king), "the model shows while he is up")
	assert_false(king.is_ghost_shown(), "and the ghost does not")
	_start_night(map_root)
	var knocked_out: Callable = func() -> bool: return ctx.king.is_down()
	assert_true(
		await E2eSupport.wait_until(self, knocked_out, KO_TIMEOUT_S), "the grunts knock him out"
	)
	await wait_process_frames(3)
	assert_true(label.visible, "the countdown label shows")
	var matched: RegExMatch = RegEx.create_from_string(LABEL_PATTERN).search(label.text)
	assert_not_null(matched, "reads 'Knocked out — back in N s', got '%s'" % label.text)
	if matched != null:
		var shown: int = int(matched.get_string(1))
		var now: int = ceili(ctx.king.respawn_seconds_remaining())
		assert_between(shown, now, now + 1, "N is the remaining seconds rounded up")
		assert_gt(shown, 0, "never reads 0 while down")
	assert_false(_model_visible(king), "the model is hidden")
	assert_true(king.is_ghost_shown(), "the ghost stands in")
	var fell_at: Vector3 = king.global_position
	await E2eSupport.hold_action_seconds(self, &"move_right", PUSH_SECONDS)
	assert_true(ctx.king.is_down(), "still down after the push")
	assert_almost_eq(king.global_position.x, fell_at.x, POSITION_TOLERANCE, "x unchanged")
	assert_almost_eq(king.global_position.z, fell_at.z, POSITION_TOLERANCE, "z unchanged")


func test_after_the_countdown_the_king_stands_at_the_castle_and_the_ghost_and_label_go() -> void:
	var map_root: MapRoot = await _spawn(_ambush_map())
	var ctx: RunContext = map_root.get_context()
	var king: King = map_root.get_king()
	ctx.events.king_respawned.connect(_on_respawned.bind(king, map_root))
	_start_night(map_root)
	var seen: Callable = func() -> bool: return _respawn_seen
	var wait_s: float = _tuning.respawn_seconds(1) + KO_TIMEOUT_S + RESPAWN_SLACK_S
	assert_true(await E2eSupport.wait_until(self, seen, wait_s), "he respawns")
	if _at_respawn.is_empty():
		return
	assert_almost_eq(_at_respawn["position"].x, ctx.map.king_spawn.x, POSITION_TOLERANCE, "x")
	assert_almost_eq(_at_respawn["position"].z, ctx.map.king_spawn.z, POSITION_TOLERANCE, "z")
	assert_true(_at_respawn["model"], "the model is back")
	assert_false(_at_respawn["ghost"], "the ghost is gone")
	assert_false(_at_respawn["bar"], "full health shows no bar")
	assert_eq(_at_respawn["health"], KING_HEALTH, "full health")
	await wait_process_frames(2)
	var label: Label = _respawn_label(map_root)
	assert_not_null(label, "the HUD has a RespawnLabel")
	if label != null:
		assert_false(label.visible, "the countdown label hid")


func test_the_king_bar_hides_at_full_health_and_shows_once_hurt() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.waveless_prototype_map())
	var ctx: RunContext = map_root.get_context()
	var bar: HealthBar3D = map_root.get_king().get_health_bar()
	assert_not_null(bar, "the king has a health bar")
	if bar == null:
		return
	assert_false(bar.visible, "hidden at full health")
	ctx.king.take_damage(1)
	await wait_process_frames(1)
	assert_true(bar.visible, "shown after the first hit")
	assert_almost_eq(
		bar.get_fill_ratio(), float(KING_HEALTH - 1) / float(KING_HEALTH), 0.0001, "fill ratio"
	)


## Records the bar's fill ratio at the instant of each king_healed event (this handler connects
## after the King's own, so the bar has already been told) next to the event's own numbers.
func _on_healed(_amount: int, hp: int, max_hp: int, bar: HealthBar3D, heals: Array) -> void:
	heals.append({"hp": hp, "max_hp": max_hp, "bar_ratio": bar.get_fill_ratio()})


func test_after_regeneration_the_king_bar_follows_each_heal_and_hides_at_full() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.waveless_prototype_map(), 0)
	var ctx: RunContext = map_root.get_context()
	var king_def: KingDef = ctx.king.get_def()
	var max_hp: int = ctx.king.get_max_health()
	var bar: HealthBar3D = map_root.get_king().get_health_bar()
	var widget: KingWidget = map_root.get_node("HUD").find_child("KingWidget", true, false)
	assert_not_null(widget, "the HUD has the king widget")
	if bar == null or widget == null:
		return
	var label: Label = widget.get_health_label()
	assert_gt(max_hp, HEAL_DAMAGE, "the shipped king survives the damage dealt here")
	var heals: Array = []
	ctx.events.king_healed.connect(_on_healed.bind(bar, heals))
	ctx.king.take_damage(HEAL_DAMAGE)
	await wait_process_frames(1)
	assert_true(bar.visible, "the bar shows once he is hurt")
	var points_per_second: float = float(max_hp) * king_def.regen_fraction_per_second
	var first_heal_s: float = (
		SimClock.seconds(SimClock.ticks(king_def.regen_delay_seconds))
		+ 1.0 / points_per_second
		+ HEAL_SLACK_S
	)
	var healed: Callable = func() -> bool: return not heals.is_empty()
	assert_true(await E2eSupport.wait_until(self, healed, first_heal_s), "the first heal arrives")
	await wait_process_frames(1)
	assert_true(bar.visible, "the bar stays up while he is still hurt")
	var expected_ratio: float = float(ctx.king.get_health()) / float(max_hp)
	assert_almost_eq(bar.get_fill_ratio(), expected_ratio, 0.0001, "the bar shows the simulation")
	var shown: Callable = func() -> bool:
		return label.text == HEALTH_TEXT % [ctx.king.get_health(), max_hp]
	assert_true(await E2eSupport.wait_until(self, shown, HEAL_SLACK_S), "the widget agrees")
	var whole_s: float = float(HEAL_DAMAGE) / points_per_second + HEAL_SLACK_S
	var whole: Callable = func() -> bool: return ctx.king.get_health() >= max_hp
	assert_true(await E2eSupport.wait_until(self, whole, whole_s), "he regenerates to full health")
	await wait_process_frames(1)
	assert_false(bar.visible, "the bar hides again at full health")
	assert_eq(label.text, HEALTH_TEXT % [max_hp, max_hp], "the widget reads full")
	for heal: Dictionary in heals:
		var heal_ratio: float = float(heal["hp"]) / float(heal["max_hp"])
		assert_almost_eq(heal["bar_ratio"], heal_ratio, 0.0001, "the bar followed this heal")


func test_the_castle_bar_hides_at_full_health_and_shows_once_hurt() -> void:
	var map_root: MapRoot = await _spawn(E2eSupport.waveless_prototype_map())
	var ctx: RunContext = map_root.get_context()
	var views: BuildingViews = map_root.get_node("BuildingViews") as BuildingViews
	var bar: HealthBar3D = views.get_castle_health_bar()
	assert_not_null(bar, "the castle has a health bar")
	if bar == null:
		return
	assert_false(bar.visible, "hidden at full health")
	ctx.castle.damage(1)
	await wait_process_frames(1)
	assert_true(bar.visible, "shown after the first hit")
