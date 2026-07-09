extends Node2D

## Standalone test spawner for this world skeleton -- deliberately NOT
## Waves/DayDirector. Reuses the real EnemyDef content (via the Game
## autoload) so speeds/sizes are meaningful, but picks randomly among all
## defined enemies regardless of unlocked_enemy_ids, since this scene
## doesn't track invasion progression.

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

@export var spawn_interval: float = 1.75
@export var yard_size: Vector2 = Vector2(960, 672)
@export var house_target: Node2D

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_spawn_one()


func _spawn_one() -> void:
	var defs: Array = Game.content.enemies.values()
	if defs.is_empty() or house_target == null:
		return
	var def: EnemyDef = defs[randi() % defs.size()]
	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = _random_perimeter_point()
	enemy.target_point = house_target.get_nearest_boundary_point(enemy.global_position)
	enemy.set_def(def)


func _random_perimeter_point() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(randf() * yard_size.x, 0)
		1:
			return Vector2(randf() * yard_size.x, yard_size.y)
		2:
			return Vector2(0, randf() * yard_size.y)
		_:
			return Vector2(yard_size.x, randf() * yard_size.y)
