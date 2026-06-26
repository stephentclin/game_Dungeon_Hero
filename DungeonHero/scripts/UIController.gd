extends CanvasLayer
class_name UIController

# v11 UI foundation
# - Right-side cast cards use the supplied portrait art.
# - Left-side detail opens for the currently selected unit and contains no upgrade controls.
# - Player-earned items live in the bottom script strip.
# - Unlock and upgrade controls have moved into the Skill Tree overlay.

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
const LOCK_TEXTURE = preload("res://assets/ui/icons/lock_normal.png")
const PuzzleBoardScene = preload("res://scenes/ui/PuzzleBoard.tscn")

const UNIT_CARD_TEXTURES = {
	"warrior": preload("res://assets/ui/unit_cards/warrior_thumb.png"),
	"archer": preload("res://assets/ui/unit_cards/archer_thumb.png"),
	"slime": preload("res://assets/ui/unit_cards/slime_thumb.png"),
	"bomber": preload("res://assets/ui/unit_cards/bomber_thumb.png"),
	"shaman": preload("res://assets/ui/unit_cards/shaman_thumb.png"),
	"ogre": preload("res://assets/ui/unit_cards/ogre_thumb.png")
}

var main = null
var root = null
var bars = {}

var hero_lives_label = null
var seal_label = null
var relic_label = null
var room_label = null
var timer_label = null
var resource_label = null
var match_score_label = null
var population_label = null
var score_flash_label = null
var last_display_score := -1
var score_flash_timer := 0.0
var score_pulse_timer := 0.0
var life_pips = []

var boss_hp_panel = null
var boss_hp_label = null
var boss_hp_prefix_label = null
var boss_hp_tube_label = null
var boss_hp_next_bar = null
var boss_hp_delay_bar = null
var boss_hp_fill_bar = null
var boss_hp_fill_top = null
var boss_hp_fill_shadow = null
var boss_hp_fill_spark = null
var boss_hp_bar_width := 730.0
const HERO_HP_TUBE_COUNT := 10
var boss_hp_segments = []
var boss_hp_under_layers = []
var boss_hp_tick_marks = []
var boss_hp_last_ratio := 1.0
var boss_hp_delay_ratio := 1.0
var boss_hp_flash_timer := 0.0
var boss_hp_shake_timer := 0.0
var boss_hp_last_tube := HERO_HP_TUBE_COUNT

var cast_panel = null
var puzzle_board = null
var unit_list = null
var unit_buttons = {}
var selected_monster_id = ""

var detail_panel = null
var detail_portrait = null
var detail_title = null
var detail_role = null
var detail_stats = null
var detail_ability = null

var command_label = null
var event_label = null
var start_button = null
var red_button = null
var skill_tree_button = null
var return_menu_button = null
var return_menu_popup_active := false
var return_menu_previous_pause := false

var item_strip = null
var item_summary_label = null

var overlay = null
var overlay_title = null
var overlay_body = null
var overlay_buttons = null
var overlay_close_button = null

var hero_pass_cutscene_layer = null
var hero_pass_video_player = null
var hero_pass_audio_player = null
var hero_pass_timer = null
var hero_pass_callback := Callable()
const HERO_PASS_MP4_PATH := "res://assets/videos/Hero_pass.mp4"
const HERO_PASS_OGV_PATH := "res://assets/videos/Hero_pass.ogv"
const OUTCOME_FAIL_VIDEO_PATH := "res://assets/videos/fail.mp4"
const OUTCOME_FAIL_OGV_PATH := "res://assets/videos/fail.ogv"
const OUTCOME_SUCCESS_VIDEO_PATH := "res://assets/videos/success.mp4"
const OUTCOME_SUCCESS_OGV_PATH := "res://assets/videos/success.ogv"
const OUTCOME_WILHELM_AUDIO_PATH := "res://assets/audio/Wilhelm Scream.ogg"
const OUTCOME_TOM_AUDIO_PATH := "res://assets/audio/Tom Screaming.ogg"

func setup(game_main) -> void:
	main = game_main
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)
	_build_hero_intel()
	_build_room_header()
	_build_resource_header()
	_build_detail_panel()
	_build_cast_panel()
	_build_return_menu_button()
	_build_bottom_strip()
	_build_overlay()
	refresh_monster_list()

func _process(delta: float) -> void:
	if boss_hp_flash_timer > 0.0:
		boss_hp_flash_timer = max(0.0, boss_hp_flash_timer - delta)
	if boss_hp_shake_timer > 0.0:
		boss_hp_shake_timer = max(0.0, boss_hp_shake_timer - delta)
	if match_score_label != null and score_pulse_timer > 0.0:
		score_pulse_timer = max(0.0, score_pulse_timer - delta)
		var t := score_pulse_timer / 0.34
		var scale_value := 1.0 + 0.20 * sin(t * PI)
		match_score_label.scale = Vector2.ONE * scale_value
		if score_pulse_timer <= 0.0:
			match_score_label.scale = Vector2.ONE
	if score_flash_label != null and score_flash_timer > 0.0:
		score_flash_timer = max(0.0, score_flash_timer - delta)
		var alpha: float = clamp(score_flash_timer / 0.70, 0.0, 1.0)
		score_flash_label.modulate.a = alpha
		score_flash_label.position.y = 31.0 - (1.0 - alpha) * 22.0
		if score_flash_timer <= 0.0:
			score_flash_label.visible = false

func update_stats() -> void:
	_sync_overlay_pause()
	if main == null or main.hero == null:
		return
	_update_hero_intel()
	_update_room_header()
	_update_resource_header()
	_update_unit_detail()
	_update_command_area()
	_refresh_cast_states()
	_refresh_item_strip()

func refresh_monster_list() -> void:
	if main == null:
		return
	if unit_list == null:
		unit_buttons.clear()
		_update_unit_detail()
		return
	for child in unit_list.get_children():
		child.queue_free()
	unit_buttons.clear()
	for id in main.monster_order():
		var data = main.monster_catalog[id]
		var unlocked = main.is_monster_unlocked(id)
		var card = _make_unit_card(id, data, unlocked)
		unit_list.add_child(card)
		unit_buttons[id] = card
	_refresh_cast_states()
	_update_unit_detail()

func set_selected(monster_id) -> void:
	selected_monster_id = str(monster_id)
	if detail_panel != null:
		detail_panel.visible = selected_monster_id != ""
	_refresh_cast_states()
	_update_unit_detail()

func show_event(message, urgent = false) -> void:
	if event_label == null:
		return
	event_label.text = str(message)
	if urgent:
		event_label.add_theme_color_override("font_color", Color("#ffb28f"))
	else:
		event_label.add_theme_color_override("font_color", Color("#e8f1ff"))


