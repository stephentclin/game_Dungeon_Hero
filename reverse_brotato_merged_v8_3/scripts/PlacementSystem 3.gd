extends Node2D
class_name PlacementSystem

# The arena is the visual battlefield. DEPLOY_RECT is the part that is actually clickable.
# Keeping them separate prevents the UI from pretending that covered areas are deployable.
const ARENA_RECT = Rect2(Vector2(38, 62), Vector2(908, 610))
const DEPLOY_RECT = Rect2(Vector2(48, 154), Vector2(894, 420))
const HERO_BLOCK_RADIUS = 96.0
const TOP_UI_RECT = Rect2(Vector2(10, 10), Vector2(628, 132))
const RIGHT_UI_RECT = Rect2(Vector2(968, 10), Vector2(300, 538))
const ACTION_UI_RECT = Rect2(Vector2(10, 598), Vector2(936, 110))
const OVERLAY_RECT = Rect2(Vector2(312, 164), Vector2(560, 360))

var main: Node
var selected_monster_id = ""
var enabled = true

func setup(owner: Node) -> void:
	main = owner
	set_process_input(true)
	queue_redraw()

func set_selected(monster_id: String) -> void:
	selected_monster_id = monster_id
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if main.phase != "prepare" and main.phase != "battle":
			return
		if selected_monster_id == "":
			return
		var point = event.position
		if _ui_blocks_point(point):
			return
		if can_place_at(point):
			main.request_place_monster(selected_monster_id, point)
			get_viewport().set_input_as_handled()
		elif ARENA_RECT.has_point(point):
			main.ui.show_event(block_reason(point), true)
			get_viewport().set_input_as_handled()

func can_place_at(point: Vector2) -> bool:
	return block_reason(point) == ""

func block_reason(point: Vector2) -> String:
	if _ui_blocks_point(point):
		return "界面区域不能部署怪物。"
	if not ARENA_RECT.has_point(point):
		return "只能在竞技场地图内部署怪物。"
	if not DEPLOY_RECT.has_point(point):
		return "请放进绿色部署区，不要压住上方状态栏或下方指挥台。"
	if main != null and main.hero != null:
		if point.distance_to(main.hero.global_position) < HERO_BLOCK_RADIUS:
			return "离勇者太近，换个位置部署。"
	return ""

func _ui_blocks_point(point: Vector2) -> bool:
	if TOP_UI_RECT.has_point(point) or RIGHT_UI_RECT.has_point(point) or ACTION_UI_RECT.has_point(point):
		return true
	if main != null and main.ui != null and main.ui.overlay != null and main.ui.overlay.visible:
		return OVERLAY_RECT.has_point(point)
	return false

func _draw() -> void:
	if selected_monster_id == "":
		return

	# The bright frame is now the exact rectangle where deployment works.
	draw_rect(DEPLOY_RECT, Color(0.24, 0.98, 0.44, 0.10), true)
	draw_rect(DEPLOY_RECT.grow(-4), Color(0.24, 0.98, 0.44, 0.70), false, 2.4)
	draw_string(ThemeDB.fallback_font, Vector2(64, 176), "绿色部署区", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#baffb6"))

	if main != null and main.hero != null:
		draw_circle(main.hero.global_position, HERO_BLOCK_RADIUS, Color(1.0, 0.14, 0.09, 0.08))
		draw_arc(main.hero.global_position, HERO_BLOCK_RADIUS, 0.0, TAU, 48, Color(1.0, 0.30, 0.20, 0.88), 2.8)
		draw_string(ThemeDB.fallback_font, main.hero.global_position + Vector2(-28, 116), "禁区", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffb1a1"))

	var mouse = get_global_mouse_position()
	var ok = can_place_at(mouse)
	var color = Color(0.72, 1.0, 0.46, 0.90) if ok else Color(1.0, 0.30, 0.20, 0.90)
	var preview_radius = 16.0
	var preview_name = "部署"
	var preview_cost = 0
	if main != null and main.monster_catalog.has(selected_monster_id):
		var data = main.monster_catalog[selected_monster_id]
		preview_radius = float(data.attack_range)
		preview_name = str(data.display_name)
		preview_cost = int(data.command_cost)
		# Thin range ring: this turns “where can I place?” into “where will it matter?”.
		draw_circle(mouse, preview_radius, Color(color.r, color.g, color.b, 0.035))
		draw_arc(mouse, preview_radius, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.30), 1.3)

	draw_circle(mouse, 16.0, Color(color.r, color.g, color.b, 0.20))
	draw_arc(mouse, 18.0, 0.0, TAU, 24, color, 2.2)
	var preview_text = "%s · %d指挥点 · 射程%.0f" % [preview_name, preview_cost, preview_radius]
	draw_string(ThemeDB.fallback_font, mouse + Vector2(-58, -26), preview_text if ok else "不能部署：%s" % block_reason(mouse), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

	if main != null and main.is_tutorial_wave():
		_draw_tutorial_marks()

func _draw_tutorial_marks() -> void:
	# Minimal first-wave teaching, written directly on the play space so it survives without art assets.
	draw_circle(Vector2(160, 236), 18.0, Color(0.16, 0.95, 0.42, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(154, 241), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#112217"))
	draw_string(ThemeDB.fallback_font, Vector2(190, 240), "点击绿色区域，部署战士", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d7ffce"))
	draw_line(Vector2(180, 246), Vector2(270, 276), Color(0.48, 1.0, 0.56, 0.75), 2.2)
	draw_circle(Vector2(270, 276), 4.0, Color("#d7ffce"))
	draw_circle(Vector2(160, 524), 18.0, Color(1.0, 0.75, 0.20, 0.86))
	draw_string(ThemeDB.fallback_font, Vector2(154, 529), "2", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#342100"))
	draw_string(ThemeDB.fallback_font, Vector2(190, 528), "准备好后，点击下方“开始战斗”", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffe3a1"))

func _process(_delta: float) -> void:
	queue_redraw()
