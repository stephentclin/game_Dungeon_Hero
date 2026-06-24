extends Node2D

const ArenaScene = preload("res://scenes/Arena.tscn")
const HeroScene = preload("res://scenes/Hero.tscn")
const CommanderScene = preload("res://scenes/GoblinCommander.tscn")
const SpawnerScene = preload("res://scenes/MonsterSpawner.tscn")

const BalanceConfigScript = preload("res://scripts/data/BalanceConfig.gd")
const SaveSystemScript = preload("res://scripts/SaveSystem.gd")
const WaveDirectorScript = preload("res://scripts/WaveDirector.gd")
const RageSystemScript = preload("res://scripts/RageSystem.gd")
const RedButtonSystemScript = preload("res://scripts/RedButtonSystem.gd")
const CombatSystemScript = preload("res://scripts/CombatSystem.gd")
const PlacementSystemScript = preload("res://scripts/PlacementSystem.gd")
const UIControllerScript = preload("res://scripts/UIController.gd")
const InteractiveObjectScript = preload("res://scripts/InteractiveObject.gd")
const MapDirectorScript = preload("res://scripts/MapDirector.gd")

var balance = BalanceConfigScript.new()
var save_system = SaveSystemScript.new()
var wave_director = WaveDirectorScript.new()
var rage_system = RageSystemScript.new()
var red_button_system = RedButtonSystemScript.new()
var combat_system = CombatSystemScript.new()
var placement = PlacementSystemScript.new()
var ui = UIControllerScript.new()
var map_director = MapDirectorScript.new()

var world_root: Node2D
var interactive_root: Node2D
var unit_root: Node2D
var arena: Node2D
var hero: Node
var commander: Node
var spawner: Node

var monster_catalog = {}
var save_data = {}
var phase = "boot"
var wave = 1
var command_points = 0.0
var max_command_points = 100.0
var battle_time = 0.0
var time_event_countdown = 0.0
var selected_monster_id = "warrior"
var active_boons: Array[String] = []
var first_free_used = {}
var red_free_deploy_charges = 0
var interactives: Array = []
var interactive_spawn_countdown = 0.0
var interactive_despawn_countdown = 0.0
const MAX_INTERACTIVES = 5
const INTERACTIVE_SPAWN_RECT = Rect2(Vector2(112, 188), Vector2(760, 330))
# The selected number of lives is loaded from menu settings (1–5).
var hero_lives_total = 5
var hero_lives_remaining = 5
const ARENA_BOUNDS = Rect2(Vector2(38, 62), Vector2(908, 610))
var pending_boons: Array[Dictionary] = []
var current_hero_stats = {}
var duel = {}
var waves_defeated = 0
var map_index = 0
var room_time_remaining = 90.0
var hero_inventory: Array = []
var hero_escape_count = 0
var last_reclaimed_loot: Array = []
var pending_choice_kind = ""
var pending_transition_reason = ""
const FINAL_ROOM_INDEX = 4

func _ready() -> void:
	randomize()
	monster_catalog = balance.create_monster_catalog()
	save_data = save_system.load_progress(monster_catalog)
	hero_lives_total = clampi(int(save_data.get("settings", {}).get("hero_lives", 5)), 1, 5)
	hero_lives_remaining = hero_lives_total
	_build_world()
	_connect_signals()
	start_new_run()

func current_language() -> String:
	return str(save_data.get("settings", {}).get("language", "zh"))

func hero_level() -> int:
	# The hero levels when he successfully writes a chapter and escapes to the next room.
	return max(1, hero_escape_count + 1)

func hero_seal_count() -> int:
	var lost_lives = hero_lives_total - hero_lives_remaining
	return clampi(1 + lost_lives, 1, 5)

func hero_seal_names() -> Array:
	var names = ["虚无", "元素", "能量", "生命", "轮回"]
	var result = []
	for index in range(hero_seal_count()):
		result.append(names[index])
	return result

func newly_activated_seal_name() -> String:
	var names = ["虚无之躯", "元素屏障", "能量限界", "生命圣泉", "轮回圣印"]
	var index = clampi(hero_seal_count() - 1, 0, names.size() - 1)
	return names[index]

func is_final_room() -> bool:
	return map_index >= FINAL_ROOM_INDEX

func guardian_tower_active() -> bool:
	return is_final_room() and commander != null and commander.visible

func should_show_deploy_prompt() -> bool:
	return is_tutorial_wave() and not bool(save_data.get("settings", {}).get("deploy_tutorial_seen", false))

func mark_deploy_tutorial_seen() -> void:
	if not save_data.has("settings"):
		save_data["settings"] = {}
	save_data["settings"]["deploy_tutorial_seen"] = true
	save_system.save_progress(save_data)

