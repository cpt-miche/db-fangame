extends Node

signal battle_finished(result: String)

@export var player_base: FighterStats
@export var enemy_base: FighterStats
@export var kaioken_def: TransformationDef

@export var strike_attack: AttackDef
@export var ki_blast_attack: AttackDef
@export var ki_volley_attack: AttackDef
@export var ki_barrage_attack: AttackDef

@onready var ui: Control = $"../BattleUI"

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
	ui.action_pressed.connect(_on_action_pressed)
	ui.infusion_changed.connect(func(v: float) -> void: infusion_ratio = v)
	_refresh_view()

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
		&"transform":
			_toggle_kaioken(state.player)
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
	if action == &"transform":
		_toggle_kaioken(state.enemy)
		return

	var result := resolver.resolve_attack(state.enemy, state.player, attacks[action], 0.25, kaioken_def, rng)
	_log_attack_result(state.enemy.fighter_name, attacks[action], result)

func _apply_end_round() -> void:
	state.turn += 1
	state.player.escalation += 3
	state.enemy.escalation += 3
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

func _toggle_kaioken(fighter: FighterStats) -> void:
	if fighter.kaioken_active:
		fighter.kaioken_active = false
		_log("%s deactivates Kaioken." % fighter.fighter_name)
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

func _fighter_line(f: FighterStats) -> String:
	return "%s HP %d/%d | Stam %d/%d | StoredKi %d/%d | DrawnKi %d/%d" % [
		f.fighter_name, f.hp, f.max_hp, f.stamina, f.max_stamina, f.stored_ki, f.max_stored_ki, f.drawn_ki, f.max_drawn_ki
	]
