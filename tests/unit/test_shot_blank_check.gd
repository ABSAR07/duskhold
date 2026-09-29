extends GutTest
## DEV-04: the screenshot runner must refuse a blank capture instead of saving it. The check is a
## pure function on an Image, so it is tested here without a renderer.

const WIDTH: int = 320
const HEIGHT: int = 180


func _filled(color: Color) -> Image:
	var image: Image = Image.create_empty(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


func _scene_like() -> Image:
	var image: Image = _filled(Color(0.35, 0.5, 0.35))
	for x: int in range(WIDTH):
		var shade: float = float(x) / float(WIDTH)
		image.fill_rect(Rect2i(x, 130, 1, 50), Color(shade, 0.3 + 0.4 * shade, 1.0 - shade))
	image.fill_rect(Rect2i(40, 60, 100, 60), Color(0.9, 0.7, 0.4))
	image.fill_rect(Rect2i(200, 20, 80, 120), Color(0.2, 0.25, 0.6))
	image.fill_rect(Rect2i(0, 0, 320, 20), Color(0.95, 0.95, 0.95))
	return image


func test_a_black_image_is_rejected() -> void:
	assert_ne(ShotRunner.blank_reason(_filled(Color.BLACK)), "", "all black is blank")


func test_a_flat_grey_image_is_rejected() -> void:
	assert_ne(ShotRunner.blank_reason(_filled(Color(0.5, 0.5, 0.5))), "", "one colour is blank")


func test_a_uniform_image_with_faint_noise_is_still_rejected() -> void:
	var image: Image = _filled(Color(0.4, 0.4, 0.4))
	image.set_pixel(10, 10, Color(0.41, 0.4, 0.4))
	assert_ne(ShotRunner.blank_reason(image), "", "a single pixel of noise is not a scene")


func test_a_scene_with_several_regions_is_accepted() -> void:
	assert_eq(ShotRunner.blank_reason(_scene_like()), "", "a varied image passes")
