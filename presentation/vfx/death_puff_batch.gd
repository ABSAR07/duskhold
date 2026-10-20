class_name DeathPuffBatch
extends CrowdBatch
## A ring of death puffs in one batch (PLAT-01): replaces one particle node and one timer per death.
## A puff lives EnemyViews.PUFF_SECONDS of real time and carries its age (0 to 1) in the instance's
## custom data, so the shader grows and fades it. A puff spawned while MAX_PUFFS are still standing
## is not drawn, the cap the particle nodes had at 64. The clock is passed in, so the batch never
## reads time itself. The ring (the slots, the birth times, the standing scan and the per-frame
## write) runs in native/src/native_puffs.cpp (NativePuffs, plan 04-26: a line-by-line port of the
## GDScript ring pinned through tests/unit/test_enemy_fill_pins.gd, which hashes this batch); this
## node builds the mesh and the batch and uploads what the native refresh wrote. Display only.

const MAX_PUFFS: int = 128
const PUFF_RADIUS: float = 0.35
const PUFF_SIDES: int = 6
const PUFF_RINGS: int = 3
## A slot nothing was ever written to counts as born this long before time zero.
const NEVER_BORN_S: float = -1000.0
const PUFF_SHADER: Shader = preload("res://presentation/vfx/death_puff.gdshader")

## The ring and its per-frame write, in C++; null until setup_puffs has built the batch.
var _native: NativePuffs


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
	if not setup(mesh, material, MAX_PUFFS, true):
		return false
	_native = NativePuffs.new()
	_native.configure(MAX_PUFFS, EnemyViews.PUFF_SECONDS, NEVER_BORN_S)
	if not _native.set_mirror(mirror(), layout()):
		push_error("DeathPuffBatch: the native puff ring refused the batch mirror")
		return false
	return true


## Starts a puff at `origin` in `color`, `now_s` being the real clock in seconds. Not drawn while
## MAX_PUFFS puffs are still standing.
func spawn(origin: Vector3, now_s: float, color: Color = Color.WHITE) -> void:
	if _native == null:
		return
	_native.spawn(origin, now_s, color)


## Redraws every puff still standing at `now_s` with its age in the custom data, and commits.
func refresh(now_s: float) -> void:
	if _native == null:
		return
	# The refresh comes first: it detaches the native copy of the mirror, and the copy handed back
	# must be the one it wrote (GDScript evaluates arguments left to right).
	var written: int = _native.refresh(now_s)
	commit_buffer(_native.mirror(), written)


## Puffs standing as of the latest spawn or refresh.
func active_count() -> int:
	return _native.active_count() if _native != null else 0
