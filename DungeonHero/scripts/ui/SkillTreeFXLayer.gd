extends Control
class_name SkillTreeFXLayer

var accent_color := Color("#7b1fff")
var grid_color := Color(0.45, 0.95, 1.0, 0.08)
var rune_color := Color(1.0, 0.15, 0.25, 0.10)
var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#05070d"))
	draw_rect(rect, Color(0.10, 0.0, 0.02, 0.62))
	var vignette_steps := 9
	for i in range(vignette_steps):
		var t := float(i) / float(vignette_steps)
		var inset := t * 46.0
		var alpha := 0.05 + t * 0.045
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0)), Color(0, 0, 0, alpha), false, 18.0 - t * 12.0)

	var spacing := 38.0
	var offset := fmod(time * 7.0, spacing)
	var x := -spacing + offset
	while x < size.x + spacing:
		draw_line(Vector2(x, 0), Vector2(x + size.y * 0.22, size.y), grid_color, 1.0)
		x += spacing
	var y := -spacing + offset
	while y < size.y + spacing:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color.darkened(0.15), 1.0)
		y += spacing

	for i in range(18):
		var px := fmod(float(i * 137) + time * (8.0 + float(i % 5)), max(1.0, size.x))
		var py := fmod(float(i * 79) + sin(time * 0.45 + float(i)) * 18.0 + 31.0, max(1.0, size.y))
		var alpha := 0.11 + 0.08 * sin(time * 1.7 + float(i))
		draw_circle(Vector2(px, py), 1.5 + float(i % 3), Color(accent_color.r, accent_color.g, accent_color.b, alpha))

	var center := size * 0.5
	for r in [72.0, 126.0, 196.0, 268.0]:
		draw_arc(center, r, time * 0.10, TAU + time * 0.10, 96, rune_color, 1.5, true)
	for i in range(10):
		var angle := time * 0.18 + float(i) * TAU / 10.0
		var p := center + Vector2(cos(angle), sin(angle)) * (110.0 + float(i % 4) * 42.0)
		draw_line(p - Vector2(8, 0), p + Vector2(8, 0), rune_color.lightened(0.35), 1.5)
		draw_line(p - Vector2(0, 8), p + Vector2(0, 8), rune_color.lightened(0.35), 1.5)
