extends Node

@onready var world: Node = $WorldIso
@onready var battle: Node = $Battle

var enemy_map := {
	&"raditz_scout": preload("res://resources/fighters/raditz_scout.tres")
}

func _ready() -> void:
	world.encounter_requested.connect(_on_encounter_requested)
	battle.battle_finished.connect(_on_battle_finished)
	battle.visible = false

func _on_encounter_requested(enemy_id: StringName) -> void:
	if not enemy_map.has(enemy_id):
		push_warning("Unknown enemy id: %s" % enemy_id)
		return
	battle.start_battle(enemy_map[enemy_id])
	world.visible = false
	battle.visible = true
	battle.process_mode = Node.PROCESS_MODE_INHERIT

func _on_battle_finished(_result: String) -> void:
	battle.visible = false
	world.visible = true
