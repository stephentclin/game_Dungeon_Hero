extends SceneTree

var main_scene
var board
var recorded_summons := []

func _init() -> void:
	var packed = load("res://scenes/Main.tscn")
	main_scene = packed.instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	board = main_scene.ui.puzzle_board
	if board == null:
		push_error("Puzzle board was not created.")
		quit(1)
		return
	var main_summon_callback := Callable(main_scene, "request_puzzle_summon")
	if board.summon_requested.is_connected(main_summon_callback):
		board.summon_requested.disconnect(main_summon_callback)
	board.summon_requested.connect(_on_summon_requested)
	board.board_width = 6
	board.board_height = 6
	board.reset_board()
	main_scene.waves_defeated = 1
	main_scene.wave = 2
	main_scene.run_unlocked = main_scene.monster_order().duplicate()

	await _run_match_case("clear_1_normal", _three_match_rows(), {"warrior": 1})
	board._last_clear_time_msec = 0
	board._rapid_chain = 0
	await _run_special_case("clear_2_total_row_stacks", _special_rows(100), Vector2i(0, 0), {"warrior": 1, "slime": 1, "bomber": 2, "ogre": 1})
	await _run_special_case("clear_3_column", _special_rows(200), Vector2i(0, 0), {"warrior": 1, "shaman": 1, "slime": 1})
	await _run_match_case("clear_4_normal", _three_match_rows(), {"warrior": 1})
	await _run_match_case("clear_5_total", _three_match_rows(), {"warrior": 1, "archer": 1, "shaman": 1, "slime": 1, "bomber": 1})
	await _run_match_case("clear_6_normal", _three_match_rows(), {"warrior": 1})
	await _run_match_case("clear_7_normal", _three_match_rows(), {"warrior": 1})
	await _run_match_case("clear_8_total", _three_match_rows(), {"warrior": 1, "slime": 1, "bomber": 1, "archer": 1, "shaman": 1, "ogre": 1})
	await _run_direct_board_spawn_bypass_case()

	print("PUZZLE_SMOKE_OK")
	quit(0)

func _run_match_case(name: String, piece_rows: Array, expected_counts: Dictionary) -> void:
	recorded_summons.clear()
	board.debug_set_board(piece_rows)
	await process_frame
	await board.debug_force_resolve()
	await process_frame
	_assert_summons(name, expected_counts)

func _run_special_case(name: String, piece_rows: Array, cell: Vector2i, expected_counts: Dictionary) -> void:
	recorded_summons.clear()
	board.debug_set_board(piece_rows)
	await process_frame
	await board._activate_special_piece(cell)
	await process_frame
	_assert_summons(name, expected_counts)

func _assert_summons(name: String, expected_counts: Dictionary) -> void:
	var actual_counts := {}
	for summon in recorded_summons:
		var unit_id := str(summon["unit"])
		actual_counts[unit_id] = int(actual_counts.get(unit_id, 0)) + int(summon["amount"])
	if actual_counts.size() != expected_counts.size():
		push_error("Case %s summon keys mismatch: got %s expected %s" % [name, actual_counts, expected_counts])
		quit(1)
		return
	for unit_id in expected_counts.keys():
		if int(actual_counts.get(unit_id, 0)) != int(expected_counts[unit_id]):
			push_error("Case %s mismatch: got %s expected %s" % [name, actual_counts, expected_counts])
			quit(1)
			return

func _run_direct_board_spawn_bypass_case() -> void:
	main_scene.spawner.despawn_all()
	var default_unlocked: Array[String] = ["warrior", "archer", "slime"]
	main_scene.run_unlocked = default_unlocked
	main_scene.wave = 1
	main_scene.waves_defeated = 0
	main_scene.request_puzzle_summon("bomber", 1, 1)
	main_scene.request_puzzle_summon("shaman", 1, 1)
	await process_frame
	var actual_counts := _active_monster_counts()
	var expected_counts := {"bomber": 1, "shaman": 1}
	for unit_id in expected_counts.keys():
		if int(actual_counts.get(unit_id, 0)) != int(expected_counts[unit_id]):
			push_error("Direct board summon bypass mismatch: got %s expected %s" % [actual_counts, expected_counts])
			quit(1)
			return

func _active_monster_counts() -> Dictionary:
	var counts := {}
	for monster in main_scene.get_active_monsters():
		if monster == null or monster.data == null:
			continue
		var unit_id := str(monster.data.id)
		counts[unit_id] = int(counts.get(unit_id, 0)) + 1
	return counts

func _three_match_rows() -> Array:
	return [
		[0, 0, 0, 3, 4, 5],
		[1, 2, 3, 4, 5, 0],
		[2, 3, 4, 5, 0, 1],
		[3, 4, 5, 0, 1, 2],
		[4, 5, 0, 1, 2, 3],
		[5, 0, 1, 2, 3, 4]
	]

func _special_rows(special_value: int) -> Array:
	var rows := [
		[0, 1, 2, 3, 4, 5],
		[1, 2, 3, 4, 5, 0],
		[2, 3, 4, 5, 0, 1],
		[3, 4, 5, 0, 1, 2],
		[4, 5, 0, 1, 2, 3],
		[5, 0, 1, 2, 3, 4]
	]
	rows[0][0] = special_value
	return rows

func _on_summon_requested(unit_type: String, amount: int, power_level: int) -> void:
	recorded_summons.append({
		"unit": unit_type,
		"amount": amount,
		"power": power_level
	})
