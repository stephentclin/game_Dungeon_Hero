extends Node2D
class_name Projectile

const ARROW_TEXTURE = preload("res://assets/monster_forms/archer/arrow.png")
const ARROW_DRAW_RECT = Rect2(Vector2(-21, -3.5), Vector2(42, 7))

var active = false
var target: Node2D
var main: Node
var source_monster
var damage = 0.0
var speed = 440.0
var color = Color.WHITE
var tags = {}

func launch(from_position: Vector2, target_node: Node2D, amount: float, projectile_color: Color, tag_data: Dictionary, owner: Node, origin_monster = null) -> void:
	global_position = from_position
	target = target_node
	damage = amount
	color = projectile_color
	tags = tag_data
	main = owner
	source_monster = origin_monster
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rotation = 0.0
	if target != null and is_instance_valid(target):
		rotation = (target.global_position - global_position).angle()
	active = true
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	if target == null or not is_instance_valid(target):
		_deactivate()
		return
	var to_target = target.global_position - global_position
	if to_target.length() <= 15.0:
		main.apply_damage_to_hero(damage, source_monster, tags)
		if source_monster != null and is_instance_valid(source_monster) and source_monster.has_method("on_projectile_hit"):
			source_monster.on_projectile_hit(target.global_position, target, damage, tags)
		_deactivate()
		return
	var direction = to_target.normalized()
	rotation = direction.angle()
	global_position += direction * speed * delta

func _draw() -> void:
	if _uses_arrow_texture() and ARROW_TEXTURE != null:
		draw_texture_rect(ARROW_TEXTURE, ARROW_DRAW_RECT, false)
		return
	draw_circle(Vector2.ZERO, 5.0, color)
	draw_circle(Vector2.ZERO, 8.0, Color(color.r, color.g, color.b, 0.18))

func _uses_arrow_texture() -> bool:
	return str(tags.get("ability", "")) == "arrow" or str(tags.get("source", "")) == "archer"

func _deactivate() -> void:
	active = false
	visible = false
	source_monster = null
