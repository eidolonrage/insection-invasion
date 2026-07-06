class_name TrapDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var cost: int = 0
@export var damage: int = 1
@export var durability: int = 1
@export_enum("border", "interior") var placement: String = "border"
@export var tags: Array[String] = []
