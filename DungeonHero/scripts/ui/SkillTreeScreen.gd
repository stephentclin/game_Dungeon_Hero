extends Control
class_name SkillTreeScreen

signal closed

const SkillTreeFXLayerScript = preload("res://scripts/ui/SkillTreeFXLayer.gd")
const SkillTreeConnectionLayerScript = preload("res://scripts/ui/SkillTreeConnectionLayer.gd")
const SkillTreeNodeScript = preload("res://scripts/ui/SkillTreeNode.gd")
const SKILL_TREE_OPEN_SOUND_PATH := "res://assets/audio/skill_tree_sound.mp3"

const BRANCH_COLORS := {
	"core": Color("#c76cff"),
	"red": Color("#ff3347"),
	"purple": Color("#b95cff"),
	"blue": Color("#28b7ff"),
	"gold": Color("#f2c15b")
}

const BRANCH_NAMES := {
	"core": "改写核心",
	"red": "军势改写",
	"purple": "墨水命运",
	"blue": "契约调度",
	"gold": "兵种训练"
}

const BRANCH_INFO := {
	"core": {"zh": "改写核心：开启技能树并解锁后续节点。", "en": "Rewrite Core: opens the Skill Tree and unlocks later nodes."},
	"red": {"zh": "军势改写：强化全体攻击、攻速、暴击率与暴击效果。", "en": "Army Rewrite: improves all monster attack, attack speed, crit chance, and crit damage."},
	"purple": {"zh": "墨水命运：提升怪物移动速度，并增加消消乐幸运点。", "en": "Ink Fate: increases monster movement speed and Match Board luck."},
	"blue": {"zh": "契约调度：强化巫毒萨满施法、毒素伤害、炸弹小鬼与食人魔。", "en": "Contract Dispatch: improves shaman casting, poison damage, bomb goblins, and ogres."},
	"gold": {"zh": "兵种训练：保留给后续兵种专精。", "en": "Unit Training: reserved for future unit mastery."}
}

var main = null
var active_tab := "core"
var selected_skill_id := "core_rewrite"
var preview_skill_id := ""
var skill_data: Dictionary = {}
var tab_ids: Dictionary = {}
var node_controls: Dictionary = {}

var top_ink_label: Label
var tab_core_button: Button
var tab_unit_button: Button
var skill_tree_area: Control
var node_layer: Control
var connection_layer: SkillTreeConnectionLayer
var info_icon: Label
var info_icon_image: TextureRect
var info_title: Label
var info_level: Label
var info_status: Label
var info_desc: Label
var info_next: Label
var info_req: Label
var info_cost: Label
var upgrade_button: Button
var reset_button: Button
var bottom_info_label: Label
var feedback_label: Label
var back_button: Button
var skill_tree_audio_player: AudioStreamPlayer

func setup(game_main) -> void:
	main = game_main
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_skill_data()
	_build_layout()
	refresh_skill_tree()
	refresh_node_info(selected_skill_id)
	_play_open_sound()


func _play_open_sound() -> void:
	if not ResourceLoader.exists(SKILL_TREE_OPEN_SOUND_PATH):
		return
	if skill_tree_audio_player == null:
		skill_tree_audio_player = AudioStreamPlayer.new()
		skill_tree_audio_player.name = "SkillTreeOpenSound"
		skill_tree_audio_player.bus = "Master"
		skill_tree_audio_player.volume_db = 0.0
		add_child(skill_tree_audio_player)
	var stream: AudioStream = ResourceLoader.load(SKILL_TREE_OPEN_SOUND_PATH) as AudioStream
	if stream == null:
		return
	skill_tree_audio_player.stop()
	skill_tree_audio_player.stream = stream
	skill_tree_audio_player.play()

func _is_english() -> bool:
	return main != null and main.has_method("current_language") and str(main.current_language()) == "en"

func _t(zh: String, en: String) -> String:
	return en if _is_english() else zh

func _localized_dict_text(value, fallback := "") -> String:
	if typeof(value) == TYPE_DICTIONARY:
		return str(value.get("en" if _is_english() else "zh", value.get("zh", fallback)))
	return str(value) if str(value) != "" else fallback

func _skill_name(data: Dictionary) -> String:
	return _localized_dict_text(data.get("name_text", data.get("name", "")), str(data.get("name", "")))

