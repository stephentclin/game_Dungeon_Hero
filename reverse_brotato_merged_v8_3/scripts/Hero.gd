extends CharacterBody2D
class_name Hero

const HeroFormLibrary = preload("res://scripts/data/HeroFormLibrary.gd")
const ATTACK_POSE_DURATION = 0.28
const HURT_FLASH_DURATION = 0.16
const HIT_SHAKE_DURATION = 0.14
const BASE_DRAW_RECT = Rect2(Vector2(-48, -54), Vector2(96, 96))
const ATTACK_DRAW_RECT = Rect2(Vector2(-56, -62), Vector2(112, 112))

signal died()
signal armor_broken()

var active = false
var main: Node
var stats = {}
var hp = 1.0
var max_hp = 1.0
var armor = 0.0
var max_armor = 0.0
var attack_timer = 0.0
var statuses = {}
var armor_was_broken = false

# The hero is now a real body in the arena, not just a moving drawing.
var collision_radius = 22.0
var collision_shape: CollisionShape2D
var environment_tick = 0.0
var in_poison_pool = false
var current_form_lives = 5
var visual_time = 0.0
var attack_pose_time = 0.0
var hurt_flash_time = 0.0
var hit_shake_time = 0.0
var visual_facing = 1.0
var visual_offset = Vector2.ZERO
var visual_rotation = 0.0
var visual_scale = Vector2.ONE
var wall_hit_cooldown = 0.0
var life_regen_timer = 0.0
var eternal_countdown = -1.0
var eternal_used = false

func setup(hero_stats: Dictionary, world_position: Vector2, owner: Node) -> void:
	stats = hero_stats.duplicate(true)
	main = owner
	global_position = world_position
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_collision_shape()
	collision_shape.set_deferred("disabled", false)
	max_hp = float(stats.get("max_hp", 150.0))
	hp = max_hp
	max_armor = float(stats.get("max_armor", 60.0))
	armor = max_armor
	attack_timer = 0.25
	statuses.clear()
	armor_was_broken = false
	environment_tick = 0.0
	in_poison_pool = false
	visual_time = 0.0
	attack_pose_time = 0.0
	hurt_flash_time = 0.0
	hit_shake_time = 0.0
	visual_facing = 1.0
	visual_offset = Vector2.ZERO
	visual_rotation = 0.0
	visual_scale = Vector2.ONE
	var lives_remaining = 5
	if main != null:
		lives_remaining = int(main.get("hero_lives_remaining"))
	wall_hit_cooldown = 0.0
	life_regen_timer = 0.0
	eternal_countdown = -1.0
	eternal_used = false
	set_life_form(lives_remaining)
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()

func activate() -> void:
	active = true
	visible = true
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)
	set_physics_process(true)

func deactivate() -> void:
	active = false
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)

func collision_size() -> float:
	return collision_radius

func _ensure_collision_shape() -> void:
	collision_layer = 4
	collision_mask = 2 # Monster bodies.
	if collision_shape == null or not is_instance_valid(collision_shape):
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	var circle = CircleShape2D.new()
	circle.radius = collision_radius
	collision_shape.shape = circle

func hp_ratio() -> float:
	return hp / max_hp if max_hp > 0.0 else 0.0

func armor_ratio() -> float:
	return armor / max_armor if max_armor > 0.0 else 0.0

func set_life_form(lives_remaining: int) -> void:
	current_form_lives = clampi(lives_remaining, 1, 5)
	queue_redraw()

func on_wall_contact(inward_direction: Vector2) -> void:
	if not active or wall_hit_cooldown > 0.0:
		return
	wall_hit_cooldown = 0.45
	velocity = inward_direction.normalized() * 220.0
	take_damage(6.0, null, {"source": "wall", "always_hit": true})
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-14, -68), "撞墙", Color("#f4ca7c"), false)

