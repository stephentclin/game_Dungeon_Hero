extends Control

const SaveSystemScript = preload("res://scripts/SaveSystem.gd")
const MENU_TEXTURE = preload("res://assets/ui/backgrounds/menu_dungeon.png")
const BLUE_NORMAL = preload("res://assets/ui/buttons/blue_normal.png")
const BLUE_HOVER = preload("res://assets/ui/buttons/blue_hover.png")
const BLUE_PRESSED = preload("res://assets/ui/buttons/blue_pressed.png")
const BLUE_DISABLED = preload("res://assets/ui/buttons/blue_disabled.png")
const PURPLE_NORMAL = preload("res://assets/ui/buttons/purple_normal.png")
const PURPLE_HOVER = preload("res://assets/ui/buttons/purple_hover.png")
const PURPLE_PRESSED = preload("res://assets/ui/buttons/purple_pressed.png")
const PURPLE_DISABLED = preload("res://assets/ui/buttons/purple_disabled.png")
const LEFT_NORMAL = preload("res://assets/ui/icons/arrow_left_normal.png")
const LEFT_HOVER = preload("res://assets/ui/icons/arrow_left_hover.png")
const LEFT_PRESSED = preload("res://assets/ui/icons/arrow_left_pressed.png")
const LEFT_DISABLED = preload("res://assets/ui/icons/arrow_left_disabled.png")
const RIGHT_NORMAL = preload("res://assets/ui/icons/arrow_right_normal.png")
const RIGHT_HOVER = preload("res://assets/ui/icons/arrow_right_hover.png")
const RIGHT_PRESSED = preload("res://assets/ui/icons/arrow_right_pressed.png")
const RIGHT_DISABLED = preload("res://assets/ui/icons/arrow_right_disabled.png")

var save_system = SaveSystemScript.new()
var save_data: Dictionary = {}
var background: TextureRect
var settings_panel: PanelContainer
var start_button: TextureButton
var settings_button: TextureButton
var language_en_button: TextureButton
var language_zh_button: TextureButton
var lives_left_button: TextureButton
var lives_right_button: TextureButton
var lives_label: Label
var info_label: Label
var settings_open = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save_data = save_system.load_progress({})
	_build_menu()
	_refresh_text()

func _build_menu() -> void:
	background = TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = MENU_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	start_button = _make_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(390, 96))
	start_button.position = Vector2(440, 500)
	start_button.pressed.connect(_start_game)
	_add_button_label(start_button, "开始游戏", 34)
	add_child(start_button)

	settings_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(390, 96))
	settings_button.position = Vector2(440, 605)
	settings_button.pressed.connect(_toggle_settings)
	_add_button_label(settings_button, "设置", 34)
	add_child(settings_button)

	_build_settings_panel()

func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(900, 120)
	settings_panel.size = Vector2(342, 510)
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.06, 0.12, 0.94)))
	settings_panel.visible = false
	add_child(settings_panel)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	settings_panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var title = Label.new()
	title.text = "设置 / SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("#ffd568"))
	box.add_child(title)

	var language_title = Label.new()
	language_title.text = "语言 / LANGUAGE"
	language_title.add_theme_font_size_override("font_size", 16)
	language_title.add_theme_color_override("font_color", Color("#fff0bf"))
	box.add_child(language_title)
	var language_row = HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 8)
	box.add_child(language_row)
	language_en_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(138, 48))
	language_en_button.pressed.connect(_set_english)
	_add_button_label(language_en_button, "English", 18)
	language_row.add_child(language_en_button)
	language_zh_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(138, 48))
	language_zh_button.pressed.connect(_set_chinese)
	_add_button_label(language_zh_button, "中文", 19)
	language_row.add_child(language_zh_button)

	var lives_title = Label.new()
	lives_title.text = "勇者命数 / HERO LIVES"
	lives_title.add_theme_font_size_override("font_size", 16)
	lives_title.add_theme_color_override("font_color", Color("#fff0bf"))
	box.add_child(lives_title)
	var lives_row = HBoxContainer.new()
	lives_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lives_row.add_theme_constant_override("separation", 10)
	box.add_child(lives_row)
	lives_left_button = _make_button(LEFT_NORMAL, LEFT_HOVER, LEFT_PRESSED, LEFT_DISABLED, Vector2(56, 56))
	lives_left_button.pressed.connect(_decrease_lives)
	lives_row.add_child(lives_left_button)
	lives_label = Label.new()
	lives_label.custom_minimum_size = Vector2(118, 56)
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lives_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lives_label.add_theme_font_size_override("font_size", 32)
	lives_label.add_theme_color_override("font_color", Color("#fff1bd"))
	lives_label.add_theme_color_override("font_outline_color", Color("#080d17"))
	lives_label.add_theme_constant_override("outline_size", 4)
	lives_row.add_child(lives_label)
	lives_right_button = _make_button(RIGHT_NORMAL, RIGHT_HOVER, RIGHT_PRESSED, RIGHT_DISABLED, Vector2(56, 56))
	lives_right_button.pressed.connect(_increase_lives)
	lives_row.add_child(lives_right_button)

	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("font_size", 15)
	info_label.add_theme_color_override("font_color", Color("#e7efff"))
	box.add_child(info_label)

