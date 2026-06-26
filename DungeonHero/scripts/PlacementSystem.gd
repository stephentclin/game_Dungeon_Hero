extends Node2D
class_name PlacementSystem

# The arena is the visual battlefield. DEPLOY_RECT is the part that is actually clickable.
# Keeping them separate prevents the UI from pretending that covered areas are deployable.
const ARENA_RECT = Rect2(Vector2(258, 118), Vector2(718, 450))
const DEPLOY_RECT = Rect2(Vector2(270, 164), Vector2(694, 354))
const HERO_BLOCK_RADIUS = 96.0
const TOP_UI_RECT = Rect2(Vector2(10, 8), Vector2(1260, 102))
const RIGHT_UI_RECT = Rect2(Vector2(988, 110), Vector2(282, 462))
const LEFT_UI_RECT = Rect2(Vector2(8, 110), Vector2(242, 458))
const ACTION_UI_RECT = Rect2(Vector2(8, 570), Vector2(1264, 142))
const OVERLAY_RECT = Rect2(Vector2(280, 134), Vector2(720, 416))

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

func _input(_event: InputEvent) -> void:
	# Manual battlefield deployment is disabled. Units are now deployed only by
	# match-3 rewards, which choose random valid positions through find_auto_place_slot().
	return

func can_place_at(point: Vector2) -> bool:
	return block_reason(point) == ""

func find_auto_place_slot(monster_id: String = "") -> Vector2:
	var radius := 18.0
	if main != null and main.monster_catalog.has(monster_id):
		radius = float(main.monster_catalog[monster_id].collision_radius)
	var best := Vector2(-1, -1)
	var best_score := -INF
	for _attempt in range(32):
		var candidate := Vector2(
			randf_range(DEPLOY_RECT.position.x + radius, DEPLOY_RECT.end.x - radius),
			randf_range(DEPLOY_RECT.position.y + radius, DEPLOY_RECT.end.y - radius)
		)
		if not can_place_at(candidate):
			continue
		var score := _slot_score(candidate, radius)
		if score > best_score:
			best_score = score
			best = candidate
	if best.x < 0.0:
		best = DEPLOY_RECT.get_center()
		if not can_place_at(best):
			return Vector2(-1, -1)
	return best

func _loc(zh: String, en: String) -> String:
	if main != null and main.has_method("loc"):
		return main.loc(zh, en)
	return zh

func block_reason(point: Vector2) -> String:
	if _ui_blocks_point(point):
		return _loc("界面区域不能部署怪物。", "Cannot deploy on the interface.")
	if not ARENA_RECT.has_point(point):
		return _loc("只能在竞技场地图内部署怪物。", "Deploy only inside the arena.")
	if not DEPLOY_RECT.has_point(point):
		return _loc("请放进绿色部署区，不要压住上方状态栏或下方指挥台。", "Place units inside the green deployment zone.")
	if main != null and main.hero != null:
		if point.distance_to(main.hero.global_position) < HERO_BLOCK_RADIUS:
			return _loc("离勇者太近，换个位置部署。", "Too close to the hero. Choose another spot.")
	return ""

func _ui_blocks_point(point: Vector2) -> bool:
	if TOP_UI_RECT.has_point(point) or LEFT_UI_RECT.has_point(point) or RIGHT_UI_RECT.has_point(point) or ACTION_UI_RECT.has_point(point):
		return true
	if main != null and main.ui != null and main.ui.overlay != null and main.ui.overlay.visible:
		return OVERLAY_RECT.has_point(point)
	return false

func _draw() -> void:
	# Do not show mouse deployment preview anymore; deployment happens automatically from the puzzle board.
	return

func _draw_tutorial_marks() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(292, 218), _loc("右侧选择兵种，再在绿色区部署。", "Choose a unit on the right, then deploy in the green zone."), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d7ffce"))

func _process(_delta: float) -> void:
	queue_redraw()

func _slot_score(candidate: Vector2, radius: float) -> float:
	var nearest := INF
	if main != null and main.hero != null:
		nearest = min(nearest, candidate.distance_to(main.hero.global_position) - HERO_BLOCK_RADIUS - radius)
	if main != null and main.has_method("get_active_monsters"):
		for monster in main.get_active_monsters():
			if monster == null or not is_instance_valid(monster) or not monster.active:
				continue
			var spacing := radius
			if monster.has_method("collision_size"):
				spacing += float(monster.collision_size())
			nearest = min(nearest, candidate.distance_to(monster.global_position) - spacing)
	return nearest
