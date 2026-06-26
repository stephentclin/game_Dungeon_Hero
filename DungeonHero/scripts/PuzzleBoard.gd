extends Control
class_name PuzzleBoard

signal summon_requested(unit_type: String, amount: int, power_level: int)
signal reward_requested(ink_amount: int, gold_amount: int, combo_count: int, label: String)
signal preview_unit_requested(unit_type: String)
signal board_message_requested(message: String, urgent: bool)
signal matchboard_started()

const PuzzlePieceScene = preload("res://scenes/ui/PuzzlePiece.tscn")
const MatchDetectorScript = preload("res://scripts/MatchDetector.gd")
const PuzzleToUnitMapperScript = preload("res://scripts/PuzzleToUnitMapper.gd")
const PuzzleBoardModelScript = preload("res://scripts/PuzzleBoardModel.gd")
const NORMAL_CLEAR_UNIT := "warrior"
const SPECIAL_CLEAR_REWARD_UNITS := {
	2: ["slime", "bomber"],
	5: ["archer", "shaman", "slime", "bomber"],
	8: ["slime", "bomber", "archer", "shaman", "ogre"]
}
const ROW_CLEAR_REWARD_UNITS := ["bomber", "ogre"]
const COLUMN_CLEAR_REWARD_UNITS := ["shaman", "slime"]
const SPACE_DROP_DURATION := 1.0

@export var board_width := 15
@export var board_height := 19
@export var cell_size := 25.0
@export var cell_gap := 1.0

static var _match_board_guide_seen_this_session: bool = false

static func reset_match_board_guide_for_new_run() -> void:
	_match_board_guide_seen_this_session = false

var grid := []
var main: Node = null
var audio_manager = null

var _detector: MatchDetector
var _mapper: PuzzleToUnitMapper
var _model: PuzzleBoardModel
var _piece_layer: Control
var _fx_layer: Control
var _pieces := {}
var _selected_cell := Vector2i(-1, -1)
var _drag_origin_cell := Vector2i(-1, -1)
var _busy := false
var _last_clear_time_msec := 0
var _rapid_chain := 0
var _special_clear_count := 0
var _interactive_enabled := true

# Hybrid Match-3 x falling-block mode. The board starts empty and random cute blocks fall in.
var _active_cells: Array = []
var _fall_interval := 0.72
var _fall_accumulator := 0.0
var _soft_drop_interval := 0.08
var _move_repeat_delay := 0.18
var _move_repeat_interval := 0.075
var _rotate_repeat_delay := 0.22
var _rotate_repeat_interval := 0.14
var _held_move_dir := 0
var _move_hold_elapsed := 0.0
var _move_repeat_elapsed := 0.0
var _rotate_held := false
var _rotate_hold_elapsed := 0.0
var _rotate_repeat_elapsed := 0.0
var _piece_bag: Array = []
var _game_started := false
var _start_overlay: Control = null
var _start_button: Button = null
var _guide_panel: Control = null
var _guide_close_button: Button = null
var _countdown_label: Label = null
var _countdown_running := false
var _guide_open_during_game := false
var _hard_drop_locked := false
var _hard_drop_cooldown := 0.0
var _locking_piece := false

func setup(owner: Node, audio_owner = null) -> void:
	main = owner
	audio_manager = audio_owner
	_ensure_runtime()
	reset_board()

func _main_run_finished() -> bool:
	return main != null and main.has_method("is_run_finished") and main.is_run_finished()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	_ensure_runtime()
	reset_board()

func set_interactive_enabled(value: bool) -> void:
	_interactive_enabled = value
	if _piece_layer != null:
		_piece_layer.modulate = Color(0.42, 0.42, 0.46, 0.50) if not value else Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE if not value else Control.MOUSE_FILTER_PASS

func reset_board() -> void:
	_locking_piece = false
	_hard_drop_locked = false
	_ensure_runtime()
	_busy = false
	_game_started = false
	_countdown_running = false
	_guide_open_during_game = false
	_last_clear_time_msec = 0
	_rapid_chain = 0
	_special_clear_count = 0
	_selected_cell = Vector2i(-1, -1)
	_drag_origin_cell = Vector2i(-1, -1)
	_active_cells.clear()
	_reset_continuous_input_state()
	_clear_piece_nodes()
	_model.clear()
	_sync_grid_cache()
	if _match_board_guide_seen_this_session:
		_start_countdown_without_guide()
	else:
		_show_start_overlay()
	queue_redraw()

func debug_set_board(piece_types: Array) -> void:
	_ensure_runtime()
	if piece_types.size() != board_height:
		return
	for row in piece_types:
		if row.size() != board_width:
			return
	_busy = false
	_clear_piece_nodes()
	_model.set_rows(piece_types)
	_sync_grid_cache()
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			_create_piece(_model.get_type(cell), cell, false)
	queue_redraw()

func debug_force_resolve() -> void:
	_ensure_runtime()
	if _busy:
		return
	var matches := _detector.find_matches(_model.to_type_grid())
	if matches.is_empty():
		return
	_busy = true
	await _resolve_matches(matches)
	_busy = false

func board_pixel_size() -> Vector2:
	return Vector2(
		board_width * cell_size + max(0.0, board_width - 1.0) * cell_gap,
		board_height * cell_size + max(0.0, board_height - 1.0) * cell_gap
	)

func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, board_pixel_size())
	draw_rect(outer, Color("#121821"), true)
	draw_rect(outer, Color("#4a5569"), false, 2.0)
	for y in range(board_height):
		for x in range(board_width):
			var cell_rect := Rect2(_cell_position(Vector2i(x, y)), Vector2(cell_size, cell_size))
			var tint := Color("#1e2734") if (x + y) % 2 == 0 else Color("#18212c")
			draw_rect(cell_rect, tint, true)
			draw_rect(cell_rect, Color(0.30, 0.34, 0.40, 0.75), false, 1.0)

