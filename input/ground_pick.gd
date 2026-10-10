class_name GroundPick
extends RefCounted
## Turns a screen point into a ground point and a ground point into whole centimetres (D-13,
## Pattern 6). Presentation only: the camera never enters the simulation, only the centimetres do.


## The point where the camera ray through `screen` meets the y = 0 ground, or null when the ray
## never reaches it.
static func ground_point(_camera: Camera3D, _screen: Vector2) -> Variant:
	return null


## The ground point in whole centimetres, each axis rounded once.
static func to_centimetres(_ground: Vector3) -> Vector2i:
	return Vector2i.ZERO


## True when `cm` lies within `half_extent_m` of the origin on both axes, inclusive.
static func in_bounds(_cm: Vector2i, _half_extent_m: float) -> bool:
	return false