func play_hero_pass_cutscene(callback: Callable) -> void:
	hide_overlay()
	hero_pass_callback = callback
	if hero_pass_cutscene_layer != null:
		hero_pass_cutscene_layer.queue_free()
		hero_pass_cutscene_layer = null

	hero_pass_cutscene_layer = Control.new()
	hero_pass_cutscene_layer.name = "HeroPassCutscene"
	hero_pass_cutscene_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_pass_cutscene_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_pass_cutscene_layer.z_index = 2000
	root.add_child(hero_pass_cutscene_layer)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 1.0)
	hero_pass_cutscene_layer.add_child(backdrop)

	var loaded_stream: VideoStream = _load_hero_pass_video_stream()
	if loaded_stream == null:
		push_warning("Hero_pass video stream could not be loaded. Continuing without text fallback.")
		_finish_hero_pass_cutscene()
		return

	hero_pass_video_player = VideoStreamPlayer.new()
	hero_pass_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_pass_video_player.expand = true
	hero_pass_video_player.stream = loaded_stream
	hero_pass_cutscene_layer.add_child(hero_pass_video_player)
	hero_pass_video_player.finished.connect(Callable(self, "_finish_hero_pass_cutscene"), CONNECT_ONE_SHOT)
	hero_pass_video_player.play()

func play_commander_killed_cutscene(callback: Callable) -> void:
	play_outcome_cutscene([OUTCOME_FAIL_VIDEO_PATH, OUTCOME_FAIL_OGV_PATH], OUTCOME_WILHELM_AUDIO_PATH, callback)

func play_hero_killed_cutscene(callback: Callable) -> void:
	play_outcome_cutscene([OUTCOME_SUCCESS_VIDEO_PATH, OUTCOME_SUCCESS_OGV_PATH], OUTCOME_TOM_AUDIO_PATH, callback)

func play_outcome_cutscene(video_paths: Array, audio_path: String, callback: Callable) -> void:
	hide_overlay()
	hero_pass_callback = callback
	if hero_pass_cutscene_layer != null:
		hero_pass_cutscene_layer.queue_free()
		hero_pass_cutscene_layer = null

	hero_pass_cutscene_layer = Control.new()
	hero_pass_cutscene_layer.name = "FinalOutcomeCutscene"
	hero_pass_cutscene_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_pass_cutscene_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_pass_cutscene_layer.z_index = 2500
	root.add_child(hero_pass_cutscene_layer)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 1.0)
	hero_pass_cutscene_layer.add_child(backdrop)

	if ResourceLoader.exists(audio_path):
		var loaded_audio: Resource = ResourceLoader.load(audio_path)
		if loaded_audio is AudioStream:
			hero_pass_audio_player = AudioStreamPlayer.new()
			hero_pass_audio_player.stream = loaded_audio as AudioStream
			hero_pass_audio_player.bus = "Master"
			hero_pass_audio_player.volume_db = 0.0
			hero_pass_cutscene_layer.add_child(hero_pass_audio_player)
			hero_pass_audio_player.play()

	var loaded_stream: VideoStream = _load_video_stream_from_paths(video_paths)
	if loaded_stream == null:
		push_warning("Outcome video stream could not be loaded: " + str(video_paths))
		_finish_hero_pass_cutscene()
		return

	hero_pass_video_player = VideoStreamPlayer.new()
	hero_pass_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_pass_video_player.expand = true
	hero_pass_video_player.stream = loaded_stream
	hero_pass_cutscene_layer.add_child(hero_pass_video_player)
	hero_pass_video_player.finished.connect(Callable(self, "_finish_hero_pass_cutscene"), CONNECT_ONE_SHOT)
	hero_pass_video_player.play()

func _load_hero_pass_video_stream() -> VideoStream:
	# Keep the requested MP4 in /assets/videos/Hero_pass.mp4.
	# Godot's built-in player may not decode MP4 on every setup, so the project
	# also includes Hero_pass.ogv converted from the same MP4 and uses it only if
	# the MP4 is not exposed as a playable VideoStream.
	return _load_video_stream_from_paths([HERO_PASS_MP4_PATH, HERO_PASS_OGV_PATH])

func _load_video_stream_from_paths(paths: Array) -> VideoStream:
	for path in paths:
		var stream_path: String = str(path)
		if not ResourceLoader.exists(stream_path):
			continue
		var loaded_resource: Resource = ResourceLoader.load(stream_path)
		if loaded_resource is VideoStream:
			return loaded_resource as VideoStream
	return null

func _finish_hero_pass_cutscene() -> void:
	if hero_pass_video_player != null:
		hero_pass_video_player.stop()
		hero_pass_video_player = null
	if hero_pass_audio_player != null:
		hero_pass_audio_player.stop()
		hero_pass_audio_player = null
	if hero_pass_timer != null:
		hero_pass_timer.stop()
		hero_pass_timer = null
	if hero_pass_cutscene_layer != null:
		hero_pass_cutscene_layer.queue_free()
		hero_pass_cutscene_layer = null
	var callback: Callable = hero_pass_callback
	hero_pass_callback = Callable()
	if callback.is_valid():
		callback.call()

func show_prepare(_hero_stats) -> void:
	if puzzle_board != null and puzzle_board.has_method("reset_board"):
		puzzle_board.reset_board()
	if main != null and main.should_show_deploy_prompt():
		overlay.visible = true
		overlay_title.text = _t("棋盘召唤阶段", "MATCHBOARD PREP")
		overlay_body.text = _t("右侧交换怪物方块，做出三消或更高形状来召唤怪物。\n每次消除=骷髅兵；累计第2/5/8次会追加高级单位。整行与整列清除会额外追加对应魔物，并同时计入累计消除。\n\n第一次成功消除后，勇者会自动入场。", "Swap monster blocks on the right to make 3-matches or stronger shapes and summon your cast.\nEvery clear summons a Skeleton; cumulative clears 2/5/8 add advanced units. Full row and column clears add their own units and also count toward the clear total.\n\nAfter your first successful match, the hero enters automatically.")
		var choices = []
		choices.append({"text": _t("开始消除", "START MATCHING"), "callable": Callable(self, "dismiss_deploy_tutorial")})
		_set_overlay_buttons(choices)
	else:
		overlay.visible = false

func dismiss_deploy_tutorial() -> void:
	if main != null:
		main.mark_deploy_tutorial_seen()
	hide_overlay()

func show_power_choice(rewards, seal_name, boons, time_left = 0.0, transition_room = false) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = false
	overlay_title.text = _t("勇者被击倒：封印反转", "HERO DEFEATED: SEAL REVERSED")
	var flow = _t("选择后勇者在本室复活，倒计时从 %.1f 秒继续。", "After choosing, the hero revives here with %.1f seconds remaining.") % float(time_left)
	if transition_room:
		flow = _t("剩余时间 ≤ 3 秒：选择后进入下一间。", "≤ 3 seconds remained: move to the next room after choosing.")
	overlay_body.text = _t("勇者失去一条命，并解封【%s】。\n\n改写墨水 +%d。\n%s", "The hero loses a life and unlocks [%s].\n\nRewrite Ink +%d.\n%s") % [str(seal_name), int(rewards.get("ink", 0)), flow]
	var choices = []
	for boon in boons:
		choices.append({"text": "%s\n%s" % [main.boon_display_name(boon), main.boon_display_description(boon)], "callable": Callable(main, "choose_temp_boon").bind(str(boon["id"]))})
	_set_overlay_buttons(choices)

