extends StaticBody2D

## A single hollow one-room house. Owns its own geometry so it can answer
## "where's the nearest point on my outer wall" for enemy pathing.

const INTERIOR_SIZE := Vector2(288, 240)
const WALL_THICKNESS := 16.0


## Nearest point on the house's outer rectangle to `from_global`. Used as
## the straight-line walk target for enemies -- not the door specifically,
## since reaching the door would require pathfinding around corners.
func get_nearest_boundary_point(from_global: Vector2) -> Vector2:
	var local := to_local(from_global)
	var outer_half := INTERIOR_SIZE * 0.5 + Vector2(WALL_THICKNESS, WALL_THICKNESS)
	var clamped := Vector2(
		clampf(local.x, -outer_half.x, outer_half.x),
		clampf(local.y, -outer_half.y, outer_half.y)
	)
	return to_global(clamped)
