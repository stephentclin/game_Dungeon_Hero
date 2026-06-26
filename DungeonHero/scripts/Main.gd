extends Node2D

@export var debug_show_summon_buttons := false

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
const AudioManagerScript = preload("res://scripts/AudioManager.gd")
const InteractiveObjectScript = preload("res://scripts/InteractiveObject.gd")
const MapDirectorScript = preload("res://scripts/MapDirector.gd")
const HeroReviveEffectTexture = preload("res://assets/effects/hero_revive_effect_4f.png")

var balance = BalanceConfigScript.new()
var save_system = SaveSystemScript.new()
var wave_director = WaveDirectorScript.new()
var rage_system = RageSystemScript.new()
var red_button_system = RedButtonSystemScript.new()
var combat_system = CombatSystemScript.new()
var placement = PlacementSystemScript.new()
var ui = UIControllerScript.new()
var audio_manager = AudioManagerScript.new()
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
var final_outcome_cutscene_playing := false
var pending_game_over_reason := ""
var pending_victory_waves_defeated := 0
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
const INTERACTIVE_SPAWN_RECT = Rect2(Vector2(150, 205), Vector2(535, 255))
# The selected number of lives is loaded from menu settings (1–5).
var hero_lives_total = 5
var hero_lives_remaining = 5
const ARENA_BOUNDS = Rect2(Vector2(18, 118), Vector2(824, 476))
const ROOM_DURATION := 50.0
const DEFAULT_SKILL_LEVELS := {
	"army_rewrite": 0,
	"attack": 0,
	"attack_speed": 0,
	"crit_chance": 0,
	"crit_damage": 0,
	"ink_yield": 0,
	"ink_reflux": 0,
	"normal_dice_unlock": 0,
	"power_dice_unlock": 0,
	"cooldown": 0,
	"quick_entrance": 0,
	"unlock_bomber": 0,
	"unlock_shaman": 0,
	"unlock_ogre": 0
}
var pending_boons: Array = [] # untyped to avoid Godot Array -> Array[Dictionary] runtime assignment bug
var current_hero_stats = {}
var duel = {}
var waves_defeated = 0
var map_index = 0
var room_time_remaining = ROOM_DURATION
var hero_inventory: Array = []
var hero_escape_count = 0
var last_reclaimed_loot: Array = []
var pending_hero_revive_effect := false
var pending_choice_kind = ""
var pending_transition_reason = ""
var auto_hero_started_this_room := false
const FINAL_ROOM_INDEX = 4

# v12: Rewrite Ink is the only spendable currency. Cast Slots remain a limit, not money.
var rewrite_ink = 0
var ink_damage_progress = 0.0
var run_unlocked: Array[String] = []
var run_upgrades = {}
var skill_levels = {}
var summon_cooldowns = {}
var normal_dice_uses = 0
var power_dice_uses = 0
var death_rewrite_ready = false
var rewrite_bonus_charges = 0
var curtain_blast_target = ""
var score_recorded := false
var combo_score_bonus := 0
var highest_combo := 0
var carried_hero_hp := -1.0
var timer_warning_beep_cooldown := 0.0

func _ready() -> void:
	randomize()
	monster_catalog = balance.create_monster_catalog()
	save_data = save_system.load_progress(monster_catalog)
	# Keep startup light so Godot can draw the first frame instead of staying on "Game starting...".
	call_deferred("_finish_startup")

func _finish_startup() -> void:
	hero_lives_total = clampi(int(save_data.get("settings", {}).get("hero_lives", 5)), 1, 5)
	hero_lives_remaining = hero_lives_total
	_build_world()
	_connect_signals()
	start_new_run()

func current_language() -> String:
	return str(save_data.get("settings", {}).get("language", "en"))

func loc(zh: String, en: String) -> String:
	if current_language() == "en":
		return en
	return zh

func monster_display_name(monster_id: String) -> String:
	var english_names = {
		"warrior": "Skeleton Soldier",
		"archer": "Goblin Archer",
		"slime": "Slime Guard",
		"bomber": "Bomb Imp",
		"shaman": "Voodoo Shaman",
		"ogre": "Ogre"
	}
	if current_language() == "en":
		return str(english_names.get(monster_id, monster_id))
	if monster_catalog.has(monster_id):
		return str(monster_catalog[monster_id].display_name)
	return monster_id

func hero_seal_name(index: int, full_name: bool = false) -> String:
	var zh_short = ["虚无", "元素", "能量", "生命", "轮回", "永恒"]
	var en_short = ["Void", "Element", "Energy", "Life", "Reincarnation", "Eternal"]
	var zh_full = ["虚无之躯", "元素屏障", "能量限界", "生命圣泉", "轮回圣印", "永恒神血"]
	var en_full = ["Void Body", "Element Barrier", "Energy Limit", "Life Spring", "Reincarnation Seal", "Eternal Blood"]
	var safe_index = clampi(index, 0, 5)
	if current_language() == "en":
		return en_full[safe_index] if full_name else en_short[safe_index]
	return zh_full[safe_index] if full_name else zh_short[safe_index]

func boon_display_name(boon: Dictionary) -> String:
	if current_language() == "en":
		return str(boon.get("name_en", boon.get("name", "Item")))
	return str(boon.get("name", "道具"))

func boon_display_description(boon: Dictionary) -> String:
	if current_language() == "en":
		return str(boon.get("description_en", boon.get("description", "")))
	return str(boon.get("description", ""))

func red_effect_name(effect) -> String:
	var english = {
		"emergency": "Tactical Airdrop",
		"missile": "Armor-Break Cannon",
		"duel": "Goblin Launch Duel"
	}
	if current_language() == "en":
		return str(english.get(effect.id, effect.display_name))
	return str(effect.display_name)

func red_effect_description(effect) -> String:
	var english = {
		"emergency": "Freeze the hero for 4 seconds, gain 70 Command Points, and make the next 3 deployments free.",
		"missile": "Deal 45 true damage, shatter all armor, and stun the hero for 2 seconds.",
		"duel": "The commander inherits a snapshot of your army and enters a risky turn-based duel."
	}
	if current_language() == "en":
		return str(english.get(effect.id, effect.description))
	return str(effect.description)

func hero_level() -> int:
	# The hero levels when he successfully writes a chapter and escapes to the next room.
	return max(1, hero_escape_count + 1)

func hero_seal_count() -> int:
	var lost_lives = hero_lives_total - hero_lives_remaining
	return clampi(1 + lost_lives, 1, 5)

func hero_seal_names() -> Array:
	var result = []
	for index in range(hero_seal_count()):
		result.append(hero_seal_name(index, false))
	return result

func newly_activated_seal_name() -> String:
	return hero_seal_name(hero_seal_count() - 1, true)

func hero_seal_brief_text() -> String:
	var zh = ["虚无·70% MISS", "元素·异常后受伤", "能量·单击≤30", "生命·3秒回血", "轮回·末命抗远程", "永恒·低血回满"]
	var en = ["Void·70% MISS", "Element·ailment first", "Energy·hit ≤30", "Life·heal /3s", "Reincarnation·final ranged resist", "Eternal·low HP refill"]
	var items = zh
	if current_language() == "en":
		items = en
	var result: Array[String] = []
	for index in range(hero_seal_count()):
		result.append(items[index])
	if hero_lives_remaining <= 1 and hero_seal_count() >= 5:
		result.append(items[5])
	return " · ".join(result)

