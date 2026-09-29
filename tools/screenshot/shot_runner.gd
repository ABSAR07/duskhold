class_name ShotRunner
extends Node
## Captures one scripted scene of the prototype map as a PNG (DEV-04). Run through
## `bash tools/screenshot.sh`, never under `--headless`: the dummy renderer would save a blank
## image without any error, so this refuses to run there and also rejects near-uniform images.
##
## User args (after `--`): `--shot=<name>` (required), `--out=<dir>` (default res://screenshots).
## Exit codes: 0 saved, 1 scenario or image check failed, 2 no real renderer.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const MAP_DATA_PATH := "res://data/maps/prototype_map.tres"
const DEFAULT_OUT := "res://screenshots"
const SHOT_STARTING_GOLD: int = 30
const SETTLE_FRAMES: int = 3
const SAMPLE_SIZE := Vector2i(64, 36)
const COLOR_LEVELS: float = 15.0
const MIN_LUMA_VARIANCE: float = 0.0005
const MIN_DISTINCT_COLORS: int = 8
const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_NO_RENDERER: int = 2


func _ready() -> void:
	var args: Dictionary = _parse_args(OS.get_cmdline_user_args())
	var shot_name: String = args.get("shot", "")
	var out_dir: String = args.get("out", DEFAULT_OUT)
	if DisplayServer.get_name() == "headless":
		printerr("screenshots need a real renderer; never run under --headless")
		get_tree().quit(EXIT_NO_RENDERER)
		return
	if shot_name.is_empty():
		printerr("missing --shot=<name>")
		get_tree().quit(EXIT_FAILED)
		return
	_capture(StringName(shot_name), out_dir)


## Returns "" when the image looks like a real render, otherwise the reason it does not. A
## blank or single-colour frame has almost no luminance variance and very few distinct colours.
static func blank_reason(image: Image) -> String:
	var sample: Image = image.duplicate()
	sample.resize(SAMPLE_SIZE.x, SAMPLE_SIZE.y, Image.INTERPOLATE_BILINEAR)
	var lumas: PackedFloat32Array = PackedFloat32Array()
	var colors: Dictionary = {}
	for y: int in range(sample.get_height()):
		for x: int in range(sample.get_width()):
			var pixel: Color = sample.get_pixel(x, y)
			lumas.append(0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b)
			colors[_quantize(pixel)] = true
	var mean: float = 0.0
	for luma: float in lumas:
		mean += luma
	mean /= float(lumas.size())
	var variance: float = 0.0
	for luma: float in lumas:
		variance += (luma - mean) * (luma - mean)
	variance /= float(lumas.size())
	if variance < MIN_LUMA_VARIANCE:
		return "luminance variance %.6f is below %.4f" % [variance, MIN_LUMA_VARIANCE]
	if colors.size() < MIN_DISTINCT_COLORS:
		return "only %d distinct colours (need %d)" % [colors.size(), MIN_DISTINCT_COLORS]
	return ""


## Packs a colour into 4 bits per channel.
static func _quantize(color: Color) -> int:
	var red: int = roundi(color.r * COLOR_LEVELS)
	var green: int = roundi(color.g * COLOR_LEVELS)
	var blue: int = roundi(color.b * COLOR_LEVELS)
	return (red << 8) | (green << 4) | blue


static func _parse_args(user_args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	for arg: String in user_args:
		if arg.begins_with("--shot="):
			parsed["shot"] = arg.trim_prefix("--shot=")
		elif arg.begins_with("--out="):
			parsed["out"] = arg.trim_prefix("--out=")
	return parsed


func _capture(shot_name: StringName, out_dir: String) -> void:
	var map_root: MapRoot = _spawn_map()
	for _frame: int in range(SETTLE_FRAMES):
		await get_tree().process_frame
	var ok: bool = await ShotScenarios.run(shot_name, self, map_root)
	if not ok:
		printerr("scenario %s failed" % shot_name)
		get_tree().quit(EXIT_FAILED)
		return
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	ShotScenarios.cleanup()
	var reason: String = blank_reason(image)
	if not reason.is_empty():
		printerr("refusing to save %s: image looks blank (%s)" % [shot_name, reason])
		get_tree().quit(EXIT_FAILED)
		return
	var target: String = "%s/%s.png" % [out_dir, shot_name]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var error: int = image.save_png(target)
	if error != OK:
		printerr("could not save %s (error %d)" % [target, error])
		get_tree().quit(EXIT_FAILED)
		return
	print("saved %s" % target)
	get_tree().quit(EXIT_OK)


## The prototype map with enough starting gold to show several buildings in one scene.
func _spawn_map() -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	var config: MapConfig = (load(MAP_DATA_PATH) as MapConfig).duplicate(true)
	config.starting_gold = SHOT_STARTING_GOLD
	map_root.map_config = config
	add_child(map_root)
	return map_root