func show_normal_room_choice(relic, room_name, boons) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = false
	overlay_title.text = _t("勇者清荡房间", "HERO CLEARED THE ROOM")
	overlay_body.text = _t("勇者在【%s】撑到倒计时结束，带走遗物【%s】并成长。\n\n你选择一件普通道具，写进下一间房。", "The hero survived [%s], carried away [%s], and grew stronger.\n\nChoose one normal item for the next room.") % [str(room_name), str(relic)]
	var choices = []
	for boon in boons:
		choices.append({"text": "%s\n%s" % [main.boon_display_name(boon), main.boon_display_description(boon)], "callable": Callable(main, "choose_temp_boon").bind(str(boon["id"]))})
	_set_overlay_buttons(choices)

func show_hero_escape(relic, room_name, callback) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = true
	overlay_title.text = _t("勇者写完了这一章", "THE HERO WROTE THIS CHAPTER")
	overlay_body.text = _t("勇者在【%s】撑到倒计时结束，带走【%s】。", "The hero survived [%s] and carried away [%s].") % [str(room_name), str(relic)]
	_set_overlay_buttons([{"text": _t("进入下一间", "NEXT ROOM"), "callable": callback}])

func show_game_over(reason, waves_defeated) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = false
	overlay_title.text = _t("挑战失败", "DEFEAT")
	overlay_body.text = "%s\n%s" % [str(reason), _t("完成房间：%d", "Rooms completed: %d") % int(waves_defeated)]
	_set_overlay_buttons([{"text": _t("返回主界面", "BACK TO MAIN MENU"), "callable": Callable(self, "_return_to_main_menu")}])

func show_run_victory(rewards, defeated_lives) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = false
	overlay_title.text = _t("最终胜利", "VICTORY")
	overlay_body.text = _t("勇者的 %d 条命已耗尽。\n最后一击获得改写墨水 +%d。", "The hero's %d lives are gone.\nFinal blow granted +%d Rewrite Ink.") % [int(defeated_lives), int(rewards.get("ink", 0))]
	_set_overlay_buttons([{"text": _t("返回主界面", "BACK TO MAIN MENU"), "callable": Callable(self, "_return_to_main_menu")}])

func show_red_button_options(effects) -> void:
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = true
	overlay_title.text = _t("改写剧本", "REWRITE SCENE")
	overlay_body.text = _t("当前房间的规则被你强行改写。", "You force the current room to follow your script.")
	var choices = []
	for effect in effects:
		choices.append({"text": "%s\n%s" % [main.red_effect_name(effect), main.red_effect_description(effect)], "callable": Callable(main, "choose_red_button").bind(effect.id)})
	_set_overlay_buttons(choices)

func show_duel(duel_data, actions) -> void:
	overlay.visible = true
	overlay_title.text = _t("哥布林弹射决斗", "GOBLIN DUEL")
	overlay_body.text = _t("指挥官生命 %.0f / %.0f\n勇者生命 %.0f / %.0f", "Commander HP %.0f / %.0f\nHero HP %.0f / %.0f") % [float(duel_data.get("goblin_hp", 0.0)), float(duel_data.get("goblin_max_hp", 0.0)), float(duel_data.get("hero_hp", 0.0)), float(duel_data.get("hero_max_hp", 0.0))]
	var choices = []
	for action in actions:
		choices.append({"text": "%s\n%s" % [str(action["name"]), str(action["description"])], "callable": Callable(main, "choose_duel_action").bind(str(action["id"]))})
	_set_overlay_buttons(choices)

func show_dice_choice(boons, _is_power: bool) -> void:
	overlay.visible = true
	overlay_title.text = _t("普通骰子：二选一", "NORMAL DICE: PICK ONE")
	overlay_body.text = _t("命运给出两段可改写的台词。选一段写进本房间。", "Fate offers two rewrite lines. Pick one for this room.")
	var choices = []
	for boon in boons:
		choices.append({"text": "%s\n%s" % [main.boon_display_name(boon), main.boon_display_description(boon)], "callable": Callable(main, "choose_dice_talent").bind(str(boon["id"]))})
	_set_overlay_buttons(choices)

func show_power_dice_result(boon) -> void:
	overlay.visible = true
	overlay_title.text = _t("强力骰子：命运落笔", "POWER DICE: FATE WRITES")
	overlay_body.text = _t("你没有选择它。它选择了你。\n\n%s\n%s", "You did not choose it. It chose you.\n\n%s\n%s") % [main.boon_display_name(boon), main.boon_display_description(boon)]
	_set_overlay_buttons([{"text": _t("接受改写", "ACCEPT REWRITE"), "callable": Callable(self, "hide_overlay")}])

func hide_overlay() -> void:
	if return_menu_popup_active:
		_restore_return_menu_pause_state()
	if overlay != null:
		overlay.visible = false
	_sync_overlay_pause()

func _restore_return_menu_pause_state() -> void:
	return_menu_popup_active = false
	get_tree().paused = return_menu_previous_pause

func _sync_overlay_pause() -> void:
	if puzzle_board != null and puzzle_board.has_method("set_interactive_enabled"):
		var allow_input := true
		if overlay != null and overlay.visible:
			allow_input = false
		if main != null and main.has_method("is_run_finished") and main.is_run_finished():
			allow_input = false
		puzzle_board.set_interactive_enabled(allow_input)

func _build_return_menu_button() -> void:
	# Small top-right HUD icon to return from gameplay to the main menu.
	return_menu_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(42, 42))
	return_menu_button.position = Vector2(1224, 10)
	return_menu_button.tooltip_text = _t("回主画面", "Back to Main Menu")
	return_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	return_menu_button.pressed.connect(_show_return_menu_popup)
	root.add_child(return_menu_button)

	var icon = Label.new()
	icon.text = "↩"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_theme_font_size_override("font_size", 24)
	icon.add_theme_color_override("font_color", Color("#fff0cb"))
	icon.add_theme_color_override("font_outline_color", Color("#05070b"))
	icon.add_theme_constant_override("outline_size", 4)
	return_menu_button.add_child(icon)

func _show_return_menu_popup() -> void:
	if overlay == null:
		return
	if not return_menu_popup_active:
		return_menu_previous_pause = get_tree().paused
	return_menu_popup_active = true
	get_tree().paused = true
	overlay.visible = true
	if overlay_close_button != null:
		overlay_close_button.visible = true
	overlay_title.text = _t("暂停选单", "PAUSE MENU")
	overlay_body.text = _t("游戏已暂停。请选择继续游戏，或返回主界面。", "Game paused. Continue playing, or return to the main menu.")
	_set_overlay_buttons([
		{"text": _t("继续", "CONTINUE"), "callable": Callable(self, "hide_overlay")},
		{"text": _t("返回主界面", "BACK TO MAIN MENU"), "callable": Callable(self, "_show_return_main_confirm")}
	])

func _show_return_main_confirm() -> void:
	if overlay == null:
		return
	return_menu_popup_active = true
	get_tree().paused = true
	if overlay_close_button != null:
		overlay_close_button.visible = true
	overlay_title.text = _t("确认返回主界面？", "RETURN TO MAIN MENU?")
	overlay_body.text = _t("目前这一局会中断，确定要回到主界面吗？", "This run will be interrupted. Are you sure you want to return to the main menu?")
	_set_overlay_buttons([
		{"text": _t("取消", "CANCEL"), "callable": Callable(self, "_show_return_menu_popup")},
		{"text": _t("确定返回", "CONFIRM RETURN"), "callable": Callable(self, "_return_to_main_menu")}
	])

