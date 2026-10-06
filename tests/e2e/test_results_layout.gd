extends GutTest
## G-02-2 (owner UAT 2026-10-06) on the real results scene: the visible gap from the last stat row
## to the buttons equals the gap between two stat rows. The Column puts the same separation between
## every child rect, but each stat Label rect carries empty font leading above its capitals while a
## button face fills its rect, so the Buttons row needs a little extra space above it. The scene is
## measured on its own (no run is bound), so nothing here can reload the scene or quit the game.

const RESULTS_SCENE := "res://ui/results/results_screen.tscn"
const COLUMN_PATH := "Center/Panel/Margin/Column"
const STAT_LABELS: Array[String] = [
	"NightsLabel", "GoldLabel", "BuildingsLostLabel", "KnockoutsLabel"
]
## The extra space above the button row, in pixels: 9 px of leading above the capitals of a stat
## label (Open Sans SemiBold 26 px from the default theme: ascent 28 against a cap height of about
## 19) plus the 2 px the focused button's outline reaches above its rect. Source: the diagnosis in
## .planning/debug/results-screen-button-gap.md. If the theme or the font changes, the focus-expand
## test below points at the number to recompute.
const BUTTON_ROW_EXTRA_PX: float = 11.0
const FOCUS_EXPAND_PX: float = 2.0
const SETTLE_FRAMES: int = 3

var _screen: Node


func before_each() -> void:
	var scene: PackedScene = load(RESULTS_SCENE)
	_screen = scene.instantiate()
	add_child_autofree(_screen)
	(_screen as CanvasLayer).visible = true
	_set_text("OutcomeLabel", "Victory")
	_set_text("NightsLabel", "Nights survived: 8 of 8")
	_set_text("GoldLabel", "Gold earned: 27")
	_set_text("BuildingsLostLabel", "Buildings lost: 4")
	_set_text("KnockoutsLabel", "King knockouts: 1")
	await wait_process_frames(SETTLE_FRAMES)


func test_stat_rows_stay_one_separation_apart() -> void:
	var separation: float = _separation()
	for i: int in range(STAT_LABELS.size() - 1):
		var upper: Rect2 = _rect(STAT_LABELS[i])
		var lower: Rect2 = _rect(STAT_LABELS[i + 1])
		assert_almost_eq(
			lower.position.y - upper.end.y,
			separation,
			0.01,
			"%s to %s is exactly the Column separation" % [STAT_LABELS[i], STAT_LABELS[i + 1]]
		)


func test_buttons_sit_the_row_gap_plus_the_leading_below_the_last_stat() -> void:
	var knockouts: Rect2 = _rect("KnockoutsLabel")
	var play_again: Rect2 = _rect("PlayAgainButton")
	assert_almost_eq(
		play_again.position.y,
		knockouts.end.y + _separation() + BUTTON_ROW_EXTRA_PX,
		0.01,
		"Play again starts Column separation + 11 px below the last stat label"
	)


func test_quit_shares_the_play_again_row() -> void:
	assert_almost_eq(
		_rect("QuitButton").position.y,
		_rect("PlayAgainButton").position.y,
		0.01,
		"Quit sits on the same row as Play again"
	)


func test_focus_outline_still_reaches_two_pixels_above_the_button() -> void:
	var button: Button = _screen.get_node("%PlayAgainButton") as Button
	var focus: StyleBox = button.get_theme_stylebox("focus")
	assert_almost_eq(
		focus.expand_margin_top,
		FOCUS_EXPAND_PX,
		0.01,
		"the 11 px is 9 px of label leading plus this outline reach: recompute it if this moves"
	)


func _separation() -> float:
	var column: Container = _screen.get_node(COLUMN_PATH) as Container
	return float(column.get_theme_constant("separation"))


func _rect(node_name: String) -> Rect2:
	return (_screen.get_node("%" + node_name) as Control).get_global_rect()


func _set_text(node_name: String, text: String) -> void:
	(_screen.get_node("%" + node_name) as Label).text = text