func take_damage(amount: float, source = null, tags = {}) -> float:
	if not active or amount <= 0.0:
		return 0.0
	var gate = _gate_incoming_damage(amount, tags)
	if bool(gate.get("miss", false)):
		if main != null:
			main.combat_system.spawn_floating_text(global_position + Vector2(-10, -58), "MISS", Color("#c9d4ef"), false)
		return 0.0
	if bool(gate.get("blocked", false)):
		if main != null:
			main.combat_system.spawn_floating_text(global_position + Vector2(-18, -58), str(gate.get("text", "IMMUNE")), Color("#a6d4ff"), false)
		return 0.0
	amount = float(gate.get("amount", amount))
	var hp_before = hp
	var remaining = amount
	var armor_bonus = float(tags.get("armor_bonus", 0.0))
	var ignore_armor = bool(tags.get("ignore_armor", false))
	var displayed = amount
	if armor > 0.0 and not ignore_armor:
		var armor_hit = min(armor, remaining + armor_bonus)
		armor -= armor_hit
		remaining = max(0.0, remaining - armor_hit)
		displayed = armor_hit
		if armor <= 0.0 and not armor_was_broken:
			armor_was_broken = true
			armor_broken.emit()
	if remaining > 0.0:
		hp = max(0.0, hp - remaining)
		displayed = remaining
	if main != null:
		var critical = bool(tags.get("critical", false))
		var popup_color = Color(1.0, 0.82, 0.30) if ignore_armor else (Color(1.0, 0.24, 0.22) if remaining > 0.0 else Color(0.76, 0.82, 0.92))
		var popup = "-%d 破甲" % int(displayed) if ignore_armor else "-%d" % int(displayed)
		main.combat_system.spawn_floating_text(global_position + Vector2(-8, -44), popup, popup_color, critical)
		main.rage_system.reduce(amount * 0.032 + armor_bonus * 0.018)
	hurt_flash_time = HURT_FLASH_DURATION
	hit_shake_time = HIT_SHAKE_DURATION
	queue_redraw()
	if hp <= 0.0:
		active = false
		visible = false
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)
		died.emit()
	return max(0.0, hp_before - hp)

func _gate_incoming_damage(amount: float, tags: Dictionary) -> Dictionary:
	var result = {"amount": amount, "miss": false, "blocked": false, "text": ""}
	if main == null:
		return result
	var dot_damage = bool(tags.get("dot", false))
	var always_hit = bool(tags.get("always_hit", false)) or bool(tags.get("trap", false)) or bool(tags.get("marked_arrow", false)) or bool(tags.get("backstab", false)) or bool(tags.get("true_curse", false))
	var seals = main.hero_seal_count()
	# Seal 1: Void. Ordinary attacks miss 70%, while marked/trap/true attacks remain reliable.
	if seals >= 1 and not dot_damage and not always_hit and randf() < 0.70:
		result["miss"] = true
		return result
	# Seal 2: Element. Direct attacks are blocked until an elemental ailment is active.
	if seals >= 2 and not dot_damage and not _has_elemental_ailment():
		result["blocked"] = true
		result["text"] = "元素屏障"
		return result
	# Seal 3: Energy. Burst is capped; repeated attacks and damage-over-time are still useful.
	if seals >= 3 and not dot_damage:
		result["amount"] = min(float(result["amount"]), 30.0)
	# Seal 5: Reincarnation changes the final form's resistance.
	if seals >= 5 and current_form_lives <= 1 and bool(tags.get("ranged", false)):
		result["blocked"] = true
		result["text"] = "轮回抗性"
	return result

func _has_elemental_ailment() -> bool:
	for id in ["poison", "burn", "freeze", "corrosion", "bleed"]:
		if statuses.has(id):
			return true
	return false

func shatter_armor(amount: float) -> void:
	if not active or amount <= 0.0 or armor <= 0.0:
		return
	var removed = min(armor, amount)
	armor -= removed
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-34, -70), "护甲 -%d" % int(removed), Color(0.72, 0.86, 1.0), true)
	if armor <= 0.0 and not armor_was_broken:
		armor_was_broken = true
		armor_broken.emit()
	queue_redraw()

