class_name NightDef
extends Resource
## One night's hand-authored wave. Data only.

## Order is significant: spawns due on the same tick happen in group order.
@export var groups: Array[SpawnGroupDef] = []
