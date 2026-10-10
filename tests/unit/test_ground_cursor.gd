extends GutTest
## INPT-02, D-12, T-03-15 (RESEARCH Pattern 6): GroundCursor is the pad's screen-space aiming point.
## Pure and node-free: it starts where it is told (the king's projected ground point), moves with
## the right stick at a speed in pixels per second, and is clamped 48 px inside the visible rect
## (SpawnTelegraph.EDGE_MARGIN_PX) so the point it releases on is always on the screen.

const SPEED: float = 900.0
const MARGIN: float = SpawnTelegraph.EDGE_MARGIN_PX
const RECT := Rect2(0.0, 0.0, 1280.0, 720.0)


func test_a_new_cursor_is_inactive() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	assert_false(cursor.is_active(), "nothing is aimed yet")


func test_start_places_the_cursor_at_the_given_point_and_activates_it() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(640.0, 360.0))
	assert_true(cursor.is_active(), "active")
	assert_eq(cursor.position(), Vector2(640.0, 360.0), "where it was told")


func test_the_stick_moves_it_at_the_speed_in_pixels_per_second() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(100.0, 100.0))
	cursor.move(Vector2(1.0, 0.0), 0.5, SPEED)
	assert_almost_eq(cursor.position().x, 550.0, 0.001, "450 px right in half a second")
	assert_almost_eq(cursor.position().y, 100.0, 0.001, "and not up or down")


func test_a_half_push_is_half_as_fast_and_a_diagonal_goes_both_ways() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(100.0, 100.0))
	cursor.move(Vector2(0.5, 0.0), 1.0, SPEED)
	assert_almost_eq(cursor.position().x, 550.0, 0.001, "an analog push scales the speed")
	cursor.move(Vector2(-1.0, 1.0).normalized(), 1.0, SPEED)
	assert_lt(cursor.position().x, 550.0, "left")
	assert_gt(cursor.position().y, 100.0, "and down")


func test_an_inactive_cursor_does_not_move() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.move(Vector2(1.0, 1.0), 1.0, SPEED)
	assert_eq(cursor.position(), Vector2.ZERO, "it stays where it was")
	assert_false(cursor.is_active(), "and stays inactive")


func test_clamp_allows_exactly_the_margin_and_pulls_in_anything_closer() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(MARGIN, MARGIN))
	cursor.clamp_to(RECT, MARGIN)
	assert_eq(cursor.position(), Vector2(MARGIN, MARGIN), "48 px from the top-left is allowed")
	cursor.start(Vector2(MARGIN - 1.0, MARGIN - 1.0))
	cursor.clamp_to(RECT, MARGIN)
	assert_eq(cursor.position(), Vector2(MARGIN, MARGIN), "47 px is pulled in to 48")
	cursor.start(Vector2(1280.0 - MARGIN, 720.0 - MARGIN))
	cursor.clamp_to(RECT, MARGIN)
	assert_eq(cursor.position(), Vector2(1232.0, 672.0), "48 px from the bottom-right is allowed")
	cursor.start(Vector2(1280.0 - MARGIN + 1.0, 720.0 - MARGIN + 1.0))
	cursor.clamp_to(RECT, MARGIN)
	assert_eq(cursor.position(), Vector2(1232.0, 672.0), "47 px is pulled in")


func test_clamp_keeps_a_point_far_outside_the_rect_inside_it() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(-5000.0, 9000.0))
	cursor.clamp_to(RECT, MARGIN)
	assert_eq(cursor.position(), Vector2(MARGIN, 720.0 - MARGIN), "bottom-left corner, inset")


func test_clamp_uses_the_rects_own_origin() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(0.0, 0.0))
	cursor.clamp_to(Rect2(100.0, 50.0, 400.0, 300.0), MARGIN)
	assert_eq(cursor.position(), Vector2(148.0, 98.0), "inset from the rect, not the screen")


func test_a_rect_too_small_for_the_margin_still_holds_the_cursor_inside() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	var tiny: Rect2 = Rect2(0.0, 0.0, 64.0, 64.0)
	cursor.start(Vector2(1000.0, -1000.0))
	cursor.clamp_to(tiny, MARGIN)
	assert_true(tiny.has_point(cursor.position()), "inside even when 48 px would not fit")


func test_stop_deactivates_it() -> void:
	var cursor: GroundCursor = GroundCursor.new()
	cursor.start(Vector2(640.0, 360.0))
	cursor.stop()
	assert_false(cursor.is_active(), "no longer aimed")
	cursor.move(Vector2(1.0, 0.0), 1.0, SPEED)
	assert_false(cursor.is_active(), "and moving does not wake it")