func _input(event: InputEvent) -> void:
	if _main_run_finished():
		return
	if _guide_open_during_game:
		return
	if _busy or not _interactive_enabled:
		return
	if _drag_origin_cell.x < 0:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var center := _cell_position(_drag_origin_cell) + Vector2(cell_size * 0.5, cell_size * 0.5)
		var delta := get_local_mouse_position() - center
		if delta.length() < cell_size * 0.34:
			return
		var direction := _drag_direction(delta)
		if direction == Vector2i.ZERO:
			return
		var target := _drag_origin_cell + direction
		if _model.is_inside(target):
			call_deferred("_deferred_swap", _drag_origin_cell, target)
			_drag_origin_cell = Vector2i(-1, -1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_origin_cell = Vector2i(-1, -1)

func _process(delta: float) -> void:
	_hard_drop_cooldown = max(0.0, _hard_drop_cooldown - delta)
	if _main_run_finished():
		_reset_continuous_input_state()
		return
	if _guide_open_during_game:
		_reset_continuous_input_state()
		return
	if not _game_started or _busy or _hard_drop_locked or not _interactive_enabled:
		_reset_continuous_input_state()
		return
	_handle_continuous_controls(delta)
	if _active_cells.is_empty():
		_spawn_falling_piece()
		return
	_fall_accumulator += delta
	var interval := _soft_drop_interval if _is_soft_drop_pressed() else _fall_interval
	if _fall_accumulator >= interval:
		_fall_accumulator = 0.0
		_step_falling_piece()

func _unhandled_input(event: InputEvent) -> void:
	if _main_run_finished():
		return
	if _event_key_pressed(event, [KEY_H]):
		_toggle_runtime_guide()
		get_viewport().set_input_as_handled()
		return
	if _guide_open_during_game:
		get_viewport().set_input_as_handled()
		return
	if _busy or _hard_drop_locked or not _interactive_enabled or _active_cells.is_empty():
		return
	# Falling-block controls:
	# Left/Right or A/D: continuous horizontal movement while held.
	# Up or W: continuous clockwise rotation while held.
	# Down or S: soft-drop / speed up while held.
	# Space/Enter: guided drop over one second.
	# Movement and rotation are handled in _process() so held keys repeat smoothly.
	if event.is_action_pressed("ui_down") or _event_key_pressed(event, [KEY_S]):
		_step_falling_piece()
		_fall_accumulator = 0.0
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if event is InputEventKey and (event as InputEventKey).echo:
			return
		if _hard_drop_cooldown > 0.0 or _hard_drop_locked or _busy:
			return
		# Lock immediately before the deferred call. This prevents repeated Space/Enter
		# presses in the same frame from scheduling multiple drop sequences for one piece,
		# which was the source of visual ghost/floating-piece artifacts.
		_hard_drop_locked = true
		call_deferred("_hard_drop_active_piece")
		_reset_continuous_input_state()
		get_viewport().set_input_as_handled()

func _handle_continuous_controls(delta: float) -> void:
	if _active_cells.is_empty():
		_reset_continuous_input_state()
		return
	var dir := _held_horizontal_direction()
	if dir == 0:
		_held_move_dir = 0
		_move_hold_elapsed = 0.0
		_move_repeat_elapsed = 0.0
	elif dir != _held_move_dir:
		_held_move_dir = dir
		_move_hold_elapsed = 0.0
		_move_repeat_elapsed = 0.0
		_move_active_piece(Vector2i(dir, 0))
	else:
		_move_hold_elapsed += delta
		if _move_hold_elapsed >= _move_repeat_delay:
			_move_repeat_elapsed += delta
			while _move_repeat_elapsed >= _move_repeat_interval:
				_move_repeat_elapsed -= _move_repeat_interval
				_move_active_piece(Vector2i(dir, 0))

	var rotate_pressed := _is_rotate_pressed()
	if not rotate_pressed:
		_rotate_held = false
		_rotate_hold_elapsed = 0.0
		_rotate_repeat_elapsed = 0.0
	elif not _rotate_held:
		_rotate_held = true
		_rotate_hold_elapsed = 0.0
		_rotate_repeat_elapsed = 0.0
		_rotate_active_piece(true)
	else:
		_rotate_hold_elapsed += delta
		if _rotate_hold_elapsed >= _rotate_repeat_delay:
			_rotate_repeat_elapsed += delta
			while _rotate_repeat_elapsed >= _rotate_repeat_interval:
				_rotate_repeat_elapsed -= _rotate_repeat_interval
				_rotate_active_piece(true)

func _held_horizontal_direction() -> int:
	var left_pressed := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var right_pressed := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	if left_pressed and not right_pressed:
		return -1
	if right_pressed and not left_pressed:
		return 1
	return 0

func _is_rotate_pressed() -> bool:
	return Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W)

func _reset_continuous_input_state() -> void:
	_held_move_dir = 0
	_move_hold_elapsed = 0.0
	_move_repeat_elapsed = 0.0
	_rotate_held = false
	_rotate_hold_elapsed = 0.0
	_rotate_repeat_elapsed = 0.0

func _event_key_pressed(event: InputEvent, keys: Array) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return keys.has(key_event.keycode) or keys.has(key_event.physical_keycode)

func _is_soft_drop_pressed() -> bool:
	return Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)


func _deferred_swap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if _busy:
		return
	await _attempt_swap(from_cell, to_cell)

func _ensure_runtime() -> void:
	if _piece_layer == null:
		_piece_layer = Control.new()
		_piece_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_piece_layer.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_piece_layer)
	if _fx_layer == null:
		_fx_layer = Control.new()
		_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_fx_layer)
	if _start_overlay == null:
		_create_start_overlay()
	if _detector == null:
		_detector = MatchDetectorScript.new()
	if _mapper == null:
		_mapper = PuzzleToUnitMapperScript.new()
	if _model == null:
		_model = PuzzleBoardModelScript.new()
	if _model.board_width != board_width or _model.board_height != board_height or _model.piece_type_count != PuzzleToUnitMapper.PIECE_KEYS.size():
		_model.configure(board_width, board_height, PuzzleToUnitMapper.PIECE_KEYS.size())
	custom_minimum_size = board_pixel_size()
	size = board_pixel_size()
	_update_start_overlay_layout()

func _create_start_overlay() -> void:
	_start_overlay = Control.new()
	_start_overlay.name = "MatchBoardStartOverlay"
	_start_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_start_overlay.position = Vector2.ZERO
	_start_overlay.size = board_pixel_size()
	_start_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_overlay.z_index = 500
	_start_overlay.clip_contents = true
	add_child(_start_overlay)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.03, 0.05, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_start_overlay.add_child(dim)
	_start_button = Button.new()
	_start_button.name = "ClickToStartButton"
	_start_button.text = "<Click to Start>"
	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.custom_minimum_size = Vector2(210, 54)
	_start_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_button.pressed.connect(_on_click_to_start_pressed)
	_start_overlay.add_child(_start_button)
	_create_match_board_guide()
	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.text = "3"
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_label.add_theme_font_size_override("font_size", 82)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35, 1.0))
	_countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 1.0))
	_countdown_label.add_theme_constant_override("outline_size", 8)
	_start_overlay.add_child(_countdown_label)
	_start_overlay.visible = false

func _create_match_board_guide() -> void:
	_guide_panel = Panel.new()
	_guide_panel.name = "MatchBoardGuide"
	_guide_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_guide_panel.clip_contents = true
	_guide_panel.z_index = 510
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.045, 0.060, 0.98)
	panel_style.border_color = Color(0.78, 0.84, 0.92, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 8
	_guide_panel.add_theme_stylebox_override("panel", panel_style)
	_start_overlay.add_child(_guide_panel)

	var title := Label.new()
	title.name = "GuideTitle"
	title.text = "MATCH BOARD GUIDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	_guide_panel.add_child(title)

	var text := Label.new()
	text.name = "GuideText"
	text.text = "Move: Left / Right or A / D\nRotate: Up or W\nFast drop: Down or S\nSlow drop: Space / Enter\nSwap: drag / click adjacent blocks\nSpecial blocks: click to blast\n\nSummon ladder: 3=Skeleton, 4=Archer, 5=Bomber\nSpecial shapes: L=Slime, T=Shaman, Cross=Ogre\nPriority: Cross > T > L > 5 > 4 > 3\n\nPress Close to start. During play, press H to show / hide this guide."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.94, 0.95, 0.98, 1.0))
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	text.add_theme_constant_override("outline_size", 2)
	_guide_panel.add_child(text)

	var hint := Label.new()
	hint.name = "GuideHint"
	hint.text = "Hint: this is a game mix of Tetris & Candy Crush."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1.0, 0.12, 0.10, 1.0))
	hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	hint.add_theme_constant_override("outline_size", 4)
	_guide_panel.add_child(hint)

	_guide_close_button = Button.new()
	_guide_close_button.name = "CloseGuideButton"
	_guide_close_button.text = "Close"
	_guide_close_button.focus_mode = Control.FOCUS_NONE
	_guide_close_button.custom_minimum_size = Vector2(130.0, 34.0)
	_guide_close_button.add_theme_font_size_override("font_size", 18)
	_guide_close_button.pressed.connect(_on_guide_close_pressed)
	_guide_panel.add_child(_guide_close_button)

