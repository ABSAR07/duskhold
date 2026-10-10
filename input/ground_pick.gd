class_name GroundPick
extends RefCounted
## Turns a screen point into a ground point and a ground point into whole centimetres (D-13,
## Pattern 6). Presentation only: the camera never enters the simulation, only the centimetres do,
## inside a SquadOrderIntent. The conversion to centimetres is the single rounding every command
## point goes through, so the same click is the same order on every machine.


## The point where the camera ray through `screen` meets the y = 0 ground, or null when the ray
## never reaches it (a camera looking at the sky or along the horizon).
static func ground_point(camera: Camera3D, screen: Vector2) -> Variant:
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


## The ground point in whole centimetres, each axis rounded once (height is not a command).
static func to_centimetres(ground: Vector3) -> Vector2i:
	return Vector2i(roundi(ground.x * 100.0), roundi(ground.z * 100.0))


## True when `cm` lies within `half_extent_m` of the origin on both axes, inclusive. A half extent
## that is not a positive finite number bounds nothing: no point is inside it.
static func in_bounds(cm: Vector2i, half_extent_m: float) -> bool:
	if not is_finite(half_extent_m) or half_extent_m <= 0.0:
		return false
	var limit: int = roundi(minf(half_extent_m, MapConfig.MAX_GROUND_HALF_EXTENT) * 100.0)
	return cm.x >= -limit and cm.x <= limit and cm.y >= -limit and cm.y <= limit
