extends CanvasLayer
class_name UIController

# Conservative UI controller: all interactive artwork is a real TextureButton.
# The script deliberately avoids compact syntax so it stays friendly to Godot 4.x parsers.

const HeroFormLibrary = preload("res://scripts/data/HeroFormLibrary.gd")
const BLUE_NORMAL = preload("res://assets/ui/buttons/blue_normal.png")
const BLUE_HOVER = preload("res://assets/ui/buttons/blue_hover.png")
const BLUE_PRESSED = preload("res://assets/ui/buttons/blue_pressed.png")
const BLUE_DISABLED = preload("res://assets/ui/buttons/blue_disabled.png")
const PURPLE_NORMAL = preload("res://assets/ui/buttons/purple_normal.png")
const PURPLE_HOVER = preload("res://assets/ui/buttons/purple_hover.png")
const PURPLE_PRESSED = preload("res://assets/ui/buttons/purple_pressed.png")
const PURPLE_DISABLED = preload("res://assets/ui/buttons/purple_disabled.png")
const RED_NORMAL = preload("res://assets/ui/buttons/red_normal.png")
const RED_HOVER = preload("res://assets/ui/buttons/red_hover.png")
const RED_PRESSED = preload("res://assets/ui/buttons/red_pressed.png")
const RED_DISABLED = preload("res://assets/ui/buttons/red_disabled.png")

var main = null
var root = null
var bars = {}
var monster_list = null
var selected_label = null
var event_label = null
var commander_label = null
var wave_label = null
var resource_label = null
var hero_lives_label = null
var seal_label = null
var life_pips = []
var selected_monster_id = ""
var start_button = null
var red_button = null
var unlock_button = null
var upgrade_button = null
var convert_button = null
var overlay = null
var overlay_title = null
var overlay_body = null
var overlay_buttons = null

func setup(game_main) -> void:
	main = game_main
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_left()
	_build_top_center()
	_build_unit_panel()
	_build_command_panel()
	_build_overlay()
	refresh_monster_list()

func update_stats() -> void:
	if main == null:
		return
	if main.hero == null or main.commander == null:
		return
	_update_bar("hero_hp", main.hero.hp, main.hero.max_hp, _t("勇者生命", "Hero HP"))
	_update_bar("hero_armor", main.hero.armor, main.hero.max_armor, _t("勇者护甲", "Hero Armor"))
	_update_bar("commander", main.commander.hp, main.commander.max_hp, _t("指挥台", "Command Post"))
	_update_bar("rage", main.rage_system.rage, 100.0, _t("怒气", "Rage"))
	_update_bar("cp", main.command_points, main.max_command_points, _t("指挥点", "Command Points"))
	wave_label.text = _t("波次 %d  ·  勇者等级 %d", "Wave %d  ·  Hero Lv.%d") % [main.wave, main.hero_level()]
	resource_label.text = _t("金币 %d  ·  技能点 %d  ·  红按钮 %d", "Gold %d  ·  Skill %d  ·  Red %d") % [int(main.save_data["gold"]), int(main.save_data["skill_points"]), main.red_button_system.safe_triggers_left()]
	_update_life_strip()
	_update_seal_label()
	_update_selected_panel()
	_update_command_panel()
	start_button.visible = main.phase == "prepare" and not overlay.visible
	red_button.visible = main.phase == "battle"
	red_button.disabled = main.phase != "battle" or main.rage_system.rage < 100.0 or main.red_button_system.safe_triggers_left() <= 0
	_set_button_text(start_button, _t("开始战斗", "START BATTLE"))
	_set_button_text(red_button, _t("红按钮", "RED BUTTON"))
	if convert_button != null:
		convert_button.visible = main.all_monsters_unlocked()

func refresh_monster_list() -> void:
	if monster_list == null or main == null:
		return
	for child in monster_list.get_children():
		child.queue_free()
	for id in main.monster_order():
		var data = main.monster_catalog[id]
		var unlocked = main.is_monster_unlocked(id)
		var unit_button = null
		if unlocked:
			unit_button = _make_texture_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(0, 36))
		else:
			unit_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(0, 36))
		unit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unit_button.disabled = not main.is_monster_available_this_wave(id)
		var label_text = "%s  ·  CP %d  ·  Lv.%d" % [data.display_name, data.command_cost, main.monster_level(id)]
		if not unlocked:
			label_text = _t("未解锁：%s  ·  %d 金币", "LOCKED: %s  ·  %d Gold") % [data.display_name, data.unlock_cost]
		elif not main.is_monster_available_this_wave(id):
			label_text = _t("%s（训练后开放）", "%s (after tutorial)") % data.display_name
		_add_button_label(unit_button, label_text, 13)
		unit_button.pressed.connect(Callable(main, "select_monster").bind(id))
		monster_list.add_child(unit_button)
	_update_selected_panel()