func apply_status(id: String, duration: float, value: float = 1.0) -> void:
	statuses[id] = {"duration": max(duration, float(statuses.get(id, {}).get("duration", 0.0))), "value": value, "tick": 0.0}
	queue_redraw()

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = min(max_hp, hp + amount)
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-4, -58), "+%d" % int(amount), Color(0.42, 1.0, 0.48))
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active or main == null or main.phase != "battle":
		return
	wall_hit_cooldown = max(0.0, wall_hit_cooldown - delta)
	_tick_environment(delta)
	_tick_statuses(delta)
	_tick_seals(delta)
	if not active:
		_update_visual_fx(delta, Vector2.ZERO, 0.0)
		queue_redraw()
		return
	var crowd_push = main.get_hero_crowd_push(global_position)
	if statuses.has("stun"):
		velocity = crowd_push
		move_and_slide()
		main.resolve_wall_contact(self)
		_update_visual_fx(delta, velocity, 0.0)
		queue_redraw()
		return
	attack_timer = max(0.0, attack_timer - delta)
	var target = main.get_hero_target()
	if target == null:
		velocity = crowd_push
		move_and_slide()
		main.resolve_wall_contact(self)
		_update_visual_fx(delta, velocity, 0.0)
		queue_redraw()
		return
	var target_position: Vector2 = target.global_position
	var distance = global_position.distance_to(target_position)
	var attack_range = float(stats.get("attack_range", 52.0))
	var movement = Vector2.ZERO
	if distance <= attack_range:
		if attack_timer <= 0.0:
			_attack(target)
			attack_timer = 1.0 / max(0.1, float(stats.get("attack_speed", 0.8)) * _status_attack_speed_multiplier())
	else:
		var desired = (target_position - global_position).normalized()
		movement = desired * _move_speed()
	velocity = movement + crowd_push
	move_and_slide()
	main.resolve_wall_contact(self)
	_update_visual_fx(delta, velocity, target_position.x - global_position.x)
	queue_redraw()

func _tick_environment(delta: float) -> void:
	var effects = main.get_environment_effects_at(global_position)
	in_poison_pool = bool(effects.get("poison", false))
	environment_tick += delta
	if environment_tick < 1.0:
		return
	environment_tick -= 1.0
	if in_poison_pool:
		take_damage(float(effects.get("poison_dps", 6.0)), null, {"source": "poison_pool", "dot": true, "always_hit": true})

func _attack(target: Node) -> void:
	attack_pose_time = ATTACK_POSE_DURATION
	var damage = float(stats.get("attack", 12.0))
	if statuses.has("weak"):
		damage *= 0.75
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
	if target.has_method("apply_knockback"):
		target.apply_knockback(global_position, 165.0 + damage * 3.0)
	if bool(stats.get("area_attack", false)):
		for monster in main.get_active_monsters():
			if monster != target and monster.global_position.distance_to(target.global_position) <= 54.0:
				monster.take_damage(damage * 0.42, self)
				if monster.has_method("apply_knockback"):
					monster.apply_knockback(global_position, 105.0 + damage * 1.5)

func _tick_statuses(delta: float) -> void:
	for id in statuses.keys():
		statuses[id]["duration"] -= delta
		if id == "poison":
			statuses[id]["tick"] += delta
			if statuses[id]["tick"] >= 0.5:
				statuses[id]["tick"] = 0.0
				take_damage(float(statuses[id]["value"]) * 0.5, null, {"source": "poison", "dot": true, "always_hit": true})
		elif id == "burn":
			statuses[id]["tick"] += delta
			if statuses[id]["tick"] >= 0.5:
				statuses[id]["tick"] = 0.0
				take_damage(float(statuses[id]["value"]) * 0.7, null, {"source": "burn", "dot": true, "always_hit": true})
	var expired: Array[String] = []
	for id in statuses.keys():
		if statuses[id]["duration"] <= 0.0:
			expired.append(id)
	for id in expired:
		statuses.erase(id)