func resolve_wall_contact(body: Node2D) -> void:
	if body == null or not body.has_method("collision_size"):
		return
	var radius = float(body.call("collision_size"))
	var safe_rect = ARENA_BOUNDS.grow(-radius - 4.0)
	var old_position = body.global_position
	var corrected = Vector2(clamp(old_position.x, safe_rect.position.x, safe_rect.end.x), clamp(old_position.y, safe_rect.position.y, safe_rect.end.y))
	if corrected == old_position:
		return
	var inward = (ARENA_BOUNDS.get_center() - old_position).normalized()
	body.global_position = corrected
	if body.has_method("on_wall_contact"):
		body.call("on_wall_contact", inward)

func _process(delta: float) -> void:
	if phase == "battle":
		_process_battle(delta)
	# Lives and stat bars must also refresh during reward / victory overlays.
	ui.update_stats()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var order = monster_order()
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var index = event.keycode - KEY_1
			if index < order.size():
				select_monster(order[index])
		elif event.keycode == KEY_SPACE:
			begin_battle()
		elif event.keycode == KEY_R:
			force_red_button()

func start_new_run() -> void:
	wave = 1
	waves_defeated = 0
	map_index = 0
	hero_escape_count = 0
	hero_inventory.clear()
	last_reclaimed_loot.clear()
	pending_choice_kind = ""
	pending_transition_reason = ""
	hero_lives_total = clampi(int(save_data.get("settings", {}).get("hero_lives", 5)), 1, 5)
	hero_lives_remaining = hero_lives_total
	active_boons.clear()
	first_free_used.clear()
	red_free_deploy_charges = 0
	red_button_system.reset_for_run()
	rage_system.reset_for_run()
	commander.reset_health()
	# New players begin with one clear unit and one clear decision.
	selected_monster_id = "warrior"
	select_monster(selected_monster_id)
	start_prepare()

func start_prepare() -> void:
	phase = "prepare"
	wave = map_index + 1
	battle_time = 0.0
	room_time_remaining = 90.0
	time_event_countdown = balance.time_event_interval
	# Population is deliberately fixed for now. Room victories improve the build via item choices, not more slots.
	max_command_points = 0.0
	command_points = 0.0
	spawner.despawn_all()
	combat_system.clear_runtime_fx()
	map_director.start_room(map_index)
	if commander != null and commander.has_method("set_guardian_mode"):
		commander.set_guardian_mode(is_final_room())
	current_hero_stats = wave_director.build_hero_stats(hero_level())
	_apply_hero_escape_upgrades(current_hero_stats)
	hero.setup(current_hero_stats, Vector2(492, 284), self)
	hero.deactivate()
	_reroll_interactives_for_wave()
	interactive_spawn_countdown = randf_range(9.0, 14.0)
	interactive_despawn_countdown = randf_range(15.0, 22.0)
	placement.enabled = true
	ui.show_prepare(current_hero_stats)
	ui.refresh_monster_list()
	if is_final_room():
		ui.show_event("最终房间：守卫塔已上线。范围内怪物获得【鼓舞】。", true)
	elif is_tutorial_wave():
		ui.show_event("第一波训练：点击绿色部署区放下战士，再开始战斗。")
	else:
		ui.show_event("剧本席位 %d/%d：怪物死亡会立刻返还席位，可立即补位。" % [population_used(), population_capacity()])

func begin_battle() -> void:
	if phase != "prepare":
		return
	phase = "battle"
	hero.activate()
	ui.hide_overlay()
	ui.show_event("战斗开始：怪物会自动围攻勇者。")

func request_place_monster(monster_id: String, slot: Vector2) -> void:
	if not monster_catalog.has(monster_id):
		return
	if not is_monster_unlocked(monster_id):
		ui.show_event("该兵种还没有解锁。", true)
		return
	if is_tutorial_wave() and monster_id != "warrior":
		ui.show_event("第一波先用战士练习部署，胜利后会开放其他已解锁兵种。", true)
		return
	if not placement.can_place_at(slot):
		ui.show_event(placement.block_reason(slot), true)
		return
	var data = monster_catalog[monster_id]
	var cost = int(data.population_cost)
	if population_used() + cost > population_capacity():
		ui.show_event("剧本席位不足：需要 %d，剩余 %d。" % [cost, population_free()], true)
		return
	if commander != null and commander.has_method("trigger_summon_cast"):
		commander.trigger_summon_cast()
	var monster = spawner.spawn(data, monster_level(monster_id), slot)
	if hero.armor <= 0.0:
		monster.apply_berserk()
	ui.show_event("写入战场：%s（席位 %d）" % [data.display_name, cost])

func select_monster(monster_id: String) -> void:
	if not monster_catalog.has(monster_id):
		return
	if not is_monster_available_this_wave(monster_id):
		ui.show_event("第一波训练中：先使用战士。", true)
		return
	selected_monster_id = monster_id
	placement.set_selected(monster_id)
	ui.set_selected(monster_id)