func set_selected(monster_id) -> void:
	selected_monster_id = str(monster_id)
	_update_selected_panel()

func show_event(message, urgent = false) -> void:
	if event_label == null:
		return
	event_label.text = str(message)
	if urgent:
		event_label.add_theme_color_override("font_color", Color("#ffb18d"))
	else:
		event_label.add_theme_color_override("font_color", Color("#e8f2ff"))

func show_prepare(_hero_stats) -> void:
	if main != null and main.should_show_deploy_prompt():
		overlay.visible = true
		overlay_title.text = _t("第一波训练：守住指挥台", "Tutorial: Hold the Command Post")
		overlay_body.text = _t("① 已选小哥布林战士。\n② 点击绿色区域放下它。\n③ 点击【去部署】关闭教学，再按【开始战斗】。\n\n部署按钮只会在第一次出现。", "1) A Goblin Warrior is selected.\n2) Click the green zone to deploy it.\n3) Press Deploy to close this guide, then press Start Battle.\n\nThis guide appears only once.")
		var choices = []
		choices.append({"text": _t("去部署", "DEPLOY"), "callable": Callable(self, "dismiss_deploy_tutorial")})
		_set_overlay_buttons(choices)
	else:
		overlay.visible = false

func dismiss_deploy_tutorial() -> void:
	if main != null:
		main.mark_deploy_tutorial_seen()
	overlay.visible = false

func show_reward(rewards, boons) -> void:
	overlay.visible = true
	overlay_title.text = _t("勇者被击倒", "Hero Defeated")
	overlay_body.text = _t("剩余命数：%d / %d\n获得金币 %d，技能点 %d。\n选择一个临时强化。", "Lives remaining: %d / %d\nReward: %d Gold, %d Skill.\nChoose a temporary boon.") % [main.hero_lives_remaining, main.hero_lives_total, int(rewards.get("gold", 0)), int(rewards.get("skill_points", 0))]
	var choices = []
	for boon in boons:
		choices.append({"text": "%s\n%s" % [boon["name"], boon["description"]], "callable": Callable(main, "choose_temp_boon").bind(str(boon["id"]))})
	_set_overlay_buttons(choices)

func show_game_over(reason, waves_defeated) -> void:
	overlay.visible = true
	overlay_title.text = _t("挑战失败", "Defeat")
	overlay_body.text = "%s\n%s" % [str(reason), _t("完成波数：%d", "Waves completed: %d") % int(waves_defeated)]
	var choices = []
	choices.append({"text": _t("重新开始", "RESTART"), "callable": Callable(main, "start_new_run")})
	_set_overlay_buttons(choices)

func show_run_victory(rewards, defeated_lives) -> void:
	overlay.visible = true
	overlay_title.text = _t("最终胜利", "Victory")
	overlay_body.text = _t("勇者的 %d 条命已耗尽。\n最终奖励：金币 %d，技能点 %d。", "The hero's %d lives are gone.\nFinal reward: %d Gold, %d Skill.") % [int(defeated_lives), int(rewards.get("gold", 0)), int(rewards.get("skill_points", 0))]
	var choices = []
	choices.append({"text": _t("再开一局", "PLAY AGAIN"), "callable": Callable(main, "start_new_run")})
	_set_overlay_buttons(choices)

func show_red_button_options(effects) -> void:
	overlay.visible = true
	overlay_title.text = _t("红按钮：选择翻盘方案", "Red Button: Choose a Comeback")
	overlay_body.text = _t("怒气已满。选择一项紧急战术。", "Rage is full. Choose an emergency tactic.")
	var choices = []
	for effect in effects:
		choices.append({"text": "%s\n%s" % [effect.display_name, effect.description], "callable": Callable(main, "choose_red_button").bind(effect.id)})
	_set_overlay_buttons(choices)

