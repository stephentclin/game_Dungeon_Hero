extends Control

const SaveSystemScript = preload("res://scripts/SaveSystem.gd")
const SkillTreeScreenScript = preload("res://scripts/ui/SkillTreeScreen.gd")
const PuzzleBoardScript = preload("res://scripts/PuzzleBoard.gd")
const MENU_TEXTURE = preload("res://assets/ui/backgrounds/menu_dungeon.png")
const MAINPAGE_MP4_PATH := "res://assets/videos/mainpage.mp4"
const MAINPAGE_OGV_PATH := "res://assets/videos/mainpage.ogv"
const MAIN_MENU_MUSIC_PATH := "res://assets/audio/Crusade.mp3"
const INTRODUCTION_IMAGE_PATH := "res://assets/ui/Introduction.png"
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
const SCORE_ICON = preload("res://assets/ui/icons/score_trophy.png")
const SKILL_TREE_STARTING_INK := 9999
const DEFAULT_SKILL_LEVELS := {
	"army_rewrite": 0,
	"attack": 0,
	"attack_speed": 0,
	"crit_chance": 0,
	"crit_damage": 0,
	"ink_yield": 0,
	"ink_reflux": 0,
	"normal_dice_unlock": 0,
	"power_dice_unlock": 0,
	"cooldown": 0,
	"quick_entrance": 0,
	"unlock_bomber": 0,
	"unlock_shaman": 0,
	"unlock_ogre": 0
}

var save_system = SaveSystemScript.new()
var save_data: Dictionary = {}
var background: TextureRect
var background_video: VideoStreamPlayer
var settings_panel: PanelContainer
var start_button: TextureButton
var settings_button: TextureButton
var score_button: TextureButton
var skill_tree_button: TextureButton
var skill_tree_panel = null
var score_panel: PanelContainer
var player_name_edit: LineEdit
var start_name_edit: LineEdit
var start_name_warning: Label
var language_en_button: TextureButton
var language_zh_button: TextureButton
var lives_left_button: TextureButton
var lives_right_button: TextureButton
var lives_label: Label
var info_label: Label
var settings_title_label: Label
var language_title_label: Label
var lives_title_label: Label
var settings_open = false
var menu_music_player: AudioStreamPlayer
var introduction_overlay: Control
var introduction_panel: PanelContainer
var introduction_image: TextureRect
var introduction_next_button: TextureButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	save_data = save_system.load_progress({})
	_ensure_skill_tree_starting_ink()
	_build_menu()
	_refresh_text()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_introduction_layout()

func _ensure_skill_tree_starting_ink() -> void:
	if bool(save_data.get("skill_tree_initial_ink_v3", false)):
		return
	save_data["skill_points"] = SKILL_TREE_STARTING_INK
	save_data["skill_levels"] = DEFAULT_SKILL_LEVELS.duplicate(true)
	save_data["unlocked"] = ["warrior", "archer", "slime"]
	save_data["skill_tree_initial_ink_v2"] = true
	save_data["skill_tree_initial_ink_v3"] = true
	save_system.save_progress(save_data)

func _build_menu() -> void:
	background = TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = MENU_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_build_video_background()
	_play_main_menu_music()

	# v10_57: all three main menu buttons use the exact same size.
	# START stays fixed; SKILL TREE is shifted upward to cover the animated blue button behind it,
	# while SETTINGS is shifted downward to cover the animated Chinese settings button.
	var main_button_size := Vector2(520, 96)
	var main_button_x := 380.0
	start_button = _make_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, main_button_size)
	start_button.position = Vector2(main_button_x, 392)
	start_button.pressed.connect(_start_game)
	_add_button_label(start_button, "START", 38)
	add_child(start_button)

	skill_tree_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, main_button_size)
	skill_tree_button.position = Vector2(main_button_x, 500)
	skill_tree_button.pressed.connect(_toggle_skill_tree)
	_add_button_label(skill_tree_button, "SKILL TREE", 38)
	add_child(skill_tree_button)

	score_button = TextureButton.new()
	score_button.ignore_texture_size = true
	score_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	score_button.texture_normal = SCORE_ICON
	score_button.texture_hover = SCORE_ICON
	score_button.texture_pressed = SCORE_ICON
	score_button.custom_minimum_size = Vector2(54, 54)
	score_button.size = Vector2(54, 54)
	score_button.position = Vector2(1204, 18)
	score_button.tooltip_text = "Scores"
	score_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	score_button.pressed.connect(_toggle_scores)
	add_child(score_button)

	settings_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, main_button_size)
	settings_button.position = Vector2(main_button_x, 610)
	settings_button.pressed.connect(_toggle_settings)
	_add_button_label(settings_button, "SETTINGS", 38)
	add_child(settings_button)

	_build_settings_panel()
	_build_score_panel()
	_build_introduction_overlay()

