extends Node2D
class_name MapDirector

# One arena, five rule-sets. The scenery remains familiar while the room itself
# changes how both sides read the same battlefield.
const ARENA_RECT = Rect2(Vector2(38, 62), Vector2(908, 610))
const ROOM_DURATION = 90.0

const ROOMS = [
	{
		"id": "poison",
		"name_zh": "毒雾孢子室",
		"name_en": "Spore Fog Chamber",
		"subtitle_zh": "毒雾会改写路线；史莱姆把它当作补给。",
		"subtitle_en": "Fog rewrites routes; slimes turn it into fuel.",
		"relic_zh": "孢子核心",
		"relic_en": "Spore Core"
	},
	{
		"id": "dark",
		"name_zh": "无光档案室",
		"name_en": "Lightless Archive",
		"subtitle_zh": "你看见全场，勇者只能追逐自己看见的目标。",
		"subtitle_en": "You see all. The hero can only chase what the lantern reveals.",
		"relic_zh": "失落灯笼",
		"relic_en": "Lost Lantern"
	},
	{
		"id": "light",
		"name_zh": "日耀审判室",
		"name_en": "Sunlit Tribunal",
		"subtitle_zh": "光束里攻击更快且必中，但所有人都会曝晒。",
		"subtitle_en": "The beam grants speed and sure hits, but burns everyone inside.",
		"relic_zh": "审判棱镜",
		"relic_en": "Judgement Prism"
	},
	{
		"id": "mirror",
		"name_zh": "镜像审判厅",
		"name_en": "Mirror Tribunal",
		"subtitle_zh": "预警结束后，战场左右翻转。",
		"subtitle_en": "After the warning, the battlefield flips left to right.",
		"relic_zh": "反写镜片",
		"relic_en": "Reversal Lens"
	},
	{
		"id": "gravity",
		"name_zh": "逆重力铸炉",
		"name_en": "Inverse Gravity Forge",
		"subtitle_zh": "先吸向中央，再把所有人推向外墙。",
		"subtitle_en": "First pull to the core, then throw everyone to the walls.",
		"relic_zh": "反重力炉心",
		"relic_en": "Inverse Core"
	}
]

var main = null
var room_index = 0
var room_elapsed = 0.0
var room_duration = ROOM_DURATION
var milestone_60_done = false
var milestone_30_done = false
var rewrite_used = false
var fog_reversed = false
var lantern_pulse_time = 0.0
var lantern_cycle_time = 0.0
var light_x = 360.0
var light_direction = 1.0
var eclipse_time = 0.0
var mirror_warning_time = 0.0
var mirror_waiting = false
var gravity_cycle_time = 0.0
var gravity_pulse_time = 0.0
var last_notice = ""

func setup(owner) -> void:
	main = owner
	z_index = -5
	queue_redraw()

func start_room(index: int) -> void:
	room_index = index % ROOMS.size()
	room_elapsed = 0.0
	room_duration = ROOM_DURATION
	milestone_60_done = false
	milestone_30_done = false
	rewrite_used = false
	fog_reversed = false
	lantern_pulse_time = 0.0
	lantern_cycle_time = 0.0
	light_x = 360.0
	light_direction = 1.0
	eclipse_time = 0.0
	mirror_warning_time = 0.0
	mirror_waiting = false
	gravity_cycle_time = 0.0
	gravity_pulse_time = 0.0
	last_notice = ""
	queue_redraw()

func process_room(delta: float) -> void:
	room_elapsed += delta
	var room_id = current_id()
	if room_id == "dark":
		lantern_cycle_time += delta
		if lantern_cycle_time >= 12.0:
			lantern_cycle_time = 0.0
			lantern_pulse_time = 2.5
			_notice("勇者灯笼扫光！", "Hero lantern sweep!")
		lantern_pulse_time = max(0.0, lantern_pulse_time - delta)
	elif room_id == "light":
		light_x += light_direction * 160.0 * delta
		if light_x < ARENA_RECT.position.x + 54.0:
			light_x = ARENA_RECT.position.x + 54.0
			light_direction = 1.0
		if light_x > ARENA_RECT.end.x - 54.0:
			light_x = ARENA_RECT.end.x - 54.0
			light_direction = -1.0
		eclipse_time = max(0.0, eclipse_time - delta)
	elif room_id == "mirror":
		if mirror_waiting:
			mirror_warning_time -= delta
			if mirror_warning_time <= 0.0:
				mirror_waiting = false
				if main != null and main.has_method("mirror_combatants"):
					main.mirror_combatants()
				_notice("镜像重置！", "Mirror reset!")
	elif room_id == "gravity":
		gravity_cycle_time += delta
		if gravity_cycle_time >= 12.0:
			gravity_cycle_time = 0.0
			trigger_gravity_pulse()
		_process_gravity(delta)

	var time_left = get_time_left()
	if not milestone_60_done and time_left <= 60.0:
		milestone_60_done = true
		_trigger_milestone(60)
	if not milestone_30_done and time_left <= 30.0:
		milestone_30_done = true
		_trigger_milestone(30)
	queue_redraw()

