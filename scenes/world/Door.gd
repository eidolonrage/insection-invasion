extends Interactable

## Sits in the house's wall gap as the future interaction point. No
## behavior yet -- the gap itself (missing wall collision) is what makes
## it walkable; this node doesn't block movement.

## Largest enemy footprint (in grid cells) that fits through this entrance.
## Nothing enforces this yet -- it's the seam for the size-gated infiltration
## rule: enemies larger than this must pursue another goal (chew a new
## entrance) rather than pathing through here. Compared against EnemyDef.grid_size.
@export var max_enemy_size: Vector2i = Vector2i(2, 2)
