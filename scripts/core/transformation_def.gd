class_name TransformationDef
extends Resource

@export var id: StringName = &"kaioken"
@export var label: String = "Kaioken"

@export var required_hp: int = 40
@export var required_stamina: int = 35

@export var damage_multiplier: float = 1.28
@export var speed_bonus: int = 8

@export var drain_hp_per_turn: int = 8
@export var drain_stamina_per_turn: int = 14
@export var drain_drawn_ki_per_turn: int = 0

func get_adjusted_stamina_drain(control_stat: int) -> int:
	return maxi(1, drain_stamina_per_turn - int(round(control_stat * 0.06)))
