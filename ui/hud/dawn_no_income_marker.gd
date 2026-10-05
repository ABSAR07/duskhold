class_name DawnNoIncomeMarker
extends Control
## D-14, LOOP-05: at dawn a crossed-out coin hangs over every economic building that was rebuilt, so
## the player sees at a glance which Houses pay nothing this morning while the surviving Houses'
## coins fly to the gold counter. The marks fade when the day starts. Display only: it reads the
## rebuilt list the dawn announces and never writes the simulation. Mouse input is ignored.

## Size of one mark, the same coin the payout flies.
const MARK_SIZE := Vector2(26.0, 26.0)
## The red bar across the coin, from its lower left to its upper right, in mark space.
const BAR_FROM := Vector2(2.0, 24.0)
const BAR_TO := Vector2(24.0, 2.0)
const BAR_WIDTH: float = 4.0
const BAR_COLOR := Color(0.86, 0.1, 0.1)
## Seconds the marks take to fade out once the day starts.
const FADE_SECONDS: float = 0.5
## Group of every mark this node creates, so only marks are counted and freed as marks.
const MARK_GROUP := &"dawn_no_income_mark"

var _ctx: RunContext
var _coin_texture: GradientTexture2D
## One entry per live mark, in the order the marks were created (MapConfig order):
## {spot: StringName, node: Control}.
var _marks: Array[Dictionary] = []


## Binds the marker to one run. A repeat call is ignored so no signal is connected twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_coin_texture = DawnPayoutVfx.make_coin_texture()
	ctx.events.buildings_rebuilt.connect(_on_buildings_rebuilt)
	ctx.events.day_started.connect(_on_day_started)


func _process(_delta: float) -> void:
	for mark: Dictionary in _marks:
		var node: Control = mark["node"]
		node.position = (
			DawnPayoutVfx.spot_screen_point(_ctx, get_viewport(), mark["spot"]) - MARK_SIZE * 0.5
		)


## Marks currently shown, those still fading included. 0 by night and once the day's fade is done.
func marker_count() -> int:
	return _marks.size()


## The spots wearing a mark, in the order the marks were created (MapConfig order). A fresh array.
func marked_spots() -> Array[StringName]:
	var spots: Array[StringName] = []
	for mark: Dictionary in _marks:
		spots.append(mark["spot"])
	return spots


## One mark per rebuilt building whose current tier pays income, in the order listed. A building
## that never pays (a Tower) is not marked: there is no income to miss.
func _on_buildings_rebuilt(spot_ids: Array) -> void:
	_clear_marks()
	for spot_id: StringName in spot_ids:
		if _pays_income(spot_id):
			_add_mark(spot_id)


func _on_day_started(_day_number: int) -> void:
	for mark: Dictionary in _marks.duplicate():
		_fade_out(mark)


func _pays_income(spot_id: StringName) -> bool:
	var building_def: BuildingDef = _ctx.buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return false
	var tier_def: BuildingTierDef = building_def.tier_def(_ctx.buildings.current_tier(spot_id))
	return tier_def != null and tier_def.dawn_income > 0


func _add_mark(spot_id: StringName) -> void:
	var node: Control = Control.new()
	node.name = "NoIncome_%s" % spot_id
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.size = MARK_SIZE
	node.add_to_group(MARK_GROUP)
	var coin: TextureRect = TextureRect.new()
	coin.texture = _coin_texture
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.size = MARK_SIZE
	node.add_child(coin)
	var bar: Line2D = Line2D.new()
	bar.points = PackedVector2Array([BAR_FROM, BAR_TO])
	bar.width = BAR_WIDTH
	bar.default_color = BAR_COLOR
	bar.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bar.end_cap_mode = Line2D.LINE_CAP_ROUND
	node.add_child(bar)
	add_child(node)
	node.position = (
		DawnPayoutVfx.spot_screen_point(_ctx, get_viewport(), spot_id) - MARK_SIZE * 0.5
	)
	_marks.append({"spot": spot_id, "node": node})


func _fade_out(mark: Dictionary) -> void:
	var node: Control = mark["node"]
	var fade: Tween = node.create_tween()
	fade.tween_property(node, "modulate:a", 0.0, FADE_SECONDS)
	fade.tween_callback(_finish_fade.bind(mark))


## A faded mark leaves the count and is freed.
func _finish_fade(mark: Dictionary) -> void:
	_marks.erase(mark)
	(mark["node"] as Control).queue_free()


## Removes every mark at once, those still fading included.
func _clear_marks() -> void:
	for mark: Dictionary in _marks:
		(mark["node"] as Control).queue_free()
	_marks.clear()
	for node: Node in get_tree().get_nodes_in_group(MARK_GROUP):
		if is_ancestor_of(node):
			node.queue_free()
