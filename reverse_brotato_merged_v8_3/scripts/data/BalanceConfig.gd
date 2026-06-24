extends Resource
class_name BalanceConfig

const MonsterDataScript = preload("res://scripts/data/MonsterData.gd")
const RedButtonEffectDataScript = preload("res://scripts/data/RedButtonEffectData.gd")
const DEFAULT_UNLOCKED: Array[String] = ["warrior", "archer", "slime"]
const GOLD_TO_SKILL_POINT_RATE = 25

@export var command_points_base = 92.0
@export var command_points_per_wave = 7.0
@export var command_point_regen = 4.2
@export var rage_command_regen_bonus_max = 1.2
@export var command_point_damage_reward = 0.045
@export var command_point_armor_break_reward = 24.0
@export var command_point_monster_death_reward = 3.0
@export var commander_max_hp = 180.0
@export var time_event_interval = 24.0

func create_monster_catalog() -> Dictionary:
	var catalog = {}
	catalog["warrior"] = _monster("warrior", "小哥布林战士", 0, 13, 36, 5.5, 0.0, 42, 1.55, 92, ["melee", "cheap"], "fast_melee", Color(0.35, 0.90, 0.34))
	catalog["archer"] = _monster("archer", "哥布林弓手", 0, 18, 24, 4.2, 0.0, 230, 0.95, 70, ["ranged"], "arrow", Color(0.36, 0.80, 0.95))
	catalog["slime"] = _monster("slime", "史莱姆守卫", 0, 22, 78, 3.0, 0.0, 46, 0.70, 46, ["tank", "slow"], "slow", Color(0.26, 0.82, 0.62))
	catalog["bomber"] = _monster("bomber", "炸弹小鬼", 80, 24, 25, 20.0, 8.0, 34, 1.0, 110, ["burst"], "suicide", Color(0.96, 0.54, 0.20))
	catalog["shaman"] = _monster("shaman", "巫毒萨满", 140, 26, 34, 3.5, 0.0, 188, 0.85, 62, ["ranged", "support"], "ritual_heal", Color(0.73, 0.42, 0.96))
	catalog["ogre"] = _monster("ogre", "食人魔", 260, 42, 150, 13.0, 12.0, 58, 0.55, 48, ["tank", "armor_breaker"], "armor_breaker", Color(0.84, 0.70, 0.38))
	# Population is the new real-time deployment limit. Command cost remains only for old-save compatibility.
	catalog["warrior"].population_cost = 1
	catalog["archer"].population_cost = 2
	catalog["slime"].population_cost = 2
	catalog["bomber"].population_cost = 2
	catalog["shaman"].population_cost = 3
	catalog["ogre"].population_cost = 5
	# Physical sizes and crowd pressure. Slimes fully resist knockback; ogres are heavy,
	# but can still be moved a little by a sufficiently strong hit.
	catalog["warrior"].collision_radius = 15.0
	catalog["warrior"].push_power = 1.0
	catalog["archer"].collision_radius = 14.0
	catalog["archer"].push_power = 0.35
	catalog["slime"].collision_radius = 21.0
	catalog["slime"].knockback_resistance = 0.0
	catalog["slime"].push_power = 1.35
	catalog["bomber"].collision_radius = 13.0
	catalog["bomber"].push_power = 0.85
	catalog["shaman"].collision_radius = 15.0
	catalog["shaman"].push_power = 0.35
	catalog["ogre"].collision_radius = 25.0
	catalog["ogre"].knockback_resistance = 0.35
	catalog["ogre"].push_power = 2.0

	catalog["bomber"].balance = {"radius": 82.0, "trigger_range": 38.0, "death_damage": 10.0}
	catalog["slime"].balance = {"slow_duration": 3.0, "slow_strength": 0.45}
	catalog["shaman"].balance = {"heal_amount": 10.0, "heal_radius": 92.0, "poison_duration": 5.0, "poison_dps": 2.0}
	return catalog

func create_red_button_effects() -> Array:
	var result: Array = []
	result.append(_red_effect("emergency", "战术空投", "勇者停滞 4 秒，立刻获得 70 指挥点；接下来 3 次部署免费。", {"stun": 4.0, "command_points": 70.0, "free_charges": 3}))
	result.append(_red_effect("missile", "破甲重炮", "无视护甲造成 45 伤害，击碎所有剩余护甲并眩晕 2 秒。护甲粉碎会让怪物狂暴。", {"true_damage": 45.0, "armor_percent": 1.0, "stun": 2.0, "radius": 132.0}))
	result.append(_red_effect("duel", "哥布林弹射决斗", "指挥官继承场上怪物快照，进入三选一回合制决斗。高风险，但可在残局赌一把。", {}))
	return result

func create_temp_boons() -> Array[Dictionary]:
	var boons: Array[Dictionary] = []
	boons.append({"id": "frenzy", "name": "快节奏剧本", "description": "本局所有怪物攻击速度 +15%。"})
	boons.append({"id": "melee_hp", "name": "前排增援", "description": "近战与坦克怪物生命 +20%。"})
	boons.append({"id": "ranged_crit", "name": "精准伏笔", "description": "弓手与萨满获得 18% 暴击概率。"})
	boons.append({"id": "better_berserk", "name": "破甲狂潮", "description": "勇者护甲粉碎后，怪物狂暴效果更强。"})
	boons.append({"id": "poison_amp", "name": "毒性加笔", "description": "中毒伤害提高 50%。"})
	boons.append({"id": "swift_cast", "name": "快速改写", "description": "所有怪物移动速度 +12%。"})
	return boons

func create_power_boons() -> Array[Dictionary]:
	var boons: Array[Dictionary] = []
	boons.append({"id": "power_attack", "name": "强力道具：剧本利刃", "description": "本局所有怪物攻击力 +30%。"})
	boons.append({"id": "power_swarm", "name": "强力道具：无尽群演", "description": "本局所有怪物攻击速度 +30%。"})
	boons.append({"id": "power_fortify", "name": "强力道具：地下城甲胄", "description": "本局所有怪物最大生命 +35%。"})
	return boons

func hero_base_stats(wave: int) -> Dictionary:
	return {
		"max_hp": 165.0 + wave * 24.0,
		"max_armor": 72.0 + wave * 13.0,
		"attack": 12.0 + wave * 2.3,
		"attack_range": 52.0,
		"attack_speed": 0.82 + min(0.35, wave * 0.025),
		"move_speed": 88.0 + min(26.0, wave * 3.0),
		"area_attack": false,
		"life_steal": 0.0,
		"weapon_name": "训练剑"
	}

func upgrade_cost(level: int) -> int:
	return 1 + level

func victory_rewards(wave: int) -> Dictionary:
	return {"gold": 62 + wave * 24, "skill_points": 1 + int(wave / 3)}

func _monster(id: String, display_name: String, unlock_cost: int, command_cost: int, hp: float, attack: float, armor_damage: float, attack_range: float, attack_speed: float, move_speed: float, tags: Array[String], ability: String, color: Color):
	var data = MonsterDataScript.new()
	data.id = id
	data.display_name = display_name
	data.unlock_cost = unlock_cost
	data.command_cost = command_cost
	data.max_hp = hp
	data.attack = attack
	data.armor_damage = armor_damage
	data.attack_range = attack_range
	data.attack_speed = attack_speed
	data.move_speed = move_speed
	data.tags = tags
	data.ability = ability
	data.color = color
	return data

func _red_effect(id: String, display_name: String, description: String, values: Dictionary):
	var data = RedButtonEffectDataScript.new()
	data.id = id
	data.display_name = display_name
	data.description = description
	data.values = values
	return data
