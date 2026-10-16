class_name ShotRunner
extends Node
## Captures one scripted scene of the prototype map as a PNG (DEV-04). Run through
## `bash tools/screenshot.sh`, never under `--headless`: the dummy renderer would save a blank
## image without any error, so this refuses to run there and also rejects near-uniform images.
##
## User args (after `--`): `--shot=<name>` (required), `--out=<dir>` (default res://screenshots).
## Exit codes: 0 saved, 1 scenario or image check failed, 2 no real renderer.

const MAP_SCENE_PATH := "res://presentation/map/prototype_map.tscn"
const DEFAULT_OUT := "res://screenshots"
const FIXED_RUN_SEED: int = 1
const SETTLE_FRAMES: int = 3
const SAMPLE_SIZE := Vector2i(64, 36)
const COLOR_LEVELS: float = 15.0
const MIN_LUMA_VARIANCE: float = 0.0005
const MIN_DISTINCT_COLORS: int = 8
const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_NO_RENDERER: int = 2
## The clear centre of the 1280x720 HUD (UI-SPEC "Layout", D-21): no visible HUD control sits in it
## on a shot whose name starts with one of CHECKED_PREFIXES, apart from the exempt nodes.
const PROTECTED_RECT := Rect2(384.0, 96.0, 512.0, 404.0)
const CHECKED_PREFIXES: Array[String] = ["hud_", "cmd_"]
## Nodes (and everything under them) allowed in the clear centre: the two shipped top-centre
## banners with their boxes, and the full-screen layers that only host world-anchored markers.
const EXEMPT_NODES: Array[StringName] = [
	&"PhaseBanner",
	&"PhaseBannerBox",
	&"RespawnLabel",
	&"RespawnBox",
	&"SpawnTelegraph",
	&"DawnPayoutVfx",
	&"DawnNoIncomeMarker",
	&"DebugOverlay",
]
## Full-rect layout nodes that draw nothing themselves.
const LAYOUT_ONLY_NODES: Array[StringName] = [&"HudRoot"]


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


## Every visible HUD control that draws something and reaches into PROTECTED_RECT, as one line each
## ("path rect"), except the exempt nodes and the drag box while it is being dragged. Containers
## that only lay out their children are skipped; their children are checked. Rects are the global
## rects of the canvas, which under canvas_items stretch is the 1280x720-based space.
static func protected_violations(hud: CanvasLayer) -> Array[String]:
	var found: Array[String] = []
	for child: Node in hud.get_children():
		_collect_violations(child, hud, found)
	return found


static func _collect_violations(node: Node, hud: CanvasLayer, found: Array[String]) -> void:
	var control: Control = node as Control
	if control == null:
		for child: Node in node.get_children():
			_collect_violations(child, hud, found)
		return
	if not control.visible or EXEMPT_NODES.has(control.name):
		return
	var box: DragBox = control as DragBox
	if box != null and box.is_dragging():
		return
	if _draws(control):
		var rect: Rect2 = control.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0 and rect.intersects(PROTECTED_RECT):
			found.append("%s %s" % [hud.get_path_to(control), rect])
	for child: Node in control.get_children():
		_collect_violations(child, hud, found)


## False for a node that only places its children: a plain container (a panel container draws its
## panel and counts) and the HudRoot; an empty label draws nothing.
static func _draws(control: Control) -> bool:
	if LAYOUT_ONLY_NODES.has(control.name):
		return false
	if control is Container and not (control is PanelContainer):
		return false
	var label: Label = control as Label
	return label == null or not label.text.is_empty()


## The protected-centre lines for a hud_ or cmd_ shot, empty for any other shot.
func _centre_offenders(shot_name: StringName, map_root: MapRoot) -> Array[String]:
	var checked: bool = false
	for prefix: String in CHECKED_PREFIXES:
		checked = checked or String(shot_name).begins_with(prefix)
	if not checked:
		return [] as Array[String]
	var hud: CanvasLayer = map_root.get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return [] as Array[String]
	return protected_violations(hud)


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
	var map_root: MapRoot = _spawn_map(shot_name)
	for _frame: int in range(SETTLE_FRAMES):
		await get_tree().process_frame
	var ok: bool = await ShotScenarios.run(shot_name, self, map_root)
	if not ok:
		printerr("scenario %s failed" % shot_name)
		get_tree().quit(EXIT_FAILED)
		return
	# The batched views (enemies, bars, puffs) upload their instances in _process, so a scenario that
	# stepped the simulation by hand needs one processed frame before the draw this captures.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var offenders: Array[String] = _centre_offenders(shot_name, map_root)
	ShotScenarios.cleanup()
	if not offenders.is_empty():
		printerr("%s: HUD controls inside the clear centre:" % shot_name)
		for offender: String in offenders:
			printerr("  %s" % offender)
		get_tree().quit(EXIT_FAILED)
		return
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


## The prototype map on the copy the shot needs (`ShotScenarios.map_for`). The run seed is fixed so
## a shot looks the same every time, and the results screen buttons stay inert so nothing can
## reload the scene or close the game while a scenario runs.
func _spawn_map(shot_name: StringName) -> MapRoot:
	var scene: PackedScene = load(MAP_SCENE_PATH)
	var map_root: MapRoot = scene.instantiate()
	map_root.map_config = ShotScenarios.map_for(shot_name)
	(map_root.get_node("King") as King).def = ShotScenarios.king_def_for(shot_name)
	map_root.fixed_run_seed = FIXED_RUN_SEED
	map_root.handle_results_actions = false
	add_child(map_root)
	return map_root