func hero_relic_name(value: String) -> String:
	return map_director.relic_name_for_id(value, current_language())

func hero_relic_effect(value: String) -> String:
	return map_director.relic_effect_for_id(value, current_language())

func hero_carried_relic_text() -> String:
	if hero_inventory.is_empty():
		return loc("无", "None")
	var lines: Array[String] = []
	for value in hero_inventory:
		var relic_name = hero_relic_name(str(value))
		var effect = hero_relic_effect(str(value))
		lines.append("%s·%s" % [relic_name, effect])
	return "\n".join(lines)

func hero_relic_list_text(values: Array) -> String:
	var names: Array[String] = []
	for value in values:
		names.append(hero_relic_name(str(value)))
	return "、".join(names) if current_language() == "zh" else ", ".join(names)

func is_final_room() -> bool:
	return map_index >= FINAL_ROOM_INDEX

func guardian_tower_active() -> bool:
	return is_final_room() and commander != null and commander.visible

func is_run_finished() -> bool:
	return phase == "game_over" or phase == "victory" or final_outcome_cutscene_playing

func should_show_deploy_prompt() -> bool:
	return false

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
		_tick_summon_cooldowns(delta)
	ui.update_stats()

func _unhandled_input(event: InputEvent) -> void:
	if is_run_finished():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var order = monster_order()
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var index = event.keycode - KEY_1
			if index < order.size():
				select_monster(order[index])
		# Manual hero summon hotkey removed. Battle starts only after the first successful match.
		elif event.keycode == KEY_R:
			force_red_button()

func start_new_run() -> void:
	final_outcome_cutscene_playing = false
	pending_game_over_reason = ""
	pending_victory_waves_defeated = 0
	score_recorded = false
	combo_score_bonus = 0
	highest_combo = 0
	carried_hero_hp = -1.0
	timer_warning_beep_cooldown = 0.0
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
	rewrite_ink = 0
	ink_damage_progress = 0.0
	run_unlocked = BalanceConfigScript.DEFAULT_UNLOCKED.duplicate()
	run_upgrades.clear()
	for id in monster_catalog.keys():
		run_upgrades[id] = 0
	if save_data.has("skill_levels") and typeof(save_data["skill_levels"]) == TYPE_DICTIONARY:
		skill_levels = save_data["skill_levels"].duplicate(true)
	else:
		skill_levels = DEFAULT_SKILL_LEVELS.duplicate(true)
	_ensure_skill_level_defaults()
	summon_cooldowns.clear()
	normal_dice_uses = 0
	power_dice_uses = 0
	death_rewrite_ready = false
	rewrite_bonus_charges = 0
	curtain_blast_target = ""
	first_free_used.clear()
	red_free_deploy_charges = 0
	red_button_system.reset_for_run()
	rage_system.reset_for_run()
	commander.reset_health()
	selected_monster_id = "warrior"
	select_monster(selected_monster_id)
	start_prepare()

func start_prepare(resume_same_room: bool = false) -> void:
	auto_hero_started_this_room = false
	phase = "prepare"
	wave = map_index + 1
	battle_time = 0.0
	if not resume_same_room:
		room_time_remaining = ROOM_DURATION
		time_event_countdown = balance.time_event_interval
		max_command_points = 0.0
		command_points = 0.0
		normal_dice_uses = 0
		power_dice_uses = 0
		rewrite_bonus_charges = 1 if has_boon("rewrite_ending") else 0
		spawner.despawn_all()
		combat_system.clear_runtime_fx()
		map_director.start_room(map_index)
		current_hero_stats = wave_director.build_hero_stats(hero_level())
		_apply_hero_escape_upgrades(current_hero_stats)
		_reroll_interactives_for_wave()
		interactive_spawn_countdown = randf_range(9.0, 14.0)
		interactive_despawn_countdown = randf_range(15.0, 22.0)
	else:
		combat_system.clear_runtime_fx()
	if commander != null and commander.has_method("set_guardian_mode"):
		commander.set_guardian_mode(is_final_room())
	hero.setup(current_hero_stats, _hero_respawn_position(), self)
	if carried_hero_hp >= 0.0:
		hero.hp = clamp(carried_hero_hp, 1.0, hero.max_hp)
		carried_hero_hp = -1.0
		hero.queue_redraw()
	hero.deactivate()
	if pending_hero_revive_effect:
		pending_hero_revive_effect = false
		_play_hero_revive_effect()
	placement.enabled = true
	ui.show_prepare(current_hero_stats)
	ui.refresh_monster_list()
	if resume_same_room:
		ui.show_event(loc("勇者带着新封印重返本室：剩余 %.1f 秒。", "The hero returns to this room with a new seal: %.1f seconds remain.") % room_time_remaining, true)
	elif is_final_room():
		ui.show_event(loc("最终房间：守卫塔已上线。范围内怪物获得【鼓舞】。", "Final room: the Guardian Tower is active. Nearby monsters gain Inspire."), true)
	elif is_tutorial_wave():
		ui.show_event(loc("右侧 Match Board 会显示 3、2、1、GO 倒数；倒数结束后房间计时和勇者行动才会开始。", "The Match Board counts down 3, 2, 1, GO; after GO the room timer and hero movement start."))
	else:
		ui.show_event(loc("右侧棋盘负责召唤；兵数量上限已取消。", "The right board summons your cast; unit cap is now removed."))

func _play_hero_revive_effect() -> void:
	if combat_system == null or hero == null:
		return
	if not combat_system.has_method("spawn_sprite_sheet_fx"):
		return
	var effect_position: Vector2 = hero.global_position + Vector2(0.0, 2.0)
	combat_system.spawn_sprite_sheet_fx(
		effect_position,
		HeroReviveEffectTexture,
		4,
		Vector2(256.0, 256.0),
		Vector2(150.0, 150.0),
		0.72,
		Vector2(0.0, -18.0),
		Color(1.0, 1.0, 1.0, 0.96)
	)
	combat_system.spawn_floating_text(hero.global_position + Vector2(0.0, -76.0), loc("复活", "REVIVE"), Color("#7ee9ff"), true)

func _hero_respawn_position() -> Vector2:
	var safe_rect = ARENA_BOUNDS.grow(-96.0)
	var best = safe_rect.get_center()
	var best_distance = -1.0
	for _i in range(12):
		var candidate = Vector2(randf_range(safe_rect.position.x, safe_rect.end.x), randf_range(safe_rect.position.y, safe_rect.end.y))
		var nearest = INF
		for monster in get_active_monsters():
			nearest = min(nearest, candidate.distance_to(monster.global_position))
		if nearest > best_distance:
			best_distance = nearest
			best = candidate
	return best

func begin_battle() -> void:
	if is_run_finished():
		return
	if phase != "prepare":
		return
	phase = "battle"
	hero.activate()
	ui.hide_overlay()
	ui.show_event(loc("勇者被召唤入场：倒计时开始。", "The hero has been summoned: the timer begins."))

func _auto_begin_battle_after_first_match() -> void:
	if auto_hero_started_this_room:
		return
	if phase != "prepare":
		return
	auto_hero_started_this_room = true
	begin_battle()
	ui.show_event(loc("首次消除触发：勇者自动入场！", "First match trigger: hero enters automatically!"), false)

