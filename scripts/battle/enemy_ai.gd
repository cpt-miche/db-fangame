class_name EnemyAI
extends RefCounted

func _can_use_attack(enemy: FighterStats, attack: AttackDef) -> bool:
	return enemy.stamina >= attack.stamina_cost and enemy.drawn_ki >= attack.ki_cost

func choose_action(enemy: FighterStats, attacks: Dictionary) -> StringName:
	var low_ki := enemy.drawn_ki < 30
	var low_stamina := enemy.stamina < 25

	if low_ki and enemy.stored_ki > 20:
		return &"power_up"
	if low_stamina:
		return &"guard"
	if enemy.form_level < 2 and enemy.stamina > 70:
		return &"transform_form"
	if enemy.form_level == 0 and not enemy.kaioken_active and enemy.hp < 220 and enemy.stamina > 60:
		return &"kaioken"

	var roll := randf()
	if roll < 0.35 and attacks.has(&"strike") and _can_use_attack(enemy, attacks[&"strike"]):
		return &"strike"
	if roll < 0.72 and attacks.has(&"ki_blast") and _can_use_attack(enemy, attacks[&"ki_blast"]):
		return &"ki_blast"
	if attacks.has(&"ki_volley") and _can_use_attack(enemy, attacks[&"ki_volley"]):
		return &"ki_volley"
	if attacks.has(&"strike") and _can_use_attack(enemy, attacks[&"strike"]):
		return &"strike"
	if attacks.has(&"ki_blast") and _can_use_attack(enemy, attacks[&"ki_blast"]):
		return &"ki_blast"
	if enemy.stored_ki > 0 and enemy.drawn_ki < enemy.max_drawn_ki:
		return &"power_up"
	return &"guard"
