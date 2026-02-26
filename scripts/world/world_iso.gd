extends Node2D

signal encounter_requested(enemy_id: StringName)

@onready var prompt_label: Label = $CanvasLayer/Prompt

func _ready() -> void:
	prompt_label.visible = false
	for npc: Node in $Enemies.get_children():
		if npc.has_signal("player_interacted"):
			npc.player_interacted.connect(_on_enemy_interacted)
			npc.body_entered.connect(_on_enemy_body_entered)
			npc.body_exited.connect(_on_enemy_body_exited)

func _on_enemy_interacted(enemy_id: StringName) -> void:
	emit_signal("encounter_requested", enemy_id)

func _on_enemy_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = true

func _on_enemy_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false
