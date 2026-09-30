class_name DawnPayoutVfx
extends Control
## Makes the dawn income visible and attributable (D-12, ECON-02): one gold coin pops out above
## each paying House, one per gold it pays, and flies to the HUD gold counter. When the last coin
## lands a "+X gold" total appears for a moment. Purely visual: the Economy was already credited
## when dawn began, and the HUD lags its readout behind the coins (see Hud).

## Emitted once per dawn_payout, before any coin launches, with the gold the coins of this payout
## will carry in all. The HUD holds its readout back by exactly this much, so what is held back and
## what lands can never disagree. 0 when nothing will fly.
signal payout_started(carried_total: int)
## Emitted once for every coin that reaches the gold counter, with the gold that coin carries.
## The amounts of one payout always sum to `carried_total` of its payout_started.
signal coin_landed(amount: int)

const COIN_SIZE := Vector2(22.0, 22.0)
const COIN_CENTER_COLOR := Color(1.0, 0.93, 0.5)
const COIN_EDGE_COLOR := Color(0.93, 0.62, 0.08)
const COIN_RIM_START: float = 0.8
const COIN_RIM_END: float = 0.9
## World-space offset above the plot where a coin starts.
const SPOT_ANCHOR := Vector3(0.0, 2.5, 0.0)
const STAGGER_SECONDS: float = 0.08
## Coin budget of one payout. A bigger payout puts several gold on each coin.
## A soft cap: every paying spot still sends at least one coin (attribution matters more than the
## budget), so a payout from more than MAX_COINS spots sends one coin per spot. The launch stagger
## (see launch_stagger) is what keeps the whole flight inside the dawn window either way.
const MAX_COINS: int = 12
## Largest gold amount one spot's payout is trusted to carry, far above any real income. Bigger
## (malformed) amounts are clamped to it so the carried sum cannot overflow an int.
const MAX_AMOUNT: int = 1_000_000
const POP_SECONDS: float = 0.15
const POP_HEIGHT_PX: float = 40.0
## Whole trip per coin: the pop plus the flight to the counter.
const TRIP_SECONDS: float = 0.6
## Slack kept between the last coin landing and the end of dawn. Dawn ends on the simulation clock
## and the coins fly on the process clock, so landing exactly at the boundary could put the last
## coin after it.
const DAWN_MARGIN_SECONDS: float = 0.15
const TOTAL_SHOWN_SECONDS: float = 2.0

var _ctx: RunContext
var _coin_texture: GradientTexture2D
var _launched: Dictionary = {}
var _launch_delays: Array[float] = []
## The delay tweens of the current payout's coins that have not launched yet.
var _launch_tweens: Array[Tween] = []
var _last_total: int = 0
var _expected_coins: int = 0
var _landed_coins: int = 0
var _pending_total: int = 0
var _generation: int = 0
var _total_tween: Tween

@onready var _gold_label: Label = %GoldLabel
@onready var _payout_total: Label = %PayoutTotal


## Binds the payout view to one run. A repeat call is ignored so no signal is connected twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_coin_texture = _make_coin_texture()
	if ctx.tuning.dawn_seconds <= TRIP_SECONDS:
		push_warning(
			(
				"dawn_seconds (%s) is not longer than one coin trip (%s): coins cannot land inside dawn"
				% [ctx.tuning.dawn_seconds, TRIP_SECONDS]
			)
		)
	ctx.events.dawn_payout.connect(_on_dawn_payout)


## Coins in the air (freed coins are not counted).
func live_coin_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


## The gold carried by the coins of the current payout once its "+X gold" total has been shown; 0
## until then, and again 0 as soon as a new payout begins. It equals the payout's claimed total
## whenever per_spot adds up to it.
func get_last_total() -> int:
	return _last_total


## Coins that have left `spot_id` during the current payout. Tests read it too.
func get_spawned_count(spot_id: StringName) -> int:
	return _launched.get(spot_id, 0)


## Seconds after the payout began at which each coin of the current payout launches, in launch
## order. Test hook, read-only: it lets a test check the schedule without waiting on the clock.
func get_launch_delays() -> Array[float]:
	return _launch_delays.duplicate()


## The delay tweens of the current payout's coins that have not launched yet. Test hook,
## read-only: it lets a test check that a superseding payout stopped them.
func get_launch_tweens() -> Array[Tween]:
	var waiting: Array[Tween] = []
	for tween: Tween in _launch_tweens:
		# A tween that has fired is finished, and so no longer valid: its coin has launched.
		if tween.is_valid():
			waiting.append(tween)
	return waiting


