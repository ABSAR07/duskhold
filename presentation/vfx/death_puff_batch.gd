class_name DeathPuffBatch
extends CrowdBatch
## A ring of death puffs in one batch (PLAT-01): replaces one particle node and one timer per death.
## A puff lives EnemyViews.PUFF_SECONDS of real time and carries its age (0 to 1) in the instance's
## custom data, so the shader grows and fades it. A puff spawned while MAX_PUFFS are still standing
## is not drawn, the cap the particle nodes had at 64. The clock is passed in, so the batch never
## reads time itself. Display only.

const MAX_PUFFS: int = 128
const PUFF_RADIUS: float = 0.35
const PUFF_SIDES: int = 6
const PUFF_RINGS: int = 3
## A slot nothing was ever written to counts as born this long before time zero.
const NEVER_BORN_S: float = -1000.0
const PUFF_SHADER: Shader = preload("res://presentation/vfx/death_puff.gdshader")

var _origins: PackedVector3Array = PackedVector3Array()
var _born: PackedFloat64Array = PackedFloat64Array()
var _colors: PackedColorArray = PackedColorArray()
var _next: int = 0
var _now_s: float = 0.0


## Builds the ring of MAX_PUFFS slots. False when the batch could not be built.
func setup_puffs() -> bool:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = PUFF_RADIUS
	mesh.height = PUFF_RADIUS * 2.0
	mesh.radial_segments = PUFF_SIDES
	mesh.rings = PUFF_RINGS
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PUFF_SHADER
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_origins.resize(MAX_PUFFS)
	_colors.resize(MAX_PUFFS)
	_born.resize(MAX_PUFFS)
	_born.fill(NEVER_BORN_S)
	_next = 0
	return setup(mesh, material, MAX_PUFFS, true)


## Starts a puff at `origin` in `color`, `now_s` being the real clock in seconds. Not drawn while
## MAX_PUFFS puffs are still standing.
func spawn(origin: Vector3, now_s: float, color: Color = Color.WHITE) -> void:
	if _born.is_empty():
		return
	_now_s = now_s
	if active_count() >= MAX_PUFFS:
		return
	_origins[_next] = origin
	_colors[_next] = color
	_born[_next] = now_s
	_next = (_next + 1) % MAX_PUFFS


## Redraws every puff still standing at `now_s` with its age in the custom data, and commits.
func refresh(now_s: float) -> void:
	if _born.is_empty():
		return
	_now_s = now_s
	begin()
	for step: int in range(MAX_PUFFS):
		var slot: int = (_next + step) % MAX_PUFFS
		var age: float = (now_s - _born[slot]) / EnemyViews.PUFF_SECONDS
		if age < 0.0 or age >= 1.0:
			continue
		add(_origins[slot], Color(age, 0.0, 0.0, 0.0), _colors[slot])
	commit()


## Puffs standing as of the latest spawn or refresh.
func active_count() -> int:
	var standing: int = 0
	if _born.is_empty():
		return standing
	for slot: int in range(MAX_PUFFS):
		var age: float = (_now_s - _born[slot]) / EnemyViews.PUFF_SECONDS
		if age >= 0.0 and age < 1.0:
			standing += 1
	return standing
