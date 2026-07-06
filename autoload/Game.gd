extends Node

## Autoload singleton "Game". Holds the single GameState + GameContent
## instances and exposes typed getters, replacing Phaser's per-game
## scene.registry (see core/registry.ts in the original). Also emits
## signals so persistent UI (Hud, GameOverOverlay) can refresh without
## the whole scene tree being torn down and rebuilt on every phase change.

signal phase_changed(new_phase: String)
signal state_changed()
signal run_over_changed(is_over: bool)

var content: GameContent = null
var state: GameState = null


func _ready() -> void:
	content = ContentLoader.load_content()
	if content == null:
		push_error("Fatal: game content failed to load/validate.")
		get_tree().quit()
		return

	state = SaveSystem.load_game()
	if state == null:
		state = GameState.new_game_state(content.economy)


func get_state() -> GameState:
	return state


func get_content() -> GameContent:
	return content


func set_phase(new_phase: String) -> void:
	state.phase = new_phase
	phase_changed.emit(new_phase)


## Call after mutating `state` so Hud / the current phase's dynamic lists
## can refresh in place -- the narrow replacement for Phaser's
## this.scene.restart().
func notify_state_changed() -> void:
	state_changed.emit()


## Call once the caller is ready for the GameOverOverlay to actually appear.
## Kept separate from notify_state_changed() because the Afternoon outcome
## panel needs to be read first (see scenes/afternoon/Afternoon.gd) before
## the overlay covers it, whereas a rent-unpaid loss in Morning has no
## outcome panel to wait for and calls this immediately.
func notify_run_over() -> void:
	if state.run_over:
		run_over_changed.emit(true)


func reset_for_new_run() -> void:
	SaveSystem.clear_save()
	state = GameState.new_game_state(content.economy)
	run_over_changed.emit(false)
	state_changed.emit()
	phase_changed.emit(state.phase)