func _play_main_menu_music() -> void:
	if menu_music_player != null and is_instance_valid(menu_music_player):
		return
	if not ResourceLoader.exists(MAIN_MENU_MUSIC_PATH):
		return
	var stream: Resource = ResourceLoader.load(MAIN_MENU_MUSIC_PATH)
	if stream == null:
		return
	stream.set("loop", true)
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.name = "MainMenuMusic"
	menu_music_player.bus = "Master"
	menu_music_player.volume_db = 4.0
	menu_music_player.stream = stream
	add_child(menu_music_player)
	menu_music_player.play()

func _build_video_background() -> void:
	var stream := _load_mainpage_video_stream()
	if stream == null:
		push_warning("Main menu video could not be loaded; using image fallback.")
		return
	background_video = VideoStreamPlayer.new()
	background_video.name = "MainpageVideoBackground"
	background_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_video.expand = true
	background_video.stream = stream
	background_video.volume_db = -80.0
	background_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_video)
	background_video.finished.connect(_restart_mainpage_video)
	background_video.play()

func _load_mainpage_video_stream() -> VideoStream:
	# The requested MP4 is kept at /assets/videos/mainpage.mp4.
	# Godot builds often decode OGV more reliably, so mainpage.ogv is bundled as a safe fallback.
	for path in [MAINPAGE_MP4_PATH, MAINPAGE_OGV_PATH]:
		if not ResourceLoader.exists(path):
			continue
		var loaded_resource: Resource = ResourceLoader.load(path)
		if loaded_resource is VideoStream:
			return loaded_resource as VideoStream
	return null

func _restart_mainpage_video() -> void:
	if background_video == null:
		return
	background_video.stop()
	background_video.play()

func _build_start_name_panel() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(410, 298)
	panel.size = Vector2(460, 74)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.06, 0.12, 0.88)))
	add_child(panel)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var label = Label.new()
	label.text = "NAME"
	label.custom_minimum_size = Vector2(74, 34)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#ffd568"))
	row.add_child(label)
	start_name_edit = LineEdit.new()
	start_name_edit.text = str(_settings().get("player_name", ""))
	if start_name_edit.text == "Player":
		start_name_edit.text = ""
	start_name_edit.placeholder_text = "Enter player name"
	start_name_edit.custom_minimum_size = Vector2(330, 34)
	start_name_edit.text_changed.connect(func(_text): _on_start_name_changed())
	start_name_edit.text_submitted.connect(func(_text): _start_game())
	row.add_child(start_name_edit)
	start_name_warning = Label.new()
	start_name_warning.text = ""
	start_name_warning.add_theme_font_size_override("font_size", 12)
	start_name_warning.add_theme_color_override("font_color", Color("#ff8a8a"))
	box.add_child(start_name_warning)

func _on_start_name_changed() -> void:
	if start_name_warning != null:
		start_name_warning.text = ""


func _build_introduction_overlay() -> void:
	introduction_overlay = Control.new()
	introduction_overlay.name = "IntroductionOverlay"
	introduction_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	introduction_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	introduction_overlay.visible = false
	introduction_overlay.z_index = 900
	add_child(introduction_overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	introduction_overlay.add_child(dim)

	introduction_panel = PanelContainer.new()
	introduction_panel.name = "IntroductionPanel"
	introduction_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	introduction_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.023, 0.033, 0.98)))
	introduction_overlay.add_child(introduction_panel)

	var margin := MarginContainer.new()
	margin.name = "IntroductionMargin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	introduction_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "IntroductionBox"
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	introduction_image = TextureRect.new()
	introduction_image.name = "IntroductionImage"
	introduction_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	introduction_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	introduction_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	introduction_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	introduction_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	introduction_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(INTRODUCTION_IMAGE_PATH):
		introduction_image.texture = ResourceLoader.load(INTRODUCTION_IMAGE_PATH)
	box.add_child(introduction_image)

	var button_row := HBoxContainer.new()
	button_row.name = "IntroductionButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(button_row)

	introduction_next_button = _make_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(250, 62))
	introduction_next_button.name = "IntroductionNextButton"
	introduction_next_button.pressed.connect(_go_to_game_after_introduction)
	_add_button_label(introduction_next_button, "NEXT", 26)
	button_row.add_child(introduction_next_button)

	_update_introduction_layout()

