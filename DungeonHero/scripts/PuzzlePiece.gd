extends Control
class_name PuzzlePiece

signal pressed(piece)
signal entered(piece)
signal exited(piece)

var piece_type := -1
var piece_key := ""
var grid_position := Vector2i.ZERO

var _accent := Color.WHITE
var _base_size := Vector2(40, 40)
var _selected := false
var _hovered := false

var _panel: Panel
var _icon: TextureRect
var _label: Label
var _special_pulse_tween: Tween
var _move_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_build_visuals()
	_apply_style()

func configure(type_value: int, key: String, texture: Texture2D, short_label: String, accent: Color, size_value: Vector2) -> void:
	piece_type = type_value
	piece_key = key
	_accent = accent
	_base_size = size_value
	custom_minimum_size = size_value
	size = size_value
	if _panel == null:
		_build_visuals()
	_icon.texture = texture
	_icon.visible = texture != null
	_label.text = _special_label(type_value)
	_label.visible = type_value >= 100
	if type_value >= 100:
		_start_special_glow()
	else:
		_stop_special_glow()
	_apply_style()
	queue_redraw()

func set_board_position(position_value: Vector2, animate := true, duration := 0.12) -> void:
	# Only one movement tween may own the position at a time. Rapid drop
	# inputs create many cell-to-cell moves in one frame; killing the previous
	# tween prevents delayed tweens from pulling pieces back upward and leaving
	# visual afterimages.
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
		_move_tween = null
	if animate and is_inside_tree():
		_move_tween = create_tween()
		_move_tween.set_trans(Tween.TRANS_QUAD)
		_move_tween.set_ease(Tween.EASE_OUT)
		_move_tween.tween_property(self, "position", position_value, duration)
	else:
		position = position_value

func set_selected(active: bool) -> void:
	_selected = active
	_apply_style()
	queue_redraw()

func set_hovered(active: bool) -> void:
	_hovered = active
	_apply_style()
	queue_redraw()

func play_invalid_bump() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.08, 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.10)

func play_swap_pop() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.04, 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func play_clear_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.14, 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12).set_delay(0.08)
	await tween.finished

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(self)
		accept_event()

