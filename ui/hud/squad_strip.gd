class_name SquadStrip
extends HBoxContainer
## UI-01 / D-23: the bottom-centre strip of squad slots, y 544..616 at 1280x720, 8 px above the
## start-night box and clear of the king widget. One 136x72 slot per squad in creation order (the
## order the military buildings were first built); a slot appears, fading in over 0.15 s, the step
## its squad exists and keeps its place for the rest of the run, even at 0 alive. With no squad the
## strip is hidden and shows nothing in its place. Up to six slots fit in 856 px; more are scaled
## down uniformly (about the bottom centre, so the strip never rises toward the clear centre) to
## at most 720 px wide. Display only: it polls the simulation each frame and never writes it.

const SLOT_SCENE: PackedScene = preload("res://ui/hud/squad_slot.tscn")
## Six slots and five gaps: the widest the strip stays unscaled.
const FULL_WIDTH: float = 856.0
## With more slots than fit, the strip is scaled down to this width.
const MAX_WIDTH: float = 720.0
const FADE_SECONDS: float = 0.15

var _ctx: RunContext
var _selection: SelectionModel
var _slots: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = slot_count() > 0


## Binds the strip to one run. A repeat call is ignored.
func bind_run(ctx: RunContext, map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	if map_root != null:
		_selection = map_root.get_selection()
	if _selection != null:
		_selection.changed.connect(_on_selection_changed)
	_sync()


## Slots in the strip.
func slot_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child is SquadSlot:
			count += 1
	return count


## The slot of a squad; null when the strip has none for it.
func slot_for(squad_id: StringName) -> SquadSlot:
	return _slots.get(squad_id) as SquadSlot


func _process(_delta: float) -> void:
	if _ctx != null:
		_sync()


## Adds a slot for every squad that has none yet, refreshes them all, and fits the strip.
func _sync() -> void:
	for squad_id: StringName in _ctx.squads.squad_ids():
		if not _slots.has(squad_id):
			_add_slot(squad_id)
	for slot: SquadSlot in _slots.values():
		slot.refresh(_ctx)
	visible = slot_count() > 0
	_fit()


func _add_slot(squad_id: StringName) -> void:
	var slot: SquadSlot = SLOT_SCENE.instantiate() as SquadSlot
	slot.squad_id = squad_id
	slot.modulate.a = 0.0
	add_child(slot)
	_slots[squad_id] = slot
	slot.bind_selection(_selection)
	if _selection != null:
		slot.set_selected(_selection.is_selected(squad_id))
	slot.create_tween().tween_property(slot, "modulate:a", 1.0, FADE_SECONDS)


## A selection change lights exactly the slots of the selected squads.
func _on_selection_changed() -> void:
	for squad_id: StringName in _slots:
		var slot: SquadSlot = _slots[squad_id]
		slot.set_selected(_selection.is_selected(squad_id))


## Scales the strip down uniformly to MAX_WIDTH once its natural width passes FULL_WIDTH (more than
## six slots, unreachable in Phase 3, which has two squads). The pivot is the
## bottom centre, so the bottom edge and the centre line stay where the layout put them.
func _fit() -> void:
	var width: float = get_combined_minimum_size().x
	var factor: float = 1.0
	if width > FULL_WIDTH:
		factor = MAX_WIDTH / width
	scale = Vector2(factor, factor)
	pivot_offset = Vector2(size.x * 0.5, size.y)