func _skill_description(data: Dictionary) -> String:
	return _localized_dict_text(data.get("description_text", data.get("description", "")), str(data.get("description", "")))

func _skill_effects(data: Dictionary) -> Array:
	var key := "effects_en" if _is_english() else "effects_zh"
	if data.has(key) and typeof(data[key]) == TYPE_ARRAY:
		return data[key]
	return data.get("effects", [])

func _branch_info(branch: String) -> String:
	return _localized_dict_text(BRANCH_INFO.get(branch, ""), "")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _build_layout() -> void:
	var background := SkillTreeFXLayerScript.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(18, 14)
	top_bar.size = Vector2(1244, 82)
	top_bar.add_theme_stylebox_override("panel", _style(Color(0.03, 0.025, 0.035, 0.92), Color("#b77932"), 2))
	add_child(top_bar)
	var top_margin := _margin(16, 10, 16, 10)
	top_bar.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 22)
	top_margin.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size = Vector2(265, 0)
	title_box.add_theme_constant_override("separation", 0)
	top_row.add_child(title_box)
	var title := _label(_t("技能树", "SKILL TREE"), 27, Color("#ffe0a3"))
	title_box.add_child(title)
	var subtitle := _label(_t("改写技能树", "REWRITE SKILL TREE"), 12, Color("#8fdfff"))
	title_box.add_child(subtitle)

	var resource_row := HBoxContainer.new()
	resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.alignment = BoxContainer.ALIGNMENT_CENTER
	resource_row.add_theme_constant_override("separation", 10)
	top_row.add_child(resource_row)
	top_ink_label = _resource_chip(resource_row, _t("改写墨水", "Rewrite Ink"), Color("#ff4058"))
	top_ink_label.custom_minimum_size = Vector2(260, 44)

	var back_box := VBoxContainer.new()
	back_box.custom_minimum_size = Vector2(178, 0)
	top_row.add_child(back_box)
	back_button = Button.new()
	back_button.custom_minimum_size = Vector2(174, 48)
	back_button.text = _back_button_text()
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.add_theme_font_size_override("font_size", 14)
	back_button.add_theme_stylebox_override("normal", _style(Color("#191017"), Color("#ffcf6e"), 2))
	back_button.add_theme_stylebox_override("hover", _style(Color("#321019"), Color("#ff4058"), 2))
	back_button.add_theme_stylebox_override("pressed", _style(Color("#3d1514"), Color("#ffffff"), 2))
	back_button.pressed.connect(_on_back_pressed)
	back_box.add_child(back_button)

	var tab_bar := HBoxContainer.new()
	tab_bar.position = Vector2(22, 108)
	tab_bar.size = Vector2(382, 40)
	tab_bar.add_theme_constant_override("separation", 8)
	add_child(tab_bar)
	tab_core_button = _tab_button(_t("核心改写", "Core Rewrite"), "core")
	tab_unit_button = _tab_button(_t("兵种专精", "Unit Mastery"), "unit")
	tab_bar.add_child(tab_core_button)
	tab_bar.add_child(tab_unit_button)
	tab_unit_button.visible = false

	skill_tree_area = Control.new()
	skill_tree_area.position = Vector2(22, 154)
	skill_tree_area.size = Vector2(900, 500)
	skill_tree_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(skill_tree_area)

	var area_panel := PanelContainer.new()
	area_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	area_panel.add_theme_stylebox_override("panel", _style(Color(0.015, 0.018, 0.030, 0.82), Color("#47505d"), 1))
	skill_tree_area.add_child(area_panel)
	var area_fx := SkillTreeFXLayerScript.new()
	area_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	area_fx.accent_color = Color("#ff4058")
	area_fx.grid_color = Color(0.6, 0.9, 1.0, 0.06)
	skill_tree_area.add_child(area_fx)

	connection_layer = SkillTreeConnectionLayerScript.new()
	connection_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	connection_layer.branch_colors = BRANCH_COLORS
	connection_layer.purchased_callable = Callable(self, "_is_purchased")
	skill_tree_area.add_child(connection_layer)
	node_layer = Control.new()
	node_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	node_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_tree_area.add_child(node_layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(942, 110)
	panel.size = Vector2(316, 544)
	panel.add_theme_stylebox_override("panel", _style(Color(0.026, 0.024, 0.036, 0.94), Color("#b77932"), 2))
	add_child(panel)
	var detail_margin := _margin(16, 16, 16, 16)
	panel.add_child(detail_margin)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 10)
	detail_margin.add_child(detail_box)

	var detail_head := HBoxContainer.new()
	detail_head.add_theme_constant_override("separation", 12)
	detail_box.add_child(detail_head)
	info_icon = _label("✦", 42, Color("#fff0bb"))
	info_icon.custom_minimum_size = Vector2(58, 58)
	info_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_icon.add_theme_stylebox_override("normal", _style(Color("#100e16"), Color("#ffcf6e"), 2))
	detail_head.add_child(info_icon)
	info_icon_image = TextureRect.new()
	info_icon_image.position = Vector2(4, 4)
	info_icon_image.size = Vector2(50, 50)
	info_icon_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_icon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info_icon_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info_icon_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_icon.add_child(info_icon_image)
	var head_text := VBoxContainer.new()
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_head.add_child(head_text)
	info_title = _label("Node", 23, Color("#ffe0a3"))
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_text.add_child(info_title)
	info_level = _label("Lv.0/1", 14, Color("#8fdfff"))
	head_text.add_child(info_level)

	info_status = _label("Status", 15, Color("#ffcf6e"))
	detail_box.add_child(info_status)
	info_desc = _detail_text("")
	detail_box.add_child(_section(_t("效果", "Effect"), info_desc))
	info_next = _detail_text("")
	detail_box.add_child(_section(_t("下一级", "Next Level"), info_next))
	info_req = _detail_text("")
	detail_box.add_child(_section(_t("需求", "Requirement"), info_req))
	info_cost = _label("Ink Cost: 0", 16, Color("#ffe0a3"))
	detail_box.add_child(info_cost)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(0, 48)
	upgrade_button.focus_mode = Control.FOCUS_NONE
	upgrade_button.text = _t("升级节点", "Upgrade Node")
	upgrade_button.add_theme_font_size_override("font_size", 17)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	detail_box.add_child(upgrade_button)

	reset_button = Button.new()
	reset_button.custom_minimum_size = Vector2(0, 40)
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.text = _t("重置天赋", "Reset Talents")
	reset_button.add_theme_font_size_override("font_size", 15)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_button.add_theme_stylebox_override("normal", _style(Color("#171018"), Color("#8c5360"), 1))
	reset_button.add_theme_stylebox_override("hover", _style(Color("#2b1118"), Color("#ff9aa8"), 1))
	reset_button.add_theme_stylebox_override("pressed", _style(Color("#3a1314"), Color("#ffffff"), 1))
	reset_button.add_theme_color_override("font_color", Color("#ffd8d8"))
	detail_box.add_child(reset_button)

	feedback_label = _label("", 13, Color("#ffb0a5"))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(feedback_label)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(22, 664)
	bottom.size = Vector2(1236, 42)
	bottom.add_theme_stylebox_override("panel", _style(Color(0.03, 0.025, 0.035, 0.90), Color("#47505d"), 1))
	add_child(bottom)
	var bottom_margin := _margin(14, 7, 14, 7)
	bottom.add_child(bottom_margin)
	bottom_info_label = _label("", 15, Color("#dcecff"))
	bottom_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_margin.add_child(bottom_info_label)