func _return_to_main_menu() -> void:
	if hero_pass_video_player != null:
		hero_pass_video_player.stop()
	if hero_pass_audio_player != null:
		hero_pass_audio_player.stop()
	if hero_pass_timer != null:
		hero_pass_timer.stop()
	hero_pass_callback = Callable()
	return_menu_popup_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _build_hero_intel() -> void:
	# Integrated top HUD: first row shows room/level/chamber/ink only; second row shows HP + long bar + xN bars.
	boss_hp_panel = _make_panel(Vector2(8, 4), Vector2(834, 76), 0.95)
	var margin = _margin(9)
	boss_hp_panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	# Title row uses absolute overlay labels: lives stay pinned left, room info stays truly centered.
	# A single centered HBox would shift the room title whenever the heart count changes.
	var title_row = Control.new()
	title_row.custom_minimum_size = Vector2(808, 22)
	box.add_child(title_row)

	hero_lives_label = _make_label("♥ x5", 16, Color("#ff4d5a"))
	hero_lives_label.position = Vector2(0, -1)
	hero_lives_label.size = Vector2(170, 24)
	hero_lives_label.add_theme_color_override("font_outline_color", Color("#05070b"))
	hero_lives_label.add_theme_constant_override("outline_size", 5)
	hero_lives_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_row.add_child(hero_lives_label)

	boss_hp_label = _make_label("ROOM 1 | Training Chamber | INK 0", 14, Color("#ffe58c"))
	boss_hp_label.position = Vector2(0, -1)
	boss_hp_label.size = Vector2(808, 24)
	boss_hp_label.add_theme_color_override("font_outline_color", Color("#05070b"))
	boss_hp_label.add_theme_constant_override("outline_size", 4)
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(boss_hp_label)

	var hp_row = HBoxContainer.new()
	hp_row.custom_minimum_size = Vector2(808, 26)
	hp_row.add_theme_constant_override("separation", 8)
	box.add_child(hp_row)

	boss_hp_prefix_label = _make_label("HP", 13, Color("#ff6a6a"))
	boss_hp_prefix_label.custom_minimum_size = Vector2(34, 26)
	boss_hp_prefix_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_hp_prefix_label.add_theme_color_override("font_outline_color", Color("#05070b"))
	boss_hp_prefix_label.add_theme_constant_override("outline_size", 4)
	hp_row.add_child(boss_hp_prefix_label)

	var bar_frame = Control.new()
	bar_frame.custom_minimum_size = Vector2(boss_hp_bar_width, 30)
	hp_row.add_child(bar_frame)

	# Original arcade action-RPG inspired boss gauge: stacked colors, bright bevels,
	# delayed damage layer, section teeth, and a moving hit spark.  It is built only
	# with Godot primitives, so no third-party game assets/fonts/icons are copied.
	var outer = ColorRect.new()
	outer.position = Vector2(-4, 2)
	outer.size = Vector2(boss_hp_bar_width + 8, 24)
	outer.color = Color("#060a12")
	bar_frame.add_child(outer)

	var rim_top = ColorRect.new()
	rim_top.position = Vector2(-3, 3)
	rim_top.size = Vector2(boss_hp_bar_width + 6, 2)
	rim_top.color = Color("#fff2a8")
	bar_frame.add_child(rim_top)

	var rim_bottom = ColorRect.new()
	rim_bottom.position = Vector2(-3, 24)
	rim_bottom.size = Vector2(boss_hp_bar_width + 6, 2)
	rim_bottom.color = Color("#6f3b11")
	bar_frame.add_child(rim_bottom)

	var back = ColorRect.new()
	back.position = Vector2(0, 7)
	back.size = Vector2(boss_hp_bar_width, 16)
	back.color = Color("#120916")
	bar_frame.add_child(back)

	# Full-width color behind the active HP fill. When one HP tube is damaged,
	# the exposed part previews the next lower tube color. v10.34 changes
	# the hero display from 3 visual tubes to 10 visual tubes without changing
	# total hero HP or incoming damage.
	boss_hp_next_bar = ColorRect.new()
	boss_hp_next_bar.position = Vector2(0, 7)
	boss_hp_next_bar.size = Vector2(boss_hp_bar_width, 16)
	boss_hp_next_bar.color = _boss_hp_next_background_color(HERO_HP_TUBE_COUNT)
	bar_frame.add_child(boss_hp_next_bar)

	boss_hp_under_layers.clear()
	for i in range(3):
		var layer = ColorRect.new()
		layer.position = Vector2(0, 8 + i * 5)
		layer.size = Vector2(boss_hp_bar_width, 3)
		layer.color = _boss_hp_next_background_color(HERO_HP_TUBE_COUNT).lightened(0.08 * float(i))
		bar_frame.add_child(layer)
		boss_hp_under_layers.append(layer)

	boss_hp_delay_bar = ColorRect.new()
	boss_hp_delay_bar.position = Vector2(0, 7)
	boss_hp_delay_bar.size = Vector2(boss_hp_bar_width, 16)
	boss_hp_delay_bar.color = Color("#ffd36d")
	bar_frame.add_child(boss_hp_delay_bar)

	boss_hp_fill_shadow = ColorRect.new()
	boss_hp_fill_shadow.position = Vector2(0, 18)
	boss_hp_fill_shadow.size = Vector2(boss_hp_bar_width, 5)
	boss_hp_fill_shadow.color = Color("#751d32")
	bar_frame.add_child(boss_hp_fill_shadow)

	boss_hp_fill_bar = ColorRect.new()
	boss_hp_fill_bar.position = Vector2(0, 9)
	boss_hp_fill_bar.size = Vector2(boss_hp_bar_width, 12)
	boss_hp_fill_bar.color = Color("#e34852")
	bar_frame.add_child(boss_hp_fill_bar)

	boss_hp_fill_top = ColorRect.new()
	boss_hp_fill_top.position = Vector2(0, 9)
	boss_hp_fill_top.size = Vector2(boss_hp_bar_width, 3)
	boss_hp_fill_top.color = Color(1.0, 1.0, 1.0, 0.38)
	bar_frame.add_child(boss_hp_fill_top)

	boss_hp_fill_spark = ColorRect.new()
	boss_hp_fill_spark.position = Vector2(boss_hp_bar_width - 4, 6)
	boss_hp_fill_spark.size = Vector2(4, 20)
	boss_hp_fill_spark.color = Color("#fff9d8")
	bar_frame.add_child(boss_hp_fill_spark)

	# v10.35: Keep the hero HP as 10 visual tubes, but do not draw the
	# heavy black 10-way divider lines. This preserves the "more HP loss"
	# feeling while keeping the bar smooth and clean.
	boss_hp_segments.clear()

	boss_hp_tick_marks.clear()
	for i in range(1, 18):
		var tick = ColorRect.new()
		tick.position = Vector2((boss_hp_bar_width / 18.0) * float(i), 11)
		tick.size = Vector2(1, 8)
		tick.color = Color(1.0, 0.92, 0.55, 0.30)
		bar_frame.add_child(tick)
		boss_hp_tick_marks.append(tick)

	boss_hp_tube_label = _make_label("x10", 13, Color("#ffe58c"))
	boss_hp_tube_label.custom_minimum_size = Vector2(34, 26)
	boss_hp_tube_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_hp_tube_label.add_theme_color_override("font_outline_color", Color("#05070b"))
	boss_hp_tube_label.add_theme_constant_override("outline_size", 4)
	hp_row.add_child(boss_hp_tube_label)

