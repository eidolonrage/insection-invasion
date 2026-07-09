class_name EnemyDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var hp: int = 1
@export var damage: int = 0
@export var speed: float = 1.0
@export var money_reward: int = 0
@export var tier: int = 1
@export var unlocks_at_invasion_level: int = 0
## Footprint in grid cells. Even a single ant occupies at least one full
## cell -- it represents a swarm, not a lone insect.
@export var grid_size: Vector2i = Vector2i(1, 1)