func _tick_seals(delta: float) -> void:
	if main == null or not active:
		return
	var seals = main.hero_seal_count()
	if seals >= 4:
		life_regen_timer += delta
		if life_regen_timer >= 3.0:
			life_regen_timer = 0.0
			heal(max_hp * 0.10)
			main.combat_system.spawn_floating_text(global_position + Vector2(-30, -78), "生命圣泉", Color("#7dffb3"), false)
	# Seal 6 is a final-life, low-health check: kill the hero during this window or it returns to full health once.
	if seals >= 5 and current_form_lives <= 1 and not eternal_used:
		if hp_ratio() <= 0.20:
			if eternal_countdown < 0.0:
				eternal_countdown = 3.0
				main.combat_system.spawn_floating_text(global_position + Vector2(-42, -92), "永恒倒计时", Color("#f5d477"), true)
			else:
				eternal_countdown -= delta
				if eternal_countdown <= 0.0 and active:
					eternal_used = true
					heal(max_hp)
					main.combat_system.spawn_floating_text(global_position + Vector2(-34, -92), "永恒神血", Color("#fff3b1"), true)
		else:
			eternal_countdown = -1.0

func _move_speed() -> float:
	var value = float(stats.get("move_speed", 88.0))
	if statuses.has("slow"):
		value *= 1.0 - clamp(float(statuses["slow"]["value"]), 0.0, 0.85)
	var effects = main.get_environment_effects_at(global_position)
	if bool(effects.get("slow", false)):
		value *= 0.55
	return value

func _status_attack_speed_multiplier() -> float:
	return 1.35 if statuses.has("momentum") else 1.0

func _update_visual_fx(delta: float, current_velocity: Vector2, facing_hint_x: float) -> void:
	visual_time += delta
	attack_pose_time = max(0.0, attack_pose_time - delta)
	hurt_flash_time = max(0.0, hurt_flash_time - delta)
	hit_shake_time = max(0.0, hit_shake_time - delta)
	if abs(current_velocity.x) > 3.0:
		visual_facing = sign(current_velocity.x)
	elif abs(facing_hint_x) > 3.0:
		visual_facing = sign(facing_hint_x)
	if is_zero_approx(visual_facing):
		visual_facing = 1.0

	var move_speed = current_velocity.length()
	var move_amount = clamp(move_speed / 110.0, 0.0, 1.0)
	var bob = sin(visual_time * (3.2 if move_amount < 0.08 else 9.0 + move_amount * 3.0)) * (0.9 if move_amount < 0.08 else 2.4 + move_amount * 1.8)
	var lunge = 0.0
	var tilt = 0.0
	var stretch_x = 1.0
	var stretch_y = 1.0
	if attack_pose_time > 0.0:
		var attack_t = 1.0 - attack_pose_time / ATTACK_POSE_DURATION
		var swing = sin(attack_t * PI)
		lunge = visual_facing * 2.5 * swing
		bob *= 0.35
	elif move_amount > 0.05:
		tilt = visual_facing * deg_to_rad(4.0) * sin(visual_time * 7.2)

	var shake = Vector2.ZERO
	if hit_shake_time > 0.0:
		var shake_strength = hit_shake_time / HIT_SHAKE_DURATION
		var shake_dir = -visual_facing if int(visual_time * 90.0) % 2 == 0 else visual_facing
		shake = Vector2(shake_dir * 4.0 * shake_strength, -2.0 * shake_strength)

	visual_offset = Vector2(lunge, bob) + shake
	visual_rotation = tilt
	visual_scale = Vector2(visual_facing * stretch_x, stretch_y)

