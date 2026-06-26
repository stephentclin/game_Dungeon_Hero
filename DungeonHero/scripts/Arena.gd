extends Node2D
class_name Arena

const VIEWPORT_SIZE = Vector2(1280, 720)
const ARENA_RECT = Rect2(Vector2(18, 118), Vector2(824, 476))
const BACKGROUND_PATH = "res://assets/backgrounds/dungeon_arena.png"

var background_texture: Texture2D
var main = null
var fire_time := 0.0

func setup(owner) -> void:
	main = owner
	set_process(true)
	queue_redraw()

func _loc(zh: String, en: String) -> String:
	if main != null and main.has_method("loc"):
		return main.loc(zh, en)
	return zh

func _ready() -> void:
	z_as_relative = false
	z_index = -100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_texture = load(BACKGROUND_PATH) as Texture2D
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	fire_time += delta
	queue_redraw()

func _draw() -> void:
	# The battle itself is deliberately smaller and centred, leaving the edges for
	# information panels rather than hiding the cast under UI.
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("#070b10"), true)
	if background_texture != null:
		draw_texture_rect(background_texture, ARENA_RECT, false)
	else:
		_draw_fallback_background()
	_draw_animated_campfires()
	draw_rect(ARENA_RECT.grow(3), Color(0.03, 0.06, 0.10, 0.94), false, 4.0)
	draw_rect(ARENA_RECT, Color(0.76, 0.54, 0.20, 0.50), false, 1.0)

func _draw_animated_campfires() -> void:
	# Smaller animated torches with flowing flame effects on every decorative fire point.
	# Kept near the arena edges so they do not cover units or UI.
	var points := [
		Vector2(78, 162),
		Vector2(792, 162),
		Vector2(78, 552),
		Vector2(792, 552),
		Vector2(428, 140),
		Vector2(428, 572)
	]
	for i in range(points.size()):
		_draw_torch(points[i], float(i) * 0.73)

func _draw_torch(pos: Vector2, phase_offset: float) -> void:
	var t := fire_time * 9.0 + phase_offset
	var flicker := 0.5 + 0.5 * sin(t)
	var flicker2 := 0.5 + 0.5 * sin(t * 1.47 + 1.9)
	var sway := sin(t * 0.78) * 2.2
	# Small warm light aura, intentionally much smaller than the previous bonfire.
	draw_circle(pos + Vector2(0, -12), 18.0 + flicker * 3.0, Color(1.0, 0.36, 0.05, 0.07 + 0.04 * flicker))
	draw_circle(pos + Vector2(0, -12), 9.0 + flicker2 * 2.0, Color(1.0, 0.82, 0.20, 0.10))
	# Torch holder / bracket.
	draw_line(pos + Vector2(0, 20), pos + Vector2(0, -4), Color(0.30, 0.18, 0.09, 0.95), 5.0)
	draw_line(pos + Vector2(-7, 10), pos + Vector2(7, 3), Color(0.47, 0.27, 0.12, 0.95), 4.0)
	draw_line(pos + Vector2(-5, -2), pos + Vector2(5, -2), Color(0.86, 0.55, 0.22, 0.85), 2.0)
	# Flowing flame layers.
	var outer := PackedVector2Array([
		pos + Vector2(-8, -2),
		pos + Vector2(-4 + sway * 0.4, -16 - flicker * 4.0),
		pos + Vector2(1 + sway, -30 - flicker2 * 5.0),
		pos + Vector2(5 + sway * 0.25, -15 - flicker * 3.0),
		pos + Vector2(8, -2)
	])
	draw_colored_polygon(outer, Color(1.0, 0.25, 0.03, 0.88))
	var inner := PackedVector2Array([
		pos + Vector2(-5, -2),
		pos + Vector2(-2 - sway * 0.15, -12 - flicker2 * 3.5),
		pos + Vector2(2 - sway * 0.25, -23 - flicker * 4.0),
		pos + Vector2(5, -2)
	])
	draw_colored_polygon(inner, Color(1.0, 0.72, 0.16, 0.94))
	var core := PackedVector2Array([
		pos + Vector2(-2.5, -3),
		pos + Vector2(0.5 + sway * 0.15, -15 - flicker * 3.0),
		pos + Vector2(3.0, -3)
	])
	draw_colored_polygon(core, Color(1.0, 0.96, 0.55, 0.92))
	# Tiny rising embers for every torch.
	for e in range(3):
		var et := fposmod(fire_time * (0.62 + 0.14 * e) + phase_offset + e * 0.33, 1.0)
		var ember_pos := pos + Vector2(sin(t + e * 1.8) * (4.5 + e * 1.5), -6.0 - et * 30.0)
		draw_circle(ember_pos, 0.9 + (1.0 - et) * 0.8, Color(1.0, 0.62, 0.14, 0.58 * (1.0 - et)))