func _update_start_overlay_layout() -> void:
	if _start_overlay == null:
		return
	var board_size: Vector2 = board_pixel_size()
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		board_size = Vector2(390.0, 494.0)
	_start_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_start_overlay.position = Vector2.ZERO
	_start_overlay.size = board_size
	_start_overlay.z_index = 500
	_start_overlay.clip_contents = true
	if _start_button != null:
		_start_button.visible = false
		_start_button.disabled = true
	if _guide_panel != null:
		var pad := 14.0
		var max_w := maxf(220.0, board_size.x - pad * 2.0)
		var max_h := maxf(280.0, board_size.y - pad * 2.0)
		var guide_w := minf(350.0, max_w)
		var guide_h := minf(430.0, max_h)
		_guide_panel.custom_minimum_size = Vector2.ZERO
		_guide_panel.size = Vector2(guide_w, guide_h)
		_guide_panel.position = Vector2(
			floor((board_size.x - guide_w) * 0.5),
			floor((board_size.y - guide_h) * 0.5)
		)
		_guide_panel.z_index = 510
		var inner_pad := 14.0
		var title_h := 34.0
		var button_w := minf(130.0, guide_w - inner_pad * 2.0)
		var button_h := 34.0
		var button_y: float = guide_h - inner_pad - button_h
		var hint_h: float = 42.0
		var hint_y: float = button_y - hint_h - 8.0
		var title_label := _guide_panel.get_node_or_null("GuideTitle") as Label
		if title_label != null:
			title_label.position = Vector2(inner_pad, 8.0)
			title_label.size = Vector2(guide_w - inner_pad * 2.0, title_h)
		var body_label := _guide_panel.get_node_or_null("GuideText") as Label
		if body_label != null:
			body_label.position = Vector2(inner_pad, 48.0)
			body_label.size = Vector2(guide_w - inner_pad * 2.0, maxf(60.0, hint_y - 54.0))
		var hint_label := _guide_panel.get_node_or_null("GuideHint") as Label
		if hint_label != null:
			hint_label.position = Vector2(inner_pad, hint_y)
			hint_label.size = Vector2(guide_w - inner_pad * 2.0, hint_h)
			hint_label.z_index = 511
		if _guide_close_button != null:
			_guide_close_button.position = Vector2(floor((guide_w - button_w) * 0.5), button_y)
			_guide_close_button.size = Vector2(button_w, button_h)
			_guide_close_button.z_index = 512
	if _countdown_label != null:
		_countdown_label.size = board_size
		_countdown_label.position = Vector2.ZERO
		_countdown_label.z_index = 520

func _show_start_overlay() -> void:
	_guide_open_during_game = false
	_update_start_overlay_layout()
	if _start_overlay != null:
		_start_overlay.visible = true
		_start_overlay.move_to_front()
	if _guide_panel != null:
		_guide_panel.visible = true
		_guide_panel.move_to_front()
	if _guide_close_button != null:
		_guide_close_button.disabled = false
	if _countdown_label != null:
		_countdown_label.visible = false
	if _piece_layer != null:
		_piece_layer.modulate = Color(0.42, 0.42, 0.46, 0.50)

func _hide_start_overlay() -> void:
	_guide_open_during_game = false
	if _start_overlay != null:
		_start_overlay.visible = false
	if _piece_layer != null:
		_piece_layer.modulate = Color.WHITE

func _start_countdown_without_guide() -> void:
	if _countdown_running or _game_started:
		return
	_guide_open_during_game = false
	_update_start_overlay_layout()
	if _start_overlay != null:
		_start_overlay.visible = true
		_start_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		_start_overlay.move_to_front()
	if _guide_panel != null:
		_guide_panel.visible = false
	if _guide_close_button != null:
		_guide_close_button.disabled = true
	if _countdown_label != null:
		_countdown_label.visible = true
	if _piece_layer != null:
		_piece_layer.modulate = Color(0.42, 0.42, 0.46, 0.50)
	_countdown_running = true
	call_deferred("_run_start_countdown")

func _on_click_to_start_pressed() -> void:
	_on_guide_close_pressed()

func _on_guide_close_pressed() -> void:
	if _countdown_running:
		return
	if _game_started:
		_hide_runtime_guide()
		return
	_match_board_guide_seen_this_session = true
	_start_countdown_without_guide()

func _toggle_runtime_guide() -> void:
	if not _game_started or _countdown_running:
		return
	if _guide_open_during_game:
		_hide_runtime_guide()
	else:
		_show_runtime_guide()

func _show_runtime_guide() -> void:
	_update_start_overlay_layout()
	_guide_open_during_game = true
	_reset_continuous_input_state()
	if _start_overlay != null:
		_start_overlay.visible = true
		_start_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		_start_overlay.move_to_front()
	if _guide_panel != null:
		_guide_panel.visible = true
		_guide_panel.move_to_front()
	if _guide_close_button != null:
		_guide_close_button.disabled = false
	if _countdown_label != null:
		_countdown_label.visible = false
	if _piece_layer != null:
		_piece_layer.modulate = Color(0.42, 0.42, 0.46, 0.50)

func _hide_runtime_guide() -> void:
	_guide_open_during_game = false
	if _guide_panel != null:
		_guide_panel.visible = false
	if _countdown_label != null:
		_countdown_label.visible = false
	if _start_overlay != null:
		_start_overlay.visible = false
	if _piece_layer != null:
		_piece_layer.modulate = Color.WHITE
	_reset_continuous_input_state()

