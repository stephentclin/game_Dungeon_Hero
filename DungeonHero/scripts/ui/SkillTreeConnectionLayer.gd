extends Control
class_name SkillTreeConnectionLayer

var skill_data: Dictionary = {}
var visible_ids: Array = []
var node_controls: Dictionary = {}
var branch_colors: Dictionary = {}
var purchased_callable := Callable()
var flow_edges: Dictionary = {}
var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	time += delta
	var expired: Array[String] = []
	for key in flow_edges.keys():
		flow_edges[key] = float(flow_edges[key]) - delta
		if float(flow_edges[key]) <= 0.0:
			expired.append(str(key))
	for key in expired:
		flow_edges.erase(key)
	queue_redraw()

func trigger_flow(from_id: String, to_id: String) -> void:
	flow_edges["%s>%s" % [from_id, to_id]] = 0.75
	queue_redraw()

func _draw() -> void:
	for id in visible_ids:
		if not skill_data.has(id):
			continue
		var data: Dictionary = skill_data[id]
		for prereq in data.get("prerequisite_ids", []):
			var from_id := str(prereq)
			if not visible_ids.has(from_id):
				continue
			if not node_controls.has(from_id) or not node_controls.has(id):
				continue
			_draw_connection(from_id, id, data)

func _draw_connection(from_id: String, to_id: String, data: Dictionary) -> void:
	var from_node: Control = node_controls[from_id]
	var to_node: Control = node_controls[to_id]
	var start := from_node.position + from_node.size * 0.5
	var finish := to_node.position + to_node.size * 0.5
	var branch := str(data.get("branch", "core"))
	var color: Color = branch_colors.get(branch, Color("#ff4058"))
	var active := false
	if purchased_callable.is_valid():
		active = bool(purchased_callable.call(from_id))
	var purchased := false
	if purchased_callable.is_valid():
		purchased = bool(purchased_callable.call(to_id))
	var line_color := color if active else Color(0.18, 0.19, 0.23, 0.82)
	var glow_alpha := 0.42 if active else 0.11
	if purchased:
		glow_alpha = 0.62
	draw_line(start, finish, Color(line_color.r, line_color.g, line_color.b, glow_alpha), 12.0, true)
	draw_line(start, finish, Color(line_color.r, line_color.g, line_color.b, 0.72 if active else 0.42), 4.0, true)
	draw_line(start, finish, Color(1, 1, 1, 0.34 if purchased else 0.08), 1.0, true)

	var edge_key := "%s>%s" % [from_id, to_id]
	if flow_edges.has(edge_key):
		var ratio := 1.0 - clampf(float(flow_edges[edge_key]) / 0.75, 0.0, 1.0)
		var p := start.lerp(finish, ratio)
		draw_circle(p, 10.0, Color(line_color.r, line_color.g, line_color.b, 0.80))
		draw_circle(p, 4.0, Color(1, 1, 1, 0.95))
	elif active:
		var pulse := 0.5 + 0.5 * sin(time * 3.5 + start.x * 0.02)
		var p2 := start.lerp(finish, pulse)
		draw_circle(p2, 3.0, Color(line_color.r, line_color.g, line_color.b, 0.52))
