class_name Squad
extends RefCounted
## One squad record. A squad is keyed by the military building spot id, which is stable for the
## whole run: it is created the first time its building stands and never deleted, so a fallen
## building keeps its squad and the dawn rebuild restores it. Private to the squad system.

## The military spot id, for example barracks_1.
var id: StringName = &""
var unit_def: UnitDef
## The post: the plot centre moved toward the castle by the building post_distance.
var home: Vector2 = Vector2.ZERO
## Where the formation centres. Equals `home` until orders move it.
var anchor: Vector2 = Vector2.ZERO
## The building current tier (1-based).
var tier: int = 0
## Seats the current tier fields: squad_size, capped at SquadSystem.MAX_UNITS_PER_SQUAD.
var cap: int = 0
## Ids of the units raised by this squad, ascending. May still list a unit that died this step.
var unit_ids: Array[int] = []
## Night steps left until the next replacement arrives; 0 while no countdown runs.
var replacement_ticks_left: int = 0
## Length in steps of the countdown that is running, kept for the progress readout; 0 when none.
var replacement_total_ticks: int = 0
## Seconds between replacements at the current tier.
var respawn_seconds: float = 0.0
## The stance the squad rests in when no one-shot verb runs (one of the SquadOrder STANCE_ names).
## Orders set it and nothing else does: nights and dawns leave it alone (D-14).
var resting_stance: StringName = SquadOrder.STANCE_POST
## True while a one-shot walk (rally) is in progress: units walk to their slots and acquire no
## target until every one has arrived (RESEARCH A5).
var moving: bool = false
## Steps left before a walk is abandoned even if some unit never reached its slot, which happens
## when two squads are sent to the same point and their formations overlap.
var moving_ticks_left: int = 0
## Per-step scratch for a following squad: true when every unit already stands within arrival
## distance of its slot, so units with nothing to fight keep still instead of creeping to the exact
## slot. Recomputed at the start of the squad turn each step; false for any other stance.
var settled: bool = false
## Orders waiting behind the running one; used from plan 03-07.
var queue: Array[SquadOrder] = []
