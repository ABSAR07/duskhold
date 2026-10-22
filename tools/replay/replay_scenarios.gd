class_name ReplayScenarios
extends RefCounted
## The replay scenarios the CLI and the golden test may run (DEV-05), and the golden lookup they
## share. A scenario is a fixed map, tuning, king, scripted PlaytestBot and tick bound; the CLI
## accepts only the names in NAMES, so no argument ever picks a path to load.
##   smoke      - self-contained fixture data (tests/fixtures/fixture_*_replay_smoke.tres). Its
##                golden digest lives in tests/golden/smoke.json and moves only when the
##                simulation rules change, never when data/ is retuned.
##   army       - self-contained fixture data (tests/fixtures/fixture_*_replay_army.tres): a map
##                with a Barracks and an Archery Range, and a king with the slam and regeneration.
##                A scripted bot builds both, gives follow, hold, move, attack-move and patrol on
##                fixed ticks and slams. Its golden digest lives in tests/golden/army.json and, like
##                the smoke golden, moves only when the simulation rules change, never when data/
##                is retuned.
##   walls      - self-contained fixture data (tests/fixtures/fixture_map_replay_walls.tres): a long
##                wall run on the west road with one gap, a tower, and two nights. A scripted bot
##                buys both; the first night's crowd breaks a segment, the second night's
##                stragglers go round through the gap, and dawn restores the wall. Its golden
##                digest lives in tests/golden/walls.json and, like the smoke and army goldens,
##                moves only when the simulation rules change, never when data/ is retuned.
##   economy    - self-contained fixture data
##                (tests/fixtures/fixture_map_replay_economy.tres): inline copies of the castle
##                (tier II with four cards), Gold Mine, Mill, Field, Fishing Harbor, Shrine and
##                tower as they were when the scenario was pinned, a west road for night 1 and a
##                north-west road for nights 2 and 3. A scripted bot buys the castle tier II with a
##                fixed card pick and every new building; night 1's crowd wakes the Shrine and
##                breaks the Mine, and dawn rebuilds it free. Its golden digest lives in
##                tests/golden/economy.json and, like the other goldens, moves only when the
##                simulation rules change, never when data/ is retuned.
##   full_idle  - the shipped prototype map, tuning and king played through all eight nights by the
##                balanced bot (the name is kept for CI; the king no longer idles, because an idle
##                king loses on night 1). No golden, because balance retunes change it. Two runs in
##                one process must agree.
## tools/ is excluded from the export.

const NAMES: Array[StringName] = [&"smoke", &"full_idle", &"army", &"walls", &"economy"]
const GOLDEN_DIR := "res://tests/golden"
## The key looked up when the file has no entry for the running platform.
const DEFAULT_KEY := "default"

const SMOKE_MAP := "res://tests/fixtures/fixture_map_replay_smoke.tres"
const SMOKE_KING := "res://tests/fixtures/fixture_king_replay_smoke.tres"
const SMOKE_TUNING := "res://tests/fixtures/fixture_tuning_replay_smoke.tres"
## The king holds the west approach in front of the tower, where the marching enemies reach him.
const SMOKE_HOLD_POINT := Vector2(-16.0, 0.0)
const SMOKE_MAX_TICKS: int = 6000
const SMOKE_BUILD_ORDER: Array[StringName] = [
	&"tower_1", &"tower_2", &"house_3", &"house_1", &"tower_1"
]

const ARMY_MAP := "res://tests/fixtures/fixture_map_replay_army.tres"
const ARMY_KING := "res://tests/fixtures/fixture_king_replay_army.tres"
const ARMY_MAX_TICKS: int = 8000
const ARMY_BUILD_ORDER: Array[StringName] = [&"barracks_1", &"archery_1", &"tower_1", &"house_1"]
## Squad orders of the army scenario as {tick, squads, verb, points (centimetres), queued}. The
## first night opens on tick 0 (the bot starts it at once), so every order falls inside a night.
const ARMY_ORDERS: Array[Dictionary] = [
	{"tick": 1, "squads": [&"barracks_1"], "verb": &"follow"},
	{"tick": 1, "squads": [&"archery_1"], "verb": &"hold"},
	{
		"tick": 120,
		"squads": [&"barracks_1"],
		"verb": &"move",
		"points": [Vector2i(-1400, 300)],
	},
	{
		"tick": 120,
		"squads": [&"barracks_1"],
		"verb": &"attack_move",
		"points": [Vector2i(-2000, 500)],
		"queued": true,
	},
	{
		"tick": 150,
		"squads": [&"archery_1"],
		"verb": &"patrol",
		"points": [Vector2i(-900, 200), Vector2i(-1300, 500)],
	},
]
## The slam is used when this many enemies stand inside its radius.
const ARMY_SLAM_MIN_ENEMIES: int = 2

const WALLS_MAP := "res://tests/fixtures/fixture_map_replay_walls.tres"
const WALLS_MAX_TICKS: int = 8000
const WALLS_BUILD_ORDER: Array[StringName] = [&"wall_west", &"tower_1"]
## The king waits on the castle side of the wall run, out of the crowd's way.
const WALLS_HOLD_POINT := Vector2(-8.0, 6.0)