func _show_introduction_overlay() -> void:
	if introduction_overlay == null:
		_go_to_game_after_introduction()
		return
	if settings_panel != null:
		settings_panel.visible = false
		settings_open = false
	if score_panel != null:
		score_panel.visible = false
	if skill_tree_panel != null:
		skill_tree_panel.visible = false
	_update_introduction_layout()
	introduction_overlay.visible = true
	introduction_overlay.move_to_front()
	if introduction_next_button != null:
		introduction_next_button.disabled = false

func _update_introduction_layout() -> void:
	if introduction_overlay == null or introduction_panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	var panel_w: float = minf(viewport_size.x * 0.94, 1180.0)
	var panel_h: float = minf(viewport_size.y * 0.92, 690.0)
	introduction_panel.size = Vector2(panel_w, panel_h)
	introduction_panel.position = Vector2(floor((viewport_size.x - panel_w) * 0.5), floor((viewport_size.y - panel_h) * 0.5))
	if introduction_image != null:
		introduction_image.custom_minimum_size = Vector2(maxf(320.0, panel_w - 24.0), maxf(220.0, panel_h - 110.0))

func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(900, 72)
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

	settings_title_label = Label.new()
	var title = settings_title_label
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("#ffd568"))
	box.add_child(title)
	var close_settings_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(280, 44))
	close_settings_button.pressed.connect(_close_settings)
	_add_button_label(close_settings_button, "CLOSE", 16)
	box.add_child(close_settings_button)

	language_title_label = Label.new()
	var language_title = language_title_label
	language_title.text = "语言"
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

	lives_title_label = Label.new()
	var lives_title = lives_title_label
	lives_title.text = "勇者命数"
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

func _build_skill_tree_panel() -> void:
	skill_tree_panel = PanelContainer.new()
	skill_tree_panel.position = Vector2(52, 52)
	skill_tree_panel.size = Vector2(1176, 676)
	skill_tree_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.06, 0.12, 0.97)))
	skill_tree_panel.visible = false
	skill_tree_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(skill_tree_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	skill_tree_panel.add_child(margin)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	var title = Label.new()
	title.text = "SKILL TREE · REWRITE INK"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#ffd568"))
	header.add_child(title)
	var close_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(150, 54))
	close_button.pressed.connect(_close_skill_tree)
	_add_button_label(close_button, "CLOSE", 20)
	header.add_child(close_button)

	var ink_label = Label.new()
	ink_label.name = "InkLabel"
	ink_label.text = "Current Ink: %d" % int(save_data.get("skill_points", 0))
	ink_label.add_theme_font_size_override("font_size", 22)
	ink_label.add_theme_color_override("font_color", Color("#eef3ff"))
	box.add_child(ink_label)

	var desc = Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = "Stable nodes strengthen the cast, unlock units, and reduce summon cooldowns. Hover a node to preview its effect."
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color("#e7efff"))
	box.add_child(desc)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list = VBoxContainer.new()
	list.name = "SkillList"
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	_refresh_skill_tree_panel()

func _build_score_panel() -> void:
	score_panel = PanelContainer.new()
	score_panel.position = Vector2(260, 72)
	score_panel.size = Vector2(760, 620)
	score_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.06, 0.12, 0.97)))
	score_panel.visible = false
	score_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(score_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	score_panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var header = HBoxContainer.new()
	box.add_child(header)
	var title = Label.new()
	title.name = "ScoreTitle"
	title.text = "SCORE MODE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#ffd568"))
	header.add_child(title)
	var close_button = _make_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(140, 52))
	close_button.pressed.connect(_close_scores)
	_add_button_label(close_button, "CLOSE", 20)
	header.add_child(close_button)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	box.add_child(name_row)
	var name_label = Label.new()
	name_label.text = "PLAYER NAME"
	name_label.custom_minimum_size = Vector2(160, 42)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("#fff0bf"))
	name_row.add_child(name_label)
	player_name_edit = LineEdit.new()
	player_name_edit.text = str(_settings().get("player_name", "Player"))
	player_name_edit.custom_minimum_size = Vector2(340, 42)
	player_name_edit.text_submitted.connect(func(_text): _save_player_name())
	player_name_edit.focus_exited.connect(_save_player_name)
	name_row.add_child(player_name_edit)

	var formula = Label.new()
	formula.text = "Score priority: Hero lives + HP first, then time. Combo chains add bonus points."
	formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	formula.add_theme_font_size_override("font_size", 16)
	formula.add_theme_color_override("font_color", Color("#c7d6ff"))
	box.add_child(formula)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list = VBoxContainer.new()
	list.name = "ScoreList"
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	_refresh_score_panel()