func get_time_left() -> float:
	return max(0.0, room_duration - room_elapsed)

func room_count() -> int:
	return ROOMS.size()

func current_room() -> Dictionary:
	return ROOMS[room_index]

func current_id() -> String:
	return str(current_room().get("id", "poison"))

func room_name(language: String) -> String:
	var room = current_room()
	if language == "en":
		return str(room.get("name_en", "Room"))
	return str(room.get("name_zh", "房间"))

func room_subtitle(language: String) -> String:
	var room = current_room()
	if language == "en":
		return str(room.get("subtitle_en", ""))
	return str(room.get("subtitle_zh", ""))

func current_relic(language: String) -> String:
	var room = current_room()
	if language == "en":
		return str(room.get("relic_en", "Relic"))
	return str(room.get("relic_zh", "遗物"))

func can_rewrite_scene() -> bool:
	return room_elapsed >= 8.0 and not rewrite_used

func rewrite_scene() -> bool:
	if not can_rewrite_scene():
		return false
	rewrite_used = true
	match current_id():
		"poison":
			fog_reversed = not fog_reversed
			_notice("剧本改写：毒雾倒灌勇者路线。", "Script rewritten: fog reverses the hero route.")
		"dark":
			lantern_pulse_time = 0.0
			lantern_cycle_time = -7.0
			_notice("剧本改写：勇者灯笼熄灭。", "Script rewritten: the hero lantern goes out.")
		"light":
			eclipse_time = 5.0
			_notice("剧本改写：短暂日蚀，光束失效。", "Script rewritten: a short eclipse disables the beam.")
		"mirror":
			_schedule_mirror(1.0)
			_notice("剧本改写：镜面提前开启。", "Script rewritten: mirror activates early.")
		"gravity":
			trigger_gravity_pulse()
			_notice("剧本改写：重力炉心过载。", "Script rewritten: the gravity core overloads.")
	queue_redraw()
	return true

func hero_can_see(point: Vector2) -> bool:
	if current_id() != "dark" or main == null or main.hero == null:
		return true
	var radius = 190.0
	if lantern_pulse_time > 0.0:
		radius = 430.0
	return main.hero.global_position.distance_to(point) <= radius

func is_in_light(point: Vector2) -> bool:
	if current_id() != "light" or eclipse_time > 0.0:
		return false
	return abs(point.x - light_x) <= 58.0 and ARENA_RECT.has_point(point)

func get_environment_effects(point: Vector2) -> Dictionary:
	var result = {"poison": false, "poison_dps": 0.0, "light": false, "light_burn": 0.0}
	if current_id() == "poison" and _in_poison_fog(point):
		result["poison"] = true
		result["poison_dps"] = 5.0
	if is_in_light(point):
		result["light"] = true
		result["light_burn"] = 2.0
	return result

func _in_poison_fog(point: Vector2) -> bool:
	var left_center = Vector2(260.0, 360.0)
	var right_center = Vector2(720.0, 340.0)
	if fog_reversed:
		left_center = Vector2(720.0, 360.0)
		right_center = Vector2(260.0, 340.0)
	var left_hit = point.distance_to(left_center) < 150.0
	var right_hit = point.distance_to(right_center) < 132.0
	return left_hit or right_hit

func _trigger_milestone(seconds: int) -> void:
	match current_id():
		"poison":
			fog_reversed = not fog_reversed
			_notice("%d 秒反转：毒雾换向。" % seconds, "%d-second rewrite: fog changes direction." % seconds)
		"dark":
			lantern_pulse_time = 0.0
			lantern_cycle_time = -4.0 if seconds == 60 else -7.0
			_notice("%d 秒反转：火把熄灭。" % seconds, "%d-second rewrite: torches fade." % seconds)
		"light":
			light_direction *= -1.0
			if seconds == 30:
				eclipse_time = 2.5
			_notice("%d 秒反转：日耀轨迹改变。" % seconds, "%d-second rewrite: sun path shifts." % seconds)
		"mirror":
			_schedule_mirror(2.0 if seconds == 60 else 1.2)
			_notice("%d 秒反转：镜像预警。" % seconds, "%d-second rewrite: mirror warning." % seconds)
		"gravity":
			trigger_gravity_pulse()
			_notice("%d 秒反转：重力脉冲。" % seconds, "%d-second rewrite: gravity pulse." % seconds)

func _schedule_mirror(delay: float) -> void:
	mirror_waiting = true
	mirror_warning_time = max(mirror_warning_time, delay)

func trigger_gravity_pulse() -> void:
	gravity_pulse_time = 3.2
	_notice("重力脉冲：先吸引，再弹开！", "Gravity pulse: pull, then throw!")

func _process_gravity(delta: float) -> void:
	if current_id() != "gravity" or gravity_pulse_time <= 0.0 or main == null:
		return
	gravity_pulse_time -= delta
	var pull_phase = gravity_pulse_time > 1.0
	var center = ARENA_RECT.get_center()
	for body in main.get_map_bodies():
		if body == null or not is_instance_valid(body):
			continue
		var direction = center - body.global_position
		if not pull_phase:
			direction = -direction
		if body.has_method("apply_map_impulse"):
			body.apply_map_impulse(direction, 960.0 * delta)