func _make_button(normal: Texture2D, hover: Texture2D, pressed: Texture2D, disabled: Texture2D, button_size: Vector2) -> TextureButton:
	var button = TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = normal
	button.texture_hover = hover
	button.texture_pressed = pressed
	button.texture_disabled = disabled
	button.custom_minimum_size = button_size
	button.size = button_size
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(Callable(AudioManager, "play_select"))
	return button

func _add_button_label(button: TextureButton, label_text: String, font_size: int) -> void:
	var label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12
	label.offset_right = -12
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff0cb"))
	label.add_theme_color_override("font_outline_color", Color("#10111a"))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

func _panel_style(fill: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#d99a1e")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _toggle_settings() -> void:
	settings_open = not settings_open
	settings_panel.visible = settings_open

func _start_game() -> void:
	save_system.save_progress(save_data)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _set_english() -> void:
	_settings()["language"] = "en"
	save_system.save_progress(save_data)
	_refresh_text()

func _set_chinese() -> void:
	_settings()["language"] = "zh"
	save_system.save_progress(save_data)
	_refresh_text()

func _decrease_lives() -> void:
	_change_lives(-1)

func _increase_lives() -> void:
	_change_lives(1)

func _change_lives(delta: int) -> void:
	var settings = _settings()
	settings["hero_lives"] = clampi(int(settings.get("hero_lives", 5)) + delta, 1, 5)
	save_system.save_progress(save_data)
	_refresh_text()

func _settings() -> Dictionary:
	if not save_data.has("settings"):
		save_data["settings"] = {"language": "zh", "hero_lives": 5, "deploy_tutorial_seen": false}
	return save_data["settings"]

func _refresh_text() -> void:
	var settings = _settings()
	var is_zh = str(settings.get("language", "zh")) == "zh"
	var lives = clampi(int(settings.get("hero_lives", 5)), 1, 5)
	lives_label.text = str(lives)
	lives_left_button.disabled = lives <= 1
	lives_right_button.disabled = lives >= 5
	if is_zh:
		start_button.get_child(0).text = "开始游戏"
		settings_button.get_child(0).text = "设置"
		info_label.text = "当前命数：%d\n\n初始拥有【虚无】封印。每少一条命，勇者再解锁一个封印。最后一命低血时会触发【永恒】。\n\n← / → 可调整命数。" % lives
	else:
		start_button.get_child(0).text = "START"
		settings_button.get_child(0).text = "SETTINGS"
		info_label.text = "Lives: %d\n\nThe hero starts with Void. Each lost life unlocks another seal. Eternal triggers on low HP during the final life.\n\nUse ← / → to adjust lives." % lives

func _unhandled_key_input(event: InputEvent) -> void:
	if not settings_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT:
			_decrease_lives()
		elif event.keycode == KEY_RIGHT:
			_increase_lives()
		elif event.keycode == KEY_ESCAPE:
			_toggle_settings()