func _build_skill_data() -> void:
	skill_data.clear()
	tab_ids = {
		"core": [
			"core_rewrite", "army_rewrite", "attack_speed", "crit_chance", "attack",
			"ink_yield", "ink_reflux", "normal_dice_unlock", "power_dice_unlock",
			"cooldown", "quick_entrance", "unlock_bomber", "unlock_shaman", "unlock_ogre"
		]
	}
	_add_skill("core_rewrite", "改写核心", "Rewrite Core", "core", "开启怪物技能树。", "Open the monster Skill Tree.", ["技能树核心已激活。"], ["Skill Tree core activated."], 1, [0], [], Vector2(0.48, 0.48), "res://assets/ui/skill_tree_icons/purple_contract.png")
	_add_skill("army_rewrite", "军势改写", "Army Rewrite", "red", "全体怪物攻击提升。", "Increase all monster attack.", ["全体攻击 +5%", "全体攻击 +10%", "全体攻击 +15%"], ["All monster ATK +5%", "All monster ATK +10%", "All monster ATK +15%"], 3, [12, 18, 24], ["core_rewrite"], Vector2(0.25, 0.28), "res://assets/ui/skill_tree_icons/red_blade.png")
	_add_skill("attack_speed", "狂躁节拍", "Feral Tempo", "red", "全体怪物攻击速度提升。", "Increase all monster attack speed.", ["攻击速度 +5%", "攻击速度 +10%", "攻击速度 +15%"], ["Attack speed +5%", "Attack speed +10%", "Attack speed +15%"], 3, [22, 34, 46], ["army_rewrite"], Vector2(0.36, 0.13), "res://assets/ui/skill_tree_icons/red_tempo.png")
	_add_skill("crit_chance", "血色伏笔", "Blood Foreshadow", "red", "全体怪物暴击率提升。", "Increase all monster critical chance.", ["暴击率 +3%", "暴击率 +6%", "暴击率 +9%", "暴击率 +12%"], ["Crit chance +3%", "Crit chance +6%", "Crit chance +9%", "Crit chance +12%"], 4, [26, 38, 50, 62], ["army_rewrite"], Vector2(0.17, 0.43), "res://assets/ui/skill_tree_icons/red_blood.png")
	_add_skill("attack", "利爪改写", "Claw Rewrite", "red", "全体怪物暴击效果提升。", "Increase all monster critical damage.", ["暴击伤害 +15%", "暴击伤害 +30%", "暴击伤害 +45%"], ["Crit damage +15%", "Crit damage +30%", "Crit damage +45%"], 3, [22, 34, 46], ["crit_chance"], Vector2(0.12, 0.13), "res://assets/ui/skill_tree_icons/red_blade.png")

	_add_skill("ink_yield", "墨水命运", "Ink Fate", "purple", "怪物移动速度提升。", "Increase monster movement speed.", ["移动速度 +4%", "移动速度 +8%", "移动速度 +12%"], ["Move speed +4%", "Move speed +8%", "Move speed +12%"], 3, [24, 36, 48], ["core_rewrite"], Vector2(0.56, 0.20), "res://assets/ui/skill_tree_icons/blue_ink.png")
	_add_skill("ink_reflux", "墨水回流", "Ink Reflux", "purple", "进一步提升怪物移动速度。", "Further increase monster movement speed.", ["额外移动速度 +5%", "额外移动速度 +10%", "额外移动速度 +15%"], ["Extra move speed +5%", "Extra move speed +10%", "Extra move speed +15%"], 3, [24, 36, 48], ["ink_yield"], Vector2(0.70, 0.11), "res://assets/ui/skill_tree_icons/blue_ink.png")
	_add_skill("normal_dice_unlock", "普通骰子", "Normal Dice", "purple", "提升消消乐幸运点，并解锁普通骰子。", "Increase Match Board luck and unlock Normal Dice.", ["消消乐幸运点 +1，普通骰子解锁"], ["Match Board Luck +1; Normal Dice unlocked"], 1, [30], ["ink_yield"], Vector2(0.70, 0.34), "res://assets/ui/skill_tree_icons/gold_dice.png")
	_add_skill("power_dice_unlock", "强力骰子", "Power Dice", "purple", "进一步提升消消乐幸运点，并解锁强力骰子。", "Further increase Match Board luck and unlock Power Dice.", ["消消乐幸运点额外 +1，强力骰子解锁"], ["Extra Match Board Luck +1; Power Dice unlocked"], 1, [85], ["normal_dice_unlock"], Vector2(0.84, 0.25), "res://assets/ui/skill_tree_icons/purple_dice.png")

	_add_skill("cooldown", "剧团调度", "Troupe Dispatch", "blue", "巫毒萨满施法速度提升。", "Increase Voodoo Shaman casting speed.", ["萨满施法速度 +6%", "萨满施法速度 +12%", "萨满施法速度 +18%"], ["Shaman cast speed +6%", "Shaman cast speed +12%", "Shaman cast speed +18%"], 3, [24, 36, 48], ["core_rewrite"], Vector2(0.56, 0.70), "res://assets/ui/skill_tree_icons/blue_cooldown.png")
	_add_skill("quick_entrance", "入场调度", "Entrance Dispatch", "blue", "进一步提升巫毒萨满施法速度。", "Further increase Voodoo Shaman casting speed.", ["萨满施法速度额外 +7%", "萨满施法速度额外 +14%", "萨满施法速度额外 +21%"], ["Extra shaman cast speed +7%", "Extra shaman cast speed +14%", "Extra shaman cast speed +21%"], 3, [24, 36, 48], ["cooldown"], Vector2(0.72, 0.68), "res://assets/ui/skill_tree_icons/blue_cooldown.png")
	_add_skill("unlock_bomber", "火药合同", "Powder Contract", "blue", "炸弹小鬼入列，并提升炸弹小鬼伤害。", "Unlock Bomb Goblin and increase its damage.", ["解锁炸弹小鬼，炸弹小鬼伤害 +15%"], ["Unlock Bomb Goblin; Bomb Goblin damage +15%"], 1, [80], ["cooldown"], Vector2(0.42, 0.84), "res://assets/ui/skill_tree_icons/purple_contract.png")
	_add_skill("unlock_shaman", "巫毒契约", "Voodoo Pact", "blue", "巫毒萨满入列，并提升毒素伤害。", "Unlock Voodoo Shaman and increase poison damage.", ["解锁巫毒萨满，毒素伤害 +20%"], ["Unlock Voodoo Shaman; poison damage +20%"], 1, [140], ["quick_entrance"], Vector2(0.68, 0.86), "res://assets/ui/skill_tree_icons/purple_shaman.png")
	_add_skill("unlock_ogre", "饕餮许可", "Gluttony Permit", "blue", "食人魔入列，并提升食人魔伤害。", "Unlock Ogre and increase Ogre damage.", ["解锁食人魔，食人魔伤害 +15%"], ["Unlock Ogre; Ogre damage +15%"], 1, [260], ["unlock_shaman"], Vector2(0.84, 0.72), "res://assets/ui/skill_tree_icons/gold_skeleton.png")

