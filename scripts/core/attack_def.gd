class_name AttackDef
extends Resource

enum AttackType { PHYSICAL, KI, UTILITY }

@export var id: StringName
@export var label: String = "Attack"
@export var attack_type: AttackType = AttackType.PHYSICAL

@export var base_damage: float = 25.0
@export var scaling: float = 1.0
@export var stamina_cost: int = 0
@export var ki_cost: int = 0
@export var infusion_cap: float = 0.0
@export var base_hit: float = 0.75
@export var can_vanish: bool = true
@export var attack_tier: int = 1
@export var escalation_gain: float = 6.0
@export var required_transformation_id: StringName = &""

func is_ki_attack() -> bool:
	return attack_type == AttackType.KI
