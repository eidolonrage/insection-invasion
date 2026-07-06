extends Control

## MORNING -- spend money on traps and deploy them before the afternoon
## wave. Gray-box: buttons stand in for the real shop/placement UI.

const SHOP_ROW := preload("res://scenes/ui/shop_button/ShopButtonRow.tscn")

@onready var shop_list: VBoxContainer = $Margin/VBox/ShopList
@onready var inventory_label: Label = $Margin/VBox/InventoryLabel
@onready var deploy_button: Button = $Margin/VBox/DeployButton
@onready var to_afternoon_button: Button = $Margin/VBox/ToAfternoonButton


func _ready() -> void:
	var state := Game.get_state()
	if state.run_over:
		return

	# Rent is charged on waking; an unpaid rent ends the run right here.
	DayDirector.start_morning(state)
	Game.notify_state_changed()
	if state.run_over:
		Game.notify_run_over()
		return

	deploy_button.pressed.connect(_on_deploy_pressed)
	to_afternoon_button.pressed.connect(_on_to_afternoon_pressed)
	_populate_shop()
	_refresh_inventory_label()


func _populate_shop() -> void:
	for child in shop_list.get_children():
		child.queue_free()

	var content := Game.get_content()
	var state := Game.get_state()
	for trap_id in content.traps:
		var trap: TrapDef = content.traps[trap_id]
		var row := SHOP_ROW.instantiate()
		shop_list.add_child(row)
		var affordable := state.money >= trap.cost
		var desc := "Buy %s  ($%d, dmg %dx%d)" % [trap.display_name, trap.cost, trap.damage, trap.durability]
		row.configure(trap.id, desc, "Buy", affordable)
		row.pressed_buy.connect(_on_buy_trap)


func _on_buy_trap(trap_id: String) -> void:
	var content := Game.get_content()
	var state := Game.get_state()
	var trap: TrapDef = content.traps[trap_id]
	if state.money < trap.cost:
		return
	state.money -= trap.cost
	var owned := OwnedTrap.new()
	owned.trap_id = trap.id
	owned.remaining_durability = trap.durability
	state.inventory_traps.append(owned)
	Game.notify_state_changed()
	_populate_shop()
	_refresh_inventory_label()


func _refresh_inventory_label() -> void:
	var state := Game.get_state()
	inventory_label.text = (
		"Owned traps: %d   Deployed: %d" % [state.inventory_traps.size(), state.placed_traps.size()]
	)
	deploy_button.disabled = state.inventory_traps.size() == 0


func _on_deploy_pressed() -> void:
	var state := Game.get_state()
	var content := Game.get_content()
	for owned in state.inventory_traps:
		var def: TrapDef = content.traps[owned.trap_id]
		var placed := PlacedTrap.new()
		placed.trap_id = owned.trap_id
		placed.damage = def.damage
		placed.remaining_durability = owned.remaining_durability
		placed.placement = def.placement
		state.placed_traps.append(placed)
	state.inventory_traps.clear()
	Game.notify_state_changed()
	_refresh_inventory_label()


func _on_to_afternoon_pressed() -> void:
	DayDirector.to_afternoon(Game.get_state())
	Game.set_phase("afternoon")
