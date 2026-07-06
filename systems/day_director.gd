class_name DayDirector
extends RefCounted

## Orchestrates the loop: morning -> afternoon -> night -> sleep -> morning.
## Pure with respect to any Node -- phase scenes call these, then swap the
## visible phase. All escalation and persistence lives here so the rules of
## "a day" are in one readable place.


## Called when a new morning begins. Charges rent if due; a miss ends the run.
static func start_morning(state: GameState) -> void:
	var rent := Economy.apply_rent_if_due(state)
	if rent["charged"] and not rent["paid"]:
		Loss.apply_loss(state, "rent_unpaid")


static func to_afternoon(state: GameState) -> void:
	state.phase = "afternoon"


static func to_night(state: GameState) -> void:
	state.phase = "night"


## Sleep = save point + escalation, Stardew-style. Overnight earners pay
## out, the invasion tightens (level up, new enemy types unlock), the day
## advances, and the run is written to disk.
static func sleep(state: GameState, content: GameContent) -> void:
	# 1. Overnight auto-farm income.
	state.money += Economy.compute_overnight_income(state, content.economy)

	# 2. Escalate the invasion.
	escalate_invasion(state, content)

	# 3. Advance the calendar and reset to next morning.
	state.day += 1
	state.phase = "morning"

	# 4. Save on sleep.
	SaveSystem.save_game(state)


## Bump invasion level and unlock any enemy types that gate on it.
static func escalate_invasion(state: GameState, content: GameContent) -> void:
	state.invasion_level += 1
	for enemy_id in content.enemies:
		var enemy: EnemyDef = content.enemies[enemy_id]
		if (
			enemy.unlocks_at_invasion_level <= state.invasion_level
			and not state.unlocked_enemy_ids.has(enemy.id)
		):
			state.unlocked_enemy_ids.append(enemy.id)
