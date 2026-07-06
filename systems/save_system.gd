class_name SaveSystem
extends RefCounted

## Single-slot save, written on sleep (see DayDirector.sleep). Uses
## user://save.json now; swapping storage backends later means changing
## only this file.

const SAVE_PATH := "user://save.json"


static func save_game(state: GameState) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Failed to save game: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(state.to_dict()))
	f.close()


static func load_game() -> GameState:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to load save: malformed JSON")
		return null
	if parsed.get("version") != GameState.STATE_VERSION:
		push_warning(
			"Save version %s != current %d; ignoring old save."
			% [str(parsed.get("version")), GameState.STATE_VERSION]
		)
		return null
	return GameState.from_dict(parsed)


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