func _refresh_skill_tree_panel() -> void:
	if skill_tree_panel == null:
		return
	var ink_label = skill_tree_panel.find_child("InkLabel", true, false)
	if ink_label != null:
		ink_label.text = "Current Ink: %d" % int(save_data.get("skill_points", 0))
	var list = skill_tree_panel.find_child("SkillList", true, false)
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	for entry in _main_menu_skill_entries():
		var button = _make_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(1060, 58))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = str(entry.get("effect", ""))
		button.pressed.connect(_try_purchase_menu_skill.bind(str(entry.get("id", ""))))
		_add_button_label(button, str(entry.get("label", "")), 20)
		list.add_child(button)

func _main_menu_skill_entries() -> Array:
	var levels: Dictionary = _skill_levels()
	var entries = []
	var defs = [
		{"id":"army_rewrite", "name":"军势改写", "base":12, "max":3, "effect":"全体攻击 +5%"},
		{"id":"attack_speed", "name":"狂躁节拍", "base":22, "max":3, "effect":"攻击速度 +5%"},
		{"id":"crit_chance", "name":"血色伏笔", "base":26, "max":4, "effect":"暴击率 +3%"},
		{"id":"attack", "name":"利爪改写", "base":22, "max":3, "effect":"暴击伤害 +15%"},
		{"id":"ink_yield", "name":"墨水命运", "base":24, "max":3, "effect":"移动速度 +4%"},
		{"id":"ink_reflux", "name":"墨水回流", "base":24, "max":3, "effect":"额外移动速度 +5%"},
		{"id":"normal_dice_unlock", "name":"普通骰子", "base":30, "max":1, "effect":"消消乐幸运点 +1"},
		{"id":"power_dice_unlock", "name":"强力骰子", "base":85, "max":1, "effect":"消消乐幸运点额外 +1"},
		{"id":"cooldown", "name":"剧团调度", "base":24, "max":3, "effect":"萨满施法速度 +6%"},
		{"id":"quick_entrance", "name":"入场调度", "base":24, "max":3, "effect":"萨满施法速度额外 +7%"}
	]
	for d in defs:
		var id = str(d["id"])
		var level = int(levels.get(id, 0))
		var max_level = int(d["max"])
		if level >= max_level:
			entries.append({"id":"", "label":"%s · MAX" % str(d["name"]), "effect":str(d["effect"])})
		else:
			var cost = int(d["base"]) + level * 12
			entries.append({"id":id, "label":"%s %d/%d · %d INK" % [str(d["name"]), level + 1, max_level, cost], "cost":cost, "effect":str(d["effect"])})
	return entries

func _skill_levels() -> Dictionary:
	if not save_data.has("skill_levels") or typeof(save_data["skill_levels"]) != TYPE_DICTIONARY:
		save_data["skill_levels"] = DEFAULT_SKILL_LEVELS.duplicate(true)
	for skill_id in DEFAULT_SKILL_LEVELS.keys():
		if not save_data["skill_levels"].has(skill_id):
			save_data["skill_levels"][skill_id] = int(DEFAULT_SKILL_LEVELS[skill_id])
	return save_data["skill_levels"]

func _try_purchase_menu_skill(id: String) -> void:
	if id == "":
		return
	var levels = _skill_levels()
	var base_costs = {"army_rewrite":12, "attack":22, "attack_speed":22, "crit_chance":26, "crit_damage":28, "ink_yield":24, "ink_reflux":24, "normal_dice_unlock":30, "power_dice_unlock":85, "cooldown":24, "quick_entrance":24}
	var max_levels = {"army_rewrite":3, "attack":3, "attack_speed":3, "crit_chance":4, "crit_damage":3, "ink_yield":3, "ink_reflux":3, "normal_dice_unlock":1, "power_dice_unlock":1, "cooldown":3, "quick_entrance":3}
	if not base_costs.has(id):
		return
	var level = int(levels.get(id, 0))
	if level >= int(max_levels[id]):
		return
	var cost = int(base_costs[id]) + level * 12
	if int(save_data.get("skill_points", 0)) < cost:
		return
	save_data["skill_points"] = int(save_data.get("skill_points", 0)) - cost
	levels[id] = level + 1
	save_system.save_progress(save_data)
	_refresh_skill_tree_panel()

