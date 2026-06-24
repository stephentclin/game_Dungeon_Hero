extends Node2D
class_name Arena

const VIEWPORT_SIZE = Vector2(1280, 720)
const ARENA_RECT = Rect2(Vector2(38, 62), Vector2(908, 610))
const BACKGROUND_PATH = "res://assets/backgrounds/dungeon_arena.png"

var background_texture: Texture2D

func _ready() -> void:
	z_as_relative = false
	z_index = -100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_texture = load(BACKGROUND_PATH) as Texture2D
	queue_redraw()

func _draw() -> void:
	if background_texture != null:
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, VIEWPORT_SIZE), false)
		return
	_draw_fallback_background()

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
	draw_string(ThemeDB.fallback_font, Vector2(410, 88), "勇者来袭方向", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f3b28f"))
	draw_rect(Rect2(Vector2(278, 556), Vector2(428, 78)), Color(0.13, 0.29, 0.20, 0.42), true)
	draw_rect(Rect2(Vector2(278, 556), Vector2(428, 78)), Color(0.34, 0.84, 0.48, 0.48), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(417, 610), "哥布林指挥台防线", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b9f3a7"))

	# A tiny in-world legend. Environmental rules are visible before the player walks into them.
	var legend = Rect2(Vector2(54, 474), Vector2(206, 104))
	draw_rect(legend, Color(0.03, 0.07, 0.07, 0.82), true)
	draw_rect(legend, Color(0.34, 0.58, 0.42, 0.55), false, 1.0)
	draw_circle(Vector2(72, 493), 7.0, Color("#db741f"))
	draw_string(ThemeDB.fallback_font, Vector2(86, 498), "油桶：碰触引爆", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f1ddb4"))
	draw_circle(Vector2(72, 516), 8.0, Color(0.68, 0.96, 0.24, 0.58))
	draw_string(ThemeDB.fallback_font, Vector2(86, 521), "毒池：双方受伤", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d5ff9e"))
	draw_circle(Vector2(72, 539), 8.0, Color(0.30, 0.78, 1.0, 0.58))
	draw_string(ThemeDB.fallback_font, Vector2(86, 544), "泥潭：双方减速", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b6e6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(68, 566), "史莱姆：池中 +10 攻击 / 每秒回血", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#baffce"))
