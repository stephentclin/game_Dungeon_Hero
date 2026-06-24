extends Label
class_name FloatingText

var active = false
var life = 0.0
var velocity = Vector2.ZERO

func pop(message: String, world_position: Vector2, color: Color, critical = false) -> void:
	text = message
	global_position = world_position
	modulate = color
	scale = Vector2.ONE * (1.25 if critical else 0.95)
	life = 0.95 if critical else 0.75
	velocity = Vector2(randf_range(-18.0, 18.0), -54.0 if critical else -38.0)
	active = true
	visible = true

func _process(delta: float) -> void:
	if not active:
		return
	life -= delta
	global_position += velocity * delta
	modulate.a = clamp(life / 0.8, 0.0, 1.0)
	if life <= 0.0:
		active = false
		visible = false