func show_duel(duel_data, actions) -> void:
	overlay.visible = true
	overlay_title.text = _t("哥布林弹射决斗", "Goblin Duel")
	overlay_body.text = _t("指挥官生命 %.0f / %.0f\n勇者生命 %.0f / %.0f", "Commander HP %.0f / %.0f\nHero HP %.0f / %.0f") % [float(duel_data.get("goblin_hp", 0.0)), float(duel_data.get("goblin_max_hp", 0.0)), float(duel_data.get("hero_hp", 0.0)), float(duel_data.get("hero_max_hp", 0.0))]
	var choices = []
	for action in actions:
		choices.append({"text": "%s\n%s" % [action["name"], action["description"]], "callable": Callable(main, "choose_duel_action").bind(str(action["id"]))})
	_set_overlay_buttons(choices)

func hide_overlay() -> void:
	if overlay != null:
		overlay.visible = false

func _build_top_left() -> void:
	var panel = _make_panel(Vector2(14, 12), Vector2(372, 204), 0.94)
	var margin = _margin(10)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var header = Label.new()
	header.text = _t("勇者情报", "HERO INTEL")
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color("#aebbd3"))
	box.add_child(header)
	hero_lives_label = Label.new()
	hero_lives_label.add_theme_font_size_override("font_size", 18)
	hero_lives_label.add_theme_color_override("font_color", Color("#ffd66f"))
	box.add_child(hero_lives_label)
	var life_row = HBoxContainer.new()
	life_row.add_theme_constant_override("separation", 5)
	box.add_child(life_row)
	for index in range(5):
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(42, 10)
		pip.color = Color("#df565d")
		life_row.add_child(pip)
		life_pips.append(pip)
	seal_label = Label.new()
	seal_label.add_theme_font_size_override("font_size", 12)
	seal_label.add_theme_color_override("font_color", Color("#c8b4ff"))
	seal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(seal_label)
	_add_bar(box, "hero_hp", Color("#df5160"))
	_add_bar(box, "hero_armor", Color("#70adff"))
	_add_bar(box, "commander", Color("#56c573"))

func _build_top_center() -> void:
	var panel = _make_panel(Vector2(396, 12), Vector2(448, 138), 0.94)
	var margin = _margin(10)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	wave_label = Label.new()
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color("#ffd66f"))
	box.add_child(wave_label)
	resource_label = Label.new()
	resource_label.add_theme_font_size_override("font_size", 13)
	resource_label.add_theme_color_override("font_color", Color("#e0eaff"))
	box.add_child(resource_label)
	_add_bar(box, "rage", Color("#f59a35"))
	_add_bar(box, "cp", Color("#e0bb4e"))

func _build_unit_panel() -> void:
	var panel = _make_panel(Vector2(946, 12), Vector2(320, 696), 0.97)
	var margin = _margin(10)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var title = Label.new()
	title.text = _t("兵种与成长", "UNITS & GROWTH")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffd66f"))
	box.add_child(title)
	monster_list = VBoxContainer.new()
	monster_list.add_theme_constant_override("separation", 5)
	box.add_child(monster_list)
	selected_label = Label.new()
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_label.add_theme_font_size_override("font_size", 13)
	selected_label.add_theme_color_override("font_color", Color("#e8f0ff"))
	box.add_child(selected_label)
	unlock_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(0, 40))
	unlock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_button.pressed.connect(Callable(main, "unlock_selected_monster"))
	_add_button_label(unlock_button, _t("解锁", "UNLOCK"), 14)
	box.add_child(unlock_button)
	upgrade_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(0, 40))
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button.pressed.connect(Callable(main, "upgrade_selected_monster"))
	_add_button_label(upgrade_button, _t("升级", "UPGRADE"), 14)
	box.add_child(upgrade_button)
	convert_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(0, 36))
	convert_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	convert_button.pressed.connect(Callable(main, "convert_gold_to_skill_points"))
	_add_button_label(convert_button, _t("金币转技能点", "GOLD TO SKILL"), 13)
	box.add_child(convert_button)

