class_name GameContent
extends RefCounted

## Runtime container assembled by ContentLoader. Not a Resource/.tres -- it's
## derived at boot, never authored or saved directly.

var enemies: Dictionary = {}   # String id -> EnemyDef
var traps: Dictionary = {}     # String id -> TrapDef
var waves: Array[WaveDef] = [] # sorted by invasion_level ascending
var economy: EconomyConfig = null
