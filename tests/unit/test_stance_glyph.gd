extends GutTest
## UI-01 / D-23 (plan 03-05): the two code-drawn pieces of a squad slot that need no scene. The
## stance glyph maps each stance to its own shape (five shapes that read without colour, plus a
## fallback), and the bow icon is a drawn texture that is not the sword.

const ICON_SIZE: int = 32
const GLYPH_SIZE := Vector2(20.0, 20.0)


func _five_stances() -> Array[StringName]:
	return [
		SquadOrder.STANCE_POST,
		SquadOrder.STANCE_FOLLOW,
		SquadOrder.STANCE_HOLD,
		SquadOrder.STANCE_PATROL,
		SquadOrder.VERB_ATTACK_MOVE,
	]


func _opaque_pixels(texture: ImageTexture) -> int:
	var image: Image = texture.get_image()
	var count: int = 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				count += 1
	return count


func test_every_stance_has_a_shape_of_its_own() -> void:
	var seen: Dictionary = {}
	for stance: StringName in _five_stances():
		var shape: StringName = StanceGlyph.shape_for(stance)
		assert_ne(shape, &"", "%s has a shape" % stance)
		assert_false(seen.has(shape), "%s does not repeat an earlier shape" % stance)
		seen[shape] = stance
	assert_eq(seen.size(), 5, "five stances, five shapes")


func test_an_unknown_stance_falls_back_to_a_shape_that_is_none_of_the_five() -> void:
	var fallback: StringName = StanceGlyph.shape_for(&"not_a_stance")
	assert_ne(fallback, &"", "the fallback is still a shape")
	for stance: StringName in _five_stances():
		assert_ne(fallback, StanceGlyph.shape_for(stance), "not the shape of %s" % stance)
	assert_eq(StanceGlyph.shape_for(&""), fallback, "an empty stance falls back the same way")


func test_the_glyph_is_twenty_by_twenty_and_ignores_the_mouse() -> void:
	var glyph: StanceGlyph = StanceGlyph.new()
	add_child_autofree(glyph)
	assert_eq(glyph.custom_minimum_size, GLYPH_SIZE, "20x20")
	assert_eq(glyph.mouse_filter, Control.MOUSE_FILTER_IGNORE, "it never takes a click")


func test_setting_the_stance_changes_the_shape_it_draws() -> void:
	var glyph: StanceGlyph = StanceGlyph.new()
	add_child_autofree(glyph)
	for stance: StringName in _five_stances():
		glyph.stance = stance
		assert_eq(glyph.current_shape(), StanceGlyph.shape_for(stance), "draws %s" % stance)


func test_a_new_glyph_starts_on_the_post_shape() -> void:
	var glyph: StanceGlyph = StanceGlyph.new()
	add_child_autofree(glyph)
	assert_eq(glyph.current_shape(), StanceGlyph.shape_for(SquadOrder.STANCE_POST), "post")


func test_the_bow_texture_is_drawn_at_the_requested_size() -> void:
	var texture: ImageTexture = BowIcon.make_texture(ICON_SIZE)
	assert_eq(texture.get_width(), ICON_SIZE, "width")
	assert_eq(texture.get_height(), ICON_SIZE, "height")
	var opaque: int = _opaque_pixels(texture)
	assert_gt(opaque, ICON_SIZE, "something is drawn")
	assert_lt(opaque, ICON_SIZE * ICON_SIZE / 2, "on a mostly transparent square")


func test_the_bow_is_not_the_sword() -> void:
	var bow: PackedByteArray = BowIcon.make_texture(ICON_SIZE).get_image().get_data()
	var sword: PackedByteArray = SwordIcon.make_texture(ICON_SIZE).get_image().get_data()
	assert_ne(bow, sword, "the two unit icons differ")


func test_the_bow_texture_is_white_so_a_modulate_can_dim_it() -> void:
	var image: Image = BowIcon.make_texture(ICON_SIZE).get_image()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.0:
				assert_eq(
					Color(pixel.r, pixel.g, pixel.b), Color.WHITE, "(%d, %d) is white" % [x, y]
				)
				return
	fail_test("no opaque pixel found")
