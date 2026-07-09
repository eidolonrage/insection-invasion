extends CharacterBody2D

## Generic enemy actor driven entirely by content data (EnemyDef). Walks a
## straight line toward `target_point` at `def.speed` -- no pathfinding or
## obstacle avoidance yet. Sized to at least one grid cell via
## `def.grid_size` ("even an ant is a swarm taking up one cell").

var def: EnemyDef
var target_point: Vector2

@onready var _visual: Polygon2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D


func set_def(new_def: EnemyDef) -> void:
	def = new_def
	var size_px: Vector2 = Vector2(def.grid_size) * Grid.CELL_SIZE
	(_collision.shape as RectangleShape2D).size = size_px
	_visual.polygon = PackedVector2Array([
		-size_px / 2,
		Vector2(size_px.x, -size_px.y) / 2,
		size_px / 2,
		Vector2(-size_px.x, size_px.y) / 2,
	])


func _physics_process(_delta: float) -> void:
	if def == null:
		return
	velocity = (target_point - global_position).normalized() * def.speed
	move_and_slide()
