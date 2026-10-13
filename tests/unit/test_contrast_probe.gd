extends GutTest
## G-03-13 evidence tool: the pure functions of the real-window contrast probe
## (tools/screenshot/contrast_probe.gd). parse_args decides which file the script opens, so its
## rejection cases are pinned here (a `..` segment, a sibling prefix, an absolute path outside the
## project, a non-.png name, a bare `.png`); measure decides the pass or fail, so a red text on a
## black outline, the same text on a mid-grey surround and an image with no red are pinned too.
## The probe is a SceneTree script; its statics are called without running it.

const ContrastProbe := preload("res://tools/screenshot/contrast_probe.gd")
const IMAGE_SIZE := Vector2i(40, 20)
const TEXT_BLOCK := Rect2i(10, 6, 6, 8)
const FULL_RECT := Rect2i(0, 0, 40, 20)
const KNOCKED_OUT_RED := Color8(255, 64, 64)
const MID_GREY := Color8(128, 128, 128)
const MIN_RATIO: float = 4.5
const BLACK_OUTLINE_RATIO: float = 6.0
const GREY_RATIO: float = 1.2


## A 40x20 image of `surround`, with a TEXT_BLOCK of the knocked-out red in it and, when `outline`
## is set, a one pixel ring of that colour around the block.
func _image(surround: Color, outline: Color = Color.TRANSPARENT) -> Image:
	var image: Image = Image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(surround)
	if outline.a > 0.0:
		var ring: Rect2i = TEXT_BLOCK.grow(1)
		for y: int in range(ring.position.y, ring.end.y):
			for x: int in range(ring.position.x, ring.end.x):
				image.set_pixel(x, y, outline)
	for y: int in range(TEXT_BLOCK.position.y, TEXT_BLOCK.end.y):
		for x: int in range(TEXT_BLOCK.position.x, TEXT_BLOCK.end.x):
			image.set_pixel(x, y, KNOCKED_OUT_RED)
	return image


func _parse(args: Array[String]) -> Dictionary:
	return ContrastProbe.parse_args(PackedStringArray(args))


func test_red_text_on_a_black_outline_passes_the_wcag_threshold() -> void:
	var result: Dictionary = ContrastProbe.measure(_image(MID_GREY, Color.BLACK), FULL_RECT)
	assert_eq(result["error"], "", "a measurement")
	assert_gte(float(result["ratio"]), MIN_RATIO, "the outline carries the contrast")
	assert_almost_eq(float(result["ratio"]), BLACK_OUTLINE_RATIO, 0.1, "about 6.1")
	assert_eq(int(result["fill_pixels"]), TEXT_BLOCK.get_area(), "every red pixel is fill")
	assert_gt(int(result["backdrop_pixels"]), 0, "the ring is the backdrop")


func test_the_same_text_on_a_mid_grey_surround_fails_the_threshold() -> void:
	var result: Dictionary = ContrastProbe.measure(_image(MID_GREY), FULL_RECT)
	assert_eq(result["error"], "", "a measurement")
	assert_lt(float(result["ratio"]), MIN_RATIO, "red on grey does not read")
	assert_almost_eq(float(result["ratio"]), GREY_RATIO, 0.1, "about 1.15")


func test_an_image_with_no_red_has_no_fill_pixels() -> void:
	var image: Image = Image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(MID_GREY)
	var result: Dictionary = ContrastProbe.measure(image, FULL_RECT)
	assert_eq(result["error"], "no fill pixels in the rect", "an error, not a pass")
	assert_eq(float(result["ratio"]), 0.0, "and no ratio")


func test_a_rect_that_is_all_fill_has_no_backdrop() -> void:
	var inside_text: Rect2i = Rect2i(TEXT_BLOCK.position, Vector2i(2, 2))
	var result: Dictionary = ContrastProbe.measure(_image(MID_GREY, Color.BLACK), inside_text)
	assert_eq(result["error"], "no backdrop pixels", "nothing surrounds the fill in the rect")