func _build_command_panel() -> void:
	var panel = _make_panel(Vector2(666, 570), Vector2(270, 138), 0.84)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var margin = _margin(10)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	commander_label = Label.new()
	commander_label.add_theme_font_size_override("font_size", 15)
	commander_label.add_theme_color_override("font_color", Color("#caffb7"))
	box.add_child(commander_label)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.add_theme_font_size_override("font_size", 12)
	event_label.add_theme_color_override("font_color", Color("#e8f2ff"))
	box.add_child(event_label)
	start_button = _make_texture_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(0, 38))
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(Callable(main, "begin_battle"))
	_add_button_label(start_button, _t("开始战斗", "START BATTLE"), 15)
	box.add_child(start_button)
	red_button = _make_texture_button(RED_NORMAL, RED_HOVER, RED_PRESSED, RED_DISABLED, Vector2(0, 38))
	red_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	red_button.pressed.connect(Callable(main, "force_red_button"))
	_add_button_label(red_button, _t("红按钮", "RED BUTTON"), 15)
	box.add_child(red_button)

func _build_overlay() -> void:
	overlay = _make_panel(Vector2(310, 148), Vector2(600, 390), 0.96)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var margin = _margin(18)
	overlay.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	overlay_title = Label.new()
	overlay_title.add_theme_font_size_override("font_size", 24)
	overlay_title.add_theme_color_override("font_color", Color("#ffd66f"))
	box.add_child(overlay_title)
	overlay_body = Label.new()
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_body.add_theme_font_size_override("font_size", 16)
	overlay_body.add_theme_color_override("font_color", Color("#eef3ff"))
	box.add_child(overlay_body)
	overlay_buttons = VBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 6)
	box.add_child(overlay_buttons)
	overlay.visible = false

func _make_panel(position_value, panel_size, alpha_value):
	var panel = PanelContainer.new()
	panel.position = position_value
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.06, 0.12, alpha_value)))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	return panel

func _margin(value):
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin

func _panel_style(fill_color):
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("#e7a326")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.60)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 4)
	return style

func _make_texture_button(normal_texture, hover_texture, pressed_texture, disabled_texture, button_size):
	var button = TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = normal_texture
	button.texture_hover = hover_texture
	button.texture_pressed = pressed_texture
	button.texture_disabled = disabled_texture
	button.custom_minimum_size = button_size
	button.size = button_size
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if has_node("/root/AudioManager"):
		button.pressed.connect(Callable(get_node("/root/AudioManager"), "play_select"))
	return button

