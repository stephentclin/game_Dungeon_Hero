extends Control
class_name SkillTreeNode

signal selected(skill_id: String)
signal previewed(skill_id: String)

const LOCK_TEXTURE = preload("res://assets/ui/icons/lock_normal.png")

var skill_id := ""
var branch_color := Color("#ff4058")
var title := ""
var icon := "✦"
var icon_texture: Texture2D
var current_level := 0
var max_level := 1
var can_upgrade := false
var unlocked := false
var selected_state := false
var pulse := 0.0

var title_label: Label
var level_label: Label
var icon_label: Label
var icon_image: TextureRect
var lock_icon: TextureRect
var burst_timer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	title_label = _make_label("", 12, Color("#fff3d0"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.position = Vector2(-15, 58)
	title_label.size = Vector2(106, 34)
	add_child(title_label)

	level_label = _make_label("", 11, Color("#d8f7ff"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.position = Vector2(0, 42)
	level_label.size = Vector2(76, 18)
	add_child(level_label)

	icon_image = TextureRect.new()
	icon_image.position = Vector2(13, 6)
	icon_image.size = Vector2(50, 50)
	icon_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_image)

	icon_label = _make_label("", 26, Color("#fff9e7"))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.position = Vector2(0, 8)
	icon_label.size = Vector2(76, 40)
	add_child(icon_label)

	lock_icon = TextureRect.new()
	lock_icon.position = Vector2(50, 37)
	lock_icon.size = Vector2(22, 22)
	lock_icon.texture = LOCK_TEXTURE
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lock_icon)
	refresh_state(current_level, unlocked, can_upgrade, selected_state)

func setup(data: Dictionary, color: Color) -> void:
	skill_id = str(data.get("id", ""))
	title = str(data.get("name", ""))
	icon = str(data.get("icon", "✦"))
	icon_texture = _load_icon_texture(icon)
	branch_color = color
	max_level = int(data.get("max_level", 1))
	refresh_state(int(data.get("current_level", 0)), bool(data.get("unlocked", false)), bool(data.get("can_upgrade", false)), selected_state)

func refresh_state(level: int, is_unlocked: bool, is_can_upgrade: bool, is_selected: bool) -> void:
	current_level = level
	unlocked = is_unlocked
	can_upgrade = is_can_upgrade
	selected_state = is_selected
	if title_label != null:
		title_label.text = title
	if level_label != null:
		level_label.text = "Lv.MAX" if current_level >= max_level else "Lv.%d/%d" % [current_level, max_level]
	if icon_image != null:
		icon_image.texture = icon_texture
		icon_image.visible = icon_texture != null
		icon_image.modulate = Color.WHITE if unlocked else Color(0.36, 0.38, 0.44, 0.82)
	if icon_label != null:
		icon_label.text = "" if icon_texture != null else icon
		icon_label.modulate = Color.WHITE if unlocked else Color(0.45, 0.46, 0.52, 0.90)
	if lock_icon != null:
		lock_icon.visible = not unlocked
		lock_icon.modulate = Color(0.78, 0.80, 0.86, 0.80)
	modulate = Color.WHITE if unlocked else Color(0.55, 0.58, 0.64, 0.88)
	queue_redraw()

func play_upgrade_burst() -> void:
	burst_timer = 0.42
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if burst_timer > 0.0:
		burst_timer = maxf(0.0, burst_timer - delta)
		queue_redraw()
	if can_upgrade or selected_state:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(skill_id)

func _on_mouse_entered() -> void:
	previewed.emit(skill_id)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.10)

func _on_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _draw() -> void:
	var center := Vector2(38, 31)
	var base := branch_color
	var dark := Color("#10131b")
	if not unlocked:
		base = Color("#535965")
		dark = Color("#080a0f")
	var breathing := 0.45 + 0.55 * sin(pulse * 3.0)
	var glow := 0.18
	if can_upgrade:
		glow = 0.42 + breathing * 0.28
	if selected_state:
		glow = maxf(glow, 0.72)
	if current_level >= max_level:
		glow = maxf(glow, 0.64)
	draw_circle(center, 39.0, Color(base.r, base.g, base.b, glow * 0.38))
	draw_circle(center, 31.0, dark)
	draw_circle(center, 28.0, Color(base.r * 0.36, base.g * 0.36, base.b * 0.36, 0.92))
	if not unlocked:
		draw_circle(center, 27.0, Color(0, 0, 0, 0.36))
	draw_arc(center, 33.0, 0, TAU, 72, Color(base.r, base.g, base.b, 0.95 if unlocked else 0.38), 3.0, true)
	draw_arc(center, 25.0, pulse * 0.55, TAU + pulse * 0.55, 72, Color(1, 1, 1, 0.18 if unlocked else 0.05), 1.0, true)
	if current_level >= max_level:
		draw_arc(center, 37.0, 0, TAU, 80, Color("#ffe28a"), 2.0, true)
	if selected_state:
		draw_arc(center, 41.0, 0, TAU, 80, Color("#fff7d6"), 2.0, true)
	if burst_timer > 0.0:
		var t := 1.0 - burst_timer / 0.42
		draw_circle(center, 38.0 + t * 34.0, Color(base.r, base.g, base.b, (1.0 - t) * 0.38))
		draw_arc(center, 44.0 + t * 28.0, 0, TAU, 90, Color(1, 1, 1, (1.0 - t) * 0.68), 2.0, true)

func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#05070c"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _load_icon_texture(path: String) -> Texture2D:
	if not path.begins_with("res://"):
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
