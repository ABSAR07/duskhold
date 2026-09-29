class_name LoopTuning
extends Resource
## Feel numbers for the day loop. Tuned at the Phase 2 playtest gate (D-09).

## Seconds per coin while holding the action key (D-05).
@export var coin_drip_interval: float = 0.2
## Metres (XZ distance, inclusive) within which the king can interact with a spot.
@export var interaction_radius: float = 2.5
