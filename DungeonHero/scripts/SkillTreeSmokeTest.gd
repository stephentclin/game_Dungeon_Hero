extends SceneTree

var main_scene

func _init() -> void:
	var packed = load("res://scenes/Main.tscn")
	main_scene = packed.instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	main_scene.skill_levels.clear()
	for id in main_scene.DEFAULT_SKILL_LEVELS.keys():
		main_scene.skill_levels[id] = 0
	main_scene.skill_levels["army_rewrite"] = 2
	main_scene.skill_levels["attack_speed"] = 1
	main_scene.skill_levels["crit_chance"] = 2
	main_scene.skill_levels["attack"] = 1
	main_scene.skill_levels["ink_yield"] = 1
	main_scene.skill_levels["ink_reflux"] = 2
	main_scene.skill_levels["normal_dice_unlock"] = 1
	main_scene.skill_levels["power_dice_unlock"] = 1
	main_scene.skill_levels["cooldown"] = 2
	main_scene.skill_levels["quick_entrance"] = 1
	main_scene.skill_levels["unlock_bomber"] = 1
	main_scene.skill_levels["unlock_shaman"] = 1
	main_scene.skill_levels["unlock_ogre"] = 1
	assert_close("army damage", main_scene.monster_damage_multiplier(main_scene.monster_catalog["warrior"]), 1.10)
	assert_close("bomber damage", main_scene.monster_damage_multiplier(main_scene.monster_catalog["bomber"]), 1.10 * 1.15)
	assert_close("ogre damage", main_scene.monster_damage_multiplier(main_scene.monster_catalog["ogre"]), 1.10 * 1.15)
	assert_close("shaman cast speed", main_scene.monster_attack_speed_multiplier(main_scene.monster_catalog["shaman"]), 1.05 * 1.19)
	assert_close("move speed", main_scene.monster_move_speed_multiplier(main_scene.monster_catalog["warrior"]), 1.14)
	assert_close("poison damage", main_scene.poison_damage_multiplier(), 1.20)
	assert_close("crit chance", main_scene.crit_chance_for(null), 0.06)
	assert_close("crit damage", main_scene.crit_damage_multiplier(), 1.65)
	if main_scene.puzzle_luck_points() != 2:
		push_error("Skill tree smoke failed: puzzle luck is %d, expected 2." % main_scene.puzzle_luck_points())
		quit(1)
		return
	if main_scene.puzzle_luck_reward_bonus(1, "3 MATCH") != 2:
		push_error("Skill tree smoke failed: luck reward bonus is %d, expected 2." % main_scene.puzzle_luck_reward_bonus(1, "3 MATCH"))
		quit(1)
		return
	print("SKILL_TREE_SMOKE_OK")
	quit(0)

func assert_close(label: String, got: float, expected: float) -> void:
	if not is_equal_approx(got, expected):
		push_error("Skill tree smoke failed: %s got %.4f expected %.4f." % [label, got, expected])
		quit(1)
