class_name EnemyAI
extends RefCounted

func choose_action(enemy: FighterStats, attacks: Dictionary) -> StringName:
	var low_ki := enemy.drawn_ki < 30
	var low_stamina := enemy.stamina < 25

	if low_ki and enemy.stored_ki > 20:
		return &"power_up"
	if low_stamina:
		return &"guard"
	if not enemy.kaioken_active and enemy.hp < 220 and enemy.stamina > 60:
		return &"transform"

	var roll := randf()
	if roll < 0.35 and attacks.has(&"strike"):
		return &"strike"
	if roll < 0.72 and attacks.has(&"ki_blast"):
		return &"ki_blast"
	return &"ki_volley"