func unlock_selected_monster() -> void:
	var id = selected_monster_id
	if not monster_catalog.has(id) or is_monster_unlocked(id):
		return
	var data = monster_catalog[id]
	if int(save_data["gold"]) < data.unlock_cost:
		ui.show_event("金币不足，无法解锁。", true)
		return
	save_data["gold"] = int(save_data["gold"]) - data.unlock_cost
	save_data["unlocked"].append(id)
	save_system.save_progress(save_data)
	ui.refresh_monster_list()
	ui.show_event("永久解锁：%s" % data.display_name)

func upgrade_selected_monster() -> void:
	var id = selected_monster_id
	if not monster_catalog.has(id) or not is_monster_unlocked(id):
		return
	var level = monster_level(id)
	if level >= hero_level():
		ui.show_event("兵种等级不能超过当前勇者等级（%d）。" % hero_level(), true)
		return
	var cost = balance.upgrade_cost(level)
	if int(save_data["skill_points"]) < cost:
		ui.show_event("技能点不足，无法升级。", true)
		return
	save_data["skill_points"] = int(save_data["skill_points"]) - cost
	save_data["upgrades"][id] = level + 1
	save_system.save_progress(save_data)
	ui.refresh_monster_list()
	ui.show_event("永久升级：%s Lv.%d" % [monster_catalog[id].display_name, level + 1])

func choose_temp_boon(boon_id: String) -> void:
	if boon_id != "":
		active_boons.append(boon_id)
		ui.show_event("获得道具：%s" % _boon_name(boon_id), true)
	var reason = pending_transition_reason
	pending_choice_kind = ""
	pending_transition_reason = ""
	if reason == "hero_defeated":
		if is_final_room():
			# In the last room, another life returns to the same final arena. The tower remains active.
			start_prepare()
		else:
			map_index += 1
			start_prepare()
	elif reason == "hero_cleared_room":
		map_index += 1
		start_prepare()
	else:
		start_prepare()

func force_red_button() -> void:
	if phase != "battle":
		return
	if not map_director.can_rewrite_scene():
		ui.show_event("剧本改写仍在冷却：开战 8 秒后才能使用。", true)
		return
	if map_director.rewrite_scene():
		ui.show_event("剧本已被反写。勇者以为他在闯关，其实是你在改关。", true)

func choose_red_button(effect_id: String) -> void:
	var effect = _red_effect_by_id(effect_id)
	if effect == null:
		return
	ui.hide_overlay()
	red_button_system.mark_safe_trigger_used()
	rage_system.reset_to(0.0)
	phase = "battle"
	match effect_id:
		"emergency":
			hero.apply_status("stun", float(effect.values.get("stun", 4.0)), 1.0)
			command_points = min(max_command_points, command_points + float(effect.values.get("command_points", 70.0)))
			red_free_deploy_charges += int(effect.values.get("free_charges", 3))
			combat_system.shake(0.20, 7.0)
			ui.show_event("红按钮：战术空投完成，接下来 %d 次部署免费。" % red_free_deploy_charges, true)
		"missile":
			var armor_shatter = hero.armor * float(effect.values.get("armor_percent", 0.70))
			hero.shatter_armor(armor_shatter)
			hero.take_damage(float(effect.values.get("true_damage", 45.0)), null, {"ignore_armor": true, "source": "red_missile"})
			hero.apply_status("stun", float(effect.values.get("stun", 2.0)), 1.0)
			combat_system.spawn_explosion(hero.global_position, float(effect.values.get("radius", 132.0)), 0.0, 0.0, {"source": "red_missile"}, false)
			ui.show_event("红按钮：破甲重炮命中，勇者护甲被撕裂。", true)
		"duel":
			_start_duel()
		_:
			pass

func choose_duel_action(action_id: String) -> void:
	if phase != "duel":
		return
	var goblin_damage = float(duel.get("goblin_attack", 10.0))
	var shield = 0.0
	match action_id:
		"strike":
			duel["hero_hp"] -= goblin_damage
		"venom":
			duel["hero_hp"] -= goblin_damage * 0.62
			duel["poison"] = float(duel.get("poison", 0.0)) + 3.0
		"shield":
			shield = 0.55
			duel["hero_hp"] -= goblin_damage * 0.35
		"blast":
			duel["hero_hp"] -= goblin_damage * 1.45
			duel["goblin_hp"] -= 8.0
	if float(duel.get("poison", 0.0)) > 0.0:
		duel["hero_hp"] -= 6.0
		duel["poison"] = float(duel["poison"]) - 1.0
	if float(duel["hero_hp"]) <= 0.0:
		phase = "battle"
		hero.take_damage(99999.0, null, {"source": "duel"})
		return
	var hero_attack = float(duel.get("hero_attack", 14.0))
	if randf() < 0.30:
		hero_attack *= 0.65
	duel["goblin_hp"] -= hero_attack * (1.0 - shield)
	if float(duel["goblin_hp"]) <= 0.0:
		game_over("弹射决斗失败，哥布林亲自上场后被击败。")
		return
	ui.show_duel(duel, _duel_actions())

