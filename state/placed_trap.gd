class_name PlacedTrap
extends Resource

## A trap deployed for the coming wave. `damage` is stamped from the trap
## def at placement time so wave resolution needs no def lookups.

@export var trap_id: String = ""
@export var damage: int = 0
@export var remaining_durability: int = 0
@export var placement: String = "border"
