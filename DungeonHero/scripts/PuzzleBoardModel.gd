extends RefCounted
class_name PuzzleBoardModel

var board_width := 6
var board_height := 6
var piece_type_count := 6
var cells: Array = []

func configure(width_value: int, height_value: int, type_count_value: int) -> void:
	board_width = width_value
	board_height = height_value
	piece_type_count = max(1, type_count_value)
	clear()

func clear() -> void:
	cells.clear()
	for y in range(board_height):
		var row: Array = []
		for _x in range(board_width):
			row.append(-1)
		cells.append(row)

func generate_without_start_matches() -> void:
	clear()
	for y in range(board_height):
		for x in range(board_width):
			cells[y][x] = _random_type_avoiding_match(x, y)

func set_rows(rows: Array) -> void:
	clear()
	for y in range(min(board_height, rows.size())):
		var row: Array = rows[y]
		for x in range(min(board_width, row.size())):
			cells[y][x] = int(row[x])

func to_type_grid() -> Array:
	var result: Array = []
	for y in range(board_height):
		var row: Array = []
		for x in range(board_width):
			var value := int(cells[y][x])
			row.append(_base_type(value) if value >= 0 else -1)
		result.append(row)
	return result

func _base_type(value: int) -> int:
	if value < 0:
		return value
	return value % 100

func get_type(cell: Vector2i) -> int:
	if not is_inside(cell):
		return -1
	return int(cells[cell.y][cell.x])

func set_type(cell: Vector2i, value: int) -> void:
	if not is_inside(cell):
		return
	cells[cell.y][cell.x] = value

func swap_cells(cell_a: Vector2i, cell_b: Vector2i) -> void:
	if not is_inside(cell_a) or not is_inside(cell_b):
		return
	var temp: int = int(cells[cell_a.y][cell_a.x])
	cells[cell_a.y][cell_a.x] = cells[cell_b.y][cell_b.x]
	cells[cell_b.y][cell_b.x] = temp

func clear_cells(match_cells: Array) -> void:
	for cell in match_cells:
		if is_inside(cell):
			cells[cell.y][cell.x] = -1

func collapse() -> Array:
	var moves: Array = []
	for x in range(board_width):
		var write_y := board_height - 1
		for y in range(board_height - 1, -1, -1):
			var piece_type: int = int(cells[y][x])
			if piece_type < 0:
				continue
			if y != write_y:
				cells[write_y][x] = piece_type
				cells[y][x] = -1
				moves.append({
					"from": Vector2i(x, y),
					"to": Vector2i(x, write_y),
					"piece_type": piece_type
				})
			write_y -= 1
		while write_y >= 0:
			cells[write_y][x] = -1
			write_y -= 1
	return moves

func refill() -> Array:
	var spawns: Array = []
	for x in range(board_width):
		var source_row := -1
		for y in range(board_height - 1, -1, -1):
			if int(cells[y][x]) >= 0:
				continue
			var piece_type := _random_type()
			cells[y][x] = piece_type
			spawns.append({
				"cell": Vector2i(x, y),
				"piece_type": piece_type,
				"source_row": source_row
			})
			source_row -= 1
	return spawns

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < board_width and cell.y >= 0 and cell.y < board_height

func _random_type() -> int:
	return randi() % piece_type_count

func _random_type_avoiding_match(x: int, y: int) -> int:
	for _attempt in range(20):
		var candidate := _random_type()
		var left_match: bool = x >= 2 and int(cells[y][x - 1]) == candidate and int(cells[y][x - 2]) == candidate
		var up_match: bool = y >= 2 and int(cells[y - 1][x]) == candidate and int(cells[y - 2][x]) == candidate
		if not left_match and not up_match:
			return candidate
	return _random_type()