func request_place_monster(monster_id: String, slot: Vector2) -> void:
	if is_run_finished():
		return
	if not monster_catalog.has(monster_id):
		return
	if not is_monster_unlocked(monster_id):
		ui.show_event(loc("该兵种还没有在技能树中解锁。", "That unit is not unlocked in the Skill Tree."), true)
		return
	if is_tutorial_wave() and monster_id != "warrior":
		ui.show_event(loc("第一波先用骷髅兵练习部署。", "Use the Skeleton Soldier for the first tutorial deployment."), true)
		return
	if not placement.can_place_at(slot):
		ui.show_event(placement.block_reason(slot), true)
		return
	var data = monster_catalog[monster_id]
	var cost = int(data.population_cost)
	if phase == "battle" and summon_cooldown_remaining(monster_id) > 0.0:
		ui.show_event(loc("%s 仍在入场冷却：%.1f 秒。", "%s is still on summon cooldown: %.1f sec.") % [monster_display_name(monster_id), summon_cooldown_remaining(monster_id)], true)
		return
	if commander != null and commander.has_method("trigger_summon_cast"):
		commander.trigger_summon_cast()
	var monster = spawner.spawn(data, monster_level(monster_id), slot)
	if death_rewrite_ready:
		monster.apply_berserk()
		death_rewrite_ready = false
	if hero.armor <= 0.0:
		monster.apply_berserk()
	if phase == "battle":
		start_summon_cooldown(monster_id)
	ui.show_event(loc("写入战场：%s（席位 %d）", "Written into the arena: %s (Slots %d)") % [monster_display_name(monster_id), cost])

func request_puzzle_summon(unit_type: String, amount := 1, power_level := 1) -> void:
	if is_run_finished():
		return
	# Battle/timer now starts only after the Match Board 3-2-1-GO countdown.
	summon_unit(unit_type, amount, power_level, true, true)

func summon_unit(unit_type: String, amount := 1, power_level := 1, ignore_cooldown := false, ignore_roster_rules := false) -> void:
	if is_run_finished():
		return
	if not monster_catalog.has(unit_type):
		return
	if amount <= 0:
		return
	if not ignore_roster_rules and (not is_monster_unlocked(unit_type) or not is_monster_available_this_wave(unit_type)):
		var fallback_ink :int= max(2, (amount + max(0, power_level - 1)) * 2)
		grant_rewrite_ink(fallback_ink, false)
		ui.show_event(loc("%s 尚未开放，本次消除改为获得墨水 %d。", "%s is not available yet, so the match became %d Ink instead.") % [monster_display_name(unit_type), fallback_ink], true)
		return
	var gold_cost := puzzle_summon_gold_cost(unit_type, power_level)
	var spawned := 0
	for _index in range(amount):
		if not _can_spawn_unit_now(unit_type, ignore_cooldown):
			break
		var slot := placement.find_auto_place_slot(unit_type)
		if slot.x < 0.0:
			break
		if _spawn_unit_instance(unit_type, slot, power_level):
			spawned += 1
	if spawned > 0:
		if audio_manager != null:
			audio_manager.play_sfx("monster_appear")
		ui.show_event(loc("棋盘召唤：%s ×%d", "Board summon: %s ×%d") % [monster_display_name(unit_type), spawned], false)
	elif gold_cost > 0:
		grant_rewrite_ink(gold_cost * 2, false)
		ui.show_event(loc("人口已满：本次高级召唤改为返还墨水 %d。", "Cast Slots are full: the advanced summon refunded %d Ink.") % (gold_cost * 2), true)
	if spawned < amount:
		var refund :int= max(2, (amount - spawned) * 2)
		grant_rewrite_ink(refund, false)
		ui.show_event(loc("人口已满：未能登场的单位转化为墨水 %d。", "Cast Slots are full: unsummoned units became %d Ink.") % refund, true)

func select_monster(monster_id: String) -> void:
	if not monster_catalog.has(monster_id):
		return
	if not is_monster_available_this_wave(monster_id):
		ui.show_event(loc("第一波训练中：先使用战士。", "Tutorial wave: use the warrior first."), true)
		return
	selected_monster_id = monster_id
	placement.set_selected(monster_id)
	ui.set_selected(monster_id)

func preview_puzzle_unit(monster_id: String) -> void:
	if not monster_catalog.has(monster_id):
		return
	selected_monster_id = monster_id
	placement.set_selected(monster_id)
	ui.set_selected(monster_id)

func grant_puzzle_rewards(ink_amount: int, gold_amount: int, combo_count: int, label: String) -> void:
	if is_run_finished():
		return
	# Battle/timer now starts only after the Match Board 3-2-1-GO countdown.
	highest_combo = max(highest_combo, combo_count)
	# Live score is only the match/combo score during the run.
	# Hero lives, HP, and remaining time are added once at final settlement.
	var safe_combo: int = max(1, combo_count)
	var gained_score: int = safe_combo * safe_combo * 100
	combo_score_bonus += gained_score
	if combat_system != null:
		var score_pos := ARENA_BOUNDS.position + Vector2(ARENA_BOUNDS.size.x + 70.0, 92.0)
		combat_system.spawn_floating_text(score_pos, "+%d SCORE" % gained_score, Color(1.0, 0.18, 0.12), true)
	if ui != null:
		ui.update_stats()
	# Single-currency mode: old gold rewards are converted into extra Rewrite Ink.
	# The yield is intentionally higher to make match rewards feel more generous.
	var total_ink :int= max(0, ink_amount) + max(0, gold_amount) * 2
	if total_ink > 0:
		grant_rewrite_ink(total_ink, false)
	if total_ink > 0:
		ui.show_event(loc("%s · 墨水 +%d", "%s · Ink +%d") % [label, total_ink], false)

func unlock_selected_monster() -> void:
	var id = selected_monster_id
	if not monster_catalog.has(id):
		return
	purchase_skill_node("unlock_" + id)

func upgrade_selected_monster() -> void:
	var id = selected_monster_id
	if not monster_catalog.has(id):
		return
	purchase_skill_node("upgrade_" + id)

func choose_temp_boon(boon_id: String) -> void:
	if is_run_finished():
		return
	if boon_id != "":
		grant_boon(boon_id)
		ui.show_event(loc("获得道具：%s", "Item gained: %s") % _boon_name(boon_id), true)
	var reason = pending_transition_reason
	pending_choice_kind = ""
	pending_transition_reason = ""
	if reason == "hero_defeated_resume":
		pending_hero_revive_effect = true
		start_prepare(true)
	elif reason == "hero_defeated_transition":
		pending_hero_revive_effect = true
		map_index += 1
		start_prepare()
	elif reason == "hero_cleared_room":
		if ui != null and ui.has_method("play_hero_pass_cutscene"):
			ui.play_hero_pass_cutscene(Callable(self, "_finish_hero_cleared_room_transition"))
		else:
			_finish_hero_cleared_room_transition()
	else:
		start_prepare()


func _finish_hero_cleared_room_transition() -> void:
	map_index += 1
	start_prepare()

