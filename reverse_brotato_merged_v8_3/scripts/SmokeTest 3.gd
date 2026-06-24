extends SceneTree

var main_scene
var frame_count = 0

func _init() -> void:
	print("SMOKE_INIT")
	var packed = load("res://scenes/Main.tscn")
	main_scene = packed.instantiate()
	main_scene._ready()
	main_scene.request_place_monster("warrior", main_scene.hero.global_position + Vector2(10, 0))
	var blocked_count = main_scene.get_active_monsters().size()
	main_scene.request_place_monster("warrior", Vector2(120, 300))
	main_scene.rage_system.rage = 80.0
	var regen_mult = main_scene.command_regen_multiplier()
	main_scene.begin_battle()
	main_scene._process(0.016)
	var monster_count = main_scene.get_active_monsters().size()
	if blocked_count != 0 or monster_count != 1 or regen_mult <= 1.0:
		push_error("Smoke failed: blocked_near=%d monsters=%d regen=%.2f" % [blocked_count, monster_count, regen_mult])
		main_scene.free()
		quit(1)
		return
	print("SMOKE_OK phase=%s wave=%d blocked_near=%d monsters=%d cp=%.1f hero_hp=%.1f regen=%.2f" % [
		main_scene.phase,
		main_scene.wave,
		blocked_count,
		monster_count,
		main_scene.command_points,
		main_scene.hero.hp,
		regen_mult
	])
	main_scene.free()
	quit(0)
