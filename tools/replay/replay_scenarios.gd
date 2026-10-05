class_name ReplayScenarios
extends RefCounted
## The replay scenarios the CLI and the golden test may run (DEV-05), and the golden lookup they
## share. A scenario is a fixed map, tuning, king, scripted PlaytestBot and tick bound; the CLI
## accepts only the names in NAMES, so no argument ever picks a path to load.
##   smoke      - self-contained fixture data (tests/fixtures/fixture_*_replay_smoke.tres). Its
##                golden digest lives in tests/golden/smoke.json and moves only when the
##                simulation rules change, never when data/ is retuned.
##   full_idle  - the shipped prototype map, tuning and king played through all eight nights by the
##                balanced bot (the name is kept for CI; the king no longer idles, because an idle
##                king loses on night 1). No golden, because balance retunes change it. Two runs in
##                one process must agree.
## tools/ is excluded from the export.

const NAMES: Array[StringName] = [&"smoke", &"full_idle"]
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
	return 0


## Runs scenario `name` with `run_seed` and returns the ReplayDriver result; an empty Dictionary for
## a name that is not on the allowlist.
static func run(name: StringName, run_seed: int) -> Dictionary:
	if name == &"smoke":
		return _run_smoke(run_seed)
	if name == &"full_idle":
		return _run_full_idle(run_seed)
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


static func _run_smoke(run_seed: int) -> Dictionary:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.build_order = SMOKE_BUILD_ORDER.duplicate()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = SMOKE_HOLD_POINT
	var map: MapConfig = load(SMOKE_MAP)
	var tuning: LoopTuning = load(SMOKE_TUNING)
	var king: KingDef = load(SMOKE_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, SMOKE_MAX_TICKS, 0, king)


static func _run_full_idle(run_seed: int) -> Dictionary:
	var bot: PlaytestBot = PlaytestStrategies.make(&"balanced")
	var map: MapConfig = load(FULL_MAP)
	var tuning: LoopTuning = load(FULL_TUNING)
	var king: KingDef = load(FULL_KING)
	return ReplayDriver.run(map, tuning, run_seed, bot, FULL_MAX_TICKS, 0, king)