func force_red_button() -> void:
	if phase != "battle":
		return
	if not map_director.can_rewrite_scene():
		ui.show_event(loc("剧本改写仍在冷却：开战 8 秒后才能使用。", "Rewrite Scene is still locked. It becomes available 8 seconds after battle begins."), true)
		return
	if map_director.rewrite_scene():
		if rewrite_bonus_charges > 0:
			rewrite_bonus_charges -= 1
			map_director.rewrite_used = false
			ui.show_event(loc("改写结局生效：本房间还可再改写一次。", "Rewrite Ending: one extra rewrite remains this room."), true)
		else:
			ui.show_event(loc("剧本已被反写。勇者以为他在闯关，其实是你在改关。", "The script has been rewritten. The hero thinks he is clearing the dungeon, but you are rewriting the room."), true)

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
			ui.show_event(loc("红按钮：战术空投完成，接下来 %d 次部署免费。", "Red Button: tactical airdrop complete. The next %d deployments are free.") % red_free_deploy_charges, true)
		"missile":
			var armor_shatter = hero.armor * float(effect.values.get("armor_percent", 0.70))
			hero.shatter_armor(armor_shatter)
			hero.take_damage(float(effect.values.get("true_damage", 45.0)), null, {"ignore_armor": true, "source": "red_missile"})
			hero.apply_status("stun", float(effect.values.get("stun", 2.0)), 1.0)
			combat_system.spawn_explosion(hero.global_position, float(effect.values.get("radius", 132.0)), 0.0, 0.0, {"source": "red_missile"}, false)
			ui.show_event(loc("红按钮：破甲重炮命中，勇者护甲被撕裂。", "Red Button: armor-break cannon hit. The hero's armor is torn apart."), true)
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
		game_over(loc("弹射决斗失败，哥布林亲自上场后被击败。", "The goblin duel failed. The commander was defeated."))
		return
	ui.show_duel(duel, _duel_actions())

func has_boon(id: String) -> bool:
	return active_boons.has(id)

func boon_count(id: String) -> int:
	var value = 0
	for boon_id in active_boons:
		if boon_id == id:
			value += 1
	return value

func skill_level(id: String) -> int:
	return int(skill_levels.get(id, 0))

func _ensure_skill_level_defaults() -> void:
	for id in DEFAULT_SKILL_LEVELS.keys():
		if not skill_levels.has(id):
			skill_levels[id] = int(DEFAULT_SKILL_LEVELS[id])
	save_data["skill_levels"] = skill_levels.duplicate(true)

func active_unit_type_count() -> int:
	var kinds = {}
	for monster in get_active_monsters():
		if monster != null and monster.data != null:
			kinds[str(monster.data.id)] = true
	return kinds.size()

func crit_chance_for(_data) -> float:
	var chance = 0.03 * float(skill_level("crit_chance"))
	chance += 0.05 * float(boon_count("crimson_foreshadow"))
	if has_boon("last_monologue") and hero != null and hero.hp_ratio() <= 0.25:
		chance += 0.25
	return clamp(chance, 0.0, 0.85)

func crit_damage_multiplier() -> float:
	var value = 1.50 + 0.15 * float(skill_level("attack") + skill_level("crit_damage")) + 0.25 * float(boon_count("deadly_edit"))
	if has_boon("last_monologue") and hero != null and hero.hp_ratio() <= 0.25:
		value += 0.30
	return value

func ink_yield_multiplier() -> float:
	return 1.0

func puzzle_luck_points() -> int:
	return max(0, skill_level("normal_dice_unlock") + skill_level("power_dice_unlock"))

func puzzle_luck_reward_bonus(combo_count: int, _label := "") -> int:
	if combo_count <= 0:
		return 0
	return puzzle_luck_points()

func record_hero_damage(hp_damage: float, armor_damage: float, tags: Dictionary) -> void:
	if phase != "battle":
		return
	var source = str(tags.get("source", ""))
	if source == "wall" or source == "barrel" or source == "red_missile":
		return
	var weighted_damage = max(0.0, hp_damage) + max(0.0, armor_damage) * 0.40
	if weighted_damage <= 0.0:
		return
	ink_damage_progress += weighted_damage * ink_yield_multiplier()
	var earned = int(floor(ink_damage_progress / 8.0))
	if earned > 0:
		ink_damage_progress -= float(earned) * 8.0
		grant_rewrite_ink(earned, false)

func grant_rewrite_ink(amount: int, announce: bool = false) -> void:
	if amount <= 0:
		return
	rewrite_ink += amount
	if announce and ui != null:
		ui.show_event(loc("获得改写墨水 +%d。", "Rewrite Ink +%d.") % amount, true)

func gold_amount() -> int:
	# Compatibility shim: the visible economy now uses Rewrite Ink only.
	return rewrite_ink

func award_gold(amount: int, announce: bool = false) -> void:
	# Single-currency mode: convert any legacy gold grant into extra Rewrite Ink.
	if amount <= 0:
		return
	grant_rewrite_ink(amount * 2, announce)

func try_spend_gold(amount: int) -> bool:
	# Gold spending is disabled because Rewrite Ink is the only currency.
	return true

func hero_defeat_ink_reward() -> int:
	return 38 + map_index * 10

func summon_cooldown_remaining(monster_id: String) -> float:
	return max(0.0, float(summon_cooldowns.get(monster_id, 0.0)))

func summon_cooldown_multiplier() -> float:
	var reduction = 0.07 * float(boon_count("quick_entrance"))
	return clamp(1.0 - reduction, 0.55, 1.0)

func start_summon_cooldown(monster_id: String) -> void:
	if not monster_catalog.has(monster_id):
		return
	var base = float(monster_catalog[monster_id].summon_cooldown)
	summon_cooldowns[monster_id] = max(0.8, base * summon_cooldown_multiplier())

func _tick_summon_cooldowns(delta: float) -> void:
	var expired = []
	for monster_id in summon_cooldowns.keys():
		summon_cooldowns[monster_id] = max(0.0, float(summon_cooldowns[monster_id]) - delta)
		if float(summon_cooldowns[monster_id]) <= 0.0:
			expired.append(monster_id)
	for monster_id in expired:
		summon_cooldowns.erase(monster_id)

func normal_dice_available() -> bool:
	return normal_dice_uses < 2

func power_dice_available() -> bool:
	return power_dice_uses < 1

func _boon_definition(id: String) -> Dictionary:
	var pools = [balance.create_temp_boons(), balance.create_power_boons()]
	for pool in pools:
		for boon in pool:
			if str(boon.get("id", "")) == id:
				return boon
	return {}

func can_gain_boon(id: String) -> bool:
	var definition = _boon_definition(id)
	if definition.is_empty():
		return false
	return boon_count(id) < int(definition.get("max_stacks", 1))

func grant_boon(id: String) -> void:
	if not can_gain_boon(id):
		return
	active_boons.append(id)
	if id == "rewrite_ending":
		rewrite_bonus_charges = max(rewrite_bonus_charges, 1)
	if id == "curtain_blast":
		curtain_blast_target = selected_monster_id if selected_monster_id in ["warrior", "archer", "slime"] else "warrior"

func should_curtain_blast(monster_id: String) -> bool:
	return has_boon("curtain_blast") and monster_id == curtain_blast_target and monster_id != "bomber"

func random_boon_offers(kind: String, count: int) -> Array:
	var pool = balance.create_temp_boons() if kind == "normal" else balance.create_power_boons()
	var candidates = []
	for boon in pool:
		if can_gain_boon(str(boon.get("id", ""))):
			candidates.append(boon)
	candidates.shuffle()
	return candidates.slice(0, min(count, candidates.size()))