func _run_start_countdown() -> void:
	if _game_started:
		_countdown_running = false
		return
	if _start_overlay != null:
		_start_overlay.visible = true
		_start_overlay.move_to_front()
	if _guide_panel != null:
		_guide_panel.visible = false
	if _countdown_label != null:
		_countdown_label.visible = true
	if _piece_layer != null:
		_piece_layer.modulate = Color(0.42, 0.42, 0.46, 0.50)
	var steps: Array[String] = ["3", "2", "1", "GO!"]
	for i in range(steps.size()):
		if _countdown_label != null:
			_countdown_label.text = steps[i]
			_countdown_label.scale = Vector2(1.35, 1.35)
			_countdown_label.modulate = Color(1, 1, 1, 1)
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(_countdown_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(_countdown_label, "modulate", Color(1, 1, 1, 0.88), 0.28)
		_play_sfx("race_countdown_go" if steps[i] == "GO!" else "race_countdown_beep")
		await get_tree().create_timer(0.65 if steps[i] == "GO!" else 1.0).timeout
	_game_started = true
	_countdown_running = false
	_hide_start_overlay()
	matchboard_started.emit()
	if _active_cells.is_empty():
		_spawn_falling_piece()

func _clear_piece_nodes() -> void:
	_pieces.clear()
	grid.clear()
	if _piece_layer != null:
		for child in _piece_layer.get_children():
			child.queue_free()
	if _fx_layer != null:
		for child in _fx_layer.get_children():
			child.queue_free()

func _sync_grid_cache() -> void:
	grid = _model.to_type_grid()

func _create_piece(piece_type: int, cell: Vector2i, animate_in: bool, source_row := -1) -> PuzzlePiece:
	var piece := PuzzlePieceScene.instantiate() as PuzzlePiece
	_piece_layer.add_child(piece)
	var base_type := _base_piece_type(piece_type)
	var texture := _load_piece_texture(base_type)
	piece.grid_position = cell
	piece.configure(piece_type, _mapper.piece_key(base_type), texture, _mapper.piece_label(base_type), _mapper.piece_color(base_type), Vector2(cell_size, cell_size))
	if piece_type >= 100:
		piece.play_special_pulse()
	piece.pressed.connect(_on_piece_pressed)
	piece.entered.connect(_on_piece_entered)
	piece.exited.connect(_on_piece_exited)
	var start_position := _cell_position(cell)
	if animate_in:
		start_position.y = _cell_position(Vector2i(cell.x, source_row)).y
	piece.position = start_position
	if animate_in:
		piece.set_board_position(_cell_position(cell), true, 0.18)
	_register_piece(cell, piece)
	return piece

func _register_piece(cell: Vector2i, piece: PuzzlePiece) -> void:
	_pieces[_cell_key(cell)] = piece

func _piece_at(cell: Vector2i) -> PuzzlePiece:
	return _pieces.get(_cell_key(cell), null)

func _move_piece_registration(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var key_from := _cell_key(from_cell)
	var piece: PuzzlePiece = _pieces.get(key_from, null)
	_pieces.erase(key_from)
	if piece != null:
		_pieces[_cell_key(to_cell)] = piece

func _remove_piece_registration(cell: Vector2i) -> PuzzlePiece:
	var key := _cell_key(cell)
	var piece: PuzzlePiece = _pieces.get(key, null)
	_pieces.erase(key)
	return piece

func _on_piece_pressed(piece: PuzzlePiece) -> void:
	if _busy or not _interactive_enabled or piece == null:
		return
	var cell: Vector2i = piece.grid_position
	if piece.piece_type >= 100 and not _cell_in_active(cell):
		await _activate_special_piece(cell)
		return
	_drag_origin_cell = cell
	preview_unit_requested.emit(_mapper.preview_unit_for_piece(piece.piece_type))
	if _selected_cell == cell:
		_set_selected_cell(Vector2i(-1, -1))
		return
	if _selected_cell.x >= 0 and _are_adjacent(_selected_cell, cell):
		await _attempt_swap(_selected_cell, cell)
		return
	_set_selected_cell(cell)

func _on_piece_entered(piece: PuzzlePiece) -> void:
	if piece == null or not _interactive_enabled:
		return
	preview_unit_requested.emit(_mapper.preview_unit_for_piece(piece.piece_type))

func _on_piece_exited(_piece: PuzzlePiece) -> void:
	pass


func _activate_special_piece(cell: Vector2i) -> void:
	if _busy or not _interactive_enabled or not _model.is_inside(cell):
		return
	var value := int(_model.get_type(cell))
	if value < 100:
		return
	_busy = true
	_set_selected_cell(Vector2i(-1, -1))
	_drag_origin_cell = Vector2i(-1, -1)
	var removed_lookup := {}
	var removed_cells: Array = []
	var targets: Array = [cell]
	targets.append_array(_special_cells_for(cell))
	for target: Vector2i in targets:
		if not _model.is_inside(target):
			continue
		if _cell_in_active(target):
			continue
		if int(_model.get_type(target)) < 0:
			continue
		var key := _cell_key(target)
		if removed_lookup.has(key):
			continue
		removed_lookup[key] = true
		removed_cells.append(target)
	var removed_pieces: Array = []
	for target: Vector2i in removed_cells:
		var piece := _remove_piece_registration(target)
		if piece != null:
			removed_pieces.append(piece)
			_show_cell_pop_fx(target, _mapper.piece_color(_base_piece_type(piece.piece_type)))
			piece.play_clear_animation()
	_model.clear_cells(removed_cells)
	_sync_grid_cache()
	_show_match_popup("SPECIAL BLAST!", Color("#fff07a"))
	_play_sfx("special_clear", 1.0)
	await get_tree().create_timer(0.20).timeout
	for piece in removed_pieces:
		if piece != null and is_instance_valid(piece):
			piece.queue_free()
	_award_clear_summons(removed_cells)
	await _collapse_columns()
	await _clear_full_rows()
	var matches := _detector.find_matches(_model.to_type_grid())
	if not matches.is_empty():
		await _resolve_matches(matches)
	if _active_cells.is_empty() and _should_reset_stuck_board():
		await _restart_empty_board("NEW BOARD")
	_busy = false

func _attempt_swap(cell_a: Vector2i, cell_b: Vector2i) -> void:
	if _busy or not _interactive_enabled or not _model.is_inside(cell_a) or not _model.is_inside(cell_b) or not _are_adjacent(cell_a, cell_b):
		return
	if _cell_in_active(cell_a) or _cell_in_active(cell_b):
		return
	if _model.get_type(cell_a) < 0 or _model.get_type(cell_b) < 0:
		return
	_busy = true
	_set_selected_cell(Vector2i(-1, -1))
	_play_sfx("piece_swap")
	_swap_cells(cell_a, cell_b, true)
	var matches := _detector.find_matches(_model.to_type_grid())
	if matches.is_empty():
		await get_tree().create_timer(0.15).timeout
		_swap_cells(cell_a, cell_b, true)
		_play_sfx("piece_invalid", 0.96)
		var piece_a := _piece_at(cell_a)
		var piece_b := _piece_at(cell_b)
		if piece_a != null:
			piece_a.play_invalid_bump()
		if piece_b != null:
			piece_b.play_invalid_bump()
		_busy = false
		return
	await _resolve_matches(matches)
	_busy = false

func _resolve_matches(initial_matches: Array) -> void:
	var combo_count := 0
	var matches := initial_matches
	while not matches.is_empty():
		combo_count += 1
		var boosters_to_create: Array = []
		for match_data in matches:
			var shape := str(match_data["shape"])
			var result := _mapper.resolve_match(int(match_data["piece_type"]), shape, combo_count)
			if int(result["reward_ink"]) > 0 or int(result["reward_gold"]) > 0:
				var luck_bonus := _puzzle_luck_bonus(combo_count, str(result["match_label"]))
				reward_requested.emit(int(result["reward_ink"]) + luck_bonus, int(result["reward_gold"]), combo_count, str(result["match_label"]))
			_show_match_popup(str(result["match_label"]), _popup_color_for_shape(shape))
			_play_sfx(str(result["sfx_name"]))
			var booster := _booster_from_match(match_data, combo_count)
			if not booster.is_empty():
				boosters_to_create.append(booster)
		# Screen shake removed by request; keep all other positive feedback.
		var cleared_cells: Array = await _clear_match_groups(matches, boosters_to_create)
		_award_clear_summons(cleared_cells)
		if combo_count >= 2 or _rapid_chain >= 2:
			# Combo still affects hidden scoring/bonus logic, but no combo text is shown.
			_play_sfx("combo_chain", 1.0 + min(0.35, float(max(combo_count, _rapid_chain)) * 0.04))
		await _collapse_columns()
		await _clear_full_rows()
		_sync_grid_cache()
		matches = _detector.find_matches(_model.to_type_grid())
	# Hybrid safety: after match resolution and gravity, never leave a frozen board
	# with no possible Match-3 swap. Restart empty so the next falling piece can begin.
	if _active_cells.is_empty() and _should_reset_stuck_board():
		await _restart_empty_board("NEW BOARD")

func _clear_match_groups(matches: Array, boosters_to_create: Array = []) -> Array:
	var cleared := {}
	var protected_cells := {}
	for booster in boosters_to_create:
		protected_cells[_cell_key(booster["cell"])] = booster
	var removed_pieces: Array = []
	var removed_cells: Array = []
	for match_data in matches:
		var expanded_cells: Array = []
		for cell: Vector2i in match_data["cells"]:
			expanded_cells.append(cell)
			expanded_cells.append_array(_special_cells_for(cell))
		for cell: Vector2i in expanded_cells:
			var key := _cell_key(cell)
			if cleared.has(key) or protected_cells.has(key):
				continue
			cleared[key] = true
			removed_cells.append(cell)
			var piece := _remove_piece_registration(cell)
			if piece == null:
				continue
			removed_pieces.append(piece)
			_show_cell_pop_fx(cell, _mapper.piece_color(_base_piece_type(piece.piece_type)))
			piece.play_clear_animation()
	_model.clear_cells(removed_cells)
	for booster in boosters_to_create:
		var cell: Vector2i = booster["cell"]
		var value: int = int(booster["value"])
		_model.set_type(cell, value)
		var old_piece := _piece_at(cell)
		if old_piece != null:
			old_piece.queue_free()
			_pieces.erase(_cell_key(cell))
		_create_piece(value, cell, false)
		_show_match_popup(str(booster["label"]), Color("#ffef8a"))
		_play_sfx("booster_create")
	await get_tree().create_timer(0.19).timeout
	for piece in removed_pieces:
		if piece != null and is_instance_valid(piece):
			piece.queue_free()
	return removed_cells

func _collapse_columns() -> void:
	# Falling-block hybrid gravity: after Match-3/line clears, only the blocks that
	# were already locked on the board fall downward. The currently falling piece
	# is not pulled down by Match-3 gravity; it keeps using its own timer/controls.
	var active_lookup := {}
	for active_cell: Vector2i in _active_cells:
		active_lookup[_cell_key(active_cell)] = true
	var moves: Array = []
	for x in range(board_width):
		var locked_items: Array = []
		for y in range(board_height - 1, -1, -1):
			var from_cell := Vector2i(x, y)
			if active_lookup.has(_cell_key(from_cell)):
				continue
			var piece_type := int(_model.get_type(from_cell))
			if piece_type < 0:
				continue
			locked_items.append({"from": from_cell, "piece_type": piece_type})
		var write_y := board_height - 1
		for item in locked_items:
			while write_y >= 0 and active_lookup.has(_cell_key(Vector2i(x, write_y))):
				write_y -= 1
			if write_y < 0:
				break
			var from_cell: Vector2i = item["from"]
			var to_cell := Vector2i(x, write_y)
			var piece_type := int(item["piece_type"])
			if from_cell != to_cell:
				_model.set_type(from_cell, -1)
				_model.set_type(to_cell, piece_type)
				moves.append({"from": from_cell, "to": to_cell, "piece_type": piece_type})
			else:
				_model.set_type(to_cell, piece_type)
			write_y -= 1
		while write_y >= 0:
			var clear_cell := Vector2i(x, write_y)
			if not active_lookup.has(_cell_key(clear_cell)):
				_model.set_type(clear_cell, -1)
			write_y -= 1
	for move_data in moves:
		var from_cell: Vector2i = move_data["from"]
		var to_cell: Vector2i = move_data["to"]
		var piece := _piece_at(from_cell)
		if piece == null:
			continue
		_move_piece_registration(from_cell, to_cell)
		piece.grid_position = to_cell
		piece.set_board_position(_cell_position(to_cell), true, 0.14)
	if not moves.is_empty():
		await get_tree().create_timer(0.16).timeout
	_sync_grid_cache()

func _refill_columns() -> void:
	# Disabled in falling-block mode: new tiles arrive as falling pieces from the top.
	return

func _swap_cells(cell_a: Vector2i, cell_b: Vector2i, animate: bool) -> void:
	_model.swap_cells(cell_a, cell_b)
	_sync_grid_cache()
	var piece_a := _piece_at(cell_a)
	var piece_b := _piece_at(cell_b)
	if piece_a != null:
		_pieces.erase(_cell_key(cell_a))
	if piece_b != null:
		_pieces.erase(_cell_key(cell_b))
	if piece_a != null:
		piece_a.grid_position = cell_b
		_pieces[_cell_key(cell_b)] = piece_a
		piece_a.set_board_position(_cell_position(cell_b), animate, 0.12)
		piece_a.play_swap_pop()
	if piece_b != null:
		piece_b.grid_position = cell_a
		_pieces[_cell_key(cell_a)] = piece_b
		piece_b.set_board_position(_cell_position(cell_a), animate, 0.12)
		piece_b.play_swap_pop()

func _set_selected_cell(cell: Vector2i) -> void:
	if _selected_cell.x >= 0 and _model.is_inside(_selected_cell):
		var previous := _piece_at(_selected_cell)
		if previous != null:
			previous.set_selected(false)
	_selected_cell = cell
	if _selected_cell.x >= 0 and _model.is_inside(_selected_cell):
		var current := _piece_at(_selected_cell)
		if current != null:
			current.set_selected(true)

func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * (cell_size + cell_gap), cell.y * (cell_size + cell_gap))

func _puzzle_luck_bonus(combo_count: int, label: String) -> int:
	if main == null or not main.has_method("puzzle_luck_reward_bonus"):
		return 0
	return max(0, int(main.puzzle_luck_reward_bonus(combo_count, label)))

func _show_match_popup(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(board_pixel_size().x * 0.5 - 36.0, board_pixel_size().y * 0.5 - 20.0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#0a0e15"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 22.0, 1.05)
	tween.tween_property(label, "modulate:a", 0.0, 1.05)
	tween.finished.connect(label.queue_free)

func _shake_board(_amount: float, _duration: float) -> void:
	# Disabled: the player requested no shaking feedback.
	if _piece_layer != null:
		_piece_layer.position = Vector2.ZERO

func _popup_color_for_shape(shape: String) -> Color:
	match shape:
		"cross":
			return Color("#ffcf7d")
		"t":
			return Color("#d6a4ff")
		"l":
			return Color("#ff9f7f")
		"five":
			return Color("#ffe67d")
		"four":
			return Color("#8bddff")
		_:
			return Color("#d9f0ff")

func _booster_from_match(match_data: Dictionary, combo_count: int) -> Dictionary:
	var shape := str(match_data["shape"])
	var cells: Array = match_data["cells"]
	if cells.is_empty():
		return {}
	var make_booster := shape in ["four", "five", "cross", "t", "l"] or combo_count >= 2 or _rapid_chain >= 2
	if not make_booster:
		return {}
	var cell: Vector2i = cells[int(cells.size() / 2)]
	var base := _base_piece_type(int(match_data["piece_type"]))
	var value := 100 + base
	var label := "ROW BLASTER"
	if shape == "five" or combo_count >= 4:
		value = 400 + base
		label = "CROSS BLASTER"
	elif shape in ["cross", "t", "l"]:
		value = 300 + base
		label = "BOMB TILE"
	elif _is_vertical_match(cells):
		value = 200 + base
		label = "COLUMN BLASTER"
	elif combo_count >= 2 or _rapid_chain >= 2:
		value = (200 if randi() % 2 == 0 else 100) + base
		label = "COMBO BOOSTER"
	return {"cell": cell, "value": value, "label": label}

func _special_cells_for(cell: Vector2i) -> Array:
	var result: Array = []
	var value := _model.get_type(cell)
	if value < 100:
		return result
	_play_sfx("booster_blast")
	if value >= 400:
		_show_cross_fx(cell)
		for x in range(board_width):
			result.append(Vector2i(x, cell.y))
		for y in range(board_height):
			result.append(Vector2i(cell.x, y))
	elif value >= 300:
		_show_bomb_fx(cell)
		for y in range(cell.y - 1, cell.y + 2):
			for x in range(cell.x - 1, cell.x + 2):
				var c := Vector2i(x, y)
				if _model.is_inside(c):
					result.append(c)
	elif value >= 200:
		_show_line_fx(cell, true)
		for y in range(board_height):
			result.append(Vector2i(cell.x, y))
	else:
		_show_line_fx(cell, false)
		for x in range(board_width):
			result.append(Vector2i(x, cell.y))
	return result

func _show_line_fx(cell: Vector2i, vertical: bool) -> void:
	if _fx_layer == null:
		return
	var rect := ColorRect.new()
	rect.color = Color(0.65, 0.95, 1.0, 0.70)
	if vertical:
		rect.position = Vector2(_cell_position(cell).x + cell_size * 0.42, 0)
		rect.size = Vector2(cell_size * 0.16, board_pixel_size().y)
	else:
		rect.position = Vector2(0, _cell_position(cell).y + cell_size * 0.42)
		rect.size = Vector2(board_pixel_size().x, cell_size * 0.16)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(rect)
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.28)
	tween.finished.connect(rect.queue_free)

func _show_cross_fx(cell: Vector2i) -> void:
	_show_line_fx(cell, true)
	_show_line_fx(cell, false)
	_show_match_popup("CROSS BLAST!", Color("#fff07a"))

func _show_bomb_fx(cell: Vector2i) -> void:
	if _fx_layer == null:
		return
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.62, 0.20, 0.55)
	rect.position = _cell_position(cell) - Vector2(cell_size, cell_size)
	rect.size = Vector2(cell_size * 3.0 + cell_gap * 2.0, cell_size * 3.0 + cell_gap * 2.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(rect)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(rect, "scale", Vector2(1.25, 1.25), 0.25)
	tween.tween_property(rect, "modulate:a", 0.0, 0.25)
	tween.finished.connect(rect.queue_free)
	_show_match_popup("BOOM!", Color("#ffbe6b"))

func _spawn_falling_piece() -> void:
	if _busy or not _game_started or _countdown_running:
		return
	_active_cells.clear()
	var shape: Array = _random_falling_shape()
	var cells_to_add: Array = _pick_random_spawn_cells_for_shape(shape)
	if cells_to_add.is_empty():
		# Only clear the board when the stack has reached the top AND no Match-3 swap exists.
		# Otherwise keep the board and ask the player to swap.
		if _should_reset_stuck_board():
			await _restart_empty_board("TOP OUT")
		else:
			board_message_requested.emit("Top blocked: use Match-3 swaps!", false)
			return
		cells_to_add = _pick_random_spawn_cells_for_shape(shape)
		if cells_to_add.is_empty():
			return
	for cell: Vector2i in cells_to_add:
		var type_value: int = randi() % PuzzleToUnitMapper.PIECE_KEYS.size()
		_model.set_type(cell, type_value)
		var piece := _create_piece(type_value, cell, true, -2)
		piece.play_swap_pop()
	_active_cells = cells_to_add.duplicate()
	_fall_accumulator = 0.0
	_play_sfx("piece_drop")

func _pick_random_spawn_cells_for_shape(shape: Array) -> Array:
	var spawn_candidates: Array = _spawn_candidates_for_shape(shape)
	spawn_candidates.shuffle()
	for candidate_x: int in spawn_candidates:
		var candidate_cells: Array = _build_shape_cells(shape, candidate_x)
		if _can_place_cells(candidate_cells, []):
			return candidate_cells
	return []

func _spawn_candidates_for_shape(shape: Array) -> Array:
	var min_offset_x: int = 99999
	var max_offset_x: int = -99999
	for offset: Vector2i in shape:
		if offset.x < min_offset_x:
			min_offset_x = offset.x
		if offset.x > max_offset_x:
			max_offset_x = offset.x
	var min_spawn_x: int = -min_offset_x
	var max_spawn_x: int = board_width - 1 - max_offset_x
	var candidates: Array = []
	for candidate_x: int in range(min_spawn_x, max_spawn_x + 1):
		candidates.append(candidate_x)
	return candidates

func _build_shape_cells(shape: Array, spawn_x: int) -> Array:
	var result: Array = []
	for offset: Vector2i in shape:
		result.append(Vector2i(spawn_x + offset.x, offset.y))
	return result

func _random_falling_shape() -> Array:
	var shapes: Array = [
		[Vector2i(0, 0)],
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	]
	return shapes[randi() % shapes.size()].duplicate()

func _step_falling_piece() -> void:
	if _hard_drop_locked or _busy or _locking_piece:
		return
	if _move_active_piece(Vector2i.DOWN):
		return
	await _lock_active_piece()

func _hard_drop_active_piece() -> void:
	if _busy or _locking_piece or _active_cells.is_empty():
		_hard_drop_locked = false
		return
	_hard_drop_locked = true
	_hard_drop_cooldown = 0.22
	# Move through grid cells over a short fixed window. Do not allow another
	# input/process tick to move it until the lock/clear sequence has finished.
	var drop_distance := _fall_distance_for_active_piece()
	if drop_distance > 0:
		var step_duration := SPACE_DROP_DURATION / float(drop_distance)
		for _i in range(drop_distance):
			if not _move_active_piece(Vector2i.DOWN, step_duration * 0.92):
				break
			await get_tree().create_timer(step_duration).timeout
	await _lock_active_piece()
	_hard_drop_locked = false
	_reconcile_piece_nodes()

func _fall_distance_for_active_piece() -> int:
	var test_cells := _active_cells.duplicate()
	var distance := 0
	while true:
		var targets: Array = []
		for cell: Vector2i in test_cells:
			targets.append(cell + Vector2i.DOWN)
		if not _can_place_cells(targets, test_cells):
			return distance
		test_cells = targets
		distance += 1
	return distance

func _move_active_piece(delta: Vector2i, move_duration := 0.09) -> bool:
	if _active_cells.is_empty():
		return false
	var targets: Array = []
	for cell: Vector2i in _active_cells:
		targets.append(cell + delta)
	if not _can_place_cells(targets, _active_cells):
		return false
	_move_active_to(targets, true, move_duration)
	return true

func _rotate_active_piece(clockwise: bool = true) -> void:
	if _active_cells.size() <= 1:
		return
	var pivot: Vector2i = _active_cells[0]
	var rotated: Array = []
	for cell: Vector2i in _active_cells:
		var rel: Vector2i = cell - pivot
		if clockwise:
			rotated.append(pivot + Vector2i(-rel.y, rel.x))
		else:
			rotated.append(pivot + Vector2i(rel.y, -rel.x))
	# Soft wall-kick so rotation near the edge still feels responsive.
	for kick: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i(2, 0), Vector2i(-2, 0)]:
		var kicked: Array = []
		for cell: Vector2i in rotated:
			kicked.append(cell + kick)
		if _can_place_cells(kicked, _active_cells):
			_move_active_to(kicked, true)
			_play_sfx("piece_swap", 1.08)
			return
	_play_sfx("piece_invalid", 0.96)

func _can_place_cells(cells_to_check: Array, ignore_cells: Array) -> bool:
	var ignore := {}
	for cell: Vector2i in ignore_cells:
		ignore[_cell_key(cell)] = true
	for cell: Vector2i in cells_to_check:
		if not _model.is_inside(cell):
			return false
		if _model.get_type(cell) >= 0 and not ignore.has(_cell_key(cell)):
			return false
	return true

func _move_active_to(targets: Array, animate: bool, move_duration := 0.09) -> void:
	var old_cells := _active_cells.duplicate()
	var values: Array = []
	var pieces: Array = []
	for cell: Vector2i in old_cells:
		values.append(_model.get_type(cell))
		pieces.append(_remove_piece_registration(cell))
		_model.set_type(cell, -1)
	for i in range(targets.size()):
		var cell: Vector2i = targets[i]
		var piece_type := int(values[i])
		_model.set_type(cell, piece_type)
		var piece: PuzzlePiece = pieces[i]
		if piece != null:
			piece.grid_position = cell
			_register_piece(cell, piece)
			piece.set_board_position(_cell_position(cell), animate, move_duration)
	_active_cells = targets.duplicate()
	_sync_grid_cache()

func _lock_active_piece() -> void:
	if _active_cells.is_empty() or _busy or _locking_piece:
		_hard_drop_locked = false
		return
	_locking_piece = true
	var locked_cells: Array = _active_cells.duplicate()
	_active_cells.clear()
	_busy = true
	for cell: Vector2i in locked_cells:
		var piece := _piece_at(cell)
		if piece != null:
			piece.play_swap_pop()
	_play_sfx("piece_drop", 0.92)
	await get_tree().create_timer(0.08).timeout
	# Safety gravity: after an accelerated drop, settle every locked tile in its own column.
	# This prevents suspended clusters when Space/Enter is pressed repeatedly.
	await _collapse_columns()
	var cleared_rows: int = await _clear_full_rows()
	var matches := _detector.find_matches(_model.to_type_grid())
	if not matches.is_empty():
		await _resolve_matches(matches)
	# Locked falling blocks now stay on the board when they do not clear.
	# They accumulate at the bottom/top so the player can use mouse swaps for Match-3.
	if _should_reset_stuck_board():
		await _restart_empty_board("NEW BOARD")
	_reconcile_piece_nodes()
	_busy = false
	_locking_piece = false
	_hard_drop_locked = false
	if _game_started and not _countdown_running:
		_spawn_falling_piece()

func _clear_full_rows() -> int:
	var full_rows: Array = []
	for y in range(board_height):
		var full := true
		var first_base_type := -999
		for x in range(board_width):
			var cell_type := int(_model.get_type(Vector2i(x, y)))
			if cell_type < 0:
				full = false
				break
			var base_type := _base_piece_type(cell_type)
			if first_base_type == -999:
				first_base_type = base_type
			elif base_type != first_base_type:
				full = false
				break
		if full:
			full_rows.append(y)
	if full_rows.is_empty():
		return 0
	var removed_cells: Array = []
	for y: int in full_rows:
		for x in range(board_width):
			removed_cells.append(Vector2i(x, y))
	_award_clear_summons(removed_cells)
	reward_requested.emit(8 * full_rows.size(), 0, full_rows.size(), "ROW CLEAR")
	_show_match_popup("ROW CLEAR x%d" % full_rows.size(), Color("#fff07a"))
	_play_sfx("booster_blast", 1.0 + min(0.3, full_rows.size() * 0.08))
	for cell: Vector2i in removed_cells:
		var piece := _remove_piece_registration(cell)
		if piece != null:
			_show_cell_pop_fx(cell, _mapper.piece_color(_base_piece_type(piece.piece_type)))
			piece.play_clear_animation()
	_model.clear_cells(removed_cells)
	await get_tree().create_timer(0.18).timeout
	await _collapse_columns()
	return full_rows.size()

func _clear_locked_cells_as_empty(cells: Array) -> void:
	var removed_cells: Array = []
	for cell: Vector2i in cells:
		if not _model.is_inside(cell):
			continue
		if _model.get_type(cell) < 0:
			continue
		removed_cells.append(cell)
		var piece := _remove_piece_registration(cell)
		if piece != null:
			_show_cell_pop_fx(cell, _mapper.piece_color(_base_piece_type(piece.piece_type)))
			piece.play_clear_animation()
	if removed_cells.is_empty():
		return
	_model.clear_cells(removed_cells)
	_sync_grid_cache()
	_show_match_popup("EMPTY", Color("#b7f7ff"))
	_play_sfx("piece_invalid", 0.9)
	await get_tree().create_timer(0.16).timeout

func _locked_tile_count() -> int:
	var count := 0
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			if _model.get_type(cell) >= 0 and not _cell_in_active(cell):
				count += 1
	return count

func _should_reset_stuck_board() -> bool:
	# Reset is allowed ONLY when the falling-block stack has reached the top
	# and the locked board has no possible Match-3 swap. Sparse/no-move boards must keep accumulating.
	if _has_possible_move():
		return false
	return _is_stack_at_top() or _is_board_full()

func _is_stack_at_top() -> bool:
	for x in range(board_width):
		if _model.get_type(Vector2i(x, 0)) >= 0 and not _cell_in_active(Vector2i(x, 0)):
			return true
	# Also treat the standard spawn area as top-out, because taller pieces may fail before row 0 is fully occupied.
	var spawn_x := int(board_width / 2)
	for x in range(max(0, spawn_x - 2), min(board_width, spawn_x + 3)):
		for y in range(0, min(2, board_height)):
			var cell := Vector2i(x, y)
			if _model.get_type(cell) >= 0 and not _cell_in_active(cell):
				return true
	return false

func _has_locked_tiles() -> bool:
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			if _model.get_type(cell) >= 0 and not _cell_in_active(cell):
				return true
	return false

func _is_board_full() -> bool:
	for y in range(board_height):
		for x in range(board_width):
			if _model.get_type(Vector2i(x, y)) < 0:
				return false
	return true

func _restart_empty_board(message: String = "RESET") -> void:
	board_message_requested.emit("Board reset: stack reached the top with no Match-3 swap.", true)
	_show_match_popup(message, Color("#ffbe6b"))
	_play_sfx("booster_blast", 0.92)
	for piece in _pieces.values():
		if piece != null:
			piece.play_clear_animation()
	await get_tree().create_timer(0.18).timeout
	_model.clear()
	_clear_piece_nodes()
	_sync_grid_cache()
	queue_redraw()

func _reconcile_piece_nodes() -> void:
	# Defensive visual cleanup: rapid drop inputs can leave queued/tweening PuzzlePiece
	# nodes that are no longer registered in the board dictionary. Remove any such
	# orphan nodes and snap registered pieces back to their model cells.
	if _piece_layer == null:
		return
	var valid_ids := {}
	for key in _pieces.keys().duplicate():
		var piece: PuzzlePiece = _pieces.get(key, null)
		if piece == null or not is_instance_valid(piece):
			_pieces.erase(key)
			continue
		var cell := piece.grid_position
		if not _model.is_inside(cell) or _model.get_type(cell) < 0:
			_pieces.erase(key)
			piece.queue_free()
			continue
		valid_ids[piece.get_instance_id()] = true
		piece.position = _cell_position(cell)
		piece.modulate.a = 1.0
	for child in _piece_layer.get_children():
		if child is PuzzlePiece and not valid_ids.has(child.get_instance_id()):
			child.queue_free()

func _cell_in_active(cell: Vector2i) -> bool:
	for active_cell: Vector2i in _active_cells:
		if active_cell == cell:
			return true
	return false


func _has_possible_move() -> bool:
	var type_grid := _model.to_type_grid()
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var other: Vector2i = cell + direction
				if not _model.is_inside(other):
					continue
				if int(type_grid[cell.y][cell.x]) < 0 or int(type_grid[other.y][other.x]) < 0:
					continue
				if int(type_grid[cell.y][cell.x]) == int(type_grid[other.y][other.x]):
					continue
				var test_grid := _copy_grid(type_grid)
				var temp = test_grid[cell.y][cell.x]
				test_grid[cell.y][cell.x] = test_grid[other.y][other.x]
				test_grid[other.y][other.x] = temp
				if not _detector.find_matches(test_grid).is_empty():
					return true
	return false

func _copy_grid(source: Array) -> Array:
	var result: Array = []
	for row in source:
		result.append(row.duplicate())
	return result

func _reshuffle_until_playable() -> void:
	_busy = true
	for piece in _pieces.values():
		if piece != null:
			piece.play_shuffle_spin()
	await get_tree().create_timer(0.22).timeout
	_force_playable_board(true)
	await get_tree().create_timer(0.18).timeout
	_busy = false

func _force_playable_board(animate: bool) -> void:
	for _attempt in range(120):
		_model.generate_without_start_matches()
		_sync_grid_cache()
		if _has_possible_move():
			_refresh_all_piece_visuals(animate)
			return
	# Final safety: create an obvious playable board so the player never gets stuck.
	_model.generate_without_start_matches()
	if board_width >= 4 and board_height >= 3:
		_model.set_type(Vector2i(0, 0), 0)
		_model.set_type(Vector2i(1, 0), 0)
		_model.set_type(Vector2i(2, 0), 1)
		_model.set_type(Vector2i(2, 1), 0)
	_sync_grid_cache()
	_refresh_all_piece_visuals(animate)

func _refresh_all_piece_visuals(animate: bool) -> void:
	for y in range(board_height):
		for x in range(board_width):
			var cell := Vector2i(x, y)
			var piece := _piece_at(cell)
			var piece_type := _model.get_type(cell)
			if piece == null:
				_create_piece(piece_type, cell, animate)
				continue
			var base_type := _base_piece_type(piece_type)
			piece.configure(piece_type, _mapper.piece_key(base_type), _load_piece_texture(base_type), _mapper.piece_label(base_type), _mapper.piece_color(base_type), Vector2(cell_size, cell_size))
			piece.grid_position = cell
			piece.set_board_position(_cell_position(cell), animate, 0.16)
			if animate:
				piece.play_special_pulse()
	queue_redraw()

func _show_cell_pop_fx(cell: Vector2i, color: Color) -> void:
	if _fx_layer == null:
		return
	var center := _cell_position(cell) + Vector2(cell_size * 0.5, cell_size * 0.5)
	for i in range(5):
		var dot := ColorRect.new()
		dot.color = Color(color.r, color.g, color.b, 0.72)
		dot.size = Vector2(5, 5)
		dot.position = center - dot.size * 0.5
		dot.rotation = randf() * TAU
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx_layer.add_child(dot)
		var angle := randf() * TAU
		var distance := randf_range(cell_size * 0.18, cell_size * 0.45)
		var target := dot.position + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(dot, "position", target, 0.22)
		tween.tween_property(dot, "modulate:a", 0.0, 0.22)
		tween.tween_property(dot, "scale", Vector2.ONE * 1.6, 0.22)
		tween.finished.connect(dot.queue_free)

func _award_clear_summons(cleared_cells: Array) -> int:
	if cleared_cells.is_empty():
		return _special_clear_count
	var clear_count := _register_clear_counts()
	var summon_units: Array = [NORMAL_CLEAR_UNIT]
	if SPECIAL_CLEAR_REWARD_UNITS.has(clear_count):
		summon_units.append_array(SPECIAL_CLEAR_REWARD_UNITS[clear_count])
		_show_match_popup("SPECIAL CLEAR x%d" % clear_count, Color("#fff07a"))
	var line_info := _line_clear_info(cleared_cells)
	var row_count := int(line_info.get("rows", 0))
	var column_count := int(line_info.get("columns", 0))
	for _index in range(row_count):
		summon_units.append_array(ROW_CLEAR_REWARD_UNITS)
	for _index in range(column_count):
		summon_units.append_array(COLUMN_CLEAR_REWARD_UNITS)
	if row_count > 0:
		_show_match_popup("ROW BONUS x%d" % row_count, Color("#ffcf7d"))
	if column_count > 0:
		_show_match_popup("COLUMN BONUS x%d" % column_count, Color("#d6a4ff"))
	_emit_summon_units(summon_units)
	return clear_count

func _emit_summon_units(units: Array) -> void:
	var counts := {}
	var order: Array = []
	for unit in units:
		var unit_id := str(unit)
		if unit_id == "":
			continue
		if not counts.has(unit_id):
			counts[unit_id] = 0
			order.append(unit_id)
		counts[unit_id] = int(counts[unit_id]) + 1
	for unit_id in order:
		summon_requested.emit(str(unit_id), int(counts[unit_id]), 1)

func _line_clear_info(cleared_cells: Array) -> Dictionary:
	var seen := {}
	var row_counts := {}
	var column_counts := {}
	for cell: Vector2i in cleared_cells:
		if not _model.is_inside(cell):
			continue
		var key := _cell_key(cell)
		if seen.has(key):
			continue
		seen[key] = true
		row_counts[cell.y] = int(row_counts.get(cell.y, 0)) + 1
		column_counts[cell.x] = int(column_counts.get(cell.x, 0)) + 1
	var rows := 0
	for y in row_counts.keys():
		if int(row_counts[y]) >= board_width:
			rows += 1
	var columns := 0
	for x in column_counts.keys():
		if int(column_counts[x]) >= board_height:
			columns += 1
	return {"rows": rows, "columns": columns}

func _register_clear_counts() -> int:
	_special_clear_count += 1
	var now := Time.get_ticks_msec()
	if now - _last_clear_time_msec <= 2500:
		_rapid_chain += 1
	else:
		_rapid_chain = 1
	_last_clear_time_msec = now
	return _special_clear_count

func _is_vertical_match(cells: Array) -> bool:
	if cells.size() < 2:
		return false
	var first_x: int = cells[0].x
	for cell: Vector2i in cells:
		if cell.x != first_x:
			return false
	return true

func _base_piece_type(value: int) -> int:
	if value < 0:
		return value
	return value % 100

func _load_piece_texture(piece_type: int) -> Texture2D:
	var path := _mapper.texture_path(piece_type)
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null

func _play_sfx(id: String, pitch := 1.0) -> void:
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(id, pitch)

func _drag_direction(delta: Vector2) -> Vector2i:
	if abs(delta.x) > abs(delta.y):
		return Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT
	if abs(delta.y) > 0.0:
		return Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP
	return Vector2i.ZERO

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1