## Seconds between two coin launches for a payout of `coin_total` coins: STAGGER_SECONDS, tightened
## when needed so the last coin lands DAWN_MARGIN_SECONDS before the dawn window ends. Before
## bind_run there is no dawn window to fit, so the default applies. A dawn no longer than
## TRIP_SECONDS cannot be met: the stagger is then 0, every coin launches at once and lands after
## dawn (bind_run warns about it).
func launch_stagger(coin_total: int) -> float:
	if _ctx == null:
		return STAGGER_SECONDS
	var window: float = _ctx.tuning.dawn_seconds - TRIP_SECONDS - DAWN_MARGIN_SECONDS
	return clampf(window / float(maxi(coin_total - 1, 1)), 0.0, STAGGER_SECONDS)


func _make_coin_texture() -> GradientTexture2D:
	# Gold in the middle, a darker rim, then transparent so the square texture reads as a disc.
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, COIN_RIM_START, COIN_RIM_END])
	gradient.colors = PackedColorArray(
		[COIN_CENTER_COLOR, COIN_EDGE_COLOR, Color(COIN_EDGE_COLOR, 0.0)]
	)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture


func _on_dawn_payout(total: int, per_spot: Dictionary) -> void:
	_reset_for_new_payout()
	if total <= 0:
		payout_started.emit(0)
		return
	var amounts: Dictionary = _whole_amounts(per_spot)
	# The coin budget is spread over the gold that will actually fly, not over the claimed total.
	var carried_gold: int = 0
	for amount: int in amounts.values():
		carried_gold += maxi(amount, 0)
	var coin_counts: Dictionary = {}
	var coin_total: int = 0
	for spot_id: StringName in amounts:
		var count: int = _coins_for_amount(amounts[spot_id], carried_gold)
		coin_counts[spot_id] = count
		coin_total += count
	var stagger: float = launch_stagger(coin_total)
	# Plan every coin first, so the carried gold is announced before the first one can launch.
	var launches: Array[Dictionary] = []
	var carried: int = 0
	for spot_id: StringName in amounts:
		var amount: int = amounts[spot_id]
		var coin_count: int = coin_counts[spot_id]
		for coin: int in range(coin_count):
			var share: int = _coin_share(amount, coin_count, coin)
			carried += share
			launches.append(
				{"spot": spot_id, "delay": float(launches.size()) * stagger, "share": share}
			)
	_expected_coins = launches.size()
	# The "+X gold" label shows the gold the coins carry, the same figure the HUD readout is held
	# back by, so what the player watches fly, the counter and the label always agree. They differ
	# from the claimed total only if per_spot does not add up to it, which is worth knowing about.
	_pending_total = carried
	if carried != total:
		push_warning(
			(
				"dawn payout claims %d gold but its per-spot amounts carry %d; showing %d"
				% [total, carried, carried]
			)
		)
	payout_started.emit(carried)
	for launch: Dictionary in launches:
		_schedule_launch(launch["spot"], launch["delay"], launch["share"])
	# With no coin to fly (malformed per_spot) nothing lands and no total is shown: there is no gold
	# in the air to attribute, and the readout is not held back (payout_started carried 0).


## `per_spot` arrives as an untyped Dictionary, so each entry is checked and coerced once here: the
## spot id must be a name (it is stored as a StringName, which the loops in _on_dawn_payout rely on)
## and the amount a finite number, truncated to a whole one if it is a float and clamped to
## +/-MAX_AMOUNT. An entry that fails either check is dropped with a warning, so one bad entry
## cannot abort the whole payout.
func _whole_amounts(per_spot: Dictionary) -> Dictionary:
	var amounts: Dictionary = {}
	for spot_id: Variant in per_spot:
		var amount: Variant = per_spot[spot_id]
		var problem: String = ""
		if not (spot_id is StringName or spot_id is String):
			problem = "its spot id is a %s, not a name" % type_string(typeof(spot_id))
		elif amount is float and not is_finite(float(amount)):
			problem = "%s is not a finite number" % amount
		elif not (amount is int or amount is float):
			problem = "%s is not a number" % type_string(typeof(amount))
		if problem.is_empty():
			# Clamped before it becomes an int (a huge float has no defined int value) so that
			# neither the amount nor the sum of several can overflow and slip under MAX_COINS.
			var bounded: float = clampf(float(amount), -float(MAX_AMOUNT), float(MAX_AMOUNT))
			amounts[StringName(spot_id)] = int(bounded)
		else:
			push_warning("dawn payout for '%s' ignored: %s" % [spot_id, problem])
	return amounts