func buy_normal_dice() -> void:
	if not normal_dice_available():
		ui.show_event(loc("本房间普通骰子已用完（2/2）。", "Normal Dice already used this room (2/2)."), true)
		return
	if rewrite_ink < 30:
		if audio_manager != null:
			audio_manager.play_sfx("error")
		ui.show_event(loc("改写墨水不足：普通骰子需要 30。", "Not enough Rewrite Ink: Normal Dice costs 30."), true)
		return
	var candidates = []
	for boon in balance.create_temp_boons():
		if can_gain_boon(str(boon["id"])):
			candidates.append(boon)
	if candidates.is_empty():
		ui.show_event(loc("普通天赋已全部达到叠加上限。", "All normal talents reached their stack limits."), true)
		return
	rewrite_ink -= 30
	normal_dice_uses += 1
	candidates.shuffle()
	var offers = candidates.slice(0, min(2, candidates.size()))
	ui.show_dice_choice(offers, false)

func buy_power_dice() -> void:
	if not power_dice_available():
		ui.show_event(loc("本房间强力骰子已用完（1/1）。", "Power Dice already used this room (1/1)."), true)
		return
	if rewrite_ink < 85:
		if audio_manager != null:
			audio_manager.play_sfx("error")
		ui.show_event(loc("改写墨水不足：强力骰子需要 85。", "Not enough Rewrite Ink: Power Dice costs 85."), true)
		return
	var candidates = []
	for boon in balance.create_power_boons():
		if can_gain_boon(str(boon["id"])):
			candidates.append(boon)
	if candidates.is_empty():
		ui.show_event(loc("强力天赋已全部获得。", "All power talents have already been gained."), true)
		return
	rewrite_ink -= 85
	power_dice_uses += 1
	candidates.shuffle()
	var boon = candidates[0]
	grant_boon(str(boon["id"]))
	ui.show_power_dice_result(boon)

func choose_dice_talent(boon_id: String) -> void:
	grant_boon(boon_id)
	ui.hide_overlay()
	ui.show_event(loc("骰子改写：%s", "Dice rewrite: %s") % _boon_name(boon_id), true)

func get_skill_tree_entries() -> Array:
	var entries = []
	entries.append(_skill_entry("army_rewrite", "军势改写", "Army Rewrite", 12, 3, "全体攻击 +5%", "All ATK +5%"))
	entries.append(_skill_entry("attack_speed", "狂躁节拍", "Feral Tempo", 22, 3, "全体攻速 +5%", "All SPD +5%"))
	entries.append(_skill_entry("crit_chance", "血色伏笔", "Blood Foreshadow", 26, 4, "暴击率 +3%", "Crit chance +3%"))
	entries.append(_skill_entry("attack", "利爪改写", "Claw Rewrite", 22, 3, "暴击伤害 +15%", "Crit damage +15%"))
	entries.append(_skill_entry("ink_yield", "墨水命运", "Ink Fate", 24, 3, "移动速度 +4%", "Move speed +4%"))
	entries.append(_skill_entry("ink_reflux", "墨水回流", "Ink Reflux", 24, 3, "额外移动速度 +5%", "Extra move speed +5%"))
	entries.append(_skill_entry("normal_dice_unlock", "普通骰子", "Normal Dice", 30, 1, "消消乐幸运点 +1", "Puzzle Luck +1"))
	entries.append(_skill_entry("power_dice_unlock", "强力骰子", "Power Dice", 85, 1, "消消乐幸运点额外 +1", "Puzzle Luck +1"))
	entries.append(_skill_entry("cooldown", "剧团调度", "Troupe Dispatch", 24, 3, "萨满施法速度 +6%", "Shaman cast speed +6%"))
	entries.append(_skill_entry("quick_entrance", "入场调度", "Entrance Dispatch", 24, 3, "萨满施法速度额外 +7%", "Extra shaman cast speed +7%"))
	for id in monster_order():
		if not is_monster_unlocked(id):
			var cost = int(monster_catalog[id].unlock_cost)
			var contract_name := _unlock_contract_name(id)
			var label_text := loc("%s · %d 墨水\n%s", "%s · %d INK\n%s") % [contract_name, cost, _unlock_contract_effect(id)]
			entries.append({"id": "unlock_" + id, "cost": cost, "label": label_text})
		elif monster_level(id) < hero_level():
			var level = monster_level(id)
			var upgrade_cost = 18 + level * 14
			entries.append({"id": "upgrade_" + id, "cost": upgrade_cost, "label": loc("升级 %s Lv.%d · %d 墨水", "UPGRADE %s Lv.%d · %d INK") % [monster_display_name(id), level + 1, upgrade_cost]})
	return entries

func _skill_entry(id: String, zh: String, en: String, base_cost: int, max_level: int, zh_effect: String, en_effect: String) -> Dictionary:
	var level = skill_level(id)
	var name = zh if current_language() == "zh" else en
	var effect = zh_effect if current_language() == "zh" else en_effect
	if level >= max_level:
		return {"id": "", "cost": 0, "label": loc("%s · 已满", "%s · MAX") % name}
	var cost = base_cost + level * 12
	return {"id": id, "cost": cost, "label": loc("%s %d/%d · %d 墨水\n%s", "%s %d/%d · %d INK\n%s") % [name, level + 1, max_level, cost, effect]}

func purchase_skill_node(id: String) -> void:
	if id == "":
		return
	if id == "normal_dice":
		buy_normal_dice()
		return
	if id == "power_dice":
		buy_power_dice()
		return
	var cost = 0
	if id.begins_with("unlock_"):
		var unit_id = id.trim_prefix("unlock_")
		if not monster_catalog.has(unit_id) or is_monster_unlocked(unit_id):
			return
		cost = int(monster_catalog[unit_id].unlock_cost)
		if rewrite_ink < cost:
			if audio_manager != null:
				audio_manager.play_sfx("error")
			ui.show_event(loc("改写墨水不足。", "Not enough Rewrite Ink."), true)
			return
		rewrite_ink -= cost
		run_unlocked.append(unit_id)
		skill_levels["unlock_" + unit_id] = 1
		save_data["skill_levels"] = skill_levels.duplicate(true)
		if save_system != null:
			save_system.save_progress(save_data)
		ui.refresh_monster_list()
		ui.show_event(loc("兵种入场：%s", "Unit enters the cast: %s") % monster_display_name(unit_id), true)
		return
	if id.begins_with("upgrade_"):
		var unit_id = id.trim_prefix("upgrade_")
		if not monster_catalog.has(unit_id) or not is_monster_unlocked(unit_id):
			return
		var level = monster_level(unit_id)
		if level >= hero_level():
			ui.show_event(loc("兵种等级不能超过当前勇者等级。", "Unit level cannot exceed current Hero Level."), true)
			return
		cost = 18 + level * 14
		if rewrite_ink < cost:
			if audio_manager != null:
				audio_manager.play_sfx("error")
			ui.show_event(loc("改写墨水不足。", "Not enough Rewrite Ink."), true)
			return
		rewrite_ink -= cost
		run_upgrades[unit_id] = level + 1
		if audio_manager != null:
			audio_manager.play_sfx("hero_upgrade")
		ui.refresh_monster_list()
		ui.show_event(loc("升级完成：%s Lv.%d", "Upgrade complete: %s Lv.%d") % [monster_display_name(unit_id), level + 1], true)
		return
	if not skill_levels.has(id):
		return
	var max_level = {"army_rewrite": 3, "attack": 3, "attack_speed": 3, "crit_chance": 4, "crit_damage": 3, "ink_yield": 3, "ink_reflux": 3, "normal_dice_unlock": 1, "power_dice_unlock": 1, "cooldown": 3, "quick_entrance": 3}.get(id, 0)
	var level = skill_level(id)
	if level >= max_level:
		return
	var base_cost = {"army_rewrite": 12, "attack": 22, "attack_speed": 22, "crit_chance": 26, "crit_damage": 28, "ink_yield": 24, "ink_reflux": 24, "normal_dice_unlock": 30, "power_dice_unlock": 85, "cooldown": 24, "quick_entrance": 24}.get(id, 20)
	cost = int(base_cost) + level * 12
	if rewrite_ink < cost:
		if audio_manager != null:
			audio_manager.play_sfx("error")
		ui.show_event(loc("改写墨水不足。", "Not enough Rewrite Ink."), true)
		return
	rewrite_ink -= cost
	skill_levels[id] = level + 1
	if audio_manager != null:
		audio_manager.play_sfx("hero_upgrade")
	save_data["skill_levels"] = skill_levels.duplicate(true)
	save_system.save_progress(save_data)
	ui.show_event(loc("技能树已改写。", "The Skill Tree was rewritten."), true)

