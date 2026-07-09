class_name Grid
extends RefCounted

## Pure coordinate math for the world's logical grid. Deliberately holds no
## per-cell state (occupied/overrun/etc.) yet -- nothing consumes that yet,
## and its shape should be driven by whichever feature (trap placement,
## overrun mechanic) actually needs it first.

const CELL_SIZE: int = 48


static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))


static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


static func cell_center_world(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5
