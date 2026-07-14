extends CharacterBody2D

## Generic enemy actor driven by content data (EnemyDef). Movement and goal
## selection are deliberately separate concerns:
##   - MOVEMENT (this file's _physics_process) is dumb and stable: steer
##     toward whatever the NavigationAgent2D says is the next path point.
##   - GOAL SELECTION (_choose_goal) decides *where* to go and sets the
##     agent's target. For now it has one branch -- claim and occupy a house
##     cell -- but this is the seam the fuller behavior ladder plugs into
##     (attack player in range, make a new entrance, build a nest, etc.).
##
## Sized to at least one grid cell via `def.grid_size` ("even an ant is a
## swarm taking up one cell"), inset by CELL_INSET so the body sits visibly
## *inside* its cell(s) rather than perfectly filling them -- this also gives
## clearance to pass through the door (a one-cell-wide gap).

## Gutter in px kept on each side of the footprint, so a 1x1 enemy is
## (CELL_SIZE - 2*CELL_INSET) = 36px inside a 48px cell.
const CELL_INSET: float = 6.0

enum State { IDLE, SEEKING, OCCUPYING }

var def: EnemyDef
## The territory service this enemy tries to capture. Assigned by whatever
## spawns the enemy, before start() is called.
var house_grid: HouseGrid

var _state: int = State.IDLE
var _target_cell: int = -1

@onready var _visual: Polygon2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _nav: NavigationAgent2D = $NavigationAgent2D


func set_def(new_def: EnemyDef) -> void:
	def = new_def
	var size_px: Vector2 = Vector2(def.grid_size) * Grid.CELL_SIZE - Vector2(CELL_INSET, CELL_INSET) * 2.0
	(_collision.shape as RectangleShape2D).size = size_px
	_visual.polygon = PackedVector2Array([
		-size_px / 2,
		Vector2(size_px.x, -size_px.y) / 2,
		size_px / 2,
		Vector2(-size_px.x, size_px.y) / 2,
	])


## Called by the spawner after def/house_grid/position are set. Waits one
## physics frame so the NavigationServer has synced the region map -- before
## that, the agent reports its own position as the next path point and the
## enemy would never move.
func start() -> void:
	await get_tree().physics_frame
	_choose_goal()


## The behavior ladder. Today: seek a house cell to occupy. Future goals
## (attack player, make entrance, nest, destroy structure) branch in here
## ahead of this fallback, without the movement code below needing to change.
func _choose_goal() -> void:
	if house_grid == null:
		_state = State.IDLE
		return
	var cell: int = house_grid.request_target_cell(self)
	if cell < 0:
		_state = State.IDLE
		return
	_target_cell = cell
	_nav.target_position = house_grid.cell_world_position(cell)
	_state = State.SEEKING


func _physics_process(_delta: float) -> void:
	if _state != State.SEEKING or def == null:
		return
	if _nav.is_navigation_finished():
		velocity = Vector2.ZERO
		_state = State.OCCUPYING
		house_grid.begin_occupy(self)
		return
	var next_point: Vector2 = _nav.get_next_path_position()
	velocity = (next_point - global_position).normalized() * def.speed
	move_and_slide()
