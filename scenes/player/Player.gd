extends CharacterBody2D

## Real-time, grid-agnostic movement -- moves smoothly across grid lines,
## blocked only by actual collision shapes (walls), never snapped to cells.

@export var speed: float = 160.0

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_camera.make_current()


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
