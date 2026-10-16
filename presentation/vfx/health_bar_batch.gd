class_name HealthBarBatch
extends CrowdBatch
## Hurt-only billboard health bars in one batch (PLAT-01): replaces one HealthBar3D node pair per
## enemy. An instance exists only for a unit with 0 < hp < max (the HealthBar3D.should_show rule),
## and its fill ratio rides in the instance's custom data for the shader. Display only.

const BAR_SHADER: Shader = preload("res://presentation/vfx/health_bar_batch.gdshader")


## Builds the batch: `capacity` bars of `width` metres by HealthBar3D.BAR_HEIGHT, drawn on top of
## the scene without a depth test. False for a capacity below 1.
func setup_bars(width: float, capacity: int) -> bool:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(width, HealthBar3D.BAR_HEIGHT)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BAR_SHADER
	material.set_shader_parameter(&"fill_color", HealthBar3D.FILL_COLOR)
	material.set_shader_parameter(&"background_color", HealthBar3D.BACKGROUND_COLOR)
	material.render_priority = HealthBar3D.FILL_RENDER_PRIORITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return setup(mesh, material, capacity, false)


## Adds a bar at `origin` filled to hp / max_hp, only while the owner is hurt and alive. False when
## nothing was added (full health, dead, no max, or the batch is full).
func add_if_hurt(origin: Vector3, hp: int, max_hp: int) -> bool:
	if not HealthBar3D.should_show(hp, max_hp):
		return false
	return add(origin, Color(float(hp) / float(max_hp), 0.0, 0.0, 0.0))


## The fill ratio of bar `index`, from the mirror; -1.0 for a bar that is not there.
func ratio_of(index: int) -> float:
	if index < 0 or index >= count():
		return -1.0
	return custom_of(index).r