func _add_skill(id: String, name_zh: String, name_en: String, branch: String, description_zh: String, description_en: String, effects_zh: Array, effects_en: Array, max_level: int, costs: Array, prerequisites: Array, position: Vector2, icon: String) -> void:
	skill_data[id] = {
		"id": id,
		"name": name_zh,
		"name_text": {"zh": name_zh, "en": name_en},
		"branch": branch,
		"description": description_zh,
		"description_text": {"zh": description_zh, "en": description_en},
		"effects": effects_zh,
		"effects_zh": effects_zh,
		"effects_en": effects_en,
		"current_level": 0,
		"max_level": max_level,
		"cost": costs,
		"prerequisite_ids": prerequisites,
		"position": position,
		"icon": icon,
		"unlocked": false,
		"purchased": false
	}

func refresh_skill_tree() -> void:
	_sync_data_state()
	_update_top_bar()
	_update_tabs()
	for child in node_layer.get_children():
		child.queue_free()
	node_controls.clear()
	var ids: Array = tab_ids.get(active_tab, [])
	for id in ids:
		var data: Dictionary = skill_data[id]
		var node_data: Dictionary = data.duplicate(true)
		node_data["name"] = _skill_name(data)
		var node: SkillTreeNode = SkillTreeNodeScript.new()
		node.size = Vector2(76, 96)
		var pos_ratio: Vector2 = data["position"]
		if active_tab == "unit" and id == "core_rewrite":
			pos_ratio = Vector2(0.16, 0.50)
		node.position = Vector2(pos_ratio.x * skill_tree_area.size.x, pos_ratio.y * skill_tree_area.size.y) - Vector2(38, 38)
		node.setup(node_data, BRANCH_COLORS.get(str(data.get("branch", "core")), Color.WHITE))
		node.refresh_state(int(data["current_level"]), bool(data["unlocked"]), bool(data["can_upgrade"]), id == selected_skill_id)
		node.selected.connect(_on_node_selected)
		node.previewed.connect(_on_node_previewed)
		node_layer.add_child(node)
		node_controls[id] = node
	connection_layer.skill_data = skill_data
	connection_layer.visible_ids = ids
	connection_layer.node_controls = node_controls
	connection_layer.queue_redraw()
	if not ids.has(selected_skill_id):
		selected_skill_id = ids[0]
	refresh_node_info(selected_skill_id)