func _build_room_header() -> void:
	# Room text is now integrated into the top HUD.
	room_label = null

func _build_resource_header() -> void:
	# Ink text is now integrated into the top HUD; score lives above the Match Board.
	resource_label = null
	population_label = null

func _build_detail_panel() -> void:
	# Unit detail sidebar removed in v10.13 so the battle arena can move left and stay unobstructed.
	detail_panel = null
	detail_portrait = null
	detail_title = null
	detail_role = null
	detail_stats = null
	detail_ability = null

func _build_cast_panel() -> void:
	cast_panel = _make_panel(Vector2(850, 4), Vector2(422, 704), 0.97)
	var margin = _margin(9)
	cast_panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var title = _make_label(_t("消除棋盘", "MATCHBOARD"), 16, Color("#ffd66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	match_score_label = _make_label("SCORE 000000", 24, Color("#ff1f1f"))
	match_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_score_label.add_theme_color_override("font_outline_color", Color("#280000"))
	match_score_label.add_theme_constant_override("outline_size", 8)
	match_score_label.add_theme_color_override("font_shadow_color", Color("#ffd257"))
	match_score_label.add_theme_constant_override("shadow_offset_x", 2)
	match_score_label.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(match_score_label)
	var tip = _make_label(_t("方塊落下或交換，湊線與三消都會觸發召喚。", "Falling blocks and swaps both trigger clears and summons."), 9, Color("#aebbd3"))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tip)
	var timer_holder = VBoxContainer.new()
	timer_holder.custom_minimum_size = Vector2(398, 26)
	timer_holder.add_theme_constant_override("separation", 1)
	box.add_child(timer_holder)
	_add_bar(timer_holder, "timer", Color("#77b8ff"))
	var board_center = CenterContainer.new()
	board_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_center.custom_minimum_size = Vector2(404, 526)
	box.add_child(board_center)
	puzzle_board = PuzzleBoardScene.instantiate()
	puzzle_board.custom_minimum_size = Vector2(389, 548)
	puzzle_board.setup(main, main.audio_manager)
	puzzle_board.summon_requested.connect(Callable(main, "request_puzzle_summon"))
	puzzle_board.reward_requested.connect(Callable(main, "grant_puzzle_rewards"))
	puzzle_board.preview_unit_requested.connect(Callable(main, "preview_puzzle_unit"))
	puzzle_board.board_message_requested.connect(Callable(self, "show_event"))
	if puzzle_board.has_signal("matchboard_started"):
		puzzle_board.matchboard_started.connect(Callable(main, "begin_battle"))
	board_center.add_child(puzzle_board)
	var summon_legend = _make_label(_t("每次消除=骷髅兵 · 累计2=史莱姆+炸弹 · 累计5=弓手+萨满+史莱姆+炸弹", "Every clear=Skeleton · Total 2=Slime+Bomb · Total 5=Archer+Shaman+Slime+Bomb"), 10, Color("#d7e8b3"))
	summon_legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summon_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(summon_legend)
	var special_legend = _make_label(_t("累计8=史莱姆+炸弹+弓手+萨满+食人魔", "Total 8=Slime+Bomb+Archer+Shaman+Ogre"), 10, Color("#f2d39e"))
	special_legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	special_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(special_legend)
	var legend = _make_label(_t("整列=萨满+史莱姆 · 整行=炸弹+食人魔 · 可与累计奖励叠加", "Column=Shaman+Slime · Row=Bomb+Ogre · Stacks with total-clear rewards"), 10, Color("#9ec2d6"))
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(legend)
	if bool(main.debug_show_summon_buttons):
		var debug_title = _make_label(_t("调试召唤面板", "DEBUG SUMMON PANEL"), 11, Color("#d8e8ff"))
		debug_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(debug_title)
		unit_list = VBoxContainer.new()
		unit_list.add_theme_constant_override("separation", 4)
		box.add_child(unit_list)

func _build_bottom_strip() -> void:
	var panel = _make_panel(Vector2(8, 604), Vector2(834, 104), 0.96)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var margin = _margin(10)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var action_box = VBoxContainer.new()
	action_box.custom_minimum_size = Vector2(230, 0)
	action_box.add_theme_constant_override("separation", 3)
	row.add_child(action_box)
	command_label = _make_label("", 13, Color("#caffb7"))
	action_box.add_child(command_label)
	event_label = _make_label("", 11, Color("#e8f1ff"))
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size = Vector2(224, 24)
	action_box.add_child(event_label)
	# Manual SUMMON HERO button removed. Battle now starts from the first successful match.
	start_button = null
	red_button = _make_texture_button(RED_NORMAL, RED_HOVER, RED_PRESSED, RED_DISABLED, Vector2(220, 28))
	_add_button_label(red_button, _t("改写剧本", "REWRITE SCENE"), 14)
	red_button.pressed.connect(Callable(main, "force_red_button"))
	action_box.add_child(red_button)

	var divider = VSeparator.new()
	row.add_child(divider)

	var items_box = VBoxContainer.new()
	items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_box.add_theme_constant_override("separation", 5)
	row.add_child(items_box)
	var item_header = HBoxContainer.new()
	items_box.add_child(item_header)
	var item_title = _make_label(_t("已改写剧本 · 玩家道具", "REWRITTEN SCRIPT · PLAYER ITEMS"), 13, Color("#ffd66f"))
	item_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_header.add_child(item_title)
	skill_tree_button = null
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 58)
	items_box.add_child(scroll)
	item_strip = HBoxContainer.new()
	item_strip.add_theme_constant_override("separation", 7)
	scroll.add_child(item_strip)
	item_summary_label = _make_label("", 12, Color("#9fb4d2"))
	item_strip.add_child(item_summary_label)

func _build_overlay() -> void:
	overlay = _make_panel(Vector2(284, 138), Vector2(712, 406), 0.97)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var margin = _margin(18)
	overlay.add_child(margin)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)
	var overlay_header = HBoxContainer.new()
	overlay_header.add_theme_constant_override("separation", 8)
	box.add_child(overlay_header)
	overlay_title = _make_label("", 23, Color("#ffd66f"))
	overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_header.add_child(overlay_title)
	overlay_close_button = _make_texture_button(PURPLE_NORMAL, PURPLE_HOVER, PURPLE_PRESSED, PURPLE_DISABLED, Vector2(86, 34))
	overlay_close_button.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay_close_button.pressed.connect(Callable(self, "hide_overlay"))
	_add_button_label(overlay_close_button, "CLOSE", 11)
	overlay_header.add_child(overlay_close_button)
	overlay_body = _make_label("", 15, Color("#eef3ff"))
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(overlay_body)
	overlay_buttons = VBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 6)
	box.add_child(overlay_buttons)
	overlay.visible = false

