class_name TransformationDef
extends Resource

@export var id: StringName = &"kaioken"
@export var label: String = "Kaioken"

@export var is_form_transformation: bool = false
@export var is_toggle_transformation: bool = true

@export_range(0, 10, 1) var form_level: int = 0
@export_range(0, 10, 1) var required_form_level: int = 0

@export var required_hp_pct: float = 0.0
@export var required_stamina_pct: float = 0.0
@export var required_stored_ki_pct: float = 0.0
@export var required_drawn_ki_pct: float = 0.0

@export var strength_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var max_stamina_multiplier: float = 1.0

@export var hp_upkeep_pct: float = 0.0
@export var stamina_upkeep_pct: float = 0.0
@export var stored_ki_upkeep_pct: float = 0.0
@export var drawn_ki_upkeep_pct: float = 0.0
@export var stored_to_drawn_pct: float = 0.0

# List of transformation ids that cannot coexist with this transformation.
# Used to auto-clear incompatible active buffs when this transformation activates.
@export var incompatible_transformation_ids: PackedStringArray = PackedStringArray([])

func can_activate(fighter: FighterStats) -> bool:
	var required_hp := int(ceil(float(fighter.max_hp) * required_hp_pct))
	var required_stamina := int(ceil(float(fighter.max_stamina) * required_stamina_pct))
	var required_stored_ki := int(ceil(float(fighter.max_stored_ki) * required_stored_ki_pct))
	var required_drawn_ki := int(ceil(float(fighter.max_drawn_ki) * required_drawn_ki_pct))
	return fighter.hp >= required_hp and fighter.stamina >= required_stamina and fighter.stored_ki >= required_stored_ki and fighter.drawn_ki >= required_drawn_ki

func get_mastery_factor(mastery_level: int) -> float:
	return clampf(1.0 - float(mastery_level) * 0.2, 0.0, 1.0)

func get_upkeep_amount(max_resource: int, upkeep_pct: float, mastery_level: int) -> int:
	return int(round(float(max_resource) * upkeep_pct * get_mastery_factor(mastery_level)))
