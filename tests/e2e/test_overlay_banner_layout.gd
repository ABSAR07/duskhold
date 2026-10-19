extends GutTest
## G-04-6 (UAT test 6): the F3 overlay's panel sat in the night banner's band and hid its last
## word at the 1280x720 base size (and so at every 16:9, 16:10 and 4:3 window, because the project
## stretches canvas_items with aspect expand). The real map is laid out in a 1280x720 SubViewport
## with a stress-night row set open, and only Y coordinates are asserted: the CI fallback font for
## Consolas has other glyph widths, so an x check would measure differently on Linux, but a line
## height barely moves. The HUD (banner y 40 to 100, 36 px) is the reference and is never changed.

const BASE_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES: int = 3
const RUN_SEED: int = 11
const TOGGLE_ACTION := &"toggle_debug_overlay"
const BANNER_TEXT := "Night 8 of 8 — 300 enemies left"
## The stress night's overlay shape (04-08): 30 lines in the left column, 19 in the right.
const LEFT_LINES: int = 30
const RIGHT_LINES: int = 19
const MAX_EXTRA_SECTIONS: int = 40

var _viewport: SubViewport
var _map_root: MapRoot
var _overlay: DebugOverlay
var _hud: Node


func after_each() -> void:
	E2eSupport.release_all_actions()


## The real map in a 1280x720 SubViewport, a night started so the banner shows, the banner text of
## a 300-enemy night, the fast-forward label up, extra sections registered until the overlay lays
## out the stress-night shape, then the overlay opened (which renders at once).
func _stress_night_layout() -> void:
	_viewport = SubViewport.new()
	_viewport.size = BASE_SIZE
	add_child_autofree(_viewport)
	var scene: PackedScene = load(E2eSupport.MAP_SCENE_PATH)
	_map_root = scene.instantiate()
	_map_root.map_config = E2eSupport.shipped_prototype_map()
	_map_root.fixed_run_seed = RUN_SEED
	_map_root.handle_results_actions = false
	_viewport.add_child(_map_root)
	await wait_process_frames(SETTLE_FRAMES)
	var ctx: RunContext = _map_root.get_context()
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "night started")
	await wait_process_frames(SETTLE_FRAMES)
	_hud = _map_root.get_node("HUD")
	var banner: Label = _hud.get_node("%PhaseBanner") as Label
	banner.text = BANNER_TEXT
	var fast_forward: Label = _hud.get_node("%FastForwardLabel") as Label
	fast_forward.visible = true
	_overlay = _hud.get_node("DebugOverlay") as DebugOverlay
	await _open_overlay()
	_grow_to_the_stress_shape()


## Registers one two-line section at a time, refreshing on synthetic time, until the left column
## holds LEFT_LINES lines and the right one RIGHT_LINES: the stress night's shape and no taller.
func _grow_to_the_stress_shape() -> void:
	var left: Label = _overlay.get_node("%OverlayText") as Label
	var right: Label = _overlay.get_node("%OverlayTextRight") as Label
	for index: int in MAX_EXTRA_SECTIONS:
		if _lines(left) >= LEFT_LINES and right.visible and _lines(right) >= RIGHT_LINES:
			return
		_overlay.register_section("Stress %d" % index, _one_row)
		_overlay._advance_refresh(DebugOverlay.REFRESH_INTERVAL_S)


func _one_row() -> Array:
	return [["Row", "stress"]]


func _open_overlay() -> void:
	Input.action_press(TOGGLE_ACTION)
	await wait_process_frames(2)
	Input.action_release(TOGGLE_ACTION)
	await wait_process_frames(SETTLE_FRAMES)


func _lines(label: Label) -> int:
	return label.text.split("\n").size()


func _panel() -> PanelContainer:
	return _overlay.get_node("Panel") as PanelContainer


func test_the_stress_night_row_set_is_the_shape_under_test() -> void:
	await _stress_night_layout()
	var left: Label = _overlay.get_node("%OverlayText") as Label
	var right: Label = _overlay.get_node("%OverlayTextRight") as Label
	assert_true(_overlay.visible, "the overlay is open")
	assert_true(right.visible, "the two-column case is the one under test")
	assert_gte(_lines(left), LEFT_LINES, "at least the stress night's left column")
	assert_gte(_lines(right), RIGHT_LINES, "at least the stress night's right column")


func test_the_panel_starts_at_or_below_the_bottom_of_the_banner_box() -> void:
	await _stress_night_layout()
	var banner_box: Control = _hud.get_node("PhaseBannerBox") as Control
	assert_true((_hud.get_node("%PhaseBanner") as Label).visible, "the banner is up")
	assert_gte(
		_panel().get_global_rect().position.y,
		banner_box.get_global_rect().end.y,
		"the panel top is not above the banner box bottom"
	)


func test_the_panel_never_overlaps_the_fast_forward_label_on_y() -> void:
	await _stress_night_layout()
	var fast_forward: Label = _hud.get_node("%FastForwardLabel") as Label
	assert_true(fast_forward.visible, "the label is up")
	var panel_rect: Rect2 = _panel().get_global_rect()
	var label_rect: Rect2 = fast_forward.get_global_rect()
	var clear_above: bool = panel_rect.end.y <= label_rect.position.y
	var clear_below: bool = panel_rect.position.y >= label_rect.end.y
	assert_true(clear_above or clear_below, "no shared rows with the fast-forward label")


func test_a_full_stress_night_row_set_ends_on_screen() -> void:
	await _stress_night_layout()
	var bottom: float = _panel().get_global_rect().end.y
	assert_lte(bottom, float(BASE_SIZE.y), "the last overlay row ends at or above y 720")