func _make_unit_card(id: String, data, unlocked: bool):
	var button = _make_texture_button(BLUE_NORMAL if unlocked else PURPLE_NORMAL, BLUE_HOVER if unlocked else PURPLE_HOVER, BLUE_PRESSED if unlocked else PURPLE_PRESSED, BLUE_DISABLED if unlocked else PURPLE_DISABLED, Vector2(0, 57))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = _unit_tooltip(id, data, unlocked)
	button.pressed.connect(Callable(self, "_on_unit_card_pressed").bind(id))

	var icon = TextureRect.new()
	icon.position = Vector2(6, 4)
	icon.size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = UNIT_CARD_TEXTURES.get(id, null)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var title = _make_label("", 12, Color("#fff0cc"))
	title.name = "Title"
	title.position = Vector2(60, 6)
	title.size = Vector2(196, 18)
	title.add_theme_color_override("font_outline_color", Color("#0c101a"))
	title.add_theme_constant_override("outline_size", 2)
	button.add_child(title)

	var meta = _make_label("", 10, Color("#d8e8ff"))
	meta.name = "Meta"
	meta.position = Vector2(60, 28)
	meta.size = Vector2(196, 18)
	meta.add_theme_color_override("font_outline_color", Color("#0c101a"))
	meta.add_theme_constant_override("outline_size", 2)
	button.add_child(meta)

	if not unlocked:
		var lock = TextureRect.new()
		lock.position = Vector2(214, 8)
		lock.size = Vector2(32, 32)
		lock.texture = LOCK_TEXTURE
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lock)
	return button

func _on_unit_card_pressed(id: String) -> void:
	if main == null:
		return
	if not main.is_monster_unlocked(id):
		show_event(_t("请回主菜单的技能树解锁该兵种。", "Unlock this unit from the main menu Skill Tree."), true)
		return
	main.select_monster(id)

func _show_skill_tree() -> void:
	if main == null:
		return
	show_event(_t("技能树现在位于主菜单。", "The Skill Tree is now in the main menu."), true)

func _unlock_from_tree(_id: String) -> void:
	_show_skill_tree()

func _upgrade_from_tree(_id: String) -> void:
	_show_skill_tree()

func _purchase_tree_entry(node_id: String) -> void:
	if main == null:
		return
	main.purchase_skill_node(node_id)
	if overlay.visible:
		_show_skill_tree()

func _boss_hp_tube_color(tube_index: int) -> Color:
	match tube_index:
		10:
			return Color("#ff4058")
		9:
			return Color("#ff7a32")
		8:
			return Color("#ffd23f")
		7:
			return Color("#a8f048")
		6:
			return Color("#35e66b")
		5:
			return Color("#2fe6ff")
		4:
			return Color("#2f8dff")
		3:
			return Color("#7657ff")
		2:
			return Color("#a855ff")
		1:
			return Color("#ff55c8")
		_:
			return Color("#ff4058")

func _boss_hp_tube_shadow(tube_index: int) -> Color:
	return _boss_hp_tube_color(tube_index).darkened(0.55)

func _boss_hp_next_background_color(tube_index: int) -> Color:
	var next_tube := tube_index - 1
	if next_tube >= 1:
		return _boss_hp_tube_color(next_tube).darkened(0.18)
	return Color("#120916")

func _update_hero_intel() -> void:
	if main == null or main.hero == null:
		return
	var hp_ratio: float = clamp(float(main.hero.hp_ratio()), 0.0, 1.0)
	var max_hp: float = max(1.0, float(main.hero.max_hp))
	var hp_value: float = clamp(float(main.hero.hp), 0.0, max_hp)
	var tube_count := HERO_HP_TUBE_COUNT
	var scaled_hp := hp_ratio * float(tube_count)
	var tube := int(ceil(scaled_hp))
	tube = clamp(tube, 1, tube_count)
	var low_text := "  WARNING!" if hp_ratio <= 0.25 else ""
	var warning_flash: bool = hp_ratio <= 0.25 and int(Time.get_ticks_msec() / 180) % 2 == 0
	if hero_lives_label != null:
		var lives_count: int = 0
		if main != null:
			lives_count = int(main.hero_lives_remaining)
		if lives_count < 0:
			lives_count = 0
		var hearts: String = ""
		for _i in range(lives_count):
			hearts += "♥"
		if hearts == "":
			hearts = "♥"
		hero_lives_label.text = "%s x%d" % [hearts, lives_count]
		hero_lives_label.add_theme_color_override("font_color", Color("#ff6060") if warning_flash else Color("#ff4d5a"))
	if boss_hp_label != null:
		boss_hp_label.text = "ROOM %d | %s | INK %d%s" % [main.map_index + 1, main.map_director.room_name(main.current_language()), int(main.rewrite_ink), low_text]
		boss_hp_label.add_theme_color_override("font_color", Color("#ff6060") if warning_flash else Color("#ffe58c"))
	if boss_hp_tube_label != null:
		boss_hp_tube_label.text = "x%d" % tube
		boss_hp_tube_label.add_theme_color_override("font_color", Color("#ff6060") if hp_ratio <= 0.25 and int(Time.get_ticks_msec() / 180) % 2 == 0 else Color("#ffe58c"))
	if hp_ratio < boss_hp_last_ratio - 0.002:
		boss_hp_flash_timer = 0.28
		boss_hp_shake_timer = 0.22
		if tube < boss_hp_last_tube and main.combat_system != null:
			main.combat_system.spawn_floating_text(main.hero.global_position + Vector2(0, -72), "HP BAR BROKEN!", Color("#ffcf55"), true)
	boss_hp_last_tube = tube
	boss_hp_last_ratio = hp_ratio
	boss_hp_delay_ratio = max(hp_ratio, lerp(boss_hp_delay_ratio, hp_ratio, 0.055))
	var width := boss_hp_bar_width
	var local_ratio := scaled_hp - float(tube - 1)
	if hp_ratio <= 0.0:
		local_ratio = 0.0
	elif hp_ratio >= 0.999:
		local_ratio = 1.0
	local_ratio = clamp(local_ratio, 0.0, 1.0)
	var delay_scaled := boss_hp_delay_ratio * float(tube_count)
	var delay_tube := int(ceil(delay_scaled))
	delay_tube = clamp(delay_tube, 1, tube_count)
	var delay_local := delay_scaled - float(delay_tube - 1)
	if boss_hp_delay_ratio <= 0.0:
		delay_local = 0.0
	elif boss_hp_delay_ratio >= 0.999:
		delay_local = 1.0
	delay_local = clamp(delay_local, 0.0, 1.0)
	var fill_width := width * local_ratio
	var tube_color := _boss_hp_tube_color(tube)
	var next_background_color := _boss_hp_next_background_color(tube)
	if boss_hp_next_bar != null:
		boss_hp_next_bar.color = next_background_color
	if boss_hp_delay_bar != null:
		var delay_width := width * delay_local
		# Show only the delayed-damage tail, not a full strip from zero; this keeps
		# the depleted area readable as the next HP tube color.
		boss_hp_delay_bar.position.x = fill_width
		boss_hp_delay_bar.size.x = max(0.0, delay_width - fill_width)
		boss_hp_delay_bar.color = Color(1.0, 0.82, 0.25, 0.42)
	if boss_hp_fill_bar != null:
		boss_hp_fill_bar.size.x = fill_width
		var c := tube_color
		if hp_ratio <= 0.25:
			c = Color("#ff3030") if int(Time.get_ticks_msec() / 120) % 2 == 0 else Color("#ff9e3b")
		elif boss_hp_flash_timer > 0.0:
			c = Color("#fff6ba")
		boss_hp_fill_bar.color = c
	if boss_hp_fill_shadow != null:
		boss_hp_fill_shadow.size.x = fill_width
		boss_hp_fill_shadow.color = _boss_hp_tube_shadow(tube)
	if boss_hp_fill_top != null:
		boss_hp_fill_top.size.x = fill_width
		boss_hp_fill_top.color = Color(1.0, 1.0, 1.0, 0.52 if boss_hp_flash_timer > 0.0 else 0.30)
	if boss_hp_fill_spark != null:
		boss_hp_fill_spark.visible = fill_width > 8.0
		boss_hp_fill_spark.position.x = max(0.0, fill_width - 3.0)
		boss_hp_fill_spark.color = Color("#fff9d8") if boss_hp_flash_timer > 0.0 else tube_color.lightened(0.45)
	for i in range(boss_hp_under_layers.size()):
		var under = boss_hp_under_layers[i]
		under.color = next_background_color.lightened(0.08 * float(i))
	if boss_hp_panel != null:
		if boss_hp_shake_timer > 0.0:
			var shake := sin(float(Time.get_ticks_msec()) * 0.08) * 3.0
			boss_hp_panel.position = Vector2(8 + shake, 4)
		else:
			boss_hp_panel.position = Vector2(8, 4)

