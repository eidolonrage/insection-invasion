class_name ContentLoader
extends RefCounted

## Parse-and-index once at boot. If any content resource is malformed, this
## push_errors immediately and returns null so Game.gd can fail loudly at
## startup rather than someone reading an undefined field three scenes deep.

const ENEMIES_DIR := "res://resources/content/enemies/"
const TRAPS_DIR := "res://resources/content/traps/"
const WAVES_DIR := "res://resources/content/waves/"
const ECONOMY_PATH := "res://resources/content/economy/economy_config.tres"


static func load_content() -> GameContent:
	var content := GameContent.new()
	content.enemies = _load_keyed_dir(ENEMIES_DIR)
	content.traps = _load_keyed_dir(TRAPS_DIR)
	content.waves = _load_waves(WAVES_DIR)
	content.economy = load(ECONOMY_PATH) as EconomyConfig

	var errors := _validate(content)
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		return null
	return content


static func _load_keyed_dir(dir_path: String) -> Dictionary:
	var result := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("ContentLoader: could not open directory '%s'" % dir_path)
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res: Resource = load(dir_path + file_name)
		var key = res.get("id")
		if result.has(key):
			push_error("Duplicate content id '%s' in %s" % [key, dir_path])
		result[key] = res
	return result


static func _load_waves(dir_path: String) -> Array[WaveDef]:
	var list: Array[WaveDef] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("ContentLoader: could not open directory '%s'" % dir_path)
		return list
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			list.append(load(dir_path + file_name) as WaveDef)
	list.sort_custom(func(a: WaveDef, b: WaveDef): return a.invasion_level < b.invasion_level)
	return list


## Referential integrity: every wave entry must point at a real enemy.
static func _validate(content: GameContent) -> Array[String]:
	var errors: Array[String] = []
	for wave in content.waves:
		for entry in wave.entries:
			if not content.enemies.has(entry.enemy_id):
				errors.append(
					"waves (invasionLevel %d) references unknown enemy '%s'"
					% [wave.invasion_level, entry.enemy_id]
				)
	return errors
