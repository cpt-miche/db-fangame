class_name BattleState
extends Resource

var turn: int = 1
var player: FighterStats
var enemy: FighterStats

func setup(player_base: FighterStats, enemy_base: FighterStats) -> void:
	player = player_base.duplicate_runtime()
	enemy = enemy_base.duplicate_runtime()
	turn = 1

func is_finished() -> bool:
	return player.hp <= 0 or enemy.hp <= 0

func winner() -> String:
	if player.hp <= 0 and enemy.hp <= 0:
		return "draw"
	if enemy.hp <= 0:
		return "player"
	if player.hp <= 0:
		return "enemy"
	return ""