func _unlock_contract_name(monster_id: String) -> String:
	match monster_id:
		"bomber":
			return loc("火药合同", "Gunpowder Contract")
		"shaman":
			return loc("巫毒契约", "Voodoo Pact")
		"ogre":
			return loc("饕餮许可", "Glutton License")
		_:
			return loc("解锁 %s", "Unlock %s") % monster_display_name(monster_id)

func _unlock_contract_effect(monster_id: String) -> String:
	match monster_id:
		"bomber":
			return loc("解锁炸弹小鬼，炸弹小鬼伤害 +15%", "Unlock Bomb Imp, Bomb Imp damage +15%")
		"shaman":
			return loc("解锁巫毒萨满，毒素伤害 +20%", "Unlock Voodoo Shaman, poison damage +20%")
		"ogre":
			return loc("解锁食人魔，食人魔伤害 +15%", "Unlock Ogre, Ogre damage +15%")
		_:
			return loc("解锁新兵种", "Unlock a new unit")

func phase_name() -> String:
	match phase:
		"prepare":
			return loc("准备", "Prepare")
		"battle":
			return loc("战斗", "Battle")
		"reward":
			return loc("奖励", "Rewards")
		"red_choice":
			return loc("红按钮", "Red Button")
		"duel":
			return loc("决斗", "Duel")
		"game_over":
			return loc("失败", "Defeat")
		"victory":
			return loc("胜利", "Victory")
		"hero_escape":
			return loc("勇者升级", "Hero Upgrade")
		_:
			return phase

func monster_order() -> Array[String]:
	return ["warrior", "archer", "slime", "bomber", "shaman", "ogre"]

func is_monster_unlocked(id: String) -> bool:
	return run_unlocked.has(id)

func is_tutorial_wave() -> bool:
	return wave == 1 and waves_defeated == 0

func is_monster_available_this_wave(id: String) -> bool:
	return not is_tutorial_wave() or id == "warrior"

func monster_level(id: String) -> int:
	return int(run_upgrades.get(id, 0))

func command_regen_multiplier() -> float:
	return 0.0

func get_active_monsters() -> Array:
	return spawner.get_active_monsters()

func monster_attack_speed_multiplier(data) -> float:
	var value = 1.0
	value *= 1.0 + 0.05 * float(skill_level("attack_speed"))
	value *= 1.0 + 0.08 * float(boon_count("frantic_beat"))
	if data != null and data.id == "shaman":
		value *= 1.0 + 0.06 * float(skill_level("cooldown")) + 0.07 * float(skill_level("quick_entrance"))
	if has_boon("ensemble_riot") and active_unit_type_count() >= 3:
		value *= 1.12
	return value

func monster_damage_multiplier(data) -> float:
	var value = 1.0
	value *= 1.0 + 0.05 * float(skill_level("army_rewrite"))
	value *= 1.0 + 0.10 * float(boon_count("sharp_script"))
	if data != null and data.id == "bomber":
		value *= 1.0 + 0.15 * float(skill_level("unlock_bomber"))
	if data != null and data.id == "ogre":
		value *= 1.0 + 0.15 * float(skill_level("unlock_ogre"))
	if has_boon("ensemble_riot") and active_unit_type_count() >= 3:
		value *= 1.12
	return value

func monster_hp_multiplier(_data) -> float:
	return 1.0

func monster_move_speed_multiplier(_data) -> float:
	return 1.0 + 0.04 * float(skill_level("ink_yield")) + 0.05 * float(skill_level("ink_reflux")) + 0.05 * float(boon_count("ink_reflux"))

func ranged_crit_chance() -> float:
	return crit_chance_for(null)

func poison_damage_multiplier() -> float:
	return 1.0 + 0.20 * float(skill_level("unlock_shaman"))

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
	if ability == "poison" or ability == "ritual_heal":
		hero.apply_status("poison", 5.0, 2.0 * poison_damage_multiplier())
	elif ability == "slow":
		hero.apply_status("slow", 3.0, 0.42)
	var dealt = hero.take_damage(final_amount, source, final_tags)
	if bool(final_tags.get("critical", false)) and dealt > 0.0:
		combat_system.spawn_floating_text(hero.global_position + Vector2(20, -56), loc("暴击", "CRIT"), Color(1.0, 0.92, 0.22), true)
	return dealt

func apply_explosion_damage(world_position: Vector2, radius: float, damage: float, stun: float, tags = {}) -> void:
	if audio_manager != null:
		audio_manager.play_sfx("bomb")
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
		if monster.has_method("is_ambush_hidden") and monster.is_ambush_hidden():
			continue
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
	var center_bias = ARENA_BOUNDS.get_center() - hero_position
	if center_bias.length_squared() > 0.001:
		var inner_rect = ARENA_BOUNDS.grow(-132.0)
		var near_edge = not inner_rect.has_point(hero_position)
		direction = (direction.normalized() * 0.62 + center_bias.normalized() * (0.72 if near_edge else 0.20)).normalized()
	var strength = clamp(34.0 + (total_weight - 3.0) * 48.0, 34.0, 210.0)
	return direction.normalized() * strength

func preparation_population_capacity() -> int:
	return population_capacity()

func population_capacity() -> int:
	# Unit cap removed: keep a very large number so old UI/code can still read a capacity.
	return 9999

func population_used() -> int:
	var used = 0
	for monster in get_active_monsters():
		if monster.data != null:
			used += int(monster.data.population_cost)
	return used

func population_free() -> int:
	return 9999

func puzzle_summon_gold_cost(_unit_type: String, _power_level: int) -> int:
	# Single-currency mode: puzzle summons no longer spend gold.
	return 0

func _can_spawn_unit_now(monster_id: String, ignore_cooldown := false) -> bool:
	if not monster_catalog.has(monster_id):
		return false
	if phase == "battle" and not ignore_cooldown and summon_cooldown_remaining(monster_id) > 0.0:
		return false
	return true