func refresh_node_info(skill_id: String) -> void:
	if not skill_data.has(skill_id):
		return
	var data: Dictionary = skill_data[skill_id]
	var branch := str(data.get("branch", "core"))
	var branch_color: Color = BRANCH_COLORS.get(branch, Color.WHITE)
	var level := int(data.get("current_level", 0))
	var max_level := int(data.get("max_level", 1))
	var icon_value := str(data.get("icon", "✦"))
	var icon_texture: Texture2D = _load_icon_texture(icon_value)
	if info_icon_image != null:
		info_icon_image.texture = icon_texture
		info_icon_image.visible = icon_texture != null
	info_icon.text = "" if icon_texture != null else icon_value
	info_icon.add_theme_color_override("font_color", branch_color.lightened(0.35))
	info_title.text = _skill_name(data)
	info_level.text = "Lv.%d/%d" % [level, max_level]
	info_desc.text = _skill_description(data)
	info_next.text = _next_effect_text(data)
	info_req.text = _requirement_text(data)
	var status := _status_text(data)
	info_status.text = _t("状态：%s", "Status: %s") % status
	info_status.add_theme_color_override("font_color", _status_color(data))
	var cost := _skill_cost(data)
	info_cost.text = _t("墨水花费：%s", "Ink Cost: %s") % ("-" if level >= max_level else str(cost))
	feedback_label.text = _blocked_reason(data)
	upgrade_button.disabled = not bool(data.get("can_upgrade", false))
	if level >= max_level:
		upgrade_button.text = _t("最高等级", "MAX LEVEL")
	elif not bool(data.get("unlocked", false)):
		upgrade_button.text = _t("需求未满足", "Prerequisite Missing")
	elif _ink_amount() < cost:
		upgrade_button.text = _t("墨水不足", "Not Enough Ink")
	else:
		upgrade_button.text = _t("升级节点", "Upgrade Node")
	_apply_upgrade_button_style(branch_color, upgrade_button.disabled)
	bottom_info_label.text = _branch_info(branch)

