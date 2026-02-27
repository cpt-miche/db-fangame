extends Node

signal battle_finished(result: String)

@export var player_base: FighterStats
@export var enemy_base: FighterStats
@export var kaioken_def: TransformationDef

@export var strike_attack: AttackDef
@export var ki_blast_attack: AttackDef
@export var ki_volley_attack: AttackDef
@export var ki_barrage_attack: AttackDef

@onready var ui = $"../BattleUI"

const MAX_FORM_LEVEL := 5
const FORM_STRENGTH_MULT := {0: 1.0, 1: 5.0}
const FORM_KI_MULT := {0: 1.0, 1: 5.0}
const FORM_SPEED_MULT := {0: 1.0, 1: 2.0}
const FORM_MAX_STAMINA_MULT := {0: 1.0, 1: 2.0}
const FORM_STORED_KI_UPKEEP_PCT := {0: 0.0, 1: 0.01}
const FORM_STORED_TO_DRAWN_PCT := {0: 0.0, 1: 0.01}

var state := BattleState.new()
var resolver := CombatResolver.new()
var enemy_ai := EnemyAI.new()
var rng := RandomNumberGenerator.new()
var infusion_ratio: float = 0.0
var attacks: Dictionary

func _ready() -> void:
	rng.randomize()
	attacks = {
		&"strike": strike_attack,
		&"ki_blast": ki_blast_attack,
		&"ki_volley": ki_volley_attack,
		&"ki_barrage": ki_barrage_attack,
	}
	state.setup(player_base, enemy_base)
	_apply_form_scaling(state.player, true)
	_apply_form_scaling(state.enemy, true)
	ui.action_pressed.connect(_on_action_pressed)
	ui.infusion_changed.connect(func(v: float) -> void: infusion_ratio = v)
	ui.debug_mode_toggled.connect(_on_debug_mode_toggled)
	_refresh_view()

func get_player_stat_lines() -> PackedStringArray:
	return _fighter_stat_lines(state.player)

func _on_action_pressed(action_id: StringName) -> void:
	if state.is_finished():
		return

	state.player.guarding = false
	_match_player_action(action_id)
	if _check_end():
		return

	_resolve_enemy_turn()
	_apply_end_round()
	_check_end()
	_refresh_view()

func _match_player_action(action_id: StringName) -> void:
	match action_id:
		&"power_up":
			_power_up(state.player)
		&"guard":
			state.player.guarding = true
			state.player.stamina += 8
			_log("Player guards and steadies stance.")
		&"kaioken":
			_toggle_kaioken(state.player)
		&"transform_form":
			_transform_higher_form(state.player)
		_:
			if attacks.has(action_id):
				var attack_result := resolver.resolve_attack(state.player, state.enemy, attacks[action_id], infusion_ratio, kaioken_def, rng)
				_log_attack_result(state.player.fighter_name, attacks[action_id], attack_result)

func _resolve_enemy_turn() -> void:
	state.enemy.guarding = false
	var action := enemy_ai.choose_action(state.enemy, attacks)
	if action == &"power_up":
		_power_up(state.enemy)
		return
	if action == &"guard":
		state.enemy.guarding = true
		_log("%s guards." % state.enemy.fighter_name)
		return
	if action == &"kaioken":
		_toggle_kaioken(state.enemy)
		return
	if action == &"transform_form":
		_transform_higher_form(state.enemy)
		return

	var result := resolver.resolve_attack(state.enemy, state.player, attacks[action], 0.25, kaioken_def, rng)
	_log_attack_result(state.enemy.fighter_name, attacks[action], result)

func _apply_end_round() -> void:
	state.turn += 1
	state.player.escalation += 3
	state.enemy.escalation += 3
	_apply_form_ki_drain(state.player)
	_apply_form_ki_drain(state.enemy)
	_apply_kaioken_drain(state.player)
	_apply_kaioken_drain(state.enemy)
	state.player.stamina = clampi(state.player.stamina + 10, 0, state.player.max_stamina)
	state.enemy.stamina = clampi(state.enemy.stamina + 10, 0, state.enemy.max_stamina)
	state.player.clamp_resources()
	state.enemy.clamp_resources()

func _power_up(fighter: FighterStats) -> void:
	var amount := mini(45, mini(fighter.stored_ki, fighter.max_drawn_ki - fighter.drawn_ki))
	if amount <= 0:
		_log("%s cannot draw more ki." % fighter.fighter_name)
		return
	fighter.stored_ki -= amount
	fighter.drawn_ki += amount
	fighter.escalation += 5
	_log("%s powers up (+%d drawn ki)." % [fighter.fighter_name, amount])

