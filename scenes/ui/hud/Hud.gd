extends Control

## Persistent top-of-screen status line shared by every phase. Refreshes on
## Game signals instead of being redrawn in every scene's create(), the way
## drawHud() was in the original.

@onready var line1: Label = $Margin/VBox/Line1
@onready var line2: Label = $Margin/VBox/Line2
@onready var line3: Label = $Margin/VBox/Line3


func _ready() -> void:
	Game.state_changed.connect(_refresh)
	Game.phase_changed.connect(func(_p): _refresh())
	_refresh()


func _refresh() -> void:
	var s := Game.get_state()
	line1.text = "Day %d   Phase: %s" % [s.day, s.phase.to_upper()]
	line2.text = "$%d   Rent $%d due day %d" % [s.money, s.rent_amount, s.rent_next_due_day]
	line3.text = (
		"Home %d/%d   Health %d/%d   Invasion Lv %d"
		% [s.home_integrity, s.home_max, s.player_health, s.player_max, s.invasion_level]
	)
