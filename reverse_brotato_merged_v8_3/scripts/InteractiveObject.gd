extends Node2D
class_name InteractiveObject

signal destroyed(obj)

const BARREL_IDLE_TEXTURE_PATH = "res://assets/interactives/barrel/barrel_idle.png"
const BARREL_ARMED_TEXTURE_PATH = "res://assets/interactives/barrel/barrel_armed.png"
const BARREL_EXPLOSION_TEXTURE_PATH = "res://assets/interactives/barrel/barrel_explosion.png"
const BARREL_ASH_TEXTURE_PATH = "res://assets/interactives/barrel/barrel_ash.png"
const POISON_POOL_TEXTURE_PATHS = [
	"res://assets/interactives/poison_pool/poison_pool_idle_1.png",
	"res://assets/interactives/poison_pool/poison_pool_idle_2.png",
	"res://assets/interactives/poison_pool/poison_pool_idle_3.png",
	"res://assets/interactives/poison_pool/poison_pool_idle_1.png"
]
const SLOW_POOL_IDLE_TEXTURE_PATHS = [
	"res://assets/interactives/slow_pool/slow_pool_idle_1.png",
	"res://assets/interactives/slow_pool/slow_pool_idle_2.png",
	"res://assets/interactives/slow_pool/slow_pool_idle_3.png",
	"res://assets/interactives/slow_pool/slow_pool_idle_1.png"
]
const SLOW_POOL_TRIGGER_TEXTURE_PATHS = [
	"res://assets/interactives/slow_pool/slow_pool_trigger_1.png",
	"res://assets/interactives/slow_pool/slow_pool_trigger_2.png",
	"res://assets/interactives/slow_pool/slow_pool_trigger_1.png"
]

const BARREL_STATE_IDLE = 0
const BARREL_STATE_IGNITED = 1
const BARREL_STATE_EXPLODING = 2
const BARREL_STATE_ASH = 3

const BARREL_FUSE_DURATION = 1.1
const BARREL_TOUCH_FUSE_DURATION = 0.7
const BARREL_EXPLOSION_DURATION = 0.24
const BARREL_ASH_DURATION = 2.8
const POISON_POOL_IDLE_FPS = 4.8
const SLOW_POOL_IDLE_FPS = 4.8
const SLOW_POOL_TRIGGER_FPS = 7.5

var kind = ""
var hp = 1.0
var max_hp = 1.0
var radius = 28.0
var active = true
var main: Node
var barrel_state = BARREL_STATE_IDLE
var barrel_timer = 0.0
var barrel_idle_texture: Texture2D
var barrel_armed_texture: Texture2D
var barrel_explosion_texture: Texture2D
var barrel_ash_texture: Texture2D
var poison_pool_textures: Array[Texture2D] = []
var poison_pool_cycle_time = 0.0
var slow_pool_idle_textures: Array[Texture2D] = []
var slow_pool_trigger_textures: Array[Texture2D] = []
var slow_pool_cycle_time = 0.0

func setup(object_kind: String, world_position: Vector2, owner: Node) -> void:
	kind = object_kind
	main = owner
	global_position = world_position
	active = true
	visible = true
	z_as_relative = false
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match kind:
		"barrel":
			max_hp = 28.0
			radius = 24.0
			barrel_state = BARREL_STATE_IDLE
			barrel_timer = 0.0
			barrel_idle_texture = load(BARREL_IDLE_TEXTURE_PATH) as Texture2D
			barrel_armed_texture = load(BARREL_ARMED_TEXTURE_PATH) as Texture2D
			barrel_explosion_texture = load(BARREL_EXPLOSION_TEXTURE_PATH) as Texture2D
			barrel_ash_texture = load(BARREL_ASH_TEXTURE_PATH) as Texture2D
		"poison_pool":
			max_hp = 9999.0
			radius = 52.0
			poison_pool_cycle_time = 0.0
			poison_pool_textures = _load_texture_sequence(POISON_POOL_TEXTURE_PATHS)
		"slow_pool":
			max_hp = 9999.0
			radius = 54.0
			slow_pool_cycle_time = 0.0
			slow_pool_idle_textures = _load_texture_sequence(SLOW_POOL_IDLE_TEXTURE_PATHS)
			slow_pool_trigger_textures = _load_texture_sequence(SLOW_POOL_TRIGGER_TEXTURE_PATHS)
		"obstacle":
			max_hp = 64.0
			radius = 34.0
		_:
			max_hp = 20.0
			radius = 24.0
	hp = max_hp
	set_process(kind == "barrel" or kind == "poison_pool" or kind == "slow_pool")
	set_physics_process(kind == "barrel")
	queue_redraw()

func take_damage(amount: float, source = null) -> void:
	if not active or kind == "poison_pool" or kind == "slow_pool":
		return
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-12, -30), "-%d" % int(amount), Color(1.0, 0.86, 0.54))
	if kind == "barrel":
		ignite()
		queue_redraw()
		return
	hp -= amount
	if hp <= 0.0:
		_remove_from_scene()
	queue_redraw()