func _close_skill_tree() -> void:
	if skill_tree_panel != null and is_instance_valid(skill_tree_panel):
		skill_tree_panel.queue_free()
	skill_tree_panel = null

func _toggle_skill_tree() -> void:
	if skill_tree_panel != null and is_instance_valid(skill_tree_panel):
		_close_skill_tree()
		return
	skill_tree_panel = SkillTreeScreenScript.new()
	skill_tree_panel.name = "MainMenuSkillTreeScreen"
	add_child(skill_tree_panel)
	skill_tree_panel.setup(self)
	skill_tree_panel.closed.connect(_close_skill_tree)
	if settings_panel != null:
		settings_panel.visible = false
	settings_open = false
	if score_panel != null:
		score_panel.visible = false

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

func _refresh_score_panel() -> void:
	if score_panel == null:
		return
	var list = score_panel.find_child("ScoreList", true, false)
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	var scores: Array = []
	if save_data.has("scores") and typeof(save_data["scores"]) == TYPE_ARRAY:
		scores = save_data["scores"]
	if scores.is_empty():
		var empty = Label.new()
		empty.text = "No scores yet. Finish a run to save your score."
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", Color("#e7efff"))
		list.add_child(empty)
		return
	var rank = 1
	for item in scores.slice(0, min(scores.size(), 20)):
		var row = Label.new()
		row.text = "#%02d  %s  —  %d pts  | Lives %d | HP %d%% | Time %ds | Room %d | Best Combo x%d" % [rank, str(item.get("name", "Player")), int(item.get("score", 0)), int(item.get("lives", 0)), int(item.get("hp_percent", 0)), int(item.get("time", 0)), int(item.get("room", 1)), int(item.get("best_combo", 0))]
		row.add_theme_font_size_override("font_size", 18)
		row.add_theme_color_override("font_color", Color("#eef3ff"))
		list.add_child(row)
		rank += 1

func _save_player_name() -> void:
	if player_name_edit == null:
		return
	var name = player_name_edit.text.strip_edges()
	if name == "":
		name = "Player"
		player_name_edit.text = name
	_settings()["player_name"] = name
	save_system.save_progress(save_data)

func _toggle_scores() -> void:
	_save_player_name()
	if score_panel == null:
		return
	score_panel.visible = not score_panel.visible
	if score_panel.visible:
		_refresh_score_panel()
		if settings_panel != null:
			settings_panel.visible = false
		settings_open = false
		_close_skill_tree()

func _close_scores() -> void:
	_save_player_name()
	if score_panel != null:
		score_panel.visible = false

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

func _close_settings() -> void:
	settings_open = false
	if settings_panel != null:
		settings_panel.visible = false

func _toggle_settings() -> void:
	settings_open = not settings_open
	settings_panel.visible = settings_open
	if skill_tree_panel != null and settings_open:
		_close_skill_tree()
	if score_panel != null and settings_open:
		score_panel.visible = false

func _start_game() -> void:
	if introduction_overlay != null and introduction_overlay.visible:
		return
	if not _settings().has("player_name") or str(_settings().get("player_name", "")).strip_edges() == "":
		_settings()["player_name"] = "Player"
	save_system.save_progress(save_data)
	_show_introduction_overlay()

func _go_to_game_after_introduction() -> void:
	if introduction_next_button != null:
		introduction_next_button.disabled = true
	PuzzleBoardScript.reset_match_board_guide_for_new_run()
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
		save_data["settings"] = {"language": "en", "hero_lives": 5, "deploy_tutorial_seen": false, "player_name": "Player"}
	return save_data["settings"]

func current_language() -> String:
	return str(_settings().get("language", "en"))

func get_skill_tree_back_label() -> String:
	return "BACK TO MENU" if current_language() == "en" else "返回主菜单"

func get_skill_tree_ink() -> int:
	return int(save_data.get("skill_points", 0))