## One coin per gold while the gold that flies (`carried_gold`, the sum of the positive amounts)
## fits under MAX_COINS; otherwise the spot's share of MAX_COINS, at least one coin for any spot
## that pays.
func _coins_for_amount(amount: int, carried_gold: int) -> int:
	if amount <= 0:
		return 0
	if carried_gold <= MAX_COINS:
		return amount
	return clampi(floori(float(amount) * float(MAX_COINS) / float(carried_gold)), 1, amount)


## The gold coin `coin` (0-based) of `coin_count` carries; a spot's coins sum to its amount.
func _coin_share(amount: int, coin_count: int, coin: int) -> int:
	var remainder: int = amount % coin_count
	@warning_ignore("integer_division")
	var base: int = (amount - remainder) / coin_count
	return base + (1 if coin < remainder else 0)


func _reset_for_new_payout() -> void:
	_generation += 1
	_launched.clear()
	_launch_delays.clear()
	_expected_coins = 0
	_landed_coins = 0
	_pending_total = 0
	_last_total = 0
	if _total_tween != null:
		_total_tween.kill()
	# The generation guard would make a superseded launch a no-op anyway; killing the delay tweens
	# also stops them lingering until they fire.
	for tween: Tween in _launch_tweens:
		tween.kill()
	_launch_tweens.clear()
	_payout_total.visible = false
	for child: Node in get_children():
		child.queue_free()


func _schedule_launch(spot_id: StringName, delay: float, share: int) -> void:
	_launch_delays.append(delay)
	if delay <= 0.0:
		_launch_coin(spot_id, _generation, share)
		return
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(_launch_coin.bind(spot_id, _generation, share))
	_launch_tweens.append(tween)


func _launch_coin(spot_id: StringName, generation: int, share: int) -> void:
	if generation != _generation:
		return
	_launched[spot_id] = get_spawned_count(spot_id) + 1
	var coin: TextureRect = TextureRect.new()
	coin.texture = _coin_texture
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.size = COIN_SIZE
	add_child(coin)
	var start: Vector2 = start_point(spot_id) - COIN_SIZE * 0.5
	var target: Vector2 = _gold_label.get_global_rect().get_center() - COIN_SIZE * 0.5
	coin.global_position = start
	var tween: Tween = coin.create_tween()
	(
		tween
		. tween_property(coin, "global_position", start + Vector2(0.0, -POP_HEIGHT_PX), POP_SECONDS)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(coin, "global_position", target, TRIP_SECONDS - POP_SECONDS)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_callback(_on_coin_arrived.bind(coin, generation, share))


## Where the plot appears on screen; the middle of the screen if there is no camera or the plot is
## behind it, or the run is not bound yet. Public so a test can call it without reaching for a
## private member.
func start_point(spot_id: StringName) -> Vector2:
	if _ctx == null:
		return get_viewport_rect().size * 0.5
	var camera: Camera3D = get_viewport().get_camera_3d()
	var spot: BuildSpotDef = _ctx.buildings.get_spot(spot_id)
	if camera == null or spot == null:
		return get_viewport_rect().size * 0.5
	var world_pos: Vector3 = spot.position + SPOT_ANCHOR
	# unproject_position mirrors a point behind the camera onto the screen, so it needs the
	# fallback too.
	if camera.is_position_behind(world_pos):
		return get_viewport_rect().size * 0.5
	return camera.unproject_position(world_pos)


func _on_coin_arrived(coin: TextureRect, generation: int, share: int) -> void:
	coin.queue_free()
	if generation != _generation:
		return
	_landed_coins += 1
	coin_landed.emit(share)
	if _landed_coins >= _expected_coins:
		_show_total()


func _show_total() -> void:
	_last_total = _pending_total
	_payout_total.text = "+%d gold" % _last_total
	_payout_total.visible = true
	_total_tween = create_tween()
	_total_tween.tween_interval(TOTAL_SHOWN_SECONDS)
	_total_tween.tween_callback(_payout_total.set_visible.bind(false))
