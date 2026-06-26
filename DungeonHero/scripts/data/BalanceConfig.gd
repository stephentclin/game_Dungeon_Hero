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
	catalog["warrior"] = _monster("warrior", "骷髅兵", 0, 13, 36, 5.5, 0.0, 42, 1.55, 92, ["melee", "cheap"], "fast_melee", Color(0.35, 0.90, 0.34))
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
	catalog["warrior"].summon_cooldown = 2.2
	catalog["archer"].summon_cooldown = 4.0
	catalog["slime"].summon_cooldown = 5.0
	catalog["bomber"].summon_cooldown = 8.0
	catalog["shaman"].summon_cooldown = 8.5
	catalog["ogre"].summon_cooldown = 13.0
	catalog["warrior"].display_name_en = "Skeleton Soldier"
	catalog["archer"].display_name_en = "Goblin Archer"
	catalog["slime"].display_name_en = "Slime Guard"
	catalog["bomber"].display_name_en = "Bomb Imp"
	catalog["shaman"].display_name_en = "Voodoo Shaman"
	catalog["ogre"].display_name_en = "Ogre"
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
	boons.append({"id": "sharp_script", "name": "锋利剧本", "name_en": "Sharpened Script", "description": "全体怪物攻击 +10%。可叠加 3 次。", "description_en": "All monsters gain +10% attack. Stacks up to 3." , "max_stacks": 3, "kind": "normal"})
	boons.append({"id": "frantic_beat", "name": "狂躁节拍", "name_en": "Frantic Beat", "description": "全体怪物攻速 +8%。可叠加 3 次。", "description_en": "All monsters gain +8% attack speed. Stacks up to 3.", "max_stacks": 3, "kind": "normal"})
	boons.append({"id": "crimson_foreshadow", "name": "血色伏笔", "name_en": "Crimson Foreshadow", "description": "全体怪物暴击率 +5%。可叠加 4 次。", "description_en": "All monsters gain +5% critical chance. Stacks up to 4.", "max_stacks": 4, "kind": "normal"})
	boons.append({"id": "deadly_edit", "name": "致命落笔", "name_en": "Deadly Edit", "description": "暴击伤害 +25%。可叠加 3 次。", "description_en": "Critical damage +25%. Stacks up to 3.", "max_stacks": 3, "kind": "normal"})
	boons.append({"id": "ink_reflux", "name": "墨水回流", "name_en": "Ink Reflux", "description": "怪物移动速度 +5%。可叠加 3 次。", "description_en": "Monster move speed +5%. Stacks up to 3.", "max_stacks": 3, "kind": "normal"})
	boons.append({"id": "quick_entrance", "name": "快速入场", "name_en": "Quick Entrance", "description": "全兵种召唤冷却 -7%。可叠加 3 次。", "description_en": "All summon cooldowns -7%. Stacks up to 3.", "max_stacks": 3, "kind": "normal"})
	return boons

func create_power_boons() -> Array[Dictionary]:
	var boons: Array[Dictionary] = []
	boons.append({"id": "ensemble_riot", "name": "群演暴动", "name_en": "Ensemble Riot", "description": "场上有至少 3 种不同兵种时，全体攻击与攻速 +12%。", "description_en": "With 3 different unit types alive, all units gain +12% ATK and SPD.", "max_stacks": 1, "kind": "power"})
	boons.append({"id": "death_rewrite", "name": "死亡改稿", "name_en": "Death Rewrite", "description": "任意怪物死亡后，下一只召唤怪物进入狂暴。", "description_en": "When any unit dies, the next summoned unit enters Berserk.", "max_stacks": 1, "kind": "power"})
	boons.append({"id": "blackout_ambush", "name": "黑幕伏击", "name_en": "Blackout Ambush", "description": "新召唤怪物 1.5 秒内不会被勇者主动锁定。", "description_en": "Newly summoned units cannot be actively targeted for 1.5 seconds.", "max_stacks": 1, "kind": "power"})
	boons.append({"id": "last_monologue", "name": "临终独白", "name_en": "Last Monologue", "description": "勇者生命低于 25% 时，全体暴击率 +25%，暴伤 +30%。", "description_en": "Below 25% hero HP: +25% crit chance and +30% crit damage.", "max_stacks": 1, "kind": "power"})
	boons.append({"id": "rewrite_ending", "name": "改写结局", "name_en": "Rewrite Ending", "description": "本房间额外获得一次【改写剧本】。", "description_en": "Gain one extra Rewrite Scene use this room.", "max_stacks": 1, "kind": "power"})
	boons.append({"id": "curtain_blast", "name": "落幕爆破", "name_en": "Curtain Blast", "description": "当前选中兵种死亡时产生小爆炸，不影响炸弹兵的专业爆破地位。", "description_en": "The currently selected unit type makes a small death explosion. Bomb Imps remain the real demolition experts.", "max_stacks": 1, "kind": "power"})
	return boons

func hero_base_stats(wave: int) -> Dictionary:
	return {
		"max_hp": 165.0 + wave * 24.0,
		"max_armor": 0.0,
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
