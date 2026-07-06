extends HBoxContainer

## A single "Buy X ($cost)" / "Install X" row. Reused for both the Morning
## trap shop and the Night auto-farmer list -- one scene, no duplication.

signal pressed_buy(item_id: String)

@onready var label: Label = $Label
@onready var button: Button = $Button

var item_id: String = ""


func configure(id: String, text: String, button_text: String, enabled: bool) -> void:
	item_id = id
	label.text = text
	button.text = button_text
	button.disabled = not enabled


func _ready() -> void:
	button.pressed.connect(func(): pressed_buy.emit(item_id))