func _transform_higher_form(fighter: FighterStats) -> void:
	if fighter.form_level >= MAX_FORM_LEVEL:
		_log("%s is already at maximum form." % fighter.fighter_name)
		return
	fighter.form_level += 1
	_apply_form_scaling(fighter, false)
	var newly_rewarded_levels := maxi(0, fighter.form_level - fighter.highest_form_rewarded_this_rest)
	if newly_rewarded_levels > 0:
		var stamina_gain := int(round(float(fighter.max_stamina) * 0.25 * float(newly_rewarded_levels)))
		fighter.stamina = mini(fighter.max_stamina, fighter.stamina + stamina_gain)
		fighter.highest_form_rewarded_this_rest = fighter.form_level
		_log("%s transforms to form %d and regains %d stamina." % [fighter.fighter_name, fighter.form_level, stamina_gain])
		return
	_log("%s transforms to form %d." % [fighter.fighter_name, fighter.form_level])

func _toggle_kaioken(fighter: FighterStats) -> void:
	if fighter.kaioken_active:
		fighter.kaioken_active = false
		_log("%s deactivates Kaioken." % fighter.fighter_name)
		return
	if fighter.form_level > 0:
		_log("%s can only use Kaioken in base form." % fighter.fighter_name)
		return
	if fighter.hp < kaioken_def.required_hp or fighter.stamina < kaioken_def.required_stamina:
		_log("%s lacks HP/Stamina for Kaioken." % fighter.fighter_name)
		return
	fighter.kaioken_active = true
	fighter.escalation += 12
	_log("%s activates Kaioken!" % fighter.fighter_name)

func _apply_kaioken_drain(fighter: FighterStats) -> void:
	if not fighter.kaioken_active:
		return
	fighter.hp -= kaioken_def.drain_hp_per_turn
	fighter.stamina -= kaioken_def.get_adjusted_stamina_drain(fighter.control)
	fighter.drawn_ki -= kaioken_def.drain_drawn_ki_per_turn
	_log("%s takes Kaioken upkeep drain." % fighter.fighter_name)

func _apply_form_ki_drain(fighter: FighterStats) -> void:
	var upkeep_pct := _get_form_value(FORM_STORED_KI_UPKEEP_PCT, fighter.form_level)
	var conversion_pct := _get_form_value(FORM_STORED_TO_DRAWN_PCT, fighter.form_level)
	if upkeep_pct <= 0.0 and conversion_pct <= 0.0:
		return

	var mastery_factor := clampf(1.0 - float(fighter.form_mastery_level) * 0.2, 0.0, 1.0)
	var upkeep_amount := int(round(float(fighter.max_stored_ki) * upkeep_pct * mastery_factor))
	var conversion_amount := int(round(float(fighter.max_stored_ki) * conversion_pct * mastery_factor))
	upkeep_amount = mini(upkeep_amount, fighter.stored_ki)
	fighter.stored_ki -= upkeep_amount

	var convert_spend := mini(conversion_amount, fighter.stored_ki)
	fighter.stored_ki -= convert_spend
	var draw_gain := mini(convert_spend, fighter.max_drawn_ki - fighter.drawn_ki)
	fighter.drawn_ki += draw_gain

	if upkeep_amount > 0 or convert_spend > 0 or draw_gain > 0:
		_log("%s form upkeep drains %d stored ki and converts %d to drawn ki." % [fighter.fighter_name, upkeep_amount + convert_spend, draw_gain])

func _apply_form_scaling(fighter: FighterStats, preserve_stamina_ratio: bool) -> void:
	var stamina_ratio := float(fighter.stamina) / maxf(1.0, float(fighter.max_stamina))
	fighter.physical_strength = int(round(float(fighter.base_physical_strength) * _get_form_value(FORM_STRENGTH_MULT, fighter.form_level)))
	fighter.ki_strength = int(round(float(fighter.base_ki_strength) * _get_form_value(FORM_KI_MULT, fighter.form_level)))
	fighter.speed = int(round(float(fighter.base_speed) * _get_form_value(FORM_SPEED_MULT, fighter.form_level)))
	fighter.max_stamina = int(round(float(fighter.base_max_stamina) * _get_form_value(FORM_MAX_STAMINA_MULT, fighter.form_level)))
	if preserve_stamina_ratio:
		fighter.stamina = int(round(float(fighter.max_stamina) * clampf(stamina_ratio, 0.0, 1.0)))
	fighter.clamp_resources()

