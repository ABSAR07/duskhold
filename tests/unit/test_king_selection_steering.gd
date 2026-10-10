extends GutTest
## D-15 as amended at the 03-07 checkpoint (owner decision, 2026-10-10): while a squad is selected
## all movement input goes to the selection and the king does not move; with nothing selected the
## king is the implicit selection and the movement input steers him as before. The rule lives at
## the one point where the king reads movement, so the keyboard and the gamepad stick are covered
## alike. Sprint, the build hold, the ability and start-night are not movement and are not
## touched here.

const LEFT := Vector2(-1.0, 0.0)
const DIAGONAL := Vector2(0.6, -0.8)


func test_a_selection_takes_the_whole_movement_input() -> void:
	for raw: Vector2 in [LEFT, DIAGONAL, Vector2(0.2, 0.2), Vector2.ZERO]:
		assert_eq(King.steered_direction(raw, true), Vector2.ZERO, "%s goes to the selection" % raw)


func test_without_a_selection_the_king_steers_exactly_as_before() -> void:
	for raw: Vector2 in [LEFT, DIAGONAL, Vector2(0.2, 0.2), Vector2.ZERO]:
		assert_eq(King.steered_direction(raw, false), raw, "%s steers the king" % raw)
