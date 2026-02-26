class_name FighterStats
extends Resource

@export var fighter_name: String = "Fighter"

@export var max_hp: int = 450
@export var hp: int = 450

@export var max_stamina: int = 240
@export var stamina: int = 240

@export var max_stored_ki: int = 360
@export var stored_ki: int = 360

@export var max_drawn_ki: int = 240
@export var drawn_ki: int = 80

@export var physical_strength: int = 56
@export var ki_strength: int = 50
@export var speed: int = 46
@export var control: int = 42

@export_range(0, 5, 1) var base_form_override_level: int = 0

var escalation: float = 0.0
var guarding: bool = false
var kaioken_active: bool = false
var form_level: int = 0
var highest_form_rewarded_this_rest: int = 0

func duplicate_runtime() -> FighterStats:
	var copy := FighterStats.new()
	copy.fighter_name = fighter_name
	copy.max_hp = max_hp
	copy.hp = hp
	copy.max_stamina = max_stamina
	copy.stamina = stamina
	copy.max_stored_ki = max_stored_ki
	copy.stored_ki = stored_ki
	copy.max_drawn_ki = max_drawn_ki
	copy.drawn_ki = drawn_ki
	copy.physical_strength = physical_strength
	copy.ki_strength = ki_strength
	copy.speed = speed
	copy.control = control
	copy.base_form_override_level = base_form_override_level
	copy.form_level = base_form_override_level
	copy.highest_form_rewarded_this_rest = base_form_override_level
	return copy

func clamp_resources() -> void:
	hp = clampi(hp, 0, max_hp)
	stamina = clampi(stamina, 0, max_stamina)
	stored_ki = clampi(stored_ki, 0, max_stored_ki)
	drawn_ki = clampi(drawn_ki, 0, max_drawn_ki)
