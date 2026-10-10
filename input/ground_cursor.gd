class_name GroundCursor
extends RefCounted
## The pad's aiming point, kept in screen space (D-12, RESEARCH Pattern 6, T-03-15). Pure and
## node-free: it starts where it is told (the king's projected ground point), moves with the right
## stick at a speed in pixels per second, and is clamped inside the visible rect with a margin
## (SpawnTelegraph.EDGE_MARGIN_PX) so the point it releases on is always on the screen. The ground
## point and the centimetres come from GroundPick when the cursor is confirmed, never from here.

## A window so small that the margin would eat the screen keeps the margin to this share of the
## shorter side instead (the headless test window is 64 px square), as SpawnTelegraph does.
const MAX_MARGIN_SHARE: float = 0.25

var _position: Vector2 = Vector2.ZERO
var _active: bool = false


## Puts the cursor at `screen` and activates it.
func start(screen: Vector2) -> void:
	_position = screen
	_active = true


## Moves the cursor by `stick` (a vector of length at most 1) at `speed_px_per_s` for `delta`
## seconds. An inactive cursor does not move.
func move(stick: Vector2, delta: float, speed_px_per_s: float) -> void:
	if _active:
		_position += stick * speed_px_per_s * delta


## Keeps the cursor `margin_px` inside `rect` on every side; exactly `margin_px` is allowed. A rect
## too small for the margin uses a share of its shorter side instead, so the cursor stays inside.
func clamp_to(rect: Rect2, margin_px: float) -> void:
	var margin: float = minf(margin_px, minf(rect.size.x, rect.size.y) * MAX_MARGIN_SHARE)
	_position.x = clampf(_position.x, rect.position.x + margin, rect.end.x - margin)
	_position.y = clampf(_position.y, rect.position.y + margin, rect.end.y - margin)


func position() -> Vector2:
	return _position


func is_active() -> bool:
	return _active


func stop() -> void:
	_active = false