func expire() -> void:
	if not active:
		return
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-22, -24), "地形消散", Color(0.72, 0.86, 0.72))
	_remove_from_scene()

func explode() -> void:
	if kind == "barrel":
		_explode_barrel()
		return
	_remove_from_scene()

func ignite(fuse_override := -1.0) -> void:
	if not active or kind != "barrel":
		return
	if barrel_state == BARREL_STATE_EXPLODING or barrel_state == BARREL_STATE_ASH:
		return
	if barrel_state == BARREL_STATE_IDLE and main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-22, -42), "点燃", Color(1.0, 0.42, 0.26), true)
	barrel_state = BARREL_STATE_IGNITED
	var fuse_time = BARREL_FUSE_DURATION if fuse_override < 0.0 else fuse_override
	barrel_timer = fuse_time if barrel_timer <= 0.0 else min(barrel_timer, fuse_time)
	queue_redraw()

func _explode_barrel() -> void:
	if kind != "barrel" or barrel_state == BARREL_STATE_EXPLODING or barrel_state == BARREL_STATE_ASH:
		return
	active = false
	barrel_state = BARREL_STATE_EXPLODING
	barrel_timer = BARREL_EXPLOSION_DURATION
	set_physics_process(false)
	if main != null:
		var hero_multiplier = main.get_barrel_bomber_multiplier(global_position)
		var tags = {
			"armor_bonus": 10.0,
			"source": "barrel",
			"hero_damage_multiplier": hero_multiplier
		}
		main.combat_system.spawn_explosion(global_position, 104.0, 34.0, 0.4, tags)
		if hero_multiplier > 1.0:
			main.combat_system.spawn_floating_text(global_position + Vector2(-45, -44), "自爆联动 x%d" % int(hero_multiplier), Color(1.0, 0.72, 0.22), true)
	destroyed.emit(self)
	queue_redraw()

func _begin_barrel_ash() -> void:
	barrel_state = BARREL_STATE_ASH
	barrel_timer = BARREL_ASH_DURATION
	queue_redraw()

func _remove_from_scene() -> void:
	if not active and not (kind == "barrel" and barrel_state == BARREL_STATE_ASH):
		return
	active = false
	visible = false
	set_physics_process(false)
	set_process(false)
	if kind != "barrel" or barrel_state != BARREL_STATE_ASH:
		destroyed.emit(self)
	queue_free()

func _process(delta: float) -> void:
	if kind == "barrel":
		match barrel_state:
			BARREL_STATE_IGNITED:
				barrel_timer = max(0.0, barrel_timer - delta)
				if barrel_timer <= 0.0:
					_explode_barrel()
				queue_redraw()
			BARREL_STATE_EXPLODING:
				barrel_timer = max(0.0, barrel_timer - delta)
				if barrel_timer <= 0.0:
					_begin_barrel_ash()
				queue_redraw()
			BARREL_STATE_ASH:
				barrel_timer = max(0.0, barrel_timer - delta)
				if barrel_timer <= 0.0:
					_remove_from_scene()
				queue_redraw()
	elif kind == "slow_pool":
		slow_pool_cycle_time += delta
		queue_redraw()
	elif kind == "poison_pool":
		poison_pool_cycle_time += delta
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if not active or main == null:
		return
	if kind == "barrel" and barrel_state != BARREL_STATE_EXPLODING and barrel_state != BARREL_STATE_ASH:
		_check_barrel_touch()

func _check_barrel_touch() -> void:
	if main.hero != null and main.hero.active:
		var hero_radius = main.hero.collision_size() if main.hero.has_method("collision_size") else 22.0
		if global_position.distance_to(main.hero.global_position) <= radius + hero_radius:
			ignite(BARREL_TOUCH_FUSE_DURATION)
			return
	for monster in main.get_active_monsters():
		var monster_radius = monster.collision_size() if monster.has_method("collision_size") else 16.0
		if global_position.distance_to(monster.global_position) <= radius + monster_radius:
			ignite(BARREL_TOUCH_FUSE_DURATION)
			return

func _draw() -> void:
	if not active and not (kind == "barrel" and barrel_state >= BARREL_STATE_EXPLODING):
		return
	match kind:
		"barrel":
			_draw_barrel()
		"poison_pool":
			_draw_poison_pool()
		"slow_pool":
			_draw_slow_pool()
		"obstacle":
			_draw_crate()
		_:
			draw_circle(Vector2.ZERO, radius, Color("#888888"))

