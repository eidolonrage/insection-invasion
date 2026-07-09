class_name Interactable
extends Area2D

## Base type for world objects the player can eventually interact with
## (doors, traps, equipment, home additions). Intentionally minimal --
## no interaction logic exists yet, this just establishes the node type
## so nothing needs restructuring when real interaction is added.


func interact() -> void:
	pass # subclasses override