const ECONOMY_MAP := "res://tests/fixtures/fixture_map_replay_economy.tres"
const ECONOMY_MAX_TICKS: int = 9000
## The castle tier II first (it opens the card pick), then each new building; the Field waits for
## the Mill's plot and is deferred by the bot until it stands.
const ECONOMY_BUILD_ORDER: Array[StringName] = [
	&"castle_plot",
	&"gold_mine_1",
	&"mill_1",
	&"field_1",
	&"harbor_1",
	&"shrine_1",
	&"tower_1",
	&"tower_2",
]
## The card the bot takes at the castle's tier II.
const ECONOMY_CARD_PICKS: Array[StringName] = [&"masons"]
## The king waits on the castle's east side, out of the west road's crowd.
const ECONOMY_HOLD_POINT := Vector2(6.0, 8.0)

const FULL_MAP := "res://data/maps/prototype_map.tres"
const FULL_KING := "res://data/king/king.tres"
const FULL_TUNING := "res://data/tuning/loop_tuning.tres"
const FULL_MAX_TICKS: int = 40000


## True for a name on the allowlist.
static func has(name: StringName) -> bool:
	return NAMES.has(name)


## The seed a scenario uses when none is given. 0 for an unknown name.
static func default_seed(name: StringName) -> int:
	return 1 if has(name) else 0


## The tick bound of a scenario (T-02-02, T-02-19). 0 for an unknown name.
static func max_ticks(name: StringName) -> int:
	if name == &"smoke":
		return SMOKE_MAX_TICKS
	if name == &"full_idle":
		return FULL_MAX_TICKS
	if name == &"army":
		return ARMY_MAX_TICKS
	if name == &"walls":
		return WALLS_MAX_TICKS
	if name == &"economy":
		return ECONOMY_MAX_TICKS
	return 0


## Runs scenario `name` with `run_seed` and returns the ReplayDriver result; an empty Dictionary for
## a name that is not on the allowlist. `on_tick`, when valid, is a read-only observer called with
## the RunContext after every step (ReplayDriver.run).
static func run(name: StringName, run_seed: int, on_tick: Callable = Callable()) -> Dictionary:
	if name == &"smoke":
		return _run_smoke(run_seed, on_tick)
	if name == &"full_idle":
		return _run_full_idle(run_seed, on_tick)
	if name == &"army":
		return _run_army(run_seed, on_tick)
	if name == &"walls":
		return _run_walls(run_seed, on_tick)
	if name == &"economy":
		return _run_economy(run_seed, on_tick)
	return {}


## The digest recorded in the golden file at `path` ("res://tests/golden/<scenario>.json") for the
## running platform (OS.get_name()), else its "default" entry. "" when the file, the digests table
## or both entries are missing.
static func golden_digest(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return ""
	var table: Dictionary = parsed
	var digests: Variant = table.get("digests")
	if not digests is Dictionary:
		return ""
	var by_platform: Dictionary = digests
	for key: String in PackedStringArray([OS.get_name(), DEFAULT_KEY]):
		var value: Variant = by_platform.get(key)
		if value is String and not (value as String).is_empty():
			return value
	return ""


static func _run_smoke(run_seed: int, on_tick: Callable) -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = SMOKE_BUILD_ORDER.duplicate()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = SMOKE_HOLD_POINT
	var map: MapConfig = load(SMOKE_MAP)
	var tuning: LoopTuning = load(SMOKE_TUNING)
	var king: KingDef = load(SMOKE_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, SMOKE_MAX_TICKS, 0, king, on_tick)


static func _run_army(run_seed: int, on_tick: Callable) -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = ARMY_BUILD_ORDER.duplicate()
	bot.king_mode = PlaytestBot.KING_DEFEND_NEAREST_THREAT
	bot.scripted_orders = ARMY_ORDERS.duplicate(true)
	bot.slam_min_enemies = ARMY_SLAM_MIN_ENEMIES
	var map: MapConfig = load(ARMY_MAP)
	var tuning: LoopTuning = load(SMOKE_TUNING)
	var king: KingDef = load(ARMY_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, ARMY_MAX_TICKS, 0, king, on_tick)


static func _run_walls(run_seed: int, on_tick: Callable) -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = WALLS_BUILD_ORDER.duplicate()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = WALLS_HOLD_POINT
	var map: MapConfig = load(WALLS_MAP)
	var tuning: LoopTuning = load(SMOKE_TUNING)
	var king: KingDef = load(SMOKE_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, WALLS_MAX_TICKS, 0, king, on_tick)


static func _run_economy(run_seed: int, on_tick: Callable) -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = ECONOMY_BUILD_ORDER.duplicate()
	bot.card_picks = ECONOMY_CARD_PICKS.duplicate()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = ECONOMY_HOLD_POINT
	var map: MapConfig = load(ECONOMY_MAP)
	var tuning: LoopTuning = load(SMOKE_TUNING)
	var king: KingDef = load(SMOKE_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, ECONOMY_MAX_TICKS, 0, king, on_tick)


static func _run_full_idle(run_seed: int, on_tick: Callable) -> Dictionary:
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	var map: MapConfig = load(FULL_MAP)
	var tuning: LoopTuning = load(FULL_TUNING)
	var king: KingDef = load(FULL_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, FULL_MAX_TICKS, 0, king, on_tick)
