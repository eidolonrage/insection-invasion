class_name GameState
extends Resource

## The entire serializable run state, as a flat Resource "data bag". Two
## payoffs, matching the original GameState.ts: save/load is just
## to_dict()/JSON.stringify and JSON.parse/from_dict(), and the pure system
## scripts (systems/*.gd) take this + content and return results, so they're
## trivial to reason about without any scene in the room.

const STATE_VERSION := 1

@export var version: int = STATE_VERSION
@export var day: int = 1
@export var phase: String = "morning" # "morning" | "afternoon" | "night"

@export var money: int = 0

@export var home_integrity: int = 0
@export var home_max: int = 0
@export var player_health: int = 0
@export var player_max: int = 0

@export var rent_amount: int = 0
@export var rent_interval_days: int = 1
@export var rent_next_due_day: int = 1

@export var inventory_traps: Array[OwnedTrap] = []
@export var placed_traps: Array[PlacedTrap] = []
@export var auto_farmers: Array[String] = [] # ids of installed overnight earners

@export var invasion_level: int = 0
@export var unlocked_enemy_ids: Array[String] = []

@export var run_over: bool = false
@export var loss_reason: String = "" # "" == null; else "home_takeover"|"player_death"|"rent_unpaid"


## Build a fresh run from the economy config.
static func new_game_state(economy: EconomyConfig) -> GameState:
	var s := GameState.new()
	s.version = STATE_VERSION
	s.day = 1
	s.phase = "morning"
	s.money = economy.starting_money
	s.home_integrity = economy.home_integrity
	s.home_max = economy.home_integrity
	s.player_health = economy.player_health
	s.player_max = economy.player_health
	s.rent_amount = economy.rent_amount
	s.rent_interval_days = economy.rent_interval_days
	s.rent_next_due_day = economy.rent_interval_days # first rent falls due after one interval
	s.inventory_traps = []
	s.placed_traps = []
	s.auto_farmers = []
	s.invasion_level = 0
	s.unlocked_enemy_ids = []
	s.run_over = false
	s.loss_reason = ""
	return s


func to_dict() -> Dictionary:
	var inv := []
	for t in inventory_traps:
		inv.append({"trap_id": t.trap_id, "remaining_durability": t.remaining_durability})
	var placed := []
	for t in placed_traps:
		placed.append({
			"trap_id": t.trap_id,
			"damage": t.damage,
			"remaining_durability": t.remaining_durability,
			"placement": t.placement,
		})
	return {
		"version": version,
		"day": day,
		"phase": phase,
		"money": money,
		"home_integrity": home_integrity,
		"home_max": home_max,
		"player_health": player_health,
		"player_max": player_max,
		"rent_amount": rent_amount,
		"rent_interval_days": rent_interval_days,
		"rent_next_due_day": rent_next_due_day,
		"inventory_traps": inv,
		"placed_traps": placed,
		"auto_farmers": auto_farmers,
		"invasion_level": invasion_level,
		"unlocked_enemy_ids": unlocked_enemy_ids,
		"run_over": run_over,
		"loss_reason": loss_reason,
	}


static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	s.version = d.get("version", STATE_VERSION)
	s.day = d.get("day", 1)
	s.phase = d.get("phase", "morning")
	s.money = d.get("money", 0)
	s.home_integrity = d.get("home_integrity", 0)
	s.home_max = d.get("home_max", 0)
	s.player_health = d.get("player_health", 0)
	s.player_max = d.get("player_max", 0)
	s.rent_amount = d.get("rent_amount", 0)
	s.rent_interval_days = d.get("rent_interval_days", 1)
	s.rent_next_due_day = d.get("rent_next_due_day", 1)

	s.inventory_traps = []
	for t in d.get("inventory_traps", []):
		var o := OwnedTrap.new()
		o.trap_id = t["trap_id"]
		o.remaining_durability = t["remaining_durability"]
		s.inventory_traps.append(o)

	s.placed_traps = []
	for t in d.get("placed_traps", []):
		var p := PlacedTrap.new()
		p.trap_id = t["trap_id"]
		p.damage = t["damage"]
		p.remaining_durability = t["remaining_durability"]
		p.placement = t["placement"]
		s.placed_traps.append(p)

	var farmers: Array[String] = []
	for f in d.get("auto_farmers", []):
		farmers.append(f)
	s.auto_farmers = farmers

	s.invasion_level = d.get("invasion_level", 0)
	var unlocked: Array[String] = []
	for e in d.get("unlocked_enemy_ids", []):
		unlocked.append(e)
	s.unlocked_enemy_ids = unlocked

	s.run_over = d.get("run_over", false)
	s.loss_reason = d.get("loss_reason", "")
	return s