func draw_connections() -> void:
	if connection_layer != null:
		connection_layer.queue_redraw()

func can_upgrade(skill_id: String) -> bool:
	if not skill_data.has(skill_id):
		return false
	var data: Dictionary = skill_data[skill_id]
	if int(data.get("current_level", 0)) >= int(data.get("max_level", 1)):
		return false
	if not _prerequisites_met(data):
		return false
	return _ink_amount() >= _skill_cost(data)

func upgrade_skill(skill_id: String) -> bool:
	if not skill_data.has(skill_id):
		return false
	_sync_data_state()
	var data: Dictionary = skill_data[skill_id]
	if not can_upgrade(skill_id):
		_play_blocked_feedback(data)
		return false
	var cost := _skill_cost(data)
	_spend_ink(cost)
	var level := int(data.get("current_level", 0)) + 1
	_set_level(skill_id, level)
	apply_skill_effect(skill_id)
	if main != null and main.has_method("play_skill_tree_sfx"):
		main.play_skill_tree_sfx("upgrade")
	elif main != null and main.get("audio_manager") != null:
		main.audio_manager.play_sfx("hero_upgrade")
	if main != null and main.has_method("show_skill_tree_feedback"):
		main.show_skill_tree_feedback(_t("技能树已升级：%s", "Skill tree upgraded: %s") % _skill_name(data))
	elif main != null and main.get("ui") != null:
		main.ui.show_event(_t("技能树已升级：%s", "Skill tree upgraded: %s") % _skill_name(data), true)
	if connection_layer != null:
		for prereq in data.get("prerequisite_ids", []):
			connection_layer.trigger_flow(str(prereq), skill_id)
	refresh_skill_tree()
	if node_controls.has(skill_id):
		node_controls[skill_id].play_upgrade_burst()
	selected_skill_id = skill_id
	refresh_node_info(skill_id)
	return true

func apply_skill_effect(skill_id: String) -> void:
	if skill_id.begins_with("unlock_"):
		var unit_id := skill_id.trim_prefix("unlock_")
		if main != null and main.has_method("unlock_skill_tree_unit"):
			main.unlock_skill_tree_unit(unit_id)
		elif main != null and main.monster_catalog.has(unit_id) and not main.run_unlocked.has(unit_id):
			main.run_unlocked.append(unit_id)
			if main.ui != null:
				main.ui.refresh_monster_list()
	if main != null and main.has_method("save_skill_tree_progress"):
		main.save_skill_tree_progress()
	elif main != null and typeof(main.save_data) == TYPE_DICTIONARY:
		main.save_data["skill_levels"] = main.skill_levels.duplicate(true)
		if main.save_system != null:
			main.save_system.save_progress(main.save_data)