func _spawn_unit_instance(monster_id: String, slot: Vector2, power_level: int) -> bool:
	if not monster_catalog.has(monster_id):
		return false
	var data = monster_catalog[monster_id]
	if commander != null and commander.has_method("trigger_summon_cast"):
		commander.trigger_summon_cast()
	var total_level :int= monster_level(monster_id) + max(0, power_level - 1)
	var monster = spawner.spawn(data, total_level, slot)
	if death_rewrite_ready:
		monster.apply_berserk()
		death_rewrite_ready = false
	if hero.armor <= 0.0:
		monster.apply_berserk()
	if power_level >= 3:
		monster.apply_berserk()
		monster.heal(monster.max_hp * 0.25)
	elif power_level == 2:
		monster.heal(monster.max_hp * 0.12)
	if phase == "battle":
		start_summon_cooldown(monster_id)
	return true

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
	for value in hero_inventory:
		var relic_id = map_director.relic_id_from_value(str(value))
		match relic_id:
			"poison":
				stats["poison_damage_multiplier"] = min(float(stats.get("poison_damage_multiplier", 1.0)), 0.50)
			"dark":
				stats["lantern_bonus"] = float(stats.get("lantern_bonus", 0.0)) + 100.0
			"light":
				stats["light_attack_speed_bonus"] = float(stats.get("light_attack_speed_bonus", 0.0)) + 0.20
			"mirror":
				stats["move_speed"] = float(stats.get("move_speed", 0.0)) + 12.0
			"gravity":
				stats["wall_damage_multiplier"] = min(float(stats.get("wall_damage_multiplier", 1.0)), 0.50)
			_:
				pass

func _on_hero_escape() -> void:
	if phase != "battle":
		return
	if is_final_room():
		game_over(loc("最终房间倒计时结束，勇者仍然活着。", "The final-room timer ended while the hero was still alive."))
		return
	phase = "room_clear_choice"
	carried_hero_hp = clamp(float(hero.hp), 1.0, float(hero.max_hp))
	hero.deactivate()
	spawner.despawn_all()
	var relic = map_director.current_relic(current_language())
	hero_inventory.append(map_director.current_id())
	hero_escape_count += 1
	pending_boons.assign(random_boon_offers("normal", 3))
	if pending_boons.is_empty():
		map_index += 1
		start_prepare()
		return
	pending_choice_kind = "normal"
	pending_transition_reason = "hero_cleared_room"
	ui.show_normal_room_choice(relic, map_director.room_name(current_language()), pending_boons)
	ui.show_event(loc("勇者清荡了房间，带走【%s】；你获得一次普通道具选择。", "The hero cleared the room and took [%s]. You gain one normal item choice.") % relic, true)

func continue_after_hero_escape() -> void:
	if pending_transition_reason == "hero_cleared_room":
		choose_temp_boon("")

func game_over(reason: String) -> void:
	if phase == "game_over" or final_outcome_cutscene_playing:
		return
	phase = "game_over"
	if spawner != null:
		spawner.despawn_all()
	if placement != null:
		placement.enabled = false
	if hero != null:
		hero.deactivate()
	pending_game_over_reason = reason
	final_outcome_cutscene_playing = true
	if ui != null and ui.has_method("play_commander_killed_cutscene"):
		ui.play_commander_killed_cutscene(Callable(self, "_finish_commander_killed_game_over"))
	else:
		_finish_commander_killed_game_over()

func _finish_commander_killed_game_over() -> void:
	final_outcome_cutscene_playing = false
	_record_score("defeat")
	save_system.save_progress(save_data)
	ui.show_game_over(pending_game_over_reason, waves_defeated)
	ui.update_stats()
	ui.show_event(loc("挑战失败：永久资源已保存。", "Defeat: permanent resources have been saved."), true)
	pending_game_over_reason = ""

func _build_world() -> void:
	add_child(wave_director)
	add_child(rage_system)
	add_child(red_button_system)
	add_child(audio_manager)
	add_child(ui)
	world_root = Node2D.new()
	add_child(world_root)
	arena = ArenaScene.instantiate()
	world_root.add_child(arena)
	if arena.has_method("setup"):
		arena.setup(self)
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
	commander.setup(Vector2(617, 536), balance.commander_max_hp, self)
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
	commander.died.connect(_on_commander_died)
	rage_system.rage_full.connect(_on_rage_full)
	red_button_system.choice_required.connect(_on_red_button_choice_required)

func _process_battle(delta: float) -> void:
	battle_time += delta
	room_time_remaining = max(0.0, room_time_remaining - delta)
	timer_warning_beep_cooldown = max(0.0, timer_warning_beep_cooldown - delta)
	if room_time_remaining <= 18.0 and room_time_remaining > 0.0 and timer_warning_beep_cooldown <= 0.0:
		timer_warning_beep_cooldown = 1.0
		if audio_manager != null:
			audio_manager.play_sfx("warning", 1.0, -2.0)
	map_director.process_room(delta)
	_process_interactive_timers(delta)
	if room_time_remaining <= 0.0:
		if is_final_room() and hero != null and hero.active:
			game_over(loc("最终房间倒计时结束，勇者仍然活着。", "The final-room timer ended while the hero was still alive."))
		else:
			_on_hero_escape()

func _on_monster_died(monster) -> void:
	if has_boon("death_rewrite"):
		death_rewrite_ready = true
	if monster != null and monster.data != null:
		ui.show_event(loc("%s退场，剧本席位已返还。", "%s leaves the stage; its Cast Slot has returned.") % monster_display_name(monster.data.id), true)

func _on_hero_armor_broken() -> void:
	for monster in get_active_monsters():
		monster.apply_berserk()
	combat_system.shake(0.24, 9.0)
	ui.show_event(loc("护甲粉碎！怪物狂暴！", "Armor shattered! Monsters are berserk!"), true)

func _on_commander_died() -> void:
	game_over(loc("哥布林指挥台被勇者摧毁。", "The Goblin Command Post was destroyed by the hero."))

func _on_hero_died() -> void:
	if phase != "battle" and phase != "duel":
		return
	spawner.despawn_all()
	grant_rewrite_ink(hero_defeat_ink_reward(), true)
	hero_lives_remaining = max(0, hero_lives_remaining - 1)
	last_reclaimed_loot = hero_inventory.duplicate()
	hero_inventory.clear()
	ui.update_stats()
	if hero_lives_remaining <= 0:
		_run_victory()
		return
	_begin_hero_defeat_choice()

func _on_rage_full() -> void:
	# Legacy rage is intentionally inert in v12. The only active red action is Rewrite Scene.
	return

func _on_red_button_choice_required(effects: Array) -> void:
	ui.show_red_button_options(effects)
	ui.show_event(loc("红按钮已触发，选择一个高风险翻盘效果。", "The Red Button triggered. Choose a high-risk comeback effect."), true)

func _begin_hero_defeat_choice() -> void:
	if phase == "hero_defeated_choice" or phase == "victory":
		return
	phase = "hero_defeated_choice"
	waves_defeated += 1
	var transition_room = room_time_remaining <= 3.0 and not is_final_room()
	pending_boons.assign(random_boon_offers("power", 3))
	pending_choice_kind = "power"
	pending_transition_reason = "hero_defeated_transition" if transition_room else "hero_defeated_resume"
	ui.show_power_choice({"ink": hero_defeat_ink_reward()}, newly_activated_seal_name(), pending_boons, room_time_remaining, transition_room)
	ui.refresh_monster_list()
	var loot_text = ""
	if not last_reclaimed_loot.is_empty():
		loot_text = loc(" 夺回遗物：%s。", " Reclaimed relics: %s.") % hero_relic_list_text(last_reclaimed_loot)
	var flow_text = loc("选择强力道具后，勇者会在本室复活并继续倒计时。", "After the power choice, the hero revives in this room and the timer continues.")
	if transition_room:
		flow_text = loc("剩余时间不足 3 秒，选择强力道具后切换下一间房。", "Three seconds or less remained, so the power choice moves to the next room.")
	ui.show_event(loc("勇者倒下，【%s】解封。%s%s", "The hero fell. [%s] is unlocked. %s%s") % [newly_activated_seal_name(), flow_text, loot_text], true)