func _update_room_header() -> void:
	# Timer bar remains above Match Board; room information is in the integrated top HUD.
	_update_bar("timer", main.room_time_remaining, 50.0, "")

func _update_resource_header() -> void:
	var live_score: int = int(main.current_score())
	if match_score_label != null:
		match_score_label.text = _t("得分 %06d", "SCORE %06d") % live_score
		var flash := int(Time.get_ticks_msec() / 160) % 2 == 0
		match_score_label.add_theme_color_override("font_color", Color("#ff2020") if flash else Color("#ff5a3d"))
	if last_display_score >= 0 and live_score > last_display_score:
		var gained := live_score - last_display_score
		score_pulse_timer = 0.34
		if score_flash_label != null:
			score_flash_label.text = "+%d" % gained
			score_flash_label.visible = true
			score_flash_label.modulate = Color(1, 1, 1, 1)
			score_flash_label.position = Vector2(178, 28)
			score_flash_timer = 0.70
	last_display_score = live_score

func _update_unit_detail() -> void:
	if detail_panel == null or main == null:
		return
	var id = selected_monster_id
	if id == "" or not main.monster_catalog.has(id):
		detail_panel.visible = false
		return
	detail_panel.visible = true
	var data = main.monster_catalog[id]
	detail_portrait.texture = UNIT_CARD_TEXTURES.get(id, null)
	detail_title.text = main.monster_display_name(id)
	detail_role.text = _unit_role(data)
	detail_stats.text = _t("生命 %.0f\n攻击 %.1f · 攻速 %.2f\n射程 %.0f · 人口 %d", "HP %.0f\nATK %.1f · SPD %.2f\nRANGE %.0f · SLOTS %d") % [data.hp_with_level(), data.attack_with_level(), data.attack_speed, data.attack_range, data.population_cost]
	detail_ability.text = _ability_text(data.ability) + "\n" + _t("死亡后立即返还演员位。", "Its Cast Slot returns immediately on death.")

func _update_command_area() -> void:
	if main.is_final_room():
		command_label.text = _t("守卫塔 · 全场鼓舞", "GUARDIAN TOWER · GLOBAL INSPIRE")
	else:
		command_label.text = _t("剧本控制台 · 即时写入", "SCRIPT CONSOLE · INSTANT WRITE")
	if main.phase == "prepare":
		var name = main.monster_display_name(main.selected_monster_id) if main.monster_catalog.has(main.selected_monster_id) else "-"
		if event_label.text == "" or event_label.text.begins_with("已选") or event_label.text.begins_with("Selected"):
			event_label.text = _t("已选：%s · 准备阶段可预部署", "Selected: %s · predeploy before summoning") % name
	if start_button != null:
		start_button.visible = false
	red_button.visible = main.phase == "battle" and not overlay.visible
	red_button.disabled = main.phase != "battle" or not main.map_director.can_rewrite_scene()
	_set_button_text(red_button, _t("改写剧本", "REWRITE SCENE"))

func _refresh_cast_states() -> void:
	if main == null:
		return
	for id in unit_buttons.keys():
		var button = unit_buttons[id]
		if button == null:
			continue
		var data = main.monster_catalog[id]
		var unlocked = main.is_monster_unlocked(id)
		var cooldown = main.summon_cooldown_remaining(id)
		var able = unlocked and main.is_monster_available_this_wave(id) and main.population_free() >= int(data.population_cost) and (main.phase == "prepare" or cooldown <= 0.0)
		button.disabled = not unlocked or not main.is_monster_available_this_wave(id) or (main.phase == "battle" and cooldown > 0.0)
		button.modulate = Color(1.16, 1.12, 0.72, 1.0) if id == selected_monster_id else (Color.WHITE if able else Color(0.68, 0.68, 0.72, 0.90))
		var title = button.get_node_or_null("Title")
		var meta = button.get_node_or_null("Meta")
		if title != null:
			title.text = main.monster_display_name(id)
		if meta != null:
			if not unlocked:
				meta.text = _t("技能树解锁", "UNLOCK IN TREE")
			elif not main.is_monster_available_this_wave(id):
				meta.text = _t("训练后开放", "AFTER TUTORIAL")
			elif cooldown > 0.0 and main.phase == "battle":
				meta.text = _t("冷却 %.1f 秒", "COOLDOWN %.1f s") % cooldown
			elif main.population_free() < int(data.population_cost):
				meta.text = _t("人口不足 · 需要 %d", "NO SLOTS · NEED %d") % int(data.population_cost)
			else:
				meta.text = _t("人口 %d · CD %.1fs", "SLOTS %d · CD %.1fs") % [int(data.population_cost), float(data.summon_cooldown)]

func _refresh_item_strip() -> void:
	if item_strip == null or main == null:
		return
	for child in item_strip.get_children():
		child.queue_free()
	if main.active_boons.is_empty():
		item_summary_label = _make_label(_t("尚未获得道具。普通 / 强力天赋会显示在这里。", "No player items yet. Normal and power talents will appear here."), 12, Color("#9fb4d2"))
		item_strip.add_child(item_summary_label)
		return
	var counts = {}
	for boon_id in main.active_boons:
		counts[boon_id] = int(counts.get(boon_id, 0)) + 1
	for boon_id in counts.keys():
		var item = _make_item_chip(str(boon_id), int(counts[boon_id]))
		item_strip.add_child(item)

