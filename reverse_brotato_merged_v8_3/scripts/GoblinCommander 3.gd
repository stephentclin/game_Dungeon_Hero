extends Node2D
class_name GoblinCommander

signal died()

const PLATFORM_TEXTURES = [
	preload("res://assets/commander/goblin_platform/platform_1.png"),
	preload("res://assets/commander/goblin_platform/platform_2.png"),
	preload("res://assets/commander/goblin_platform/platform_1.png")
]
const PLATFORM_BROKEN_TEXTURE_PATH = "res://assets/commander/goblin_platform/platform_broken.png"
const PLATFORM_HIT_TEXTURE_PATH = "res://assets/commander/goblin_platform/platform_hit.png"
const CHIEF_IDLE_TEXTURES = [
	preload("res://assets/commander/goblin_chief/chief_idle_1.png"),
	preload("res://assets/commander/goblin_chief/chief_idle_2.png"),
	preload("res://assets/commander/goblin_chief/chief_idle_1.png")
]
const CHIEF_CAST_TEXTURE = preload("res://assets/commander/goblin_chief/chief_cast.png")
const PLATFORM_IDLE_FPS = 4.2
const PLATFORM_DRAW_RECT = Rect2(Vector2(-88, -176), Vector2(176, 256))
const PLATFORM_HIT_DURATION = 0.18
const CHIEF_IDLE_FPS = 4.8
const CHIEF_CAST_DURATION = 0.26
const CHIEF_IDLE_DRAW_RECT = Rect2(Vector2(-58, -106), Vector2(116, 116))
const CHIEF_CAST_DRAW_RECT = Rect2(Vector2(-64, -112), Vector2(128, 128))

var main: Node
var max_hp = 180.0
var hp = 180.0
var idle_cycle_time = 0.0
var cast_pose_time = 0.0
var platform_hit_time = 0.0

func setup(world_position: Vector2, max_health: float, owner: Node) -> void:
	global_position = world_position
	max_hp = max_health
	hp = max_hp
	main = owner
	visible = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	idle_cycle_time = 0.0
	cast_pose_time = 0.0
	platform_hit_time = 0.0
	set_process(true)
	queue_redraw()

func reset_health() -> void:
	hp = max_hp
	idle_cycle_time = 0.0
	cast_pose_time = 0.0
	platform_hit_time = 0.0
	queue_redraw()

func trigger_summon_cast() -> void:
	cast_pose_time = CHIEF_CAST_DURATION
	queue_redraw()

func take_damage(amount: float, source = null) -> void:
	hp = max(0.0, hp - amount)
	platform_hit_time = PLATFORM_HIT_DURATION
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-24, -54), "-%d" % int(amount), Color(1.0, 0.42, 0.34), amount >= 20.0)
		main.rage_system.add(amount * 0.12)
	queue_redraw()
	if hp <= 0.0:
		died.emit()

func hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return hp / max_hp

func _process(delta: float) -> void:
	idle_cycle_time += delta
	cast_pose_time = max(0.0, cast_pose_time - delta)
	platform_hit_time = max(0.0, platform_hit_time - delta)
	queue_redraw()

func _draw() -> void:
	# Friendly headquarters: deliberately large and distinctive, not another anonymous rectangle.
	draw_circle(Vector2(0, 20), 69.0, Color(0.10, 0.54, 0.23, 0.13))
	draw_arc(Vector2(0, 20), 69.0, 0.0, TAU, 36, Color(0.36, 0.98, 0.48, 0.78), 2.5)

	var platform = _platform_texture()
	if platform != null:
		draw_texture_rect(platform, PLATFORM_DRAW_RECT, false)

	var texture = _chief_texture()
	if texture != null:
		var rect = CHIEF_CAST_DRAW_RECT if cast_pose_time > 0.0 else CHIEF_IDLE_DRAW_RECT
		draw_texture_rect(texture, rect, false)
	else:
		draw_circle(Vector2(9, -17), 22.0, Color("#58cf58"))
		draw_circle(Vector2(9, -27), 15.0, Color("#8dec79"))
		draw_circle(Vector2(3, -27), 2.0, Color("#173421"))
		draw_circle(Vector2(15, -27), 2.0, Color("#173421"))
		draw_line(Vector2(-1, -16), Vector2(18, -16), Color("#214d2b"), 2.0)
		draw_circle(Vector2(29, -14), 7.0, Color("#f1d06b"))

	draw_string(ThemeDB.fallback_font, Vector2(-42, -84), "你的指挥台", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#caffb7"))
	draw_rect(Rect2(Vector2(-64, -101), Vector2(128, 8)), Color("#17311e"), true)
	draw_rect(Rect2(Vector2(-64, -101), Vector2(128 * hp_ratio(), 8)), Color("#58dd68"), true)

func _chief_texture() -> Texture2D:
	if cast_pose_time > 0.0:
		return CHIEF_CAST_TEXTURE
	if CHIEF_IDLE_TEXTURES.is_empty():
		return null
	var frame = int(floor(idle_cycle_time * CHIEF_IDLE_FPS)) % CHIEF_IDLE_TEXTURES.size()
	return CHIEF_IDLE_TEXTURES[frame]

func _platform_texture() -> Texture2D:
	if platform_hit_time > 0.0:
		return load(PLATFORM_HIT_TEXTURE_PATH) as Texture2D
	if hp_ratio() < 0.5:
		return load(PLATFORM_BROKEN_TEXTURE_PATH) as Texture2D
	if PLATFORM_TEXTURES.is_empty():
		return null
	var frame = int(floor(idle_cycle_time * PLATFORM_IDLE_FPS)) % PLATFORM_TEXTURES.size()
	return PLATFORM_TEXTURES[frame]
