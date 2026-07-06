class_name Loss
extends RefCounted

## The three ways a run ends, as a single pure check. Call it after any
## step that can change home integrity, player health, or money-at-rent.
## Home takeover is the only hard stop; the others are recoverable right up
## until they trip.
##
## Note: no call site in this port (nor in the original) ever decrements
## player_health -- "player_death" is preserved for parity but is currently
## unreachable in normal play.


static func check_loss(state: GameState) -> String:
	if state.home_integrity <= 0:
		return "home_takeover"
	if state.player_health <= 0:
		return "player_death"
	return ""


## Stamp the loss onto the state so scenes can react and stop the run.
static func apply_loss(state: GameState, reason: String) -> void:
	state.run_over = true
	state.loss_reason = reason
