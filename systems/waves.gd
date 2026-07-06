class_name Waves
extends RefCounted

## Wave logic, engine-free. resolve_wave is the "resolve a wave against
## current defenses" pure function -- this is where a later real-time
## action layer would replace the abstract auto-resolve for the DEFEND
## branch, while WORK stays auto-resolved.


## Pick the authored wave for a level, or synthesize one by scaling.
static func wave_for_invasion_level(content: GameContent, level: int) -> WaveDef:
	for wave in content.waves:
		if wave.invasion_level == level:
			return wave

	# Fallback: scale the highest authored wave. Data-driven where content
	# exists, procedural where it doesn't -- so runs never hit a dead end.
	var base: WaveDef = content.waves[content.waves.size() - 1] if content.waves.size() > 0 else null
	if base == null:
		base = WaveDef.new()
		base.invasion_level = 0
		base.entries = []

	var overshoot: int = level - base.invasion_level
	var growth: float = 1.0 + max(0, overshoot) * 0.35

	var synthesized := WaveDef.new()
	synthesized.invasion_level = level
	var entries: Array[WaveEntry] = []
	for entry in base.entries:
		var scaled := WaveEntry.new()
		scaled.enemy_id = entry.enemy_id
		scaled.count = int(ceil(entry.count * growth))
		scaled.spawn_delay_ms = entry.spawn_delay_ms
		entries.append(scaled)
	synthesized.entries = entries
	return synthesized


## Abstract resolution model (gray-box): placed traps form a shared damage
## pool (per-hit damage x remaining durability). Enemies are chewed through
## in order; an enemy whose HP the pool can cover is killed (reward
## tallied for display only), otherwise it breaches and deals its damage to
## home integrity.
##
## Mutates `placed` durability so spent traps carry over correctly, then
## prunes fully-spent traps. Returns
## {"killed": int, "breached": int, "integrity_lost": int, "money_earned": int}.
static func resolve_wave(placed: Array, wave: WaveDef, enemies: Dictionary) -> Dictionary:
	var starting_pool := _pool_of(placed)
	var pool := starting_pool

	var killed := 0
	var breached := 0
	var integrity_lost := 0
	var money_earned := 0

	for entry in wave.entries:
		var def: EnemyDef = enemies.get(entry.enemy_id)
		if def == null:
			continue
		for i in range(entry.count):
			if pool >= def.hp:
				pool -= def.hp
				killed += 1
				money_earned += def.money_reward
			else:
				breached += 1
				integrity_lost += def.damage

	_drain_durability(placed, starting_pool - pool)

	return {
		"killed": killed,
		"breached": breached,
		"integrity_lost": integrity_lost,
		"money_earned": money_earned,
	}


static func _pool_of(placed: Array) -> int:
	var total := 0
	for t in placed:
		total += t.damage * t.remaining_durability
	return total


## Spend `spent` points of damage capacity across placements, in order.
static func _drain_durability(placed: Array, spent: int) -> void:
	var remaining := spent
	for t in placed:
		while t.remaining_durability > 0 and remaining > 0:
			t.remaining_durability -= 1
			remaining -= t.damage
		if remaining <= 0:
			break

	for i in range(placed.size() - 1, -1, -1):
		if placed[i].remaining_durability <= 0:
			placed.remove_at(i)