func _get_form_value(table: Dictionary, form_level: int) -> float:
	if table.has(form_level):
		return float(table[form_level])
	var best_key := 0
	for key in table.keys():
		if int(key) <= form_level and int(key) > best_key:
			best_key = int(key)
	return float(table.get(best_key, 1.0))

func _log_attack_result(attacker_name: String, attack: AttackDef, result: Dictionary) -> void:
	if not result.get("ok", false):
		_log("%s failed %s (no resources)." % [attacker_name, attack.label])
		return
	match result.get("result", ""):
		"miss":
			_log("%s used %s but missed." % [attacker_name, attack.label])
		"vanished":
			_log("%s used %s but target vanished." % [attacker_name, attack.label])
		"hit":
			_log("%s used %s for %d dmg." % [attacker_name, attack.label, int(result.get("damage", 0))])

func _check_end() -> bool:
	if not state.is_finished():
		return false
	var result := state.winner()
	_log("Battle result: %s" % result)
	battle_finished.emit(result)
	return true

func _log(line: String) -> void:
	ui.append_log(line)

func _refresh_view() -> void:
	$"../BattleUI/Margin/VBox/Status".text = "Turn %d | Escalation P:%d E:%d" % [state.turn, int(state.player.escalation), int(state.enemy.escalation)]
	$"../BattleUI/Margin/VBox/PlayerStats".text = _fighter_line(state.player)
	$"../BattleUI/Margin/VBox/EnemyStats".text = _fighter_line(state.enemy)
	_refresh_debug_overlay()

func _fighter_line(f: FighterStats) -> String:
	return "%s HP %d/%d | Stam %d/%d | StoredKi %d/%d | DrawnKi %d/%d | Form %d%s" % [
		f.fighter_name, f.hp, f.max_hp, f.stamina, f.max_stamina, f.stored_ki, f.max_stored_ki, f.drawn_ki, f.max_drawn_ki, f.form_level,
		" +Kaioken" if f.kaioken_active else ""
	]

func _fighter_stat_lines(f: FighterStats) -> PackedStringArray:
	return PackedStringArray([
		"Name: %s" % f.fighter_name,
		"HP: %d / %d" % [f.hp, f.max_hp],
		"Stamina: %d / %d" % [f.stamina, f.max_stamina],
		"Stored Ki: %d / %d" % [f.stored_ki, f.max_stored_ki],
		"Drawn Ki: %d / %d" % [f.drawn_ki, f.max_drawn_ki],
		"Physical Strength: %d" % f.physical_strength,
		"Ki Strength: %d" % f.ki_strength,
		"Speed: %d" % f.speed,
		"Control: %d" % f.control,
		"Escalation: %d" % int(f.escalation),
		"Form Level: %d" % f.form_level,
		"Base Form Override: %d" % f.base_form_override_level,
		"Form Mastery: %d" % f.form_mastery_level,
		"Kaioken Active: %s" % ("Yes" if f.kaioken_active else "No"),
	])


func _on_debug_mode_toggled(enabled: bool) -> void:
	if enabled:
		_refresh_debug_overlay()

func _refresh_debug_overlay() -> void:
	if not ui.debug_mode_enabled:
		return
	var lines := PackedStringArray()
	lines.append("[b]Player Stats[/b]")
	for line in _fighter_debug_lines(state.player):
		lines.append(line)
	lines.append("")
	lines.append("[b]Enemy Stats[/b]")
	for line in _fighter_debug_lines(state.enemy):
		lines.append(line)
	ui.set_debug_stats(lines)

func _fighter_debug_lines(f: FighterStats) -> PackedStringArray:
	return PackedStringArray([
		"Name: %s" % f.fighter_name,
		"HP: %d / %d" % [f.hp, f.max_hp],
		"Stamina: %d / %d" % [f.stamina, f.max_stamina],
		"Stored Ki: %d / %d" % [f.stored_ki, f.max_stored_ki],
		"Drawn Ki: %d / %d" % [f.drawn_ki, f.max_drawn_ki],
		"Physical: %d (base %d)" % [f.physical_strength, f.base_physical_strength],
		"Ki: %d (base %d)" % [f.ki_strength, f.base_ki_strength],
		"Speed: %d (base %d)" % [f.speed, f.base_speed],
		"Form: %d | Kaioken: %s" % [f.form_level, "On" if f.kaioken_active else "Off"],
	])
