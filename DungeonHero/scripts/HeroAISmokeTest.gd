extends SceneTree

var main_scene

func _init() -> void:
	var packed = load("res://scenes/Main.tscn")
	main_scene = packed.instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	if not is_equal_approx(float(main_scene.room_time_remaining), 50.0):
		push_error("Hero AI smoke failed: room time is %.1f, expected 50.0." % float(main_scene.room_time_remaining))
		quit(1)
		return
	if not is_equal_approx(float(main_scene.map_director.room_duration), 50.0):
		push_error("Hero AI smoke failed: map room duration is %.1f, expected 50.0." % float(main_scene.map_director.room_duration))
		quit(1)
		return
	main_scene.phase = "battle"
	main_scene.hero.activate()
	main_scene.hero.global_position = Vector2(main_scene.ARENA_BOUNDS.position.x + 28.0, main_scene.ARENA_BOUNDS.get_center().y)
	main_scene.spawner.despawn_all()
	main_scene._spawn_unit_instance("warrior", main_scene.ARENA_BOUNDS.get_center() + Vector2(120.0, 0.0), 1)
	main_scene._spawn_unit_instance("slime", main_scene.ARENA_BOUNDS.get_center() + Vector2(160.0, 42.0), 1)
	main_scene._spawn_unit_instance("archer", main_scene.ARENA_BOUNDS.get_center() + Vector2(150.0, -54.0), 1)
	main_scene._spawn_unit_instance("bomber", main_scene.ARENA_BOUNDS.get_center() + Vector2(205.0, 12.0), 1)
	await process_frame
	var target = main_scene.get_hero_target()
	if target == null:
		push_error("Hero AI smoke failed: no target.")
		quit(1)
		return
	var distance: float = main_scene.hero.global_position.distance_to(target.global_position)
	var attack_range: float = float(main_scene.hero.stats.get("attack_range", 52.0))
	var movement: Vector2 = main_scene.hero._combat_movement(target, distance, attack_range, 0.016)
	var to_target: Vector2 = (target.global_position - main_scene.hero.global_position).normalized()
	var to_center: Vector2 = (main_scene.ARENA_BOUNDS.get_center() - main_scene.hero.global_position).normalized()
	if movement.normalized().dot(to_target) <= 0.35:
		push_error("Hero AI smoke failed: movement does not press target. movement=%s target_dir=%s" % [movement, to_target])
		quit(1)
		return
	if movement.normalized().dot(to_center) <= 0.35:
		push_error("Hero AI smoke failed: movement does not favor center. movement=%s center_dir=%s" % [movement, to_center])
		quit(1)
		return
	main_scene._on_hero_died()
	await process_frame
	if main_scene.get_active_monsters().size() != 0:
		push_error("Hero AI smoke failed: monsters were not cleared after hero death.")
		quit(1)
		return
	print("HERO_AI_SMOKE_OK")
	quit(0)