func _draw_fallback_background() -> void:
	# Whole screen: dark, slightly blue-black background.
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("#0b1113"), true)

	# Arena floor: layered rectangles give the field a clearer “place” feeling.
	draw_rect(ARENA_RECT.grow(8), Color(0.02, 0.05, 0.05, 0.68), true)
	draw_rect(ARENA_RECT, Color("#172522"), true)
	draw_rect(ARENA_RECT, Color("#426851"), false, 4.0)
	draw_rect(ARENA_RECT.grow(-10), Color(0.12, 0.22, 0.18, 0.24), false, 2.0)

	# Subtle grid, useful for placement without turning the map into graph paper.
	for x in range(int(ARENA_RECT.position.x) + 12, int(ARENA_RECT.end.x), 48):
		draw_line(Vector2(x, ARENA_RECT.position.y + 8), Vector2(x, ARENA_RECT.end.y - 8), Color(0.25, 0.38, 0.31, 0.22), 1.0)
	for y in range(int(ARENA_RECT.position.y) + 12, int(ARENA_RECT.end.y), 48):
		draw_line(Vector2(ARENA_RECT.position.x + 8, y), Vector2(ARENA_RECT.end.x - 8, y), Color(0.25, 0.38, 0.31, 0.22), 1.0)

	# Fixed floor details make the arena feel less empty while staying gameplay-neutral.
	for stone in [
		Vector2(92, 164), Vector2(178, 522), Vector2(270, 198),
		Vector2(600, 130), Vector2(726, 510), Vector2(878, 306),
		Vector2(548, 568), Vector2(112, 408)
	]:
		draw_circle(stone, 5.0, Color(0.27, 0.36, 0.31, 0.44))
		draw_circle(stone + Vector2(2, -1), 2.0, Color(0.42, 0.52, 0.43, 0.28))

	# Directional story language: hero enters from the north, commander is protected below.
	draw_rect(Rect2(Vector2(384, 68), Vector2(216, 28)), Color(0.44, 0.16, 0.12, 0.35), true)
	draw_string(ThemeDB.fallback_font, Vector2(410, 88), _loc("勇者来袭方向", "HERO ENTRY"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f3b28f"))
	draw_rect(Rect2(Vector2(278, 556), Vector2(428, 78)), Color(0.13, 0.29, 0.20, 0.42), true)
	draw_rect(Rect2(Vector2(278, 556), Vector2(428, 78)), Color(0.34, 0.84, 0.48, 0.48), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(417, 610), _loc("哥布林指挥台防线", "GOBLIN COMMAND LINE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b9f3a7"))

	# A tiny in-world legend. Environmental rules are visible before the player walks into them.
	var legend = Rect2(Vector2(54, 474), Vector2(206, 104))
	draw_rect(legend, Color(0.03, 0.07, 0.07, 0.82), true)
	draw_rect(legend, Color(0.34, 0.58, 0.42, 0.55), false, 1.0)
	draw_circle(Vector2(72, 493), 7.0, Color("#db741f"))
	draw_string(ThemeDB.fallback_font, Vector2(86, 498), _loc("油桶：碰触引爆", "BARREL: CONTACT EXPLODES"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f1ddb4"))
	draw_circle(Vector2(72, 516), 8.0, Color(0.68, 0.96, 0.24, 0.58))
	draw_string(ThemeDB.fallback_font, Vector2(86, 521), _loc("毒池：双方受伤", "POISON: HURTS BOTH SIDES"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d5ff9e"))
	draw_circle(Vector2(72, 539), 8.0, Color(0.30, 0.78, 1.0, 0.58))
	draw_string(ThemeDB.fallback_font, Vector2(86, 544), _loc("泥潭：双方减速", "BOG: SLOWS BOTH SIDES"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b6e6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(68, 566), _loc("史莱姆：池中 +10 攻击 / 每秒回血", "SLIME: +10 ATK / REGEN IN POOLS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#baffce"))
