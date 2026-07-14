class_name HouseGrid
extends Node2D

## The house's occupiable territory. Subdivides the interior floor into a
## lattice of grid cells (one room, for now) that enemies capture by
## occupying. This is the "attract" service from the invasion design: it
## hands out target cells to enemies and tracks each cell's ownership.
##
## Deliberately house-local: cells are measured from `interior_rect` (this
## node's local space), a `Grid.CELL_SIZE` lattice that need not align with
## the global yard placement grid. Reconciling the two lattices is a later
## concern -- nothing yet places objects inside the house.
##
## Cell lifecycle:
##   FREE -> CLAIMED (an enemy is pathing here; reserved so no two target
##           the same cell) -> OCCUPYING (enemy arrived, capture timer
##           running) -> OWNED (held long enough; insects control it).
## `release()` returns a not-yet-owned cell to FREE when its enemy dies or
## leaves. A full room OWNED -> advance the frontier to the next room is a
## later concern; this frames the single-room case.

enum CellState { FREE, CLAIMED, OCCUPYING, OWNED }

## Grid dimensions in cells. 6x5 exactly tiles the default 288x240 interior.
@export var cols: int = 6
@export var rows: int = 5
## Seconds a cell must be occupied before it flips to OWNED.
@export var occupy_time: float = 3.0
## Walkable interior in this node's local space. Defaults to the House
## interior floor (see House.tscn FloorVisual: -144,-120 .. 144,120).
@export var interior_rect: Rect2 = Rect2(-144, -120, 288, 240)

var _states: Array[int] = []
var _timers: Array[float] = []
var _cell_enemy: Array = []          ## cell index -> occupying enemy (or null)
var _enemy_cell: Dictionary = {}     ## enemy -> claimed cell index


func _ready() -> void:
	var count: int = cols * rows
	_states.resize(count)
	_timers.resize(count)
	_cell_enemy.resize(count)
	_states.fill(CellState.FREE)
	_timers.fill(0.0)
	_cell_enemy.fill(null)
	queue_redraw()


## Reserve the FREE cell nearest `enemy` and return its index, or -1 if the
## room is fully spoken for. The claim is what keeps enemies from stacking
## on one cell.
func request_target_cell(enemy: Node2D) -> int:
	var best: int = -1
	var best_dist: float = INF
	for i in _states.size():
		if _states[i] != CellState.FREE:
			continue
		var dist: float = enemy.global_position.distance_squared_to(cell_world_position(i))
		if dist < best_dist:
			best_dist = dist
			best = i
	if best >= 0:
		_states[best] = CellState.CLAIMED
		_cell_enemy[best] = enemy
		_enemy_cell[enemy] = best
		queue_redraw()
	return best


## The enemy assigned to a cell has arrived; start its capture timer.
func begin_occupy(enemy: Node2D) -> void:
	if not _enemy_cell.has(enemy):
		return
	var i: int = _enemy_cell[enemy]
	if _states[i] == CellState.CLAIMED:
		_states[i] = CellState.OCCUPYING
		_timers[i] = 0.0
		queue_redraw()


## Free an enemy's cell if it hasn't been captured yet (enemy died/left).
## OWNED cells stay owned -- clearing captured territory is a separate rule.
func release(enemy: Node2D) -> void:
	if not _enemy_cell.has(enemy):
		return
	var i: int = _enemy_cell[enemy]
	if _states[i] == CellState.CLAIMED or _states[i] == CellState.OCCUPYING:
		_states[i] = CellState.FREE
		_timers[i] = 0.0
	_cell_enemy[i] = null
	_enemy_cell.erase(enemy)
	queue_redraw()


## World position an enemy should path to in order to occupy `index`. The
## raw cell center can land in the navmesh's eroded margin near walls, so we
## snap it onto the mesh -- the enemy occupies as close to the cell center as
## the walkable area allows, and the target is always reachable.
func cell_world_position(index: int) -> Vector2:
	var col: int = index % cols
	var row: int = index / cols
	var local := interior_rect.position + Vector2(
		(col + 0.5) * Grid.CELL_SIZE,
		(row + 0.5) * Grid.CELL_SIZE,
	)
	var world := to_global(local)
	var map := get_world_2d().get_navigation_map()
	return NavigationServer2D.map_get_closest_point(map, world)


func _process(delta: float) -> void:
	var changed: bool = false
	for i in _states.size():
		if _states[i] != CellState.OCCUPYING:
			continue
		_timers[i] += delta
		if _timers[i] >= occupy_time:
			_states[i] = CellState.OWNED
			var enemy = _cell_enemy[i]
			if enemy != null:
				_enemy_cell.erase(enemy)
			changed = true
	if changed:
		queue_redraw()


## Debug overlay so the capture state is visible when running Yard.tscn.
func _draw() -> void:
	var cell := Vector2(Grid.CELL_SIZE, Grid.CELL_SIZE)
	for i in _states.size():
		var col: int = i % cols
		var row: int = i / cols
		var top_left := interior_rect.position + Vector2(col, row) * Grid.CELL_SIZE
		var color: Color
		match _states[i]:
			CellState.FREE:
				color = Color(1, 1, 1, 0.05)
			CellState.CLAIMED:
				color = Color(1, 0.85, 0.2, 0.18)
			CellState.OCCUPYING:
				color = Color(1, 0.5, 0.1, 0.35)
			_:
				color = Color(0.9, 0.15, 0.15, 0.5)
		draw_rect(Rect2(top_left, cell), color, true)
		draw_rect(Rect2(top_left, cell), Color(0, 0, 0, 0.25), false, 1.0)