func _draw() -> void:
	if not visible:
		return

	# Clear enemy language: a red ground ring + a readable knight silhouette.
	draw_circle(Vector2(0, 18), 27.0, Color(0.92, 0.20, 0.16, 0.12))
	draw_arc(Vector2(0, 18), 27.0, 0.0, TAU, 32, Color(1.0, 0.34, 0.26, 0.78), 1.8)
	# A subtle target line answers the important question: “who is the hero walking toward?”
	if main != null and main.phase == "battle":
		var target = main.get_hero_target()
		if target != null:
			var target_local = to_local(target.global_position)
			draw_line(Vector2(0, 8), target_local, Color(1.0, 0.42, 0.30, 0.45), 1.5)

	var hero_texture = HeroFormLibrary.texture_for_lives(current_form_lives)
	var hero_modulate = Color.WHITE
	if statuses.has("poison") or in_poison_pool:
		hero_modulate = hero_modulate.lerp(Color("#9dff93"), 0.30)
	if statuses.has("slow"):
		hero_modulate = hero_modulate.lerp(Color("#8ec7ff"), 0.32)
	if statuses.has("stun"):
		hero_modulate = hero_modulate.lerp(Color("#fff39a"), 0.42)
	if hurt_flash_time > 0.0:
		var flash = hurt_flash_time / HURT_FLASH_DURATION
		hero_modulate = hero_modulate.lerp(Color(1.0, 0.72, 0.72), 0.48 * flash)

	draw_set_transform(visual_offset, visual_rotation, visual_scale)
	if attack_pose_time > 0.0:
		var attack_texture = HeroFormLibrary.attack_texture_for_lives(current_form_lives)
		var frame_progress = 1.0 - attack_pose_time / ATTACK_POSE_DURATION
		var frame_index = clampi(int(floor(frame_progress * HeroFormLibrary.HERO_ATTACK_FRAME_COUNT)), 0, HeroFormLibrary.HERO_ATTACK_FRAME_COUNT - 1)
		var frame_width = attack_texture.get_width() / HeroFormLibrary.HERO_ATTACK_FRAME_COUNT
		var frame_region = Rect2(frame_index * frame_width, 0.0, frame_width, float(attack_texture.get_height()))
		draw_texture_rect_region(attack_texture, ATTACK_DRAW_RECT, frame_region, hero_modulate)
	else:
		draw_texture_rect(hero_texture, BASE_DRAW_RECT, false, hero_modulate)

	# Armor aura / broken-armor visual.
	draw_arc(Vector2.ZERO, 26.0, -0.2, TAU - 0.2, 32, Color(0.72, 0.82, 0.97, 0.34 + armor_ratio() * 0.45), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if armor <= 0.0:
		draw_line(Vector2(-26, -20), Vector2(9, 19), Color("#e6eefc"), 2.0)
		draw_line(Vector2(5, -26), Vector2(25, 8), Color("#e6eefc"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-28, 49), "破甲！", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff0b3"))

	if in_poison_pool:
		draw_string(ThemeDB.fallback_font, Vector2(-28, 62), "毒池侵蚀", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#baff86"))

	# Seal readout keeps the current boss rule visible during battle.
	if main != null and main.has_method("hero_seal_names"):
		var seal_text = "、".join(main.hero_seal_names())
		if main.hero_seal_count() >= 5 and current_form_lives <= 1 and not eternal_used:
			seal_text += "、永恒"
		draw_string(ThemeDB.fallback_font, Vector2(-46, 76), "封印：" + seal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe4a3"))

	# Named bars prevent “two anonymous lines floating in space”.
	draw_string(ThemeDB.fallback_font, Vector2(-23, -58), "勇者", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffe2b5"))
	draw_rect(Rect2(Vector2(-31, -53), Vector2(62, 5)), Color("#3a1517"), true)
	draw_rect(Rect2(Vector2(-31, -53), Vector2(62 * hp_ratio(), 5)), Color("#ef5549"), true)
	draw_rect(Rect2(Vector2(-31, -61), Vector2(62, 4)), Color("#1e2934"), true)
	draw_rect(Rect2(Vector2(-31, -61), Vector2(62 * armor_ratio(), 4)), Color("#aabbd1"), true)
