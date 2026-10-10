extends GutTest
## The army in the real scene (Task 2 of plan 03-01): with both military plots built there is one
## puppet per living unit, footmen wear the character-male-a model and archers character-female-a,
## and an archer shot at night puts an arrow in the air on the projectile layer.

const FIXTURE := "res://tests/fixtures/fixture_map_squads.tres"
const MALE_MODEL := "character-male-a.glb"
const FEMALE_MODEL := "character-female-a.glb"
const RAISE_TIMEOUT_S: float = 1.0
const ARROW_TIMEOUT_S: float = 30.0


func _spawn_squad_map() -> MapRoot:
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = load(FIXTURE)
	map_root.fixed_run_seed = 1
	add_child_autofree(map_root)
	await wait_process_frames(2)
	return map_root


## True when some node under `root` was instanced from a model file ending in `file_name`.
func _wears_model(root: Node, file_name: String) -> bool:
	if root.scene_file_path.ends_with(file_name):
		return true
	for child: Node in root.get_children():
		if _wears_model(child, file_name):
			return true
	return false


func test_both_squads_have_puppets_wearing_their_character_model() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var views: UnitViews = map_root.get_node("UnitViews")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"barracks_1")), CommandProcessor.OK, "barracks")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"archery_1")), CommandProcessor.OK, "range")
	var raised: Callable = func() -> bool: return views.view_count() == 8
	assert_true(await E2eSupport.wait_until(self, raised, RAISE_TIMEOUT_S), "eight puppets")
	assert_eq(ctx.get_unit_count(), 8, "the simulation fields eight units")
	var footmen: int = 0
	var archers: int = 0
	for unit_id: int in ctx.squads.get_units().ids():
		var view: Node3D = views.get_view(unit_id)
		var def: UnitDef = ctx.squads.get_units().def_of(unit_id)
		if def.id == &"footman":
			footmen += 1
			assert_true(_wears_model(view, MALE_MODEL), "footman %d wears the male model" % unit_id)
		else:
			archers += 1
			assert_true(_wears_model(view, FEMALE_MODEL), "archer %d wears the female" % unit_id)
	assert_eq(footmen, 4, "four footmen")
	assert_eq(archers, 4, "four archers")


func test_an_archer_shot_at_night_puts_an_arrow_in_the_air() -> void:
	var map_root: MapRoot = await _spawn_squad_map()
	var ctx: RunContext = map_root.get_context()
	var vfx: ProjectileVfx = map_root.get_node("ProjectileVfx")
	assert_eq(ctx.commands.submit(BuildIntent.new(&"archery_1")), CommandProcessor.OK, "range")
	await wait_process_frames(3)
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night starts")
	var arrow_seen: Array[bool] = [false]
	var probe: Callable = func() -> bool:
		if ctx.squads.get_units().count() > 0 and vfx.live_count() > 0:
			arrow_seen[0] = true
		return arrow_seen[0]
	assert_true(await E2eSupport.wait_until(self, probe, ARROW_TIMEOUT_S), "an arrow flew")