func _build_visuals() -> void:
	if _panel != null:
		return
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_icon = TextureRect.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 1
	_icon.offset_top = 1
	_icon.offset_right = -1
	_icon.offset_bottom = -1
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("#f4f0dd"))
	_label.add_theme_color_override("font_outline_color", Color("#11151c"))
	_label.add_theme_constant_override("outline_size", 2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _special_label(type_value: int) -> String:
	if type_value >= 400:
		return "★"
	if type_value >= 300:
		return "B"
	if type_value >= 200:
		return "↕"
	if type_value >= 100:
		return "↔"
	return ""

func play_special_pulse() -> void:
	_start_special_glow()
	var flash := create_tween()
	flash.set_parallel(true)
	flash.tween_property(self, "scale", Vector2.ONE * 1.28, 0.10)
	flash.tween_property(self, "rotation", 0.08, 0.10)
	flash.chain().tween_property(self, "scale", Vector2.ONE, 0.16)
	flash.parallel().tween_property(self, "rotation", 0.0, 0.16)

func _start_special_glow() -> void:
	if not is_inside_tree():
		return
	if _special_pulse_tween != null and _special_pulse_tween.is_valid():
		return
	_special_pulse_tween = create_tween()
	_special_pulse_tween.set_loops()
	_special_pulse_tween.set_trans(Tween.TRANS_SINE)
	_special_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_special_pulse_tween.tween_property(self, "scale", Vector2.ONE * 1.10, 0.42)
	_special_pulse_tween.tween_property(self, "scale", Vector2.ONE * 0.98, 0.42)

func _stop_special_glow() -> void:
	if _special_pulse_tween != null and _special_pulse_tween.is_valid():
		_special_pulse_tween.kill()
	_special_pulse_tween = null
	scale = Vector2.ONE
	rotation = 0.0

func play_shuffle_spin() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", rotation + TAU, 0.22)
	tween.tween_property(self, "scale", Vector2.ONE * 0.82, 0.10)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_delay(0.10)

func _apply_style() -> void:
	if _panel == null:
		return
	var style := StyleBoxFlat.new()
	# Normal match-board blocks now use transparent PNG art from
	# res://assets/ui/puzzle_blocks/*.png, so the old colored panel is hidden.
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	if piece_type >= 100:
		style.border_color = Color("#fff59b")
		style.set_border_width_all(4)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		style.shadow_color = Color(1.0, 0.92, 0.25, 0.45)
		style.shadow_size = 12
		style.shadow_offset = Vector2.ZERO
	if _selected:
		style.border_color = Color("#fff7c4")
		style.set_border_width_all(3)
		style.shadow_color = Color(1.0, 0.92, 0.50, 0.45)
		style.shadow_size = 12
	elif _hovered:
		style.border_color = _accent.lightened(0.7)
		style.set_border_width_all(2)
		style.shadow_color = Color(_accent.r, _accent.g, _accent.b, 0.22)
		style.shadow_size = 6
	_panel.add_theme_stylebox_override("panel", style)

func _draw() -> void:
	var draw_rect_area: Rect2 = Rect2(Vector2.ZERO, size)
	var center: Vector2 = draw_rect_area.get_center()
	var radius: float = min(size.x, size.y) * 0.30

	if piece_type >= 100:
		var glow_phase := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
		draw_circle(center, radius * (1.75 + glow_phase * 0.24), Color(1.0, 0.95, 0.20, 0.16 + glow_phase * 0.12))
		draw_circle(center, radius * 1.42, Color(1.0, 1.0, 1.0, 0.18))
		for i in range(8):
			var a := float(i) / 8.0 * TAU + Time.get_ticks_msec() / 900.0
			var p := center + Vector2(cos(a), sin(a)) * radius * 1.45
			draw_circle(p, 2.0 + glow_phase * 1.4, Color(1.0, 0.98, 0.48, 0.75))

	# When a puzzle-block texture exists, draw only the transparent PNG art.
	if _icon != null and _icon.visible:
		return

	draw_circle(center + Vector2(0, radius * 0.18), radius * 1.05, _accent.darkened(0.28))
	draw_circle(center + Vector2(0, -radius * 0.10), radius, _accent.lightened(0.12))
	draw_circle(center + Vector2(-radius * 0.38, -radius * 0.54), radius * 0.33, Color(1.0, 1.0, 1.0, 0.28))
	draw_circle(center + Vector2(radius * 0.10, -radius * 0.68), radius * 0.18, Color(1.0, 1.0, 1.0, 0.18))

	match piece_key:
		"soldier_block":
			_draw_soldier_icon(center, radius)
		"archer_block":
			_draw_archer_icon(center, radius)
		"bomber_block":
			_draw_bomber_icon(center, radius)
		"shaman_block":
			_draw_shaman_icon(center, radius)
		"ogre_block":
			_draw_ogre_icon(center, radius)
		"slime_block":
			_draw_slime_icon(center, radius)
		_:
			_draw_default_face(center, radius)

func _draw_soldier_icon(center: Vector2, radius: float) -> void:
	var shield := PackedVector2Array([
		center + Vector2(0, -radius * 0.54),
		center + Vector2(radius * 0.48, -radius * 0.22),
		center + Vector2(radius * 0.36, radius * 0.36),
		center + Vector2(0, radius * 0.66),
		center + Vector2(-radius * 0.36, radius * 0.36),
		center + Vector2(-radius * 0.48, -radius * 0.22)
	])
	draw_colored_polygon(shield, Color("#f4f0df"))
	draw_polyline(shield + PackedVector2Array([shield[0]]), Color("#7a8740"), 2.4)
	draw_line(center + Vector2(0, -radius * 0.30), center + Vector2(0, radius * 0.42), Color("#7a8740"), 2.0)
	draw_line(center + Vector2(-radius * 0.22, 0), center + Vector2(radius * 0.22, 0), Color("#7a8740"), 2.0)

func _draw_archer_icon(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(-radius * 0.10, 0), radius * 0.52, -1.2, 1.2, 18, Color("#fff6d8"), 2.4)
	draw_line(center + Vector2(radius * 0.20, -radius * 0.42), center + Vector2(radius * 0.20, radius * 0.42), Color("#fff6d8"), 2.2)
	draw_line(center + Vector2(-radius * 0.56, 0), center + Vector2(radius * 0.54, 0), Color("#6a7d35"), 2.8)
	var arrow_head := PackedVector2Array([
		center + Vector2(radius * 0.62, 0),
		center + Vector2(radius * 0.34, -radius * 0.14),
		center + Vector2(radius * 0.34, radius * 0.14)
	])
	draw_colored_polygon(arrow_head, Color("#6a7d35"))

func _draw_bomber_icon(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(0, radius * 0.06), radius * 0.62, Color("#2a3340"))
	draw_circle(center + Vector2(0, -radius * 0.08), radius * 0.56, Color("#ffda6e"))
	draw_circle(center + Vector2(radius * 0.30, -radius * 0.62), radius * 0.18, Color("#2a3340"))
	draw_line(center + Vector2(radius * 0.10, -radius * 0.54), center + Vector2(radius * 0.26, -radius * 0.76), Color("#2a3340"), 2.0)
	draw_circle(center + Vector2(radius * 0.42, -radius * 0.92), radius * 0.11, Color("#fff3ac"))
	draw_circle(center + Vector2(radius * 0.34, -radius * 0.86), radius * 0.09, Color("#ff8d5e"))
	draw_circle(center + Vector2(radius * 0.50, -radius * 0.84), radius * 0.08, Color("#fff0c0"))

func _draw_shaman_icon(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.08, radius * 0.56), center + Vector2(radius * 0.18, -radius * 0.44), Color("#f3ebd3"), 4.0)
	draw_circle(center + Vector2(radius * 0.28, -radius * 0.56), radius * 0.24, Color("#8ef8f0"))
	draw_circle(center + Vector2(radius * 0.28, -radius * 0.56), radius * 0.12, Color("#d5ffff"))
	draw_circle(center + Vector2(-radius * 0.30, radius * 0.10), radius * 0.16, Color("#ffdca9"))
	draw_circle(center + Vector2(-radius * 0.04, radius * 0.10), radius * 0.16, Color("#ffdca9"))

