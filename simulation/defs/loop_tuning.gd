class_name LoopTuning
extends Resource
## Feel numbers for the day loop. Tuned at the Phase 2 playtest gate (D-09).
##
## The hold-to-build pace follows D-05 as amended by the owner's UAT G-01-58 decision: the first
## coins take `coin_drip_interval` (0.25 s) each, later coins come faster, and a whole hold never
## lasts longer than `max_build_hold_seconds` (3 s). At the cap every remaining coin is paid at
## once. The helpers below are pure, so tests, tools and the coin VFX share one schedule.

## D-05's documented range for the first coin's interval (seconds), inclusive. The data contract
## test and the coin VFX read these instead of keeping their own copies.
const COIN_DRIP_INTERVAL_MIN_S: float = 0.15
const COIN_DRIP_INTERVAL_MAX_S: float = 0.3
## No helper returns an interval shorter than this, so zero or negative data can never make coins
## free of time or spin a loop forever.
const MIN_INTERVAL_S: float = 0.001

## Seconds the first coin and every steady coin take (D-05 as amended, UAT G-01-58: start at
## 0.25 s). The name is kept so existing overrides still compile.
@export var coin_drip_interval: float = 0.25
## Coins paid at the first interval before acceleration starts. Two keeps House I at 0.5 s (the
## UAT G-01-4 minimum).
@export var coin_drip_steady_coins: int = 2
## Each coin after the steady ones takes this fraction of the previous one's interval.
@export var coin_drip_decay: float = 0.9
## Floor for a coin's interval (seconds) so a long hold's stream stays readable.
@export var coin_drip_min_interval: float = 0.08
## Hard cap on a whole hold (seconds). When the hold clock reaches it every remaining coin is paid
## in that frame and the build completes. 0 or less means no cap.
@export var max_build_hold_seconds: float = 3.0
## Metres (XZ distance, inclusive) within which the king can interact with a spot.
@export var interaction_radius: float = 2.5
## Seconds the start_night input must be held to end the day (D-11).
@export var start_night_hold_seconds: float = 1.5
## Seconds the enemy-free placeholder night lasts before dawn (D-12). Phase 2 replaces it.
@export var placeholder_night_seconds: float = 4.0
## Seconds dawn lasts before the next day starts.
@export var dawn_seconds: float = 2.0


## Seconds the 1-based coin takes to drip. Positive and never increasing with the index, whatever
## the data says (sanitised): the first interval and the floor are at least MIN_INTERVAL_S, the
## decay is clamped to 0-1, the floor never exceeds the first interval and steady coins are at
## least 1.
func coin_interval(coin_index: int) -> float:
	var first: float = maxf(coin_drip_interval, MIN_INTERVAL_S)
	var steady: int = maxi(coin_drip_steady_coins, 1)
	if coin_index <= steady:
		return first
	var decay: float = clampf(coin_drip_decay, 0.0, 1.0)
	var floor_s: float = clampf(coin_drip_min_interval, MIN_INTERVAL_S, first)
	return maxf(floor_s, first * pow(decay, coin_index - steady))


## Seconds into the hold at which the 1-based coin is paid: the running sum of coin_interval(1..n),
## clamped to max_build_hold_seconds when that is above 0. 0.0 for coin_index <= 0. Returns the cap
## as soon as the running sum reaches it, so a call costs at most about cap / floor iterations
## instead of the coin count.
func coin_due_seconds(coin_index: int) -> float:
	if coin_index <= 0:
		return 0.0
	var capped: bool = max_build_hold_seconds > 0.0
	var total: float = 0.0
	for coin: int in range(1, coin_index + 1):
		total += coin_interval(coin)
		if capped and total >= max_build_hold_seconds:
			return max_build_hold_seconds
	return total


## Length in seconds of a full hold for a tier of this cost. Tests, the screenshot scenario and the
## coin VFX use it instead of multiplying cost by an interval. 0.0 for a cost of 0 or less.
func build_hold_seconds(cost: int) -> float:
	if cost <= 0:
		return 0.0
	return coin_due_seconds(cost)