func test_a_rect_outside_the_image_is_an_error() -> void:
	var result: Dictionary = ContrastProbe.measure(_image(MID_GREY), Rect2i(100, 100, 5, 5))
	assert_eq(result["error"], "the rect lies outside the image", "reported")


func test_luminance_and_the_ratio_follow_wcag_2() -> void:
	assert_almost_eq(ContrastProbe.luminance(Color.BLACK), 0.0, 0.0001, "black")
	assert_almost_eq(ContrastProbe.luminance(Color.WHITE), 1.0, 0.0001, "white")
	assert_almost_eq(ContrastProbe.contrast_ratio(1.0, 0.0), 21.0, 0.0001, "the maximum")
	assert_almost_eq(ContrastProbe.contrast_ratio(0.0, 1.0), 21.0, 0.0001, "in either order")
	assert_almost_eq(ContrastProbe.contrast_ratio(0.5, 0.5), 1.0, 0.0001, "equal is 1")
	assert_almost_eq(ContrastProbe.luminance(KNOCKED_OUT_RED), 0.253, 0.002, "the shipped red")


func test_a_screenshot_path_and_a_rect_are_accepted() -> void:
	var parsed: Dictionary = _parse(["--image=screenshots/a.png", "--rect=1,2,3,4"])
	assert_eq(parsed["error"], "", "accepted")
	assert_eq(parsed["image"], "res://screenshots/a.png", "as a res:// path")
	assert_eq(parsed["rect"], Rect2i(1, 2, 3, 4), "the rect")
	assert_eq(float(parsed["min_ratio"]), MIN_RATIO, "the default threshold")
	var explicit: Dictionary = _parse(
		["--image=res://screenshots/a.png", "--rect=0,0,1,1", "--min=3"]
	)
	assert_eq(explicit["error"], "", "a res:// path and --min are accepted")
	assert_eq(float(explicit["min_ratio"]), 3.0, "the threshold")


func test_an_absolute_path_inside_the_screenshots_folder_is_accepted() -> void:
	var inside: String = ProjectSettings.globalize_path("res://screenshots/a.png")
	var parsed: Dictionary = _parse(["--image=%s" % inside, "--rect=1,2,3,4"])
	assert_eq(parsed["error"], "", "the project's own screenshots folder")
	assert_eq(parsed["image"], "res://screenshots/a.png", "localised")


func test_every_unsafe_image_path_is_rejected() -> void:
	var outside: String = ProjectSettings.globalize_path("res://").get_base_dir().path_join("x.png")
	var bad: Array[String] = [
		"screenshots/../project.godot",
		"screenshots/../screenshots/a.png",
		"res://screenshots/../a.png",
		"res://screenshots_evil/x.png",
		"screenshots_evil/x.png",
		"res://screenshots/.png",
		"screenshots/.png",
		"screenshots/a.txt",
		"screenshots/a",
		"res://other/a.png",
		"a.png",
		"C:/Windows/a.png",
		"/etc/a.png",
		outside,
		"",
	]
	for path: String in bad:
		var parsed: Dictionary = _parse(["--image=%s" % path, "--rect=1,2,3,4"])
		assert_ne(parsed["error"], "", "rejected: '%s'" % path)
		assert_eq(parsed["image"], "", "no path survives: '%s'" % path)


func test_a_bad_rect_threshold_or_argument_is_a_usage_error() -> void:
	var image: String = "--image=screenshots/a.png"
	var cases: Array[Array] = [
		[image],
		["--rect=1,2,3,4"],
		[image, "--rect=1,2,3"],
		[image, "--rect=1,2,3,4,5"],
		[image, "--rect=-1,2,3,4"],
		[image, "--rect=1,2,0,4"],
		[image, "--rect=1,2,3,0"],
		[image, "--rect=a,b,c,d"],
		[image, "--rect=1,2,3,4", "--min=1.0"],
		[image, "--rect=1,2,3,4", "--min=abc"],
		[image, "--rect=1,2,3,4", "--extra"],
	]
	for args: Array in cases:
		var typed: Array[String] = []
		for arg: Variant in args:
			typed.append(str(arg))
		assert_ne(_parse(typed)["error"], "", "usage error for %s" % [typed])
