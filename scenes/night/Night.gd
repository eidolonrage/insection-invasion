extends Control

## NIGHT -- install automated money-makers, then sleep. Sleeping is the
## save point (Stardew-style) and the moment the invasion escalates for
## tomorrow.

const SHOP_ROW := preload("res://scenes/ui/shop_button/ShopButtonRow.tscn")

@onready var farmer_list: VBoxContainer = $Margin/VBox/FarmerList
@onready var projected_income_label: Label = $Margin/VBox/ProjectedIncomeLabel
@onready var sleep_button: Button = $Margin/VBox/SleepButton


func _ready() -> void:
	if Game.get_state().run_over:
		return
	sleep_button.pressed.connect(_on_sleep_pressed)
	_populate_farmers()
	_refresh_projected_income()


func _populate_farmers() -> void:
	for child in farmer_list.get_children():
		child.queue_free()

	var content := Game.get_content()
	var state := Game.get_state()
	for farmer in content.economy.auto_farmers:
		var row := SHOP_ROW.instantiate()
		farmer_list.add_child(row)
		var owned := state.auto_farmers.has(farmer.id)
		var label_text: String
		if owned:
			label_text = "%s — installed (+$%d/night)" % [farmer.display_name, farmer.income_per_night]
		else:
			label_text = "Install %s ($%d, +$%d/night)" % [farmer.display_name, farmer.cost, farmer.income_per_night]
		var enabled := not owned and state.money >= farmer.cost
		row.configure(farmer.id, label_text, "Installed" if owned else "Install", enabled)
		if not owned:
			row.pressed_buy.connect(_on_install_farmer)


func _on_install_farmer(farmer_id: String) -> void:
	var state := Game.get_state()
	var content := Game.get_content()
	var farmer: AutoFarmerDef = null
	for f in content.economy.auto_farmers:
		if f.id == farmer_id:
			farmer = f
			break
	if farmer == null or state.money < farmer.cost:
		return
	state.money -= farmer.cost
	state.auto_farmers.append(farmer.id)
	Game.notify_state_changed()
	_populate_farmers()
	_refresh_projected_income()


func _refresh_projected_income() -> void:
	var projected := Economy.compute_overnight_income(Game.get_state(), Game.get_content().economy)
	projected_income_label.text = "Projected overnight income: +$%d" % projected


func _on_sleep_pressed() -> void:
	DayDirector.sleep(Game.get_state(), Game.get_content())
	Game.notify_state_changed()
	Game.set_phase("morning")
