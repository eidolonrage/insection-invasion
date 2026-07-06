extends Control

## Persistent root. Only the center PhaseContainer child is swapped between
## Morning/Afternoon/Night; Hud and GameOverOverlay are instanced once here
## and react to Game signals instead of being rebuilt every phase change.

@onready var phase_container: Control = $Body/PhaseContainer

const MORNING_SCENE := preload("res://scenes/morning/Morning.tscn")
const AFTERNOON_SCENE := preload("res://scenes/afternoon/Afternoon.tscn")
const NIGHT_SCENE := preload("res://scenes/night/Night.tscn")

var current_phase_node: Control = null


func _ready() -> void:
	Game.phase_changed.connect(_on_phase_changed)
	_show_phase(Game.get_state().phase)


func _show_phase(phase: String) -> void:
	if current_phase_node:
		current_phase_node.queue_free()
		current_phase_node = null

	var scene: PackedScene = MORNING_SCENE
	match phase:
		"afternoon":
			scene = AFTERNOON_SCENE
		"night":
			scene = NIGHT_SCENE
		_:
			scene = MORNING_SCENE

	current_phase_node = scene.instantiate()
	phase_container.add_child(current_phase_node)


func _on_phase_changed(new_phase: String) -> void:
	_show_phase(new_phase)
