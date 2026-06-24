extends Node2D
class_name CombatSystem

const ProjectileScript = preload("res://scripts/Projectile.gd")
const FloatingTextScript = preload("res://scripts/FloatingText.gd")

var main: Node
var shake_target: Node2D
var projectile_pool: Array = []
var text_pool: Array = []
var explosions: Array[Dictionary] = []
var sprite_fx: Array[Dictionary] = []
var shake_time = 0.0
var shake_strength = 0.0

func setup(owner: Node, target: Node2D) -> void:
	main = owner
	shake_target = target
	set_process(true)

func fire_projectile(from_position: Vector2, target: Node2D, damage: float, color: Color, tags: Dictionary, source_monster = null) -> void:
	var projectile = _get_projectile()
	projectile.launch(from_position, target, damage, color, tags, main, source_monster)

func spawn_floating_text(world_position: Vector2, message: String, color: Color, critical = false) -> void:
	var text = _get_text()
	text.pop(message, world_position, color, critical)

func spawn_sprite_fx(world_position: Vector2, texture: Texture2D, size: Vector2, lifetime: float, offset := Vector2.ZERO, modulate := Color.WHITE) -> void:
	if texture == null:
		return
	sprite_fx.append({
		"position": world_position,
		"texture": texture,
		"size": size,
		"offset": offset,
		"life": lifetime,
		"max_life": lifetime,
		"modulate": modulate
	})
	queue_redraw()

func spawn_explosion(world_position: Vector2, radius: float, damage: float, stun: float, tags = {}, apply_damage = true) -> void:
	explosions.append({"position": world_position, "radius": radius, "life": 0.38, "max_life": 0.38})
	shake(0.18, 7.0)
	if main != null and apply_damage:
		main.apply_explosion_damage(world_position, radius, damage, stun, tags)
	queue_redraw()

func shake(duration: float, strength: float) -> void:
	shake_time = max(shake_time, duration)
	shake_strength = max(shake_strength, strength)

func clear_runtime_fx() -> void:
	explosions.clear()
	sprite_fx.clear()
	for p in projectile_pool:
		p.active = false
		p.visible = false
	for t in text_pool:
		t.active = false
		t.visible = false
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["life"] -= delta
		if explosions[i]["life"] <= 0.0:
			explosions.remove_at(i)
	for i in range(sprite_fx.size() - 1, -1, -1):
		sprite_fx[i]["life"] -= delta
		if sprite_fx[i]["life"] <= 0.0:
			sprite_fx.remove_at(i)
	if shake_time > 0.0 and shake_target != null:
		shake_time -= delta
		shake_target.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		if shake_time <= 0.0:
			shake_target.position = Vector2.ZERO
			shake_strength = 0.0
	queue_redraw()

func _draw() -> void:
	for explosion in explosions:
		var ratio = clamp(explosion["life"] / explosion["max_life"], 0.0, 1.0)
		var radius = explosion["radius"] * (1.25 - ratio * 0.25)
		var pos = explosion["position"]
		draw_circle(pos, radius, Color(1.0, 0.36, 0.09, 0.17 * ratio))
		draw_arc(pos, radius, 0.0, TAU, 48, Color(1.0, 0.84, 0.30, 0.85 * ratio), 5.0)
	for effect in sprite_fx:
		var ratio = clamp(effect["life"] / effect["max_life"], 0.0, 1.0)
		var size: Vector2 = effect["size"]
		var rect = Rect2(effect["position"] + effect["offset"] - size * 0.5, size)
		var modulate: Color = effect["modulate"]
		modulate.a *= ratio
		draw_texture_rect(effect["texture"], rect, false, modulate)

func _get_projectile():
	for projectile in projectile_pool:
		if not projectile.active:
			return projectile
	var projectile = ProjectileScript.new()
	projectile.visible = false
	projectile_pool.append(projectile)
	add_child(projectile)
	return projectile

func _get_text():
	for text in text_pool:
		if not text.active:
			return text
	var text = FloatingTextScript.new()
	text.visible = false
	text.add_theme_font_size_override("font_size", 18)
	text_pool.append(text)
	add_child(text)
	return text