func _draw_barrel() -> void:
	match barrel_state:
		BARREL_STATE_IDLE:
			draw_circle(Vector2(0, 18), 19.0, Color(0.01, 0.02, 0.02, 0.34))
			_draw_barrel_texture(barrel_idle_texture, Vector2(92, 92), Vector2(0, -4))
		BARREL_STATE_IGNITED:
			var pulse = 0.84 + 0.16 * sin((BARREL_FUSE_DURATION - barrel_timer) * 18.0)
			draw_circle(Vector2(0, 18), 21.0, Color(0.28, 0.02, 0.02, 0.28 + pulse * 0.08))
			_draw_barrel_texture(barrel_armed_texture, Vector2(94, 94), Vector2(0, -4), Color(1.0, 1.0, 1.0, pulse))
		BARREL_STATE_EXPLODING:
			_draw_barrel_texture(barrel_explosion_texture, Vector2(136, 136), Vector2(0, -10))
		BARREL_STATE_ASH:
			var ash_alpha = clamp(barrel_timer / BARREL_ASH_DURATION, 0.22, 1.0)
			draw_circle(Vector2(0, 18), 18.0, Color(0.01, 0.02, 0.02, 0.18 * ash_alpha))
			_draw_barrel_texture(barrel_ash_texture, Vector2(104, 104), Vector2(0, 14), Color(1.0, 1.0, 1.0, ash_alpha))

func _draw_barrel_texture(texture: Texture2D, size: Vector2, offset: Vector2, modulate := Color.WHITE) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(offset - size * 0.5, size), false, modulate)

func _draw_poison_pool() -> void:
	var texture = _poison_pool_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2(-62, -62), Vector2(124, 124)), false)
	else:
		draw_circle(Vector2(0, 4), radius, Color(0.36, 0.72, 0.12, 0.18))
		draw_circle(Vector2(-15, -4), radius * 0.50, Color(0.64, 0.96, 0.22, 0.20))
		draw_circle(Vector2(18, 10), radius * 0.38, Color(0.80, 1.0, 0.34, 0.14))
		draw_arc(Vector2(0, 4), radius * 0.82, 0.0, TAU, 32, Color(0.68, 1.0, 0.28, 0.82), 2.2)
	draw_string(ThemeDB.fallback_font, Vector2(-23, radius + 23), "毒池", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d5ff9e"))

func _draw_slow_pool() -> void:
	var texture = _slow_pool_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2(-62, -62), Vector2(124, 124)), false)
	else:
		draw_circle(Vector2(0, 4), radius, Color(0.10, 0.54, 0.92, 0.15))
		draw_circle(Vector2(-17, -4), radius * 0.50, Color(0.25, 0.72, 1.0, 0.16))
		draw_circle(Vector2(16, 10), radius * 0.40, Color(0.38, 0.84, 1.0, 0.13))
		draw_arc(Vector2(0, 4), radius * 0.82, 0.0, TAU, 32, Color(0.40, 0.82, 1.0, 0.72), 2.2)
	draw_string(ThemeDB.fallback_font, Vector2(-31, radius + 23), "拖慢泥潭", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#b6e6ff"))

func _draw_crate() -> void:
	draw_rect(Rect2(Vector2(-radius, -radius * 0.70), Vector2(radius * 2.0, radius * 1.40)), Color("#5a4632"), true)
	draw_rect(Rect2(Vector2(-radius, -radius * 0.70), Vector2(radius * 2.0, radius * 1.40)), Color("#e2bb6b"), false, 2.5)
	draw_line(Vector2(-radius + 6, -radius * 0.58), Vector2(radius - 6, radius * 0.58), Color("#8d6b42"), 3.0)
	draw_line(Vector2(radius - 6, -radius * 0.58), Vector2(-radius + 6, radius * 0.58), Color("#8d6b42"), 3.0)
	var hp_ratio = clamp(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-radius, -radius - 11), Vector2(radius * 2.0, 4)), Color("#2e241a"), true)
	draw_rect(Rect2(Vector2(-radius, -radius - 11), Vector2(radius * 2.0 * hp_ratio, 4)), Color("#f0b562"), true)
	draw_string(ThemeDB.fallback_font, Vector2(-23, radius + 24), "路障", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffe5ac"))

func _load_texture_sequence(paths: Array) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		var texture = load(path) as Texture2D
		if texture != null:
			textures.append(texture)
	return textures

func _slow_pool_texture() -> Texture2D:
	var textures = slow_pool_trigger_textures if _slow_pool_is_triggered() else slow_pool_idle_textures
	if textures.is_empty():
		return null
	var fps = SLOW_POOL_TRIGGER_FPS if _slow_pool_is_triggered() else SLOW_POOL_IDLE_FPS
	var frame = int(floor(slow_pool_cycle_time * fps)) % textures.size()
	return textures[frame]

func _poison_pool_texture() -> Texture2D:
	if poison_pool_textures.is_empty():
		return null
	var frame = int(floor(poison_pool_cycle_time * POISON_POOL_IDLE_FPS)) % poison_pool_textures.size()
	return poison_pool_textures[frame]

func _slow_pool_is_triggered() -> bool:
	if main == null:
		return false
	if main.hero != null and main.hero.active and global_position.distance_to(main.hero.global_position) <= radius + 10.0:
		return true
	for monster in main.get_active_monsters():
		if global_position.distance_to(monster.global_position) <= radius + 8.0:
			return true
	return false