func phase_name() -> String:
	match phase:
		"prepare":
			return "准备"
		"battle":
			return "战斗"
		"reward":
			return "奖励"
		"red_choice":
			return "红按钮"
		"duel":
			return "决斗"
		"game_over":
			return "失败"
		"victory":
			return "胜利"
		"hero_escape":
			return "勇者升级"
		_:
			return phase

func monster_order() -> Array[String]:
	return ["warrior", "archer", "slime", "bomber", "shaman", "ogre"]

func is_monster_unlocked(id: String) -> bool:
	return save_data.get("unlocked", []).has(id)

func is_tutorial_wave() -> bool:
	return wave == 1 and waves_defeated == 0

func is_monster_available_this_wave(id: String) -> bool:
	return not is_tutorial_wave() or id == "warrior"

func monster_level(id: String) -> int:
	return int(save_data.get("upgrades", {}).get(id, 0))

func command_regen_multiplier() -> float:
	return 0.0

func get_active_monsters() -> Array:
	return spawner.get_active_monsters()

func monster_attack_speed_multiplier(data) -> float:
	var value = 1.0
	if active_boons.has("frenzy"):
		value *= 1.15
	if active_boons.has("power_swarm"):
		value *= 1.30
	return value

func monster_damage_multiplier(data) -> float:
	var value = 1.0
	if active_boons.has("power_attack"):
		value *= 1.30
	return value

func monster_hp_multiplier(data) -> float:
	var value = 1.0
	if active_boons.has("melee_hp") and (data.tags.has("melee") or data.tags.has("tank")):
		value *= 1.20
	if active_boons.has("power_fortify"):
		value *= 1.35
	return value

func monster_move_speed_multiplier(data) -> float:
	return 1.12 if active_boons.has("swift_cast") else 1.0

func ranged_crit_chance() -> float:
	return 0.18 if active_boons.has("ranged_crit") else 0.0

func poison_damage_multiplier() -> float:
	return 1.50 if active_boons.has("poison_amp") else 1.0

func poison_rage_bonus() -> float:
	return 0.0

func berserk_attack_speed_multiplier() -> float:
	return 1.42 if active_boons.has("better_berserk") else 1.25

func berserk_move_speed_multiplier() -> float:
	return 1.25 if active_boons.has("better_berserk") else 1.15

func berserk_damage_multiplier() -> float:
	return 1.12 if active_boons.has("better_berserk") else 1.0

func guardian_inspiration_for(monster) -> bool:
	# Final-room guardian tower broadcasts a map-wide inspiration effect.
	return guardian_tower_active() and monster != null

func guardian_damage_multiplier_for(monster) -> float:
	return 1.15 if guardian_inspiration_for(monster) else 1.0

func guardian_attack_speed_multiplier_for(monster) -> float:
	return 1.15 if guardian_inspiration_for(monster) else 1.0

func guardian_move_speed_multiplier_for(monster) -> float:
	return 1.10 if guardian_inspiration_for(monster) else 1.0

func apply_damage_to_hero(amount: float, source = null, tags = {}) -> float:
	if phase != "battle" and phase != "duel":
		return 0.0
	var final_tags = tags.duplicate(true)
	var final_amount = amount
	if source != null and is_instance_valid(source) and map_director.is_in_light(source.global_position):
		final_tags["always_hit"] = true
		final_tags["light_empowered"] = true
		final_amount *= 1.22
	if bool(final_tags.get("light_empowered", false)):
		hero.apply_status("burn", 1.5, 1.0)
	var ability = str(final_tags.get("ability", ""))
	# Apply status before the Element seal checks damage.
	if ability == "poison" or ability == "ritual_heal":
		hero.apply_status("poison", 5.0, 2.0 * poison_damage_multiplier())
	elif ability == "slow":
		hero.apply_status("slow", 3.0, 0.42)
	var dealt = hero.take_damage(final_amount, source, final_tags)
	if bool(final_tags.get("critical", false)) and dealt > 0.0:
		combat_system.spawn_floating_text(hero.global_position + Vector2(20, -56), "暴击", Color(1.0, 0.92, 0.22), true)
	return dealt