func _notice(zh: String, en: String) -> void:
	if main == null or main.ui == null:
		return
	var message = zh
	if main.has_method("current_language") and main.current_language() == "en":
		message = en
	if message != last_notice:
		last_notice = message
		main.ui.show_event(message, true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if main == null:
		return
	match current_id():
		"poison":
			_draw_poison_room()
		"dark":
			_draw_dark_room()
		"light":
			_draw_light_room()
		"mirror":
			_draw_mirror_room()
		"gravity":
			_draw_gravity_room()
	_draw_room_title()

func _draw_room_title() -> void:
	var lang = "zh"
	if main != null and main.has_method("current_language"):
		lang = main.current_language()
	var title = room_name(lang)
	var subtitle = room_subtitle(lang)
	draw_rect(Rect2(Vector2(54, 138), Vector2(360, 42)), Color(0.015, 0.03, 0.07, 0.72), true)
	draw_rect(Rect2(Vector2(54, 138), Vector2(360, 42)), Color(0.74, 0.84, 1.0, 0.34), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(66, 156), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f0d98c"))
	draw_string(ThemeDB.fallback_font, Vector2(66, 173), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#dce8ff"))

func _draw_poison_room() -> void:
	var a = Vector2(260.0, 360.0)
	var b = Vector2(720.0, 340.0)
	if fog_reversed:
		a = Vector2(720.0, 360.0)
		b = Vector2(260.0, 340.0)
	for radius in [150.0, 112.0, 72.0]:
		draw_circle(a, radius, Color(0.45, 0.96, 0.16, 0.035))
		draw_circle(b, radius * 0.92, Color(0.45, 0.96, 0.16, 0.030))
	draw_arc(a, 150.0, 0.0, TAU, 32, Color(0.55, 1.0, 0.30, 0.35), 1.2)
	draw_arc(b, 132.0, 0.0, TAU, 32, Color(0.55, 1.0, 0.30, 0.30), 1.2)

func _draw_dark_room() -> void:
	draw_rect(ARENA_RECT, Color(0.0, 0.0, 0.03, 0.48), true)
	if main != null and main.hero != null:
		var sight = 190.0
		if lantern_pulse_time > 0.0:
			sight = 430.0
		draw_circle(main.hero.global_position, sight, Color(1.0, 0.83, 0.42, 0.07))
		draw_arc(main.hero.global_position, sight, 0.0, TAU, 36, Color(1.0, 0.83, 0.42, 0.42), 1.0)

func _draw_light_room() -> void:
	if eclipse_time > 0.0:
		draw_rect(ARENA_RECT, Color(0.02, 0.03, 0.12, 0.46), true)
		draw_string(ThemeDB.fallback_font, Vector2(light_x - 26.0, 206), "日蚀", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b8c7ff"))
		return
	var beam = Rect2(Vector2(light_x - 58.0, ARENA_RECT.position.y), Vector2(116.0, ARENA_RECT.size.y))
	draw_rect(beam, Color(1.0, 0.82, 0.32, 0.14), true)
	draw_line(Vector2(light_x - 58.0, ARENA_RECT.position.y), Vector2(light_x - 58.0, ARENA_RECT.end.y), Color(1.0, 0.88, 0.48, 0.54), 1.5)
	draw_line(Vector2(light_x + 58.0, ARENA_RECT.position.y), Vector2(light_x + 58.0, ARENA_RECT.end.y), Color(1.0, 0.88, 0.48, 0.54), 1.5)

func _draw_mirror_room() -> void:
	var x = ARENA_RECT.get_center().x
	draw_line(Vector2(x, ARENA_RECT.position.y + 12.0), Vector2(x, ARENA_RECT.end.y - 12.0), Color(0.72, 0.62, 1.0, 0.70), 3.0)
	for y in range(int(ARENA_RECT.position.y + 36), int(ARENA_RECT.end.y - 10), 48):
		draw_line(Vector2(x - 20.0, float(y)), Vector2(x + 20.0, float(y)), Color(0.75, 0.78, 1.0, 0.38), 1.0)
	if mirror_waiting:
		draw_rect(ARENA_RECT, Color(0.72, 0.62, 1.0, 0.10), true)
		draw_string(ThemeDB.fallback_font, Vector2(x - 74.0, 212.0), "镜像即将翻转", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#eadfff"))

func _draw_gravity_room() -> void:
	var center = ARENA_RECT.get_center()
	for radius in [58.0, 104.0, 150.0]:
		draw_arc(center, radius, 0.0, TAU, 36, Color(0.32, 0.78, 1.0, 0.24), 1.2)
	if gravity_pulse_time > 0.0:
		draw_circle(center, 94.0, Color(0.38, 0.85, 1.0, 0.09))
		var label = "吸引" if gravity_pulse_time > 1.0 else "反推"
		draw_string(ThemeDB.fallback_font, center + Vector2(-20.0, -112.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#bcecff"))
