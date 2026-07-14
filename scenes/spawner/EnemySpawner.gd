extends Node2D

## Standalone test spawner for this world skeleton -- deliberately NOT
## Waves/DayDirector. Reuses the real EnemyDef content (via the Game
## autoload) so speeds/sizes are meaningful, but picks randomly among all
## defined enemies regardless of unlocked_enemy_ids, since this scene
## doesn't track invasion progression.

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

@export var spawn_interval: float = 1.75
@export var yard_size: Vector2 = Vector2(960, 672)
## The house territory enemies try to infiltrate. Assigned by the world
## scene (see Yard.gd).
@export var house_grid: HouseGrid

## Starts at spawn_interval (not 0) so the first spawn waits a beat -- the
## navmesh map hasn't had its first synchronization on frame one, and the
## navmesh queries in _spawn_one would fail against an unsynced map.
var _timer: float = spawn_interval


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_spawn_one()


func _spawn_one() -> void:
	var defs: Array = Game.content.enemies.values()
	if defs.is_empty() or house_grid == null:
		return
	var def: EnemyDef = defs[randi() % defs.size()]
	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = _snap_to_navmesh(_random_perimeter_point())
	enemy.house_grid = house_grid
	enemy.set_def(def)
	enemy.start()


## The yard perimeter is just outside the navmesh (baking erodes the walkable
## area inward from the bounds), so snap the raw edge point onto the mesh --
## otherwise the enemy starts off-mesh and can't compute a path.
func _snap_to_navmesh(point: Vector2) -> Vector2:
	var map := get_world_2d().get_navigation_map()
	return NavigationServer2D.map_get_closest_point(map, point)


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