func apply_explosion_damage(world_position: Vector2, radius: float, damage: float, stun: float, tags = {}) -> void:
	var source = str(tags.get("source", ""))
	if hero.active and hero.global_position.distance_to(world_position) <= radius:
		var hero_damage = damage * float(tags.get("hero_damage_multiplier", 1.0))
		apply_damage_to_hero(hero_damage, null, tags)
		if stun > 0.0:
			hero.apply_status("stun", stun, 1.0)
	# Oil barrels now damage both factions. The monster multiplier prevents one stray
	# barrel from deleting a full army, while still making positioning matter.
	if source == "barrel":
		for monster in get_active_monsters():
			if monster.global_position.distance_to(world_position) <= radius * 0.86:
				monster.take_damage(damage * 0.62, null)
	for obj in get_active_interactives():
		if obj.kind == "barrel" and obj.global_position.distance_to(world_position) <= radius and source != "barrel":
			obj.ignite(0.45)

func get_hero_target() -> Node:
	var closest_monster = null
	var closest_distance = INF
	for monster in get_active_monsters():
		if not map_director.hero_can_see(monster.global_position):
			continue
		var distance = hero.global_position.distance_to(monster.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_monster = monster
	if closest_monster == null:
		return null
	var obstacle = get_blocking_obstacle_toward(hero.global_position, closest_monster.global_position)
	if obstacle != null:
		return obstacle
	return closest_monster

func get_blocking_obstacle_toward(from_position: Vector2, to_position: Vector2):
	var segment = to_position - from_position
	var length = segment.length()
	if length <= 0.1:
		return null
	var direction = segment / length
	for obj in interactives:
		if not obj.active or obj.kind != "obstacle":
			continue
		var rel = obj.global_position - from_position
		var projection = clamp(rel.dot(direction), 0.0, length)
		var closest = from_position + direction * projection
		if obj.global_position.distance_to(closest) <= obj.radius + 18.0:
			return obj
	return null

func get_active_interactives() -> Array:
	var result: Array = []
	for obj in interactives:
		if is_instance_valid(obj) and obj.active:
			result.append(obj)
	return result

func get_environment_effects_at(point: Vector2) -> Dictionary:
	var effects = {"slow": false, "poison": false, "poison_dps": 6.0, "light": false, "light_burn": 0.0}
	for obj in get_active_interactives():
		if obj.global_position.distance_to(point) > obj.radius:
			continue
		if obj.kind == "slow_pool":
			effects["slow"] = true
		elif obj.kind == "poison_pool":
			effects["poison"] = true
			effects["poison_dps"] = max(float(effects["poison_dps"]), 6.0)
	var room_effects = map_director.get_environment_effects(point)
	if bool(room_effects.get("poison", false)):
		effects["poison"] = true
		effects["poison_dps"] = max(float(effects["poison_dps"]), float(room_effects.get("poison_dps", 0.0)))
	if bool(room_effects.get("light", false)):
		effects["light"] = true
		effects["light_burn"] = float(room_effects.get("light_burn", 0.0))
	return effects

func is_point_in_slime(point: Vector2) -> bool:
	# Kept as a compatibility helper for any older scripts.
	return bool(get_environment_effects_at(point).get("slow", false))

func get_barrel_bomber_multiplier(world_position: Vector2) -> float:
	for monster in get_active_monsters():
		if monster.data != null and monster.data.ability == "suicide" and monster.global_position.distance_to(world_position) <= 116.0:
			return 3.0
	return 1.0

func get_hero_crowd_push(hero_position: Vector2) -> Vector2:
	var weighted_center = Vector2.ZERO
	var total_weight = 0.0
	var contributors = 0
	for monster in get_active_monsters():
		if not monster.can_push_hero():
			continue
		var contact_distance = hero.collision_size() + monster.collision_size() + 26.0
		if monster.global_position.distance_to(hero_position) > contact_distance:
			continue
		var weight = monster.push_weight()
		weighted_center += monster.global_position * weight
		total_weight += weight
		contributors += 1
	# Three small bodies, or a smaller crowd with an ogre, creates enough pressure.
	if contributors < 3 and total_weight < 3.0:
		return Vector2.ZERO
	if total_weight <= 0.0:
		return Vector2.ZERO
	var direction = hero_position - weighted_center / total_weight
	if direction.length_squared() < 0.001:
		direction = Vector2.UP
	var strength = clamp(34.0 + (total_weight - 3.0) * 48.0, 34.0, 210.0)
	return direction.normalized() * strength

func population_capacity() -> int:
	# Fixed in this version: progression is item-choice driven, not population growth.
	return 8

func population_used() -> int:
	var used = 0
	for monster in get_active_monsters():
		if monster.data != null:
			used += int(monster.data.population_cost)
	return used

func population_free() -> int:
	return max(0, population_capacity() - population_used())

func get_map_bodies() -> Array:
	var bodies: Array = []
	if hero != null and hero.active:
		bodies.append(hero)
	for monster in get_active_monsters():
		bodies.append(monster)
	return bodies

func mirror_combatants() -> void:
	var left = ARENA_BOUNDS.position.x + 12.0
	var right = ARENA_BOUNDS.end.x - 12.0
	if hero != null and hero.active:
		hero.global_position.x = left + right - hero.global_position.x
		resolve_wall_contact(hero)
	for monster in get_active_monsters():
		monster.global_position.x = left + right - monster.global_position.x
		resolve_wall_contact(monster)
	combat_system.clear_runtime_fx()

func _apply_hero_escape_upgrades(stats: Dictionary) -> void:
	var upgrades = hero_inventory.size()
	if upgrades <= 0:
		return
	stats["max_hp"] = float(stats.get("max_hp", 0.0)) + upgrades * 18.0
	stats["attack"] = float(stats.get("attack", 0.0)) + upgrades * 2.0
	stats["move_speed"] = float(stats.get("move_speed", 0.0)) + upgrades * 3.0
	stats["weapon_name"] = "遗物强化剑 +%d" % upgrades

func _on_hero_escape() -> void:
	if phase != "battle":
		return
	if is_final_room():
		game_over("最终房间倒计时结束，勇者仍然活着。")
		return
	phase = "room_clear_choice"
	hero.deactivate()
	spawner.despawn_all()
	var relic = map_director.current_relic(current_language())
	hero_inventory.append(relic)
	hero_escape_count += 1
	pending_boons = wave_director.choose_temp_boons()
	pending_choice_kind = "normal"
	pending_transition_reason = "hero_cleared_room"
	ui.show_normal_room_choice(relic, map_director.room_name(current_language()), pending_boons)
	ui.show_event("勇者清荡了房间，带走【%s】；你获得一次普通道具选择。" % relic, true)

func continue_after_hero_escape() -> void:
	if pending_transition_reason == "hero_cleared_room":
		choose_temp_boon("")

func game_over(reason: String) -> void:
	if phase == "game_over":
		return
	phase = "game_over"
	hero.deactivate()
	save_system.save_progress(save_data)
	ui.show_game_over(reason, waves_defeated)
	ui.show_event("挑战失败：永久资源已保存。", true)

func _build_world() -> void:
	add_child(wave_director)
	add_child(rage_system)
	add_child(red_button_system)
	add_child(ui)
	world_root = Node2D.new()
	add_child(world_root)
	arena = ArenaScene.instantiate()
	world_root.add_child(arena)
	map_director.setup(self)
	world_root.add_child(map_director)
	interactive_root = Node2D.new()
	world_root.add_child(interactive_root)
	unit_root = Node2D.new()
	world_root.add_child(unit_root)
	combat_system.setup(self, world_root)
	world_root.add_child(combat_system)
	commander = CommanderScene.instantiate()
	unit_root.add_child(commander)
	commander.setup(Vector2(492, 626), balance.commander_max_hp, self)
	hero = HeroScene.instantiate()
	unit_root.add_child(hero)
	spawner = SpawnerScene.instantiate()
	add_child(spawner)
	spawner.setup(self, unit_root)
	placement.setup(self)
	world_root.add_child(placement)
	wave_director.setup(balance)
	red_button_system.setup(balance)
	ui.setup(self)

func _connect_signals() -> void:
	hero.died.connect(_on_hero_died)
	hero.armor_broken.connect(_on_hero_armor_broken)
	commander.died.connect(func(): game_over("哥布林指挥台被勇者摧毁。"))
	rage_system.rage_full.connect(_on_rage_full)
	red_button_system.choice_required.connect(_on_red_button_choice_required)

func _process_battle(delta: float) -> void:
	battle_time += delta
	room_time_remaining = max(0.0, room_time_remaining - delta)
	map_director.process_room(delta)
	_process_interactive_timers(delta)
	if room_time_remaining <= 0.0:
		if is_final_room() and hero != null and hero.active:
			game_over("最终房间倒计时结束，勇者仍然活着。")
		else:
			_on_hero_escape()

func _on_monster_died(monster) -> void:
	# Population is derived from active units, so the seat is returned immediately.
	ui.show_event("%s退场，剧本席位已返还。" % monster.data.display_name, true)

func _on_hero_armor_broken() -> void:
	for monster in get_active_monsters():
		monster.apply_berserk()
	combat_system.shake(0.24, 9.0)
	ui.show_event("护甲粉碎！怪物狂暴！", true)

func _on_hero_died() -> void:
	if phase != "battle" and phase != "duel":
		return
	hero_lives_remaining = max(0, hero_lives_remaining - 1)
	last_reclaimed_loot = hero_inventory.duplicate()
	hero_inventory.clear()
	ui.update_stats()
	if hero_lives_remaining <= 0:
		_run_victory()
		return
	_begin_hero_defeat_choice()

func _on_rage_full() -> void:
	if phase != "battle":
		return
	if red_button_system.safe_triggers_left() <= 0:
		ui.show_event("怒气已满，但本局红按钮已经使用。它不再会造成突然失败。", true)
		return
	phase = "red_choice"
	red_button_system.begin_trigger(hero.hp_ratio())

func _on_red_button_choice_required(effects: Array) -> void:
	ui.show_red_button_options(effects)
	ui.show_event("红按钮已触发，选择一个高风险翻盘效果。", true)

func _begin_hero_defeat_choice() -> void:
	if phase == "hero_defeated_choice" or phase == "victory":
		return
	phase = "hero_defeated_choice"
	waves_defeated += 1
	spawner.despawn_all()
	var rewards = wave_director.victory_rewards(hero_level())
	var recovered_gold = last_reclaimed_loot.size() * 28
	var recovered_skill = int(last_reclaimed_loot.size() / 2)
	rewards["gold"] = int(rewards.get("gold", 0)) + recovered_gold
	rewards["skill_points"] = int(rewards.get("skill_points", 0)) + recovered_skill
	_grant_rewards(rewards)
	pending_boons = balance.create_power_boons()
	pending_choice_kind = "power"
	pending_transition_reason = "hero_defeated"
	save_system.save_progress(save_data)
	ui.show_power_choice(rewards, newly_activated_seal_name(), pending_boons)
	ui.refresh_monster_list()
	var loot_text = ""
	if not last_reclaimed_loot.is_empty():
		loot_text = " 夺回遗物：%s。" % "、".join(last_reclaimed_loot)
	ui.show_event("勇者倒下，【%s】解封。强力道具选择后进入下一间。%s" % [newly_activated_seal_name(), loot_text], true)

func _wave_victory() -> void:
	_begin_hero_defeat_choice()

func _run_victory() -> void:
	if phase == "victory":
		return
	phase = "victory"
	waves_defeated += 1
	rage_system.reset_to(0.0)
	var final_rewards = wave_director.victory_rewards(hero_level())
	_grant_rewards(final_rewards)
	spawner.despawn_all()
	hero.deactivate()
	save_system.save_progress(save_data)
	ui.update_stats()
	ui.show_run_victory(final_rewards, waves_defeated)
	ui.show_event("勇者的所有命数已经耗尽。", true)

func _grant_rewards(rewards: Dictionary) -> void:
	var gold = int(rewards.get("gold", 0))
	var skill_points = int(rewards.get("skill_points", 0))
	save_data["gold"] = int(save_data["gold"]) + gold
	save_data["skill_points"] = int(save_data["skill_points"]) + skill_points

func convert_gold_to_skill_points() -> void:
	if not all_monsters_unlocked():
		ui.show_event("解锁全部兵种后才能转换金币。", true)
		return
	var rate = BalanceConfigScript.GOLD_TO_SKILL_POINT_RATE
	var gold = int(save_data["gold"])
	var points = int(gold / rate)
	if points <= 0:
		ui.show_event("金币不足：%d 金币可转换 1 技能点。" % rate, true)
		return
	save_data["gold"] = gold - points * rate
	save_data["skill_points"] = int(save_data["skill_points"]) + points
	save_system.save_progress(save_data)
	ui.refresh_monster_list()
	ui.show_event("金币转换完成：+%d 技能点。" % points)

func _trigger_time_event() -> void:
	var ratio = hero.hp_ratio()
	if ratio > 0.70:
		hero.apply_status("momentum", 5.0, 1.0)
		rage_system.add(14.0)
		ui.show_event("时间事件：勇者气势高涨，攻速短暂提高。", true)
	elif ratio > 0.30:
		if _try_spawn_random_interactive():
			ui.show_event("时间事件：竞技场地形翻动，新的互动物出现。")
		else:
			ui.show_event("时间事件：场景物件已到上限，地形暂时稳定。")
	else:
		command_points = min(max_command_points, command_points + 26.0)
		for monster in get_active_monsters():
			monster.apply_berserk()
		ui.show_event("时间事件：压制优势，获得指挥点并激励怪物。")

func _reroll_interactives_for_wave() -> void:
	# A new wave gets a fresh layout rather than the same five props every time.
	for obj in interactives:
		if is_instance_valid(obj):
			obj.queue_free()
	interactives.clear()
	var initial_count = 2 if is_tutorial_wave() else randi_range(3, 4)
	for _i in range(initial_count):
		_try_spawn_random_interactive()

func _process_interactive_timers(delta: float) -> void:
	interactive_spawn_countdown -= delta
	interactive_despawn_countdown -= delta
	if interactive_spawn_countdown <= 0.0:
		if _try_spawn_random_interactive():
			ui.show_event("地形变化：新的场景物件出现。")
		interactive_spawn_countdown = randf_range(10.0, 16.0)
	if interactive_despawn_countdown <= 0.0:
		_expire_random_interactive()
		interactive_despawn_countdown = randf_range(16.0, 24.0)

func _try_spawn_random_interactive() -> bool:
	if get_active_interactives().size() >= MAX_INTERACTIVES:
		return false
	var kind = _random_interactive_kind()
	var position = _random_interactive_position(kind)
	if position == Vector2.INF:
		return false
	_spawn_interactive(kind, position)
	return true

func _random_interactive_kind() -> String:
	# Pools appear often enough to matter, but barrels stay rare enough to be a choice.
	var roll = randf()
	if roll < 0.28:
		return "barrel"
	if roll < 0.53:
		return "poison_pool"
	if roll < 0.79:
		return "slow_pool"
	return "obstacle"

func _random_interactive_position(kind: String) -> Vector2:
	var proposed_radius = _interactive_radius_for(kind)
	for _attempt in range(28):
		var position = Vector2(
			randf_range(INTERACTIVE_SPAWN_RECT.position.x, INTERACTIVE_SPAWN_RECT.end.x),
			randf_range(INTERACTIVE_SPAWN_RECT.position.y, INTERACTIVE_SPAWN_RECT.end.y)
		)
		if hero != null and position.distance_to(hero.global_position) < proposed_radius + 112.0:
			continue
		if commander != null and position.distance_to(commander.global_position) < proposed_radius + 94.0:
			continue
		var overlaps = false
		for obj in get_active_interactives():
			if position.distance_to(obj.global_position) < proposed_radius + obj.radius + 42.0:
				overlaps = true
				break
		if not overlaps:
			return position
	return Vector2.INF

func _interactive_radius_for(kind: String) -> float:
	match kind:
		"barrel":
			return 24.0
		"poison_pool":
			return 52.0
		"slow_pool":
			return 54.0
		"obstacle":
			return 34.0
		_:
			return 24.0

func _expire_random_interactive() -> void:
	var active_objects = get_active_interactives()
	if active_objects.is_empty():
		return
	active_objects.pick_random().expire()
	ui.show_event("地形变化：一件场景物件消散。")

func _spawn_interactive(kind: String, position: Vector2) -> void:
	if get_active_interactives().size() >= MAX_INTERACTIVES:
		return
	var obj = InteractiveObjectScript.new()
	interactive_root.add_child(obj)
	obj.setup(kind, position, self)
	obj.destroyed.connect(_on_interactive_destroyed)
	interactives.append(obj)

func _on_interactive_destroyed(obj) -> void:
	interactives.erase(obj)

func _is_free_deploy(monster_id: String) -> bool:
	if red_free_deploy_charges > 0:
		return true
	if active_boons.has("first_free") and not first_free_used.has(monster_id):
		return true
	return false

func _mark_free_deploy_used(monster_id: String) -> void:
	if red_free_deploy_charges > 0:
		red_free_deploy_charges -= 1
		return
	if active_boons.has("first_free"):
		first_free_used[monster_id] = true

func all_monsters_unlocked() -> bool:
	for id in monster_order():
		if not is_monster_unlocked(id):
			return false
	return true

func _boon_name(id: String) -> String:
	var pools = [balance.create_temp_boons(), balance.create_power_boons()]
	for pool in pools:
		for boon in pool:
			if boon["id"] == id:
				return boon["name"]
	return id

func _red_effect_by_id(effect_id: String):
	for effect in red_button_system.effects:
		if effect.id == effect_id:
			return effect
	return null

func _start_duel() -> void:
	phase = "duel"
	var total_hp = 60.0
	var total_attack = 10.0
	var tags: Array[String] = []
	for monster in get_active_monsters():
		total_hp += monster.hp * 0.26
		total_attack += monster.current_attack() * 0.34
		for tag in monster.data.tags:
			if not tags.has(tag) and tags.size() < 5:
				tags.append(tag)
	duel = {
		"goblin_hp": total_hp,
		"goblin_max_hp": total_hp,
		"goblin_attack": total_attack,
		"hero_hp": max(34.0, hero.hp * 0.72),
		"hero_max_hp": max(34.0, hero.hp * 0.72),
		"hero_attack": max(10.0, current_hero_stats.get("attack", 12.0) * 0.92),
		"tags": tags,
		"poison": 0.0
	}
	ui.show_event("红按钮：指挥官被弹射进决斗。", true)
	ui.show_duel(duel, _duel_actions())

func _duel_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	actions.append({"id": "strike", "name": "继承猛击", "description": "造成稳定伤害。"})
	actions.append({"id": "shield", "name": "怪物护盾", "description": "本回合大幅减伤，并造成少量伤害。"})
	actions.append({"id": "venom", "name": "毒性诅咒", "description": "造成伤害并让勇者持续流失生命。"})
	if _duel_has_tag("burst"):
		actions[2] = {"id": "blast", "name": "炸弹冲撞", "description": "高伤害，但指挥官也会受反冲。"}
	return actions

func _duel_has_tag(tag: String) -> bool:
	for t in duel.get("tags", []):
		if t == tag:
			return true
	return false