func _make_item_chip(boon_id: String, count: int):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(128, 64)
	panel.add_theme_stylebox_override("panel", _compact_style(Color(0.12, 0.10, 0.23, 0.95), Color("#ad8cff")))
	panel.tooltip_text = _boon_tooltip(boon_id, count)
	var label = _make_label(_boon_short_name(boon_id) + (" ×%d" % count if count > 1 else ""), 11, Color("#f4e7ff"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel

func _boon_short_name(boon_id: String) -> String:
	var info = _find_boon(boon_id)
	if info.is_empty():
		return boon_id
	return main.boon_display_name(info)

func _boon_tooltip(boon_id: String, count: int) -> String:
	var info = _find_boon(boon_id)
	if info.is_empty():
		return boon_id
	var suffix = ""
	if count > 1:
		suffix = _t("\n叠加：%d", "\nStacks: %d") % count
	return main.boon_display_name(info) + "\n" + main.boon_display_description(info) + suffix

func _find_boon(boon_id: String) -> Dictionary:
	if main == null:
		return {}
	var all_boons = []
	all_boons.append_array(main.balance.create_temp_boons())
	all_boons.append_array(main.balance.create_power_boons())
	for info in all_boons:
		if str(info.get("id", "")) == boon_id:
			return info
	return {}

func _unit_tooltip(id: String, data, unlocked: bool) -> String:
	if not unlocked:
		return _t("%s\n回主菜单技能树解锁。", "%s\nUnlock from the main menu Skill Tree.") % main.monster_display_name(id)
	return "%s\n%s\n%s" % [main.monster_display_name(id), _unit_role(data), _ability_text(data.ability)]

func _unit_role(data) -> String:
	if data == null:
		return ""
	match str(data.ability):
		"slow":
			return _t("定位：控制坦克", "ROLE: CONTROL TANK")
		"arrow":
			return _t("定位：远程标记", "ROLE: RANGED MARKER")
		"suicide":
			return _t("定位：自爆爆发", "ROLE: SUICIDE BURST")
		"ritual_heal":
			return _t("定位：异常辅助", "ROLE: STATUS SUPPORT")
		"armor_breaker":
			return _t("定位：重装破甲", "ROLE: HEAVY ARMOR BREAK")
		_:
			return _t("定位：廉价近战", "ROLE: CHEAP MELEE")

func _ability_text(ability) -> String:
	match str(ability):
		"slow":
			return _t("减速勇者；免疫击退；池中下一击 +10。", "Slows the hero; knockback immune; +10 next hit in pools.")
		"arrow":
			return _t("每第三箭为标记箭，可必中虚无勇者。", "Every third arrow is marked and bypasses Void.")
		"suicide":
			return _t("接近勇者或撞墙时直接引爆。", "Explodes near the hero or on wall contact.")
		"ritual_heal":
			return _t("命中后治疗命中点附近、且在自身射程内的友军。", "On hit, heals allies near impact and inside the shaman's range.")
		"armor_breaker":
			return _t("命中后吸血；吞噬低血友军，继承最近三种特性。", "Lifesteals; devours low-HP allies and keeps up to three traits.")
		_:
			return _t("近战围攻；多名单位可推动勇者。", "Melee swarm; several units can push the hero.")

func _set_overlay_buttons(button_defs) -> void:
	for child in overlay_buttons.get_children():
		child.queue_free()
	for button_def in button_defs:
		var raw_text := str(button_def.get("text", ""))
		var button_text := raw_text
		var tooltip := str(button_def.get("tooltip", ""))
		if raw_text.find("\n") >= 0:
			var parts := raw_text.split("\n", false, 1)
			button_text = str(parts[0])
			if tooltip == "" and parts.size() > 1:
				tooltip = str(parts[1])
		var button = _make_texture_button(BLUE_NORMAL, BLUE_HOVER, BLUE_PRESSED, BLUE_DISABLED, Vector2(0, 42))
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = tooltip
		_add_button_label(button, button_text, 14)
		button.pressed.connect(button_def["callable"])
		overlay_buttons.add_child(button)
	_sync_overlay_pause()

func _make_panel(position_value: Vector2, panel_size: Vector2, alpha_value: float):
	var panel = PanelContainer.new()
	panel.position = position_value
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.05, 0.10, alpha_value)))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(panel)
	return panel

func _make_texture_button(normal_texture, hover_texture, pressed_texture, disabled_texture, button_size: Vector2):
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
	if main != null and main.audio_manager != null:
		button.pressed.connect(func(): main.audio_manager.play_sfx("select"))
	return button

func _add_button_label(button, label_text: String, font_size: int) -> void:
	var label = _make_label(label_text, font_size, Color("#fff0cc"))
	label.name = "Text"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 10
	label.offset_right = -10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#0a0d14"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.button_down.connect(Callable(self, "_nudge_button_text").bind(label, true))
	button.button_up.connect(Callable(self, "_nudge_button_text").bind(label, false))

func _set_button_text(button, value: String) -> void:
	if button == null:
		return
	var label = button.get_node_or_null("Text")
	if label != null:
		label.text = value

func _nudge_button_text(label, pressed: bool) -> void:
	if label == null:
		return
	label.position = Vector2(0, 2) if pressed else Vector2.ZERO

func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _add_bar(parent, id: String, color: Color) -> void:
	var holder = VBoxContainer.new()
	holder.add_theme_constant_override("separation", 1)
	parent.add_child(holder)
	var label = _make_label("", 10, Color("#dce8ff"))
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var background = StyleBoxFlat.new()
	background.bg_color = Color("#0a1017")
	background.border_color = Color("#607185")
	background.set_border_width_all(1)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

	if id == "timer":
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		holder.add_child(row)
		var clock = _make_label("⏱", 18, Color("#ffdf76"))
		clock.custom_minimum_size = Vector2(24, 18)
		clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(clock)
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		label.visible = false
	else:
		holder.add_child(label)
		holder.add_child(bar)
	bars[id] = {"label": label, "bar": bar}

func _update_bar(id: String, value: float, maximum: float, label_text: String) -> void:
	if not bars.has(id):
		return
	var bar: ProgressBar = bars[id]["bar"] as ProgressBar
	var label: Label = bars[id]["label"] as Label
	var safe_max: float = maxf(1.0, maximum)
	bar.max_value = safe_max
	bar.value = clampf(value, 0.0, safe_max)
	if id == "timer":
		var ratio: float = clampf(value / safe_max, 0.0, 1.0)
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		if ratio <= 0.20 and int(Time.get_ticks_msec() / 180) % 2 == 0:
			fill.bg_color = Color("#ff2020")
		elif ratio <= 0.20:
			fill.bg_color = Color("#ff8a35")
		else:
			fill.bg_color = Color("#77b8ff")
		bar.add_theme_stylebox_override("fill", fill)
	if label.visible:
		label.text = "%s %.0f / %.0f" % [label_text, maxf(0.0, value), safe_max]

func _margin(value: int):
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin

func _panel_style(fill_color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("#d89b2b")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 3)
	return style

func _compact_style(fill_color: Color, border: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _t(zh: String, en: String) -> String:
	if main != null and main.has_method("current_language") and main.current_language() == "en":
		return en
	return zh
