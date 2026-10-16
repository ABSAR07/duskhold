class_name NavTuning
extends Resource
## Pathing tunables (ENMY-04, plan 04-06): the grid under the castle field and the small cache of
## goal fields that routes squads and the bot king round walls. Data, never code; the shipped
## values live in data/tuning/nav_tuning.tres and are pinned by test_nav_tuning_contract.
## WallValidation reports out-of-range numbers (T-04-13, T-04-15). Plan 04-07 adds the wall
## decision cadence, the notice range, the hysteresis and the stuck numbers (D-07 to D-09).

## Metres per grid cell. Smaller cells follow walls more closely and rebuild slower; authored
## gaps are at least 3 m wide (WallValidation.MIN_GAP_METRES) so 2 m cells keep every gap open.
@export var cell_size: float = 2.0
## Metres added around the map's content (castle, spots, spawns, wall ends) to size the grid.
@export var bounds_margin: float = 10.0
## Goal cells of a field are the open cells whose centres lie within the target's radius plus this.
@export var goal_margin: float = 0.8
## Goal fields kept for squads (and, in a cache of its own, the bot king).
@export var field_cache_size: int = 8
## Metres; goals that fall in one quantum-sized square share one cached field.
@export var goal_quantum: float = 4.0
## New or refreshed goal fields a cache may build in one tick; a request past it gets no field and
## the caller takes the straight step for that tick.
@export var field_builds_per_tick: int = 1
## Seconds after which a cached goal field is rebuilt on its next request.
@export var field_refresh_seconds: float = 0.5

## Seconds between two evaluations of one wall segment's time to destruction (D-08); each segment
## has its own phase, (tick + segment) % cadence, so the evaluations are spread over the cadence.
@export var wall_decision_seconds: float = 0.5
## Metres from a segment's face within which a blocked marcher counts as aggroed onto it (D-07)
## and may take it as its target when breaking through is faster than walking round.
@export var wall_notice_range: float = 12.0
## Segments of the same run on either side of an aggroed segment that count its crowd's damage.
@export var wall_neighbour_span: int = 2
## Seconds of slack before an enemy attacking a segment gives it up for the detour, so a crowd
## does not flip between breaking and walking at every rescan.
@export var wall_hysteresis_seconds: float = 0.5
## Seconds without progress (and without a target) after which an enemy is flagged stuck (D-09).
@export var stuck_seconds: float = 3.0
## Metres the route to the castle must shorten by within that time for an enemy to count as moving.
@export var stuck_progress_m: float = 0.5
