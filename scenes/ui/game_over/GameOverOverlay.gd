extends Control

## Single shared instance living in Main.tscn (not per-phase). Shown/hidden
## via Game.run_over_changed, replacing showGameOverIfNeeded being called
## at the top of every Phaser scene.

const REASON_TEXT := {
	"home_takeover": "The bugs took the house. Total home takeover.",
	"player_death": "You were eaten. The bugs win this round.",
	"rent_unpaid": "You couldn't make rent. Evicted.",
}

@onready var reason_label: Label = $Center/Panel/Margin/VBox/ReasonLabel
@onready var days_label: Label = $Center/Panel/Margin/VBox/DaysLabel
@onready var restart_button: Button = $Center/Panel/Margin/VBox/RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	Game.run_over_changed.connect(_on_run_over_changed)
	visible = Game.get_state().run_over
	if visible:
		_refresh()


func _on_run_over_changed(is_over: bool) -> void:
	visible = is_over
	if is_over:
		_refresh()


func _refresh() -> void:
	var state := Game.get_state()
	reason_label.text = REASON_TEXT.get(state.loss_reason, "Your run has ended.")
	days_label.text = "You lasted %d day(s)." % state.day


func _on_restart_pressed() -> void:
	Game.reset_for_new_run()
