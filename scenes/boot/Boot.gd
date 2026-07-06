extends Node

## The Game autoload already loads content and state in its _ready() before
## any scene's _ready() runs (Godot guarantees autoloads init first), so
## Boot's only job is a one-time redirect to the persistent Main scene --
## kept as its own scene purely for 1:1 naming parity with BootScene.ts.


func _ready() -> void:
	# Deferred: changing scenes from within the main scene's own _ready()
	# would try to remove_child() while Godot is still finishing adding it.
	get_tree().change_scene_to_file.call_deferred("res://scenes/main/Main.tscn")
