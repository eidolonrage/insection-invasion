extends Node2D

## Standalone test scene for the world skeleton: yard + house + door +
## player + enemy spawner. Not wired into Main.tscn/DayDirector yet --
## run directly via F6 to verify movement/collision/pathing.


func _ready() -> void:
	$EnemySpawner.house_target = $House
