extends RefCounted
class_name MatchDetector

const DIRECTIONS := [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN
]

func find_matches(type_grid: Array) -> Array:
	if type_grid.is_empty():
		return []
	var matched_cells := {}
	var matched_types := {}
	var width := int(type_grid[0].size())
	var height := int(type_grid.size())

	for y in range(height):
		var run_start := 0
		var run_type = type_grid[y][0]
		for x in range(1, width + 1):
			var next_type = null if x >= width else type_grid[y][x]
			if str(next_type) != str(run_type):
				var run_length := x - run_start
				if _is_matchable_type(run_type) and run_length >= 3:
					for ix in range(run_start, x):
						var cell := Vector2i(ix, y)
						var key := _cell_key(cell)
						matched_cells[key] = cell
						matched_types[key] = run_type
				run_start = x
				run_type = next_type

	for x in range(width):
		var run_start := 0
		var run_type = type_grid[0][x]
		for y in range(1, height + 1):
			var next_type = null if y >= height else type_grid[y][x]
			if str(next_type) != str(run_type):
				var run_length := y - run_start
				if _is_matchable_type(run_type) and run_length >= 3:
					for iy in range(run_start, y):
						var cell := Vector2i(x, iy)
						var key := _cell_key(cell)
						matched_cells[key] = cell
						matched_types[key] = run_type
				run_start = y
				run_type = next_type

	var visited := {}
	var groups := []
	for key in matched_cells.keys():
		if visited.has(key):
			continue
		var cells: Array = []
		var frontier: Array = [matched_cells[key]]
		var piece_type: int = int(matched_types[key])
		visited[key] = true
		while not frontier.is_empty():
			var current: Vector2i = frontier.pop_back()
			cells.append(current)
			for direction in DIRECTIONS:
				var neighbor: Vector2i = current + direction
				var neighbor_key: String = _cell_key(neighbor)
				if visited.has(neighbor_key):
					continue
				if not matched_cells.has(neighbor_key):
					continue
				if int(matched_types[neighbor_key]) != piece_type:
					continue
				visited[neighbor_key] = true
				frontier.append(neighbor)
		var cell_lookup := {}
		for cell in cells:
			cell_lookup[_cell_key(cell)] = true
		groups.append({
			"piece_type": int(piece_type),
			"cells": cells,
			"size": cells.size(),
			"line_length": _max_line_length(cells, cell_lookup),
			"shape": _classify_group(cells, cell_lookup)
		})

	groups.sort_custom(func(a, b): return _shape_priority(str(a["shape"])) < _shape_priority(str(b["shape"])))
	return groups

func _classify_group(cells: Array, cell_lookup: Dictionary) -> String:
	for cell in cells:
		var left := cell_lookup.has(_cell_key(cell + Vector2i.LEFT))
		var right := cell_lookup.has(_cell_key(cell + Vector2i.RIGHT))
		var up := cell_lookup.has(_cell_key(cell + Vector2i.UP))
		var down := cell_lookup.has(_cell_key(cell + Vector2i.DOWN))
		var horizontal_len := _axis_length(cell, cell_lookup, Vector2i.LEFT, Vector2i.RIGHT)
		var vertical_len := _axis_length(cell, cell_lookup, Vector2i.UP, Vector2i.DOWN)
		if left and right and up and down:
			return "cross"
		if horizontal_len >= 3 and vertical_len >= 3:
			var branches := int(left) + int(right) + int(up) + int(down)
			if branches >= 3:
				return "t"
			return "l"
	var longest := _max_line_length(cells, cell_lookup)
	if longest >= 5:
		return "five"
	if longest >= 4:
		return "four"
	return "three"

func _axis_length(cell: Vector2i, cell_lookup: Dictionary, negative: Vector2i, positive: Vector2i) -> int:
	var count := 1
	var cursor := cell + negative
	while cell_lookup.has(_cell_key(cursor)):
		count += 1
		cursor += negative
	cursor = cell + positive
	while cell_lookup.has(_cell_key(cursor)):
		count += 1
		cursor += positive
	return count

func _max_line_length(cells: Array, cell_lookup: Dictionary) -> int:
	var longest := 0
	for cell in cells:
		longest = max(longest, _axis_length(cell, cell_lookup, Vector2i.LEFT, Vector2i.RIGHT))
		longest = max(longest, _axis_length(cell, cell_lookup, Vector2i.UP, Vector2i.DOWN))
	return longest

func _shape_priority(shape: String) -> int:
	match shape:
		"cross":
			return 0
		"t":
			return 1
		"l":
			return 2
		"five":
			return 3
		"four":
			return 4
		_:
			return 5

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _is_matchable_type(value) -> bool:
	if value == null:
		return false
	if str(value) == "":
		return false
	return int(value) >= 0
