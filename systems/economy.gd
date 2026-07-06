class_name Economy
extends RefCounted

## All economy math is pure: (state, config) in, plain result out. Nothing
## here touches a Node, so it can be called from a test, a balance script,
## or a phase scene interchangeably.


## The "work" branch payout for the afternoon.
static func desk_job_income(config: EconomyConfig) -> int:
	return config.desk_job_income


## Sum of every installed auto-farmer's overnight yield.
static func compute_overnight_income(state: GameState, config: EconomyConfig) -> int:
	var total := 0
	for farmer_id in state.auto_farmers:
		for farmer in config.auto_farmers:
			if farmer.id == farmer_id:
				total += farmer.income_per_night
				break
	return total


## Charge rent if it's due today. Mutates money; the caller decides what a
## failed payment means (see systems/loss.gd). Returns
## {"charged": bool, "paid": bool, "amount": int}.
static func apply_rent_if_due(state: GameState) -> Dictionary:
	if state.day < state.rent_next_due_day:
		return {"charged": false, "paid": true, "amount": 0}
	var amount := state.rent_amount
	var paid := state.money >= amount
	if paid:
		state.money -= amount
		state.rent_next_due_day += state.rent_interval_days
	return {"charged": true, "paid": paid, "amount": amount}
