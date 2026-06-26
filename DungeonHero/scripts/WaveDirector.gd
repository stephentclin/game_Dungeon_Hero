extends Node
class_name WaveDirector

const HeroUpgradeDataScript = preload("res://scripts/data/HeroUpgradeData.gd")

signal wave_started(wave, hero_stats)
signal wave_finished(wave, rewards)

var balance
var rng = RandomNumberGenerator.new()

func setup(config) -> void:
	balance = config
	rng.randomize()

func build_hero_stats(wave: int) -> Dictionary:
	var stats = balance.hero_base_stats(wave)
	var upgrades = _choose_hero_upgrades(wave)
	var names: Array[String] = []
	for upgrade in upgrades:
		upgrade.apply_to(stats)
		names.append(upgrade.display_name)
	stats["upgrade_names"] = names
	wave_started.emit(wave, stats)
	return stats

func victory_rewards(wave: int) -> Dictionary:
	var rewards = balance.victory_rewards(wave)
	wave_finished.emit(wave, rewards)
	return rewards

func choose_temp_boons(count = 3) -> Array[Dictionary]:
	var pool = balance.create_temp_boons()
	var result: Array[Dictionary] = []
	while result.size() < count and pool.size() > 0:
		var index = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func _choose_hero_upgrades(wave: int) -> Array:
	var pool: Array = [
		_upgrade("hp", "生命强化", "最大生命提高。", {"max_hp": 22.0 + wave * 3.0}),
		_upgrade("attack", "武器升级", "攻击力提高。", {"attack": 3.0 + wave * 0.5, "weapon_name": "重刃"}),
		_upgrade("speed", "攻速提升", "攻击速度提高。", {"attack_speed": 0.12}),
		_upgrade("area", "横扫攻击", "攻击会波及附近怪物。", {"area_attack": true, "attack_range": 8.0}),
		_upgrade("lifesteal", "战意回血", "击杀怪物后回复生命。", {"life_steal": 5.0 + wave}),
		_upgrade("armor", "厚重护甲", "护甲更厚。", {"max_armor": 22.0 + wave * 2.0})
	]
	var result: Array = []
	var picks = clamp(1 + int(wave / 3), 1, 3)
	while result.size() < picks and pool.size() > 0:
		var index = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func _upgrade(id: String, display_name: String, description: String, changes: Dictionary):
	var data = HeroUpgradeDataScript.new()
	data.id = id
	data.display_name = display_name
	data.description = description
	data.stat_changes = changes
	return data