func spend_skill_tree_ink(amount: int) -> void:
	save_data["skill_points"] = max(0, int(save_data.get("skill_points", 0)) - amount)

func get_skill_tree_level(skill_id: String) -> int:
	if skill_id.begins_with("unlock_"):
		var unit_id := skill_id.trim_prefix("unlock_")
		return 1 if _unlocked_units().has(unit_id) else int(_skill_levels().get(skill_id, 0))
	return int(_skill_levels().get(skill_id, 0))

func set_skill_tree_level(skill_id: String, level: int) -> void:
	_skill_levels()[skill_id] = level

func unlock_skill_tree_unit(unit_id: String) -> void:
	var unlocked := _unlocked_units()
	if not unlocked.has(unit_id):
		unlocked.append(unit_id)

func reset_skill_tree_progress() -> void:
	save_data["skill_points"] = SKILL_TREE_STARTING_INK
	save_data["skill_levels"] = DEFAULT_SKILL_LEVELS.duplicate(true)
	save_data["unlocked"] = ["warrior", "archer", "slime"]
	save_data["skill_tree_initial_ink_v2"] = true
	save_data["skill_tree_initial_ink_v3"] = true
	save_skill_tree_progress()

func save_skill_tree_progress() -> void:
	if save_system != null:
		save_system.save_progress(save_data)

func get_skill_tree_ink_bonus() -> int:
	return int(_skill_levels().get("ink_yield", 0)) * 4 + int(_skill_levels().get("ink_reflux", 0)) * 5

func play_skill_tree_sfx(_kind: String) -> void:
	pass

func show_skill_tree_feedback(_message: String) -> void:
	pass

func _unlocked_units() -> Array:
	if not save_data.has("unlocked") or typeof(save_data["unlocked"]) != TYPE_ARRAY:
		save_data["unlocked"] = ["warrior", "archer", "slime"]
	return save_data["unlocked"]

func _refresh_text() -> void:
	var settings = _settings()
	var is_zh = str(settings.get("language", "en")) == "zh"
	var lives = clampi(int(settings.get("hero_lives", 5)), 1, 5)
	lives_label.text = str(lives)
	lives_left_button.disabled = lives <= 1
	lives_right_button.disabled = lives >= 5
	if is_zh:
		start_button.get_child(0).text = "开始游戏"
		start_button.get_child(0).add_theme_font_size_override("font_size", 46)
		skill_tree_button.get_child(0).text = "技能树"
		settings_button.get_child(0).text = "设置"
		settings_button.get_child(0).add_theme_font_size_override("font_size", 42)
		if start_name_edit != null:
			start_name_edit.placeholder_text = "输入玩家名称"
		settings_title_label.text = "设置"
		language_title_label.text = "语言"
		lives_title_label.text = "勇者命数"
		language_en_button.get_child(0).text = "英文"
		language_zh_button.get_child(0).text = "中文"
		info_label.text = "当前命数：%d\n\n初始拥有【虚无】封印。每少一条命，勇者再解锁一个封印。最后一命低血时会触发【永恒】。\n\n← / → 可调整命数。" % lives
	else:
		start_button.get_child(0).text = "START"
		start_button.get_child(0).add_theme_font_size_override("font_size", 48)
		skill_tree_button.get_child(0).text = "SKILL TREE"
		settings_button.get_child(0).text = "SETTINGS"
		settings_button.get_child(0).add_theme_font_size_override("font_size", 42)
		if start_name_edit != null:
			start_name_edit.placeholder_text = "Enter player name"
		settings_title_label.text = "SETTINGS"
		language_title_label.text = "LANGUAGE"
		lives_title_label.text = "HERO LIVES"
		language_en_button.get_child(0).text = "ENGLISH"
		language_zh_button.get_child(0).text = "CHINESE"
		info_label.text = "Lives: %d\n\nThe hero starts with Void. Each lost life unlocks another seal. Eternal triggers on low HP during the final life.\n\nUse ← / → to adjust lives." % lives

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and skill_tree_panel != null and is_instance_valid(skill_tree_panel):
		_close_skill_tree()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and score_panel != null and score_panel.visible:
		_close_scores()
		return
	if not settings_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT:
			_decrease_lives()
		elif event.keycode == KEY_RIGHT:
			_increase_lives()
		elif event.keycode == KEY_ESCAPE:
			_toggle_settings()