func _draw_ogre_icon(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.68, Color("#8b5f34"))
	var left_horn := PackedVector2Array([
		center + Vector2(-radius * 0.54, -radius * 0.22),
		center + Vector2(-radius * 0.90, -radius * 0.62),
		center + Vector2(-radius * 0.44, -radius * 0.72)
	])
	var right_horn := PackedVector2Array([
		center + Vector2(radius * 0.54, -radius * 0.22),
		center + Vector2(radius * 0.90, -radius * 0.62),
		center + Vector2(radius * 0.44, -radius * 0.72)
	])
	draw_colored_polygon(left_horn, Color("#f0dfb2"))
	draw_colored_polygon(right_horn, Color("#f0dfb2"))
	_draw_default_face(center, radius * 0.86, Color("#fff1c5"), Color("#5f2d1a"))

func _draw_slime_icon(center: Vector2, radius: float) -> void:
	var slime := PackedVector2Array([
		center + Vector2(-radius * 0.70, radius * 0.24),
		center + Vector2(-radius * 0.52, -radius * 0.26),
		center + Vector2(-radius * 0.22, -radius * 0.56),
		center + Vector2(radius * 0.14, -radius * 0.50),
		center + Vector2(radius * 0.48, -radius * 0.18),
		center + Vector2(radius * 0.66, radius * 0.28),
		center + Vector2(radius * 0.22, radius * 0.60),
		center + Vector2(-radius * 0.28, radius * 0.56)
	])
	draw_colored_polygon(slime, Color("#c7ffd7"))
	draw_polyline(slime + PackedVector2Array([slime[0]]), Color("#57b87a"), 2.2)
	_draw_default_face(center + Vector2(0, radius * 0.04), radius * 0.78, Color("#2f6c44"), Color("#2f6c44"))

func _draw_default_face(center: Vector2, radius: float, eye_color := Color("#31281d"), mouth_color := Color("#31281d")) -> void:
	draw_circle(center + Vector2(-radius * 0.24, -radius * 0.10), radius * 0.11, eye_color)
	draw_circle(center + Vector2(radius * 0.24, -radius * 0.10), radius * 0.11, eye_color)
	draw_arc(center + Vector2(0, radius * 0.08), radius * 0.26, 0.2, PI - 0.2, 12, mouth_color, 2.0)

func _on_mouse_entered() -> void:
	set_hovered(true)
	entered.emit(self)

func _on_mouse_exited() -> void:
	set_hovered(false)
	exited.emit(self)