func _wave_victory() -> void:
	_begin_hero_defeat_choice()

func _run_victory() -> void:
	if phase == "victory" or final_outcome_cutscene_playing:
		return
	phase = "victory"
	waves_defeated += 1
	spawner.despawn_all()
	if placement != null:
		placement.enabled = false
	hero.deactivate()
	ui.update_stats()
	pending_victory_waves_defeated = waves_defeated
	final_outcome_cutscene_playing = true
	if ui != null and ui.has_method("play_hero_killed_cutscene"):
		ui.play_hero_killed_cutscene(Callable(self, "_finish_hero_killed_run_victory"))
	else:
		_finish_hero_killed_run_victory()

func _finish_hero_killed_run_victory() -> void:
	final_outcome_cutscene_playing = false
	_record_score("victory")
	ui.show_run_victory({"ink": hero_defeat_ink_reward()}, pending_victory_waves_defeated)
	ui.update_stats()
	ui.show_event(loc("勇者的所有命数已经耗尽。", "All of the hero's lives are gone."), true)

func current_score() -> int:
	# During the room, show only the score earned by Match Board clears and combo chains.
	# This keeps the run score starting from 0 and makes every match visibly meaningful.
	return max(0, combo_score_bonus)

func final_score() -> int:
	var hp_ratio: float = 0.0
	if hero != null and hero.has_method("hp_ratio"):
		hp_ratio = clamp(float(hero.hp_ratio()), 0.0, 1.0)
	var life_score: int = int(hero_lives_remaining) * 12000
	var hp_score: int = int(round(hp_ratio * 8000.0))
	var time_score: int = int(round(max(room_time_remaining, 0.0) * 45.0))
	var room_score: int = int(max(map_index, 0)) * 1500 + int(waves_defeated) * 1000
	var economy_score: int = int(rewrite_ink) * 20
	return max(0, combo_score_bonus + life_score + hp_score + time_score + room_score + economy_score)

func _record_score(result: String) -> void:
	if score_recorded:
		return
	score_recorded = true
	if not save_data.has("scores") or typeof(save_data["scores"]) != TYPE_ARRAY:
		save_data["scores"] = []
	var settings: Dictionary = {}
	if save_data.has("settings") and typeof(save_data["settings"]) == TYPE_DICTIONARY:
		settings = save_data["settings"]
	var player_name = str(settings.get("player_name", "Player"))
	if player_name.strip_edges() == "":
		player_name = "Player"
	var hp_ratio := 0.0
	if hero != null and hero.has_method("hp_ratio"):
		hp_ratio = clamp(float(hero.hp_ratio()), 0.0, 1.0)
	var score: int = final_score()
	var entry = {
		"name": player_name,
		"score": score,
		"result": result,
		"lives": hero_lives_remaining,
		"hp_percent": int(round(hp_ratio * 100.0)),
		"time": int(round(max(room_time_remaining, 0.0))),
		"room": map_index + 1,
		"ink": rewrite_ink,
		"combo_bonus": combo_score_bonus,
		"best_combo": highest_combo
	}
	save_data["scores"].append(entry)
	save_data["scores"].sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	while save_data["scores"].size() > 30:
		save_data["scores"].pop_back()
	save_system.save_progress(save_data)

func _grant_rewards(_rewards: Dictionary) -> void:
	pass

func convert_gold_to_skill_points() -> void:
	ui.show_event(loc("现在只有改写墨水一种货币；棋盘奖励会给更多墨水。", "Rewrite Ink is the only currency now; puzzle rewards grant more Ink."), true)

func _trigger_time_event() -> void:
	var ratio = hero.hp_ratio()
	if ratio > 0.70:
		hero.apply_status("momentum", 5.0, 1.0)
		rage_system.add(14.0)
		ui.show_event(loc("时间事件：勇者气势高涨，攻速短暂提高。", "Time event: the hero gains momentum and attacks faster for a short time."), true)
	elif ratio > 0.30:
		if _try_spawn_random_interactive():
			ui.show_event(loc("时间事件：竞技场地形翻动，新的互动物出现。", "Time event: the arena shifts and a new interactive object appears."))
		else:
			ui.show_event(loc("时间事件：场景物件已到上限，地形暂时稳定。", "Time event: the interactive-object limit is reached; terrain stabilizes."))
	else:
		command_points = min(max_command_points, command_points + 26.0)
		for monster in get_active_monsters():
			monster.apply_berserk()
		ui.show_event(loc("时间事件：压制优势，获得指挥点并激励怪物。", "Time event: pressure advantage grants command points and inspires monsters."))

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
			ui.show_event(loc("地形变化：新的场景物件出现。", "Terrain shift: a new interactive object appears."))
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
	# Random roadblocks/obstacles removed. Keep only non-blocking interactive props.
	var roll = randf()
	if roll < 0.34:
		return "barrel"
	if roll < 0.67:
		return "poison_pool"
	return "slow_pool"

func _random_interactive_position(kind: String) -> Vector2:
	var proposed_radius = _interactive_radius_for(kind)
	var floor_margin = proposed_radius + 28.0
	var min_x = INTERACTIVE_SPAWN_RECT.position.x + floor_margin
	var max_x = INTERACTIVE_SPAWN_RECT.end.x - floor_margin
	var min_y = INTERACTIVE_SPAWN_RECT.position.y + floor_margin
	var max_y = INTERACTIVE_SPAWN_RECT.end.y - floor_margin
	if min_x >= max_x or min_y >= max_y:
		return Vector2.INF
	for _attempt in range(36):
		var position = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
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
	ui.show_event(loc("地形变化：一件场景物件消散。", "Terrain shift: an interactive object fades away."))

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
				return boon_display_name(boon)
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
	ui.show_event(loc("红按钮：指挥官被弹射进决斗。", "Red Button: the commander is launched into a duel."), true)
	ui.show_duel(duel, _duel_actions())

func _duel_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	actions.append({"id": "strike", "name": loc("继承猛击", "Inherited Smash"), "description": loc("造成稳定伤害。", "Deal steady damage.")})
	actions.append({"id": "shield", "name": loc("怪物护盾", "Monster Shield"), "description": loc("本回合大幅减伤，并造成少量伤害。", "Greatly reduce this turn's damage and deal a little damage.")})
	actions.append({"id": "venom", "name": loc("毒性诅咒", "Venom Curse"), "description": loc("造成伤害并让勇者持续流失生命。", "Deal damage and make the hero keep losing health.")})
	if _duel_has_tag("burst"):
		actions[2] = {"id": "blast", "name": loc("炸弹冲撞", "Bomb Charge"), "description": loc("高伤害，但指挥官也会受反冲。", "High damage, but the commander suffers recoil.")}
	return actions

func _duel_has_tag(tag: String) -> bool:
	for t in duel.get("tags", []):
		if t == tag:
			return true
	return false
