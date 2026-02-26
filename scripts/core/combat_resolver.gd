class_name CombatResolver
extends RefCounted

const BASE_SUPPRESSION := 35.0

const BASE_DR_MAX := 0.50
const DR_CURVE_P := 0.75
const DR_CAP := 0.90
const SCRATCH_PCT_HP := 0.001

const FORM_DR_BONUS := {
	0: 0.00, # Base
	1: 0.15, # SS1
	2: 0.20, # SS2
	3: 0.30, # SS3
	4: 0.35, # SSGod
	5: 0.40, # SSBlue
}

func get_suppression(fighter: FighterStats) -> float:
	return clampf((BASE_SUPPRESSION - fighter.escalation) / 100.0, 0.0, 0.5)

func get_vanish_cost(attack_tier: int) -> int:
	return 12 + attack_tier * 8

func try_vanish(attacker: FighterStats, defender: FighterStats, attack: AttackDef, rng: RandomNumberGenerator) -> Dictionary:
	var vanish_cost := get_vanish_cost(attack.attack_tier)
	if defender.drawn_ki < vanish_cost:
		return {"vanished": false}

	var speed_edge := defender.speed - attacker.speed
	var fatigue_penalty := 0.15 if float(defender.stamina) / maxf(1.0, float(defender.max_stamina)) < 0.2 else 0.0
	var tracking_bonus := attack.attack_tier * 0.08
	var chance := clampf(0.2 + speed_edge * 0.008 - tracking_bonus - fatigue_penalty, 0.05, 0.7)
	if rng.randf() > chance:
		return {"vanished": false}

	defender.drawn_ki -= vanish_cost
	var counter_damage := 0
	if defender.stamina > 15 and defender.drawn_ki > 10 and rng.randf() < 0.45:
		defender.stamina -= 12
		defender.drawn_ki -= 10
		counter_damage = int(round(16.0 + defender.physical_strength * 0.5))
		attacker.hp -= counter_damage

	return {
		"vanished": true,
		"vanish_cost": vanish_cost,
		"counter_damage": counter_damage,
	}

func compute_hp_damage(defender: FighterStats, raw_damage: float) -> int:
	var stamina_ratio := clampf(float(defender.stamina) / maxf(1.0, float(defender.max_stamina)), 0.0, 1.0)
	var form_bonus := float(FORM_DR_BONUS.get(defender.form_level, 0.0))
	var dr_max := clampf(BASE_DR_MAX + form_bonus, 0.0, DR_CAP)
	var stamina_dr := dr_max * pow(stamina_ratio, DR_CURVE_P)

	var scratch_threshold := SCRATCH_PCT_HP * float(defender.max_hp)
	var pre_mitigation := maxf(0.0, raw_damage - scratch_threshold)
	var hp_damage := pre_mitigation * (1.0 - stamina_dr)

	var final_scratch_floor := SCRATCH_PCT_HP * float(defender.max_hp)
	if hp_damage < final_scratch_floor:
		return 0
	return maxi(1, int(round(hp_damage)))

func resolve_attack(attacker: FighterStats, defender: FighterStats, attack: AttackDef, infusion_ratio: float, transformation: TransformationDef, rng: RandomNumberGenerator) -> Dictionary:
	var infusion_cost := int(round(attacker.max_drawn_ki * infusion_ratio * attack.infusion_cap))
	if attacker.stamina < attack.stamina_cost or attacker.drawn_ki < (attack.ki_cost + infusion_cost):
		return {"ok": false, "reason": "lacked_resources"}

	attacker.stamina -= attack.stamina_cost
	attacker.drawn_ki -= attack.ki_cost + infusion_cost

	var hit_chance := clampf(attack.base_hit + (attacker.speed - defender.speed) * 0.006 + infusion_ratio * 0.08 - (0.14 if defender.guarding else 0.0), 0.1, 0.95)
	if rng.randf() > hit_chance:
		return {"ok": true, "result": "miss"}

	if attack.can_vanish:
		var vanish_result := try_vanish(attacker, defender, attack, rng)
		if vanish_result.get("vanished", false):
			return {"ok": true, "result": "vanished", "details": vanish_result}

	var suppression := 1.0 - get_suppression(attacker)
	var trans_multiplier := transformation.damage_multiplier if (transformation and attacker.kaioken_active) else 1.0
	var stat_power := attacker.physical_strength if attack.attack_type == AttackDef.AttackType.PHYSICAL else attacker.ki_strength
	var infusion_boost := 1.0 + infusion_ratio * 0.9
	var raw_damage := (attack.base_damage + stat_power * attack.scaling) * suppression * trans_multiplier * infusion_boost
	var final_damage := compute_hp_damage(defender, raw_damage)

	defender.hp -= final_damage
	attacker.escalation += attack.escalation_gain
	defender.escalation += 2.0

	return {
		"ok": true,
		"result": "hit",
		"damage": final_damage,
		"infusion_cost": infusion_cost,
	}
