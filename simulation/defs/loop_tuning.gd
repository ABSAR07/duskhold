class_name LoopTuning
extends Resource
## Feel numbers for the day loop. Tuned at the Phase 2 playtest gate (D-09).

## Seconds per coin while holding the action key (D-05). Top of D-05's 0.15-0.3 s range, raised
## from 0.2 after UAT G-01-4 (House I held only 0.4 s); still tuned at the Phase 2 playtest (D-09).
@export var coin_drip_interval: float = 0.3
## Metres (XZ distance, inclusive) within which the king can interact with a spot.
@export var interaction_radius: float = 2.5
## Seconds the start_night input must be held to end the day (D-11).
@export var start_night_hold_seconds: float = 1.5
## Seconds the enemy-free placeholder night lasts before dawn (D-12). Phase 2 replaces it.
@export var placeholder_night_seconds: float = 4.0
## Seconds dawn lasts before the next day starts.
@export var dawn_seconds: float = 2.0