func _on_node_selected(skill_id: String) -> void:
	selected_skill_id = skill_id
	preview_skill_id = ""
	if main != null and main.has_method("play_skill_tree_sfx"):
		main.play_skill_tree_sfx("select")
	elif main != null and main.get("audio_manager") != null:
		main.audio_manager.play_sfx("select", 1.0, -2.0)
	refresh_skill_tree()

func _on_node_previewed(skill_id: String) -> void:
	preview_skill_id = skill_id

func _on_upgrade_pressed() -> void:
	upgrade_skill(selected_skill_id)

func _on_reset_pressed() -> void:
	if main != null and main.has_method("reset_skill_tree_progress"):
		main.reset_skill_tree_progress()
	else:
		for id in skill_data.keys():
			_set_level(str(id), 0)
		if main != null and main.has_method("save_skill_tree_progress"):
			main.save_skill_tree_progress()
	selected_skill_id = "core_rewrite"
	preview_skill_id = ""
	refresh_skill_tree()
	feedback_label.text = _t("天赋已重置，墨水已返还。", "Talents reset. Ink refunded.")

func _on_back_pressed() -> void:
	closed.emit()

func _on_tab_pressed(tab_id: String) -> void:
	active_tab = tab_id
	preview_skill_id = ""
	selected_skill_id = "core_rewrite" if active_tab == "unit" else "core_rewrite"
	refresh_skill_tree()

func _sync_data_state() -> void:
	for id in skill_data.keys():
		var data: Dictionary = skill_data[id]
		data["current_level"] = _get_level(id)
		data["purchased"] = _is_purchased(id)
		data["unlocked"] = _prerequisites_met(data)
		data["can_upgrade"] = can_upgrade(id)

func _get_level(skill_id: String) -> int:
	if main == null:
		return 0
	if main.has_method("get_skill_tree_level"):
		return int(main.get_skill_tree_level(skill_id))
	if skill_id.begins_with("unlock_"):
		var unit_id := skill_id.trim_prefix("unlock_")
		return 1 if main.run_unlocked.has(unit_id) else int(main.skill_levels.get(skill_id, 0))
	return int(main.skill_levels.get(skill_id, 0))

func _set_level(skill_id: String, level: int) -> void:
	if main == null:
		return
	if main.has_method("set_skill_tree_level"):
		main.set_skill_tree_level(skill_id, level)
		return
	main.skill_levels[skill_id] = level

func _is_purchased(skill_id: String) -> bool:
	return _get_level(skill_id) > 0

func _prerequisites_met(data: Dictionary) -> bool:
	for prereq in data.get("prerequisite_ids", []):
		if not _is_purchased(str(prereq)):
			return false
	return true

func _skill_cost(data: Dictionary) -> int:
	var costs: Array = data.get("cost", [])
	var level := int(data.get("current_level", 0))
	if costs.is_empty():
		return 0
	return int(costs[clampi(level, 0, costs.size() - 1)])

func _ink_amount() -> int:
	if main == null:
		return 0
	if main.has_method("get_skill_tree_ink"):
		return int(main.get_skill_tree_ink())
	return int(main.rewrite_ink)

func _spend_ink(cost: int) -> void:
	if main == null:
		return
	if main.has_method("spend_skill_tree_ink"):
		main.spend_skill_tree_ink(cost)
		return
	main.rewrite_ink = max(0, int(main.rewrite_ink) - cost)

func _update_top_bar() -> void:
	top_ink_label.text = _t("改写墨水  %d", "Rewrite Ink  %d") % _ink_amount()

func _update_tabs() -> void:
	_apply_tab_style(tab_core_button, active_tab == "core")
	_apply_tab_style(tab_unit_button, active_tab == "unit")

func _status_text(data: Dictionary) -> String:
	if int(data.get("current_level", 0)) >= int(data.get("max_level", 1)):
		return _t("最高等级", "MAX LEVEL")
	if bool(data.get("can_upgrade", false)):
		return _t("可以升级", "UPGRADABLE")
	if not bool(data.get("unlocked", false)):
		return _t("未解锁", "LOCKED")
	if _ink_amount() < _skill_cost(data):
		return _t("墨水不足", "NOT ENOUGH INK")
	return _t("未解锁", "LOCKED")