func _add_button_label(button, label_text, font_size) -> void:
	var label = Label.new()
	label.name = "Text"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12
	label.offset_right = -12
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = str(label_text)
	label.add_theme_font_size_override("font_size", int(font_size))
	label.add_theme_color_override("font_color", Color("#fff0cc"))
	label.add_theme_color_override("font_outline_color", Color("#0c101a"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.button_down.connect(Callable(self, "_nudge_button_text").bind(label, true))
	button.button_up.connect(Callable(self, "_nudge_button_text").bind(label, false))

func _nudge_button_text(label, pressed) -> void:
	if label == null:
		return
	if pressed:
		label.position = Vector2(0, 2)
	else:
		label.position = Vector2.ZERO

func _set_button_text(button, value) -> void:
	if button == null:
		return
	var label = button.get_node_or_null("Text")
	if label != null:
		label.text = str(value)

func _add_bar(parent, id, color) -> void:
	var holder = VBoxContainer.new()
	holder.add_theme_constant_override("separation", 1)
	parent.add_child(holder)
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#dae7ff"))
	holder.add_child(label)
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 13)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#0a1017")
	bg_style.border_color = Color("#687282")
	bg_style.set_border_width_all(1)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	holder.add_child(bar)
	bars[id] = {"label": label, "bar": bar}

func _update_bar(id, value, maximum, label_text) -> void:
	if not bars.has(id):
		return
	var bar = bars[id]["bar"]
	var label = bars[id]["label"]
	bar.max_value = max(1.0, maximum)
	bar.value = clamp(value, 0.0, maximum)
	label.text = "%s %.0f / %.0f" % [str(label_text), max(0.0, value), max(1.0, maximum)]

func _update_life_strip() -> void:
	if main == null:
		return
	var remaining = int(main.hero_lives_remaining)
	var total = int(main.hero_lives_total)
	hero_lives_label.text = _t("勇者余命 %d/%d", "Hero Lives %d/%d") % [remaining, total]
	for index in range(life_pips.size()):
		life_pips[index].visible = index < total
		if index < remaining:
			life_pips[index].color = Color("#e05259")
		else:
			life_pips[index].color = Color(0.27, 0.17, 0.19, 0.70)

func _update_seal_label() -> void:
	if main == null or seal_label == null:
		return
	var names = main.hero_seal_names()
	var joined = ""
	for name in names:
		if joined != "":
			joined += " · "
		joined += str(name)
	if main.hero_lives_remaining <= 1 and main.hero_seal_count() >= 5:
		joined += " · " + _t("永恒待命", "Eternal Armed")
	seal_label.text = _t("封印：", "SEALS: ") + joined

func _update_command_panel() -> void:
	if main == null or main.commander == null:
		return
	commander_label.text = _t("哥布林指挥台  ·  %.0f / %.0f", "Goblin Command Post  ·  %.0f / %.0f") % [main.commander.hp, main.commander.max_hp]
	if main.phase == "prepare":
		var id = main.selected_monster_id
		var unit_name = "-"
		if main.monster_catalog.has(id):
			unit_name = main.monster_catalog[id].display_name
		if event_label.text == "" or event_label.text.begins_with("已选") or event_label.text.begins_with("Selected"):
			event_label.text = _t("已选：%s", "Selected: %s") % unit_name

func _update_selected_panel() -> void:
	if main == null or selected_label == null:
		return
	var id = selected_monster_id
	if id == "" or not main.monster_catalog.has(id):
		selected_label.text = _t("未选择兵种。", "No unit selected.")
		unlock_button.disabled = true
		upgrade_button.disabled = true
		return
	var data = main.monster_catalog[id]
	var unlocked = main.is_monster_unlocked(id)
	var level = main.monster_level(id)
	selected_label.text = "%s\n%s\n%s\n%s" % [data.display_name, _t("生命 %.0f  攻击 %.1f  攻速 %.2f", "HP %.0f  ATK %.1f  SPD %.2f") % [data.hp_with_level(), data.attack_with_level(), data.attack_speed], _t("射程 %.0f", "Range %.0f") % data.attack_range, _ability_text(data.ability)]
	var level_cap = main.hero_level()
	# Keep resource-short buttons clickable so Main can play error_sound.ogg and show a reason.
	unlock_button.disabled = unlocked
	upgrade_button.disabled = not unlocked or level >= level_cap
	_set_button_text(unlock_button, _t("解锁：%d 金币", "UNLOCK: %d GOLD") % data.unlock_cost)
	_set_button_text(upgrade_button, _t("升级：%d 技能点（上限 %d）", "UPGRADE: %d SKILL (MAX %d)") % [main.balance.upgrade_cost(level), level_cap])
	_set_button_text(convert_button, _t("25 金币 → 1 技能点", "25 GOLD → 1 SKILL"))
	# Keep clickable when gold is insufficient so error_sound.ogg can play.
	convert_button.disabled = false

func _ability_text(ability) -> String:
	match str(ability):
		"slow":
			return _t("能力：减速，免疫击退，池中强化。", "Skill: slow, knockback immune, pool boost.")
		"arrow":
			return _t("能力：每第三箭为标记箭，虚无阶段必中。", "Skill: every third arrow is a marked, sure-hit arrow.")
		"suicide":
			return _t("能力：撞墙或接近勇者时爆炸。", "Skill: explodes on wall contact or near hero.")
		"ritual_heal":
			return _t("能力：命中后治疗命中点周围的友军。", "Skill: hit heals allies near impact.")
		"armor_breaker":
			return _t("能力：吸血；吞噬低血友军继承特性。", "Skill: lifesteal; devours low-HP allies to inherit traits.")
		_:
			return _t("能力：快速近战。", "Skill: fast melee.")

func _set_overlay_buttons(button_defs) -> void:
	for child in overlay_buttons.get_children():
		child.queue_free()
	for button_def in button_defs:
		var button = _make_texture_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(0, 44))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_button_label(button, str(button_def["text"]), 15)
		button.pressed.connect(button_def["callable"])
		overlay_buttons.add_child(button)

func _t(zh, en) -> String:
	if main != null and main.has_method("current_language") and main.current_language() == "en":
		return str(en)
	return str(zh)
