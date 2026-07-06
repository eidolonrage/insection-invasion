extends Control

## AFTERNOON -- the core push-your-luck decision.
##  - DEFEND: you fight, so placed traps get a big temporary boost, but you
##    earn nothing this cycle.
##  - WORK:   you earn the desk-job payout, but the wave hits your placed
##    traps alone. Watch the invasion progress while the money ticks in.
## Later, DEFEND becomes the real-time action layer; WORK stays auto-resolved.

## Active defense adds this much temporary damage capacity to the pool.
const DEFENSE_BONUS_DAMAGE := 1
const DEFENSE_BONUS_CHARGES := 24

@onready var summary_label: Label = $Margin/VBox/SummaryLabel
@onready var defend_button: Button = $Margin/VBox/DefendButton
@onready var work_button: Button = $Margin/VBox/WorkButton
@onready var outcome_panel: Panel = $Margin/VBox/OutcomePanel
@onready var outcome_label: Label = $Margin/VBox/OutcomePanel/Margin2/VBox2/OutcomeLabel
@onready var continue_button: Button = $Margin/VBox/OutcomePanel/Margin2/VBox2/ContinueButton

var _wave: WaveDef


func _ready() -> void:
	var state := Game.get_state()
	if state.run_over:
		return

	var content := Game.get_content()
	_wave = Waves.wave_for_invasion_level(content, state.invasion_level)
	_refresh_summary()

	work_button.text = "WORK (earn $%d, full exposure)" % Economy.desk_job_income(content.economy)
	defend_button.pressed.connect(_on_defend_pressed)
	work_button.pressed.connect(_on_work_pressed)
	outcome_panel.visible = false


func _refresh_summary() -> void:
	var total_bugs := 0
	for e in _wave.entries:
		total_bugs += e.count
	summary_label.text = (
		"Incoming wave: %d bug(s). Deployed traps: %d." % [total_bugs, Game.get_state().placed_traps.size()]
	)


func _on_defend_pressed() -> void:
	var state := Game.get_state()
	var content := Game.get_content()

	var boosted: Array = state.placed_traps.duplicate()
	var synthetic := PlacedTrap.new()
	synthetic.trap_id = "__active_defense__"
	synthetic.damage = DEFENSE_BONUS_DAMAGE
	synthetic.remaining_durability = DEFENSE_BONUS_CHARGES
	synthetic.placement = "interior"
	boosted.append(synthetic)

	var outcome := Waves.resolve_wave(boosted, _wave, content.enemies)

	# Copy surviving real traps back (drop the synthetic defense entry).
	var real_traps: Array[PlacedTrap] = []
	for t in boosted:
		if t.trap_id != "__active_defense__":
			real_traps.append(t)
	state.placed_traps = real_traps

	_lock_choice_buttons()
	_finish_wave(
		outcome["integrity_lost"], outcome["money_earned"], outcome["killed"], outcome["breached"], "You fought them off."
	)


func _on_work_pressed() -> void:
	var state := Game.get_state()
	var content := Game.get_content()

	var outcome := Waves.resolve_wave(state.placed_traps, _wave, content.enemies)
	var income := Economy.desk_job_income(content.economy)
	state.money += income

	_lock_choice_buttons()
	_finish_wave(
		outcome["integrity_lost"], outcome["money_earned"] + income, outcome["killed"], outcome["breached"],
		"You earned $%d at the desk." % income
	)


func _lock_choice_buttons() -> void:
	defend_button.disabled = true
	work_button.disabled = true


## Apply a resolved wave to state, check for loss, and show the readout.
## NOTE: `money_for_display` intentionally never gets added to state.money
## here -- kills never pay out directly by design; only the WORK branch's
## desk_job_income (already added to state.money by the caller above) and
## overnight auto-farmers actually earn money. This matches the original.
func _finish_wave(integrity_lost: int, money_for_display: int, killed: int, breached: int, flavor: String) -> void:
	var state := Game.get_state()
	state.home_integrity = max(0, state.home_integrity - integrity_lost)

	var reason := Loss.check_loss(state)
	if reason != "":
		Loss.apply_loss(state, reason)

	Game.notify_state_changed()
	_show_outcome(killed, breached, integrity_lost, money_for_display, flavor)


func _show_outcome(killed: int, breached: int, integrity_lost: int, money_for_display: int, flavor: String) -> void:
	outcome_panel.visible = true
	outcome_label.text = (
		"%s\nKilled %d, breached %d. Home integrity -%d. +$%d gross."
		% [flavor, killed, breached, integrity_lost, money_for_display]
	)
	continue_button.text = "See result →" if Game.get_state().run_over else "To night →"
	continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	var state := Game.get_state()
	if state.run_over:
		# Deferred until now (not the instant integrity hits 0) so the
		# player reads the outcome readout before the overlay covers it.
		Game.notify_run_over()
	else:
		DayDirector.to_night(state)
		Game.set_phase("night")
