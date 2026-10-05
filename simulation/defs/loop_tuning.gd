class_name LoopTuning
extends Resource
## Feel numbers for the day loop. Tuned at the Phase 2 playtest gate (D-09).
##
## The hold-to-build pace follows D-05 as amended by the owner (UAT G-01-58 and G-01-59): the first
## coins take `coin_drip_interval` each, later coins come faster down to `coin_drip_min_interval`,
## and every coin drips at its own due time (the shipped data sets no cap). The helpers below are
## pure, so tests, tools and the coin VFX share one schedule.

## D-05's documented range for the first coin's interval (seconds), inclusive. The data contract
## test and the coin VFX read these instead of keeping their own copies.
const COIN_DRIP_INTERVAL_MIN_S: float = 0.15
const COIN_DRIP_INTERVAL_MAX_S: float = 0.3
## No helper returns an interval shorter than this, so zero or negative data can never make coins
## free of time or spin a loop forever.
const MIN_INTERVAL_S: float = 0.001

## Seconds the first coin and every steady coin take (D-05 as amended, UAT G-01-58). The name is
## kept so existing overrides still compile.
@export var coin_drip_interval: float = 0.25
## Coins paid at the first interval before acceleration starts. The shipped count keeps the
## cheapest House hold at the UAT G-01-4 minimum.
@export var coin_drip_steady_coins: int = 2
## Each coin after the steady ones takes this fraction of the previous one's interval.
@export var coin_drip_decay: float = 0.9
## Floor for a coin's interval (seconds). Once the acceleration reaches it, every later coin takes
## exactly this long (owner, UAT G-01-59).
@export var coin_drip_min_interval: float = 0.05
## Optional cap on a whole hold (seconds). 0 or less, the shipped value since UAT G-01-59, means no
## cap. A positive value pays every coin still due at the cap in the frame the hold clock reaches
## it.
@export var max_build_hold_seconds: float = 0.0
## Metres (XZ distance, inclusive) within which the king can interact with a spot.
@export var interaction_radius: float = 2.5
## Seconds the start_night input must be held to end the day (D-11).
@export var start_night_hold_seconds: float = 1.5
## Seconds the enemy-free placeholder night lasts before dawn (D-12). Phase 2 replaces it.
@export var placeholder_night_seconds: float = 4.0
## Seconds dawn lasts before the next day starts.
@export var dawn_seconds: float = 2.0

## RED stub: the respawn data and helper arrive with the GREEN commit.
@export var respawn_start_seconds: float = 0.0
@export var respawn_step_seconds: float = 0.0
@export var respawn_cap_seconds: float = 0.0


func respawn_seconds(_knockout_number: int) -> float:
	return 0.0


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
## clamped to max_build_hold_seconds when that is above 0. 0.0 for coin_index <= 0. With a cap it
## returns as soon as the running sum reaches it; without one it sums one interval per coin up to
## coin_index, which is cheap at realistic costs (plan threat T-01-27).
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