func _status_color(data: Dictionary) -> Color:
	if int(data.get("current_level", 0)) >= int(data.get("max_level", 1)):
		return Color("#ffe28a")
	if bool(data.get("can_upgrade", false)):
		return Color("#78f7ff")
	if not bool(data.get("unlocked", false)):
		return Color("#969aa6")
	return Color("#ff8f8f")

func _next_effect_text(data: Dictionary) -> String:
	var effects: Array = _skill_effects(data)
	var level := int(data.get("current_level", 0))
	if level >= int(data.get("max_level", 1)):
		return _t("此节点已达到最高等级。", "This node is already at max level.")
	if effects.is_empty():
		return _t("下一级效果尚未设置。", "Next level effect is not set yet.")
	return str(effects[clampi(level, 0, effects.size() - 1)])

func _requirement_text(data: Dictionary) -> String:
	var reqs: Array[String] = []
	for prereq in data.get("prerequisite_ids", []):
		var prereq_id := str(prereq)
		if skill_data.has(prereq_id):
			reqs.append(_skill_name(skill_data[prereq_id]))
	if reqs.is_empty():
		return _t("没有前置需求。", "No prerequisite.")
	return _t("需要：", "Requires: ") + ", ".join(reqs)

func _blocked_reason(data: Dictionary) -> String:
	if int(data.get("current_level", 0)) >= int(data.get("max_level", 1)):
		return _t("已达到最高等级。", "Max level reached.")
	for prereq in data.get("prerequisite_ids", []):
		if not _is_purchased(str(prereq)):
			return _t("需要：%s", "Requires: %s") % _skill_name(skill_data[str(prereq)])
	if _ink_amount() < _skill_cost(data):
		return _t("墨水不足。", "Not enough ink.")
	return ""

func _play_blocked_feedback(data: Dictionary) -> void:
	feedback_label.text = _blocked_reason(data)
	if main != null and main.has_method("play_skill_tree_sfx"):
		main.play_skill_tree_sfx("error")
	elif main != null and main.get("audio_manager") != null:
		main.audio_manager.play_sfx("error")
	var original := upgrade_button.position
	var tween := create_tween()
	tween.tween_property(upgrade_button, "position", original + Vector2(7, 0), 0.035)
	tween.tween_property(upgrade_button, "position", original - Vector2(7, 0), 0.05)
	tween.tween_property(upgrade_button, "position", original, 0.045)

func _apply_upgrade_button_style(color: Color, disabled: bool) -> void:
	var fill := Color("#101923") if disabled else color.darkened(0.62)
	var border := Color("#4f5865") if disabled else color.lightened(0.30)
	upgrade_button.add_theme_stylebox_override("normal", _style(fill, border, 2))
	upgrade_button.add_theme_stylebox_override("hover", _style(fill.lightened(0.12), border.lightened(0.20), 2))
	upgrade_button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.10), Color.WHITE, 2))
	upgrade_button.add_theme_color_override("font_color", Color("#8f96a3") if disabled else Color("#fff1c7"))

func _tab_button(text: String, tab_id: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(184, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_on_tab_pressed.bind(tab_id))
	return button

func _apply_tab_style(button: Button, selected: bool) -> void:
	var border := Color("#ffcf6e") if selected else Color("#46505c")
	var fill := Color("#2b1115") if selected else Color("#090d14")
	button.add_theme_stylebox_override("normal", _style(fill, border, 2))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.10), border.lightened(0.18), 2))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.08), Color.WHITE, 2))
	button.add_theme_color_override("font_color", Color("#ffe4a6") if selected else Color("#b8c3d1"))

func _resource_chip(parent: Control, title: String, color: Color) -> Label:
	var label := _label("%s  0" % title, 16, Color("#eef6ff"))
	label.custom_minimum_size = Vector2(190, 44)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _style(Color("#080d15"), color.darkened(0.05), 1))
	parent.add_child(label)
	return label

func _back_button_text() -> String:
	if main != null and main.has_method("get_skill_tree_back_label"):
		return str(main.get_skill_tree_back_label())
	return _t("返回战斗", "BACK TO BATTLE")

func _load_icon_texture(path: String) -> Texture2D:
	if not path.begins_with("res://"):
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _section(title: String, content: Label) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var title_label := _label(title, 12, Color("#8fdfff"))
	box.add_child(title_label)
	box.add_child(content)
	return box

func _detail_text(value: String) -> Label:
	var label := _label(value, 14, Color("#e7edf7"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 58)
	return label

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#05070c"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	return style

func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin
