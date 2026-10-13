extends SceneTree
## Real-window contrast probe (plan 03-19, G-03-13). Reads one captured screenshot and measures how
## well a text reads against its immediate surround inside a rectangle of it, so the legibility
## claim about a HUD text is checked on the pixels the player sees and not only on node colours.
##
## Launch it through the wrapper, which adds the import warm-up, a timeout and the sentinel check:
##   bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56
##     --min=4.5
## The raw command it wraps (a runtime error inside still exits 0, so never trust the exit code
## alone, see tools/contrast_probe.sh):
##   godot --headless --path <project> -s res://tools/screenshot/contrast_probe.gd -- <arguments>
##
## Arguments (everything after `--`; anything else is a usage error):
##   --image=<path>     required; a .png under screenshots/ (relative to the project root or a
##                      res:// path; a path with a `..` segment is rejected)
##   --rect=x,y,w,h     required; four integers, x and y at least 0, w and h above 0
##   --min=<float>      optional; the lowest passing ratio, above 1.0, default 4.5
## Output: one line starting with CONTRAST_OK (ratio at least min, exit 0), CONTRAST_LOW (below
## min) or CONTRAST_FAILED (unreadable image, empty fill or backdrop set; both exit 1), or
## CONTRAST_USAGE on bad arguments (exit 64). tools/ is excluded from the export.
##
## The knocked-out king count: the HealthLabel's rect at 1280x720 is `--rect=280,648,96,56`.
## hud.tscn sets the KingWidget at offset_left 16, offset_top -72 and offset_bottom -16 (y
## 648..704), and the widget lays out ICON_SIZE 56 + ROW_SEPARATION 8 + BAR_SIZE.x 192 +
## ROW_SEPARATION 8 before the label (x 280), whose LABEL_MIN_WIDTH is 96 (to x 376). The digits'
## ink sits at about y 666..684 inside it.
##
## Measurement rule. Fill pixels are the text's own colour: red minus the larger of green and blue
## is at least FILL_KEY (the knocked-out #FF4040 keys at 0.75, the same fill dimmed to alpha 0.4 at
## about 0.27, the black outline at 0, the night and day grounds below 0). Backdrop pixels are the
## rect's other pixels with a fill pixel among their 8 neighbours: the glyphs' immediate surround,
## which lies inside the rendered outline (about 1 to 2 px wide at 1280x720). The text luminance is
## the TEXT_PERCENTILE of the fill pixels' relative luminance (the glyph cores, because
## anti-aliased edge pixels blend into the outline and read darker); the backdrop luminance is the
## median of the backdrop pixels'. The ratio is WCAG 2's (lighter + 0.05) / (darker + 0.05) over
## relative luminance; WCAG supplies the formula only, the surround rule above is this probe's own.

const EXIT_OK: int = 0
const EXIT_FAILED: int = 1
const EXIT_USAGE: int = 64

const RES := "res://"
const SHOT_ROOT := "res://screenshots"
const PNG_SUFFIX := ".png"
const DEFAULT_MIN_RATIO: float = 4.5
const FILL_KEY: float = 0.15
const TEXT_PERCENTILE: float = 0.9
const MEDIAN: float = 0.5
const LUMINANCE_OFFSET: float = 0.05
const RECT_PARTS: int = 4
const USAGE := "usage: --image=screenshots/<shot>.png --rect=x,y,w,h [--min=<ratio above 1.0>]"


## Parses the user arguments. Returns {error, image, rect, min_ratio}; `error` is "" when every
## argument passed, else a one-line reason. `image` comes back as a normalised res:// path and
## `rect` as a Rect2i.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"error": "",
		"image": "",
		"rect": Rect2i(),
		"min_ratio": DEFAULT_MIN_RATIO,
	}
	var seen: Dictionary = {"image": false, "rect": false}
	for arg: String in args:
		if arg.begins_with("--image="):
			parsed["image"] = _safe_image(arg.trim_prefix("--image="))
			seen["image"] = true
		elif arg.begins_with("--rect="):
			parsed["rect"] = _parse_rect(arg.trim_prefix("--rect="))
			seen["rect"] = true
		elif arg.begins_with("--min="):
			var text: String = arg.trim_prefix("--min=")
			if not text.is_valid_float() or text.to_float() <= 1.0:
				return _usage(parsed, "--min must be a number above 1.0, got '%s'" % text)
			parsed["min_ratio"] = text.to_float()
		else:
			return _usage(parsed, "unknown argument '%s'" % arg)
	return _validate(parsed, seen)


## Measures the contrast of the text inside `rect` of `image` (see the header). Returns {error,
## ratio, text_luminance, backdrop_luminance, fill_pixels, backdrop_pixels}; `error` is "" on a
## measurement and a one-line reason when the rect holds no fill pixels or no backdrop pixels.
static func measure(image: Image, rect: Rect2i) -> Dictionary:
	var result: Dictionary = {
		"error": "",
		"ratio": 0.0,
		"text_luminance": 0.0,
		"backdrop_luminance": 0.0,
		"fill_pixels": 0,
		"backdrop_pixels": 0,
	}
	var area: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if area.size.x <= 0 or area.size.y <= 0:
		result["error"] = "the rect lies outside the image"
		return result
	var mask: PackedByteArray = _fill_mask(image, area)
	var text: Array[float] = []
	var backdrop: Array[float] = []
	for row: int in range(area.size.y):
		for column: int in range(area.size.x):
			var color: Color = image.get_pixel(area.position.x + column, area.position.y + row)
			if mask[row * area.size.x + column] == 1:
				text.append(luminance(color))
			elif _touches_fill(mask, area.size, column, row):
				backdrop.append(luminance(color))
	result["fill_pixels"] = text.size()
	result["backdrop_pixels"] = backdrop.size()
	if text.is_empty():
		result["error"] = "no fill pixels in the rect"
		return result
	if backdrop.is_empty():
		result["error"] = "no backdrop pixels"
		return result
	text.sort()
	backdrop.sort()
	var text_luminance: float = _percentile(text, TEXT_PERCENTILE)
	var backdrop_luminance: float = _percentile(backdrop, MEDIAN)
	result["text_luminance"] = text_luminance
	result["backdrop_luminance"] = backdrop_luminance
	result["ratio"] = contrast_ratio(text_luminance, backdrop_luminance)
	return result


## WCAG 2 relative luminance of an sRGB colour (each channel linearised first).
static func luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


## (lighter + 0.05) / (darker + 0.05) of two relative luminances, in either order.
static func contrast_ratio(first: float, second: float) -> float:
	return (maxf(first, second) + LUMINANCE_OFFSET) / (minf(first, second) + LUMINANCE_OFFSET)


static func _linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)


## One byte per pixel of `area`, 1 where the pixel is the text's own colour.
static func _fill_mask(image: Image, area: Rect2i) -> PackedByteArray:
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(area.size.x * area.size.y)
	for row: int in range(area.size.y):
		for column: int in range(area.size.x):
			var color: Color = image.get_pixel(area.position.x + column, area.position.y + row)
			if color.r - maxf(color.g, color.b) >= FILL_KEY:
				mask[row * area.size.x + column] = 1
	return mask


## True when one of the 8 neighbours of (column, row) inside the area is a fill pixel.
static func _touches_fill(mask: PackedByteArray, size: Vector2i, column: int, row: int) -> bool:
	for offset_y: int in range(-1, 2):
		for offset_x: int in range(-1, 2):
			var x: int = column + offset_x
			var y: int = row + offset_y
			var inside: bool = x >= 0 and y >= 0 and x < size.x and y < size.y
			if inside and (offset_x != 0 or offset_y != 0) and mask[y * size.x + x] == 1:
				return true
	return false


static func _percentile(sorted_values: Array[float], fraction: float) -> float:
	return sorted_values[int(round(fraction * float(sorted_values.size() - 1)))]


## The res:// form of `raw` when it is a .png under res://screenshots/, else "". Rejects any `..`
## segment, an absolute path outside the project and a sibling that merely shares the prefix.
static func _safe_image(raw: String) -> String:
	var path: String = raw.replace("\\", "/").strip_edges()
	if path.is_empty() or ".." in path.split("/"):
		return ""
	if path.is_absolute_path() and not path.begins_with(RES):
		path = ProjectSettings.localize_path(path)
	elif not path.begins_with(RES):
		path = RES + path
	path = path.simplify_path()
	var prefix: String = SHOT_ROOT + "/"
	var named: bool = path.length() > prefix.length() + PNG_SUFFIX.length()
	if path.begins_with(prefix) and path.ends_with(PNG_SUFFIX) and named:
		return path
	return ""


## `text` as a Rect2i when it is four integers with x and y at least 0 and w and h above 0, else
## an empty Rect2i.
static func _parse_rect(text: String) -> Rect2i:
	var parts: PackedStringArray = text.split(",")
	if parts.size() != RECT_PARTS:
		return Rect2i()
	var numbers: Array[int] = []
	for part: String in parts:
		if not part.strip_edges().is_valid_int():
			return Rect2i()
		numbers.append(part.strip_edges().to_int())
	if numbers[0] < 0 or numbers[1] < 0 or numbers[2] <= 0 or numbers[3] <= 0:
		return Rect2i()
	return Rect2i(numbers[0], numbers[1], numbers[2], numbers[3])


static func _validate(parsed: Dictionary, seen: Dictionary) -> Dictionary:
	if not seen["image"]:
		return _usage(parsed, "--image is required")
	if String(parsed["image"]).is_empty():
		return _usage(parsed, "--image must be a .png under screenshots/ with no '..' segment")
	if not seen["rect"]:
		return _usage(parsed, "--rect is required")
	var rect: Rect2i = parsed["rect"]
	if rect.size.x <= 0 or rect.size.y <= 0:
		return _usage(parsed, "--rect must be x,y,w,h: four integers, x and y >= 0, w and h > 0")
	return parsed


static func _usage(parsed: Dictionary, reason: String) -> Dictionary:
	parsed["error"] = reason
	return parsed


func _initialize() -> void:
	var parsed: Dictionary = parse_args(OS.get_cmdline_user_args())
	var error: String = parsed["error"]
	if not error.is_empty():
		printerr("CONTRAST_USAGE %s" % error)
		printerr(USAGE)
		quit(EXIT_USAGE)
		return
	quit(_execute(parsed))


## Loads the image, measures it and prints the one result line. Returns the process exit code.
func _execute(parsed: Dictionary) -> int:
	var path: String = parsed["image"]
	var rect: Rect2i = parsed["rect"]
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		print("CONTRAST_FAILED could not read %s" % path)
		return EXIT_FAILED
	var result: Dictionary = measure(image, rect)
	var failure: String = result["error"]
	if not failure.is_empty():
		print("CONTRAST_FAILED %s image=%s" % [failure, path])
		return EXIT_FAILED
	var ratio: float = result["ratio"]
	var min_ratio: float = parsed["min_ratio"]
	var passed: bool = ratio >= min_ratio
	print(
		(
			"%s ratio=%.2f min=%.2f text_luminance=%.4f backdrop_luminance=%.4f"
			% [
				"CONTRAST_OK" if passed else "CONTRAST_LOW",
				ratio,
				min_ratio,
				result["text_luminance"],
				result["backdrop_luminance"],
			]
		),
		(
			" fill_pixels=%d backdrop_pixels=%d image=%s rect=%d,%d,%d,%d"
			% [
				result["fill_pixels"],
				result["backdrop_pixels"],
				path,
				rect.position.x,
				rect.position.y,
				rect.size.x,
				rect.size.y,
			]
		)
	)
	return EXIT_OK if passed else EXIT_FAILED
