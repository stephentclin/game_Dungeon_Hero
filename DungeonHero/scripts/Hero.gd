extends CharacterBody2D
class_name Hero

const HeroFormLibrary = preload("res://scripts/data/HeroFormLibrary.gd")
const ATTACK_POSE_DURATION = 0.28
const HURT_FLASH_DURATION = 0.16
const HIT_SHAKE_DURATION = 0.14
const BASE_DRAW_RECT = Rect2(Vector2(-48, -54), Vector2(96, 96))
const ATTACK_DRAW_RECT = BASE_DRAW_RECT

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
var facing_change_cooldown = 0.0
var visual_offset = Vector2.ZERO
var visual_rotation = 0.0
var visual_scale = Vector2.ONE
var wall_hit_cooldown = 0.0
var life_regen_timer = 0.0
var eternal_countdown = -1.0
var eternal_used = false
var map_impulse_velocity = Vector2.ZERO
var survival_target = Vector2.ZERO
var survival_retarget_timer = 0.0
var survival_turn = 1.0
var no_enemy_idle = false
var no_enemy_patrol_target = Vector2.ZERO
var no_enemy_patrol_timer = 0.0
var no_enemy_patrol_angle = 0.0

func setup(hero_stats: Dictionary, world_position: Vector2, owner: Node) -> void:
	stats = hero_stats.duplicate(true)
	main = owner
	global_position = world_position
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_collision_shape()
	collision_shape.set_deferred("disabled", false)
	max_hp = float(stats.get("max_hp", 150.0))
	hp = max_hp
	max_armor = 0.0
	armor = 0.0
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
	facing_change_cooldown = 0.0
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
	map_impulse_velocity = Vector2.ZERO
	survival_target = Vector2.ZERO
	survival_retarget_timer = 0.0
	survival_turn = -1.0 if randf() < 0.5 else 1.0
	no_enemy_idle = false
	no_enemy_patrol_target = Vector2.ZERO
	no_enemy_patrol_timer = 0.0
	no_enemy_patrol_angle = randf() * TAU
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
	map_impulse_velocity = Vector2.ZERO
	no_enemy_patrol_target = Vector2.ZERO
	no_enemy_patrol_timer = 0.0
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

func apply_map_impulse(direction: Vector2, strength: float) -> void:
	if not active or direction.length_squared() <= 0.001:
		return
	map_impulse_velocity += direction.normalized() * strength
	map_impulse_velocity = map_impulse_velocity.limit_length(320.0)

func _loc(zh: String, en: String) -> String:
	if main != null and main.has_method("loc"):
		return main.loc(zh, en)
	return zh

func on_wall_contact(inward_direction: Vector2) -> void:
	if not active or wall_hit_cooldown > 0.0:
		return
	wall_hit_cooldown = 0.45
	velocity = inward_direction.normalized() * 220.0
	var wall_multiplier = float(stats.get("wall_damage_multiplier", 1.0))
	take_damage(6.0 * wall_multiplier, null, {"source": "wall", "always_hit": true})
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-14, -68), _loc("撞墙", "WALL HIT"), Color("#f4ca7c"), false)

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
	if str(gate.get("text", "")) != "" and main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-26, -70), str(gate.get("text", "")), Color("#a6d4ff"), false)
	var hp_before = hp
	var armor_before = armor
	var remaining = amount
	var armor_bonus = 0.0
	var displayed = remaining
	hp = max(0.0, hp - remaining)
	if main != null:
		var critical = bool(tags.get("critical", false))
		main.combat_system.spawn_floating_text(global_position + Vector2(-8, -44), "-%d" % int(displayed), Color(1.0, 0.24, 0.22), critical)
		main.rage_system.reduce(amount * 0.032)
	hurt_flash_time = HURT_FLASH_DURATION
	hit_shake_time = HIT_SHAKE_DURATION
	queue_redraw()
	var hp_damage = max(0.0, hp_before - hp)
	var armor_damage = max(0.0, armor_before - armor)
	if main != null and main.has_method("record_hero_damage"):
		main.record_hero_damage(hp_damage, armor_damage, tags)
	if hp <= 0.0:
		active = false
		visible = false
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)
		died.emit()
	return hp_damage

func _gate_incoming_damage(amount: float, tags: Dictionary) -> Dictionary:
	var result = {"amount": amount, "miss": false, "blocked": false, "text": ""}
	if main == null:
		return result
	var dot_damage = bool(tags.get("dot", false))
	var always_hit = bool(tags.get("always_hit", false)) or bool(tags.get("trap", false)) or bool(tags.get("marked_arrow", false)) or bool(tags.get("backstab", false)) or bool(tags.get("true_curse", false))
	var seals: int = main.hero_seal_count()
	# Seal 1: Void. Ordinary attacks now miss 30% instead of 70%, so hits feel more consistent.
	if seals >= 1 and not dot_damage and not always_hit and randf() < 0.30:
		result["miss"] = true
		return result
	# Seal 2 shield/barrier mechanic removed: no damage reduction or barrier popup.
	# Seal 3: Energy. Burst is capped; repeated attacks and damage-over-time are still useful.
	if seals >= 3 and not dot_damage:
		result["amount"] = min(float(result["amount"]), 30.0)
	# Seal 5: Reincarnation changes the final form's resistance.
	if seals >= 5 and current_form_lives <= 1 and bool(tags.get("ranged", false)):
		result["blocked"] = true
		result["text"] = _loc("轮回抗性", "REINCARNATION RESIST")
	return result

func _has_elemental_ailment() -> bool:
	for id in ["poison", "burn", "freeze", "corrosion", "bleed"]:
		if statuses.has(id):
			return true
	return false

func shatter_armor(amount: float) -> void:
	# Hero shield/armor mechanic removed. Keep this method as a safe no-op.
	return

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
	map_impulse_velocity = map_impulse_velocity.move_toward(Vector2.ZERO, 640.0 * delta)
	_tick_environment(delta)
	_tick_statuses(delta)
	_tick_seals(delta)
	if not active:
		_update_visual_fx(delta, Vector2.ZERO, 0.0)
		queue_redraw()
		return
	var crowd_push: Vector2 = main.get_hero_crowd_push(global_position)
	if statuses.has("stun"):
		velocity = crowd_push + map_impulse_velocity
		move_and_slide()
		main.resolve_wall_contact(self)
		_update_visual_fx(delta, velocity, 0.0)
		queue_redraw()
		return
	attack_timer = max(0.0, attack_timer - delta)
	var active_monsters: Array = main.get_active_monsters()
	var target: Node = main.get_hero_target()
	var facing_hint: float = survival_target.x - global_position.x
	var movement: Vector2 = Vector2.ZERO
	# When the battle map has no monsters, keep the hero alive by patrolling instead of
	# standing on the center point. A dedicated patrol target avoids the old tiny
	# retarget loop that caused visible jitter.
	if active_monsters.is_empty() and target == null:
		no_enemy_idle = false
		var patrol_movement: Vector2 = _no_enemy_patrol_movement(delta)
		facing_hint = no_enemy_patrol_target.x - global_position.x
		velocity = patrol_movement + crowd_push + map_impulse_velocity
		if velocity.length_squared() < 1.0:
			velocity = Vector2.ZERO
		move_and_slide()
		main.resolve_wall_contact(self)
		_update_visual_fx(delta, velocity, facing_hint)
		queue_redraw()
		return
	no_enemy_idle = false
	movement = _survival_movement(delta)
	if target != null and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		var attack_range = float(stats.get("attack_range", 52.0))
		facing_hint = target.global_position.x - global_position.x
		# The hero should feel brave: press into targets, only sidestep when crowded.
		movement = _combat_movement(target, distance, attack_range, delta)
		if distance <= attack_range:
			if attack_timer <= 0.0:
				_attack(target)
				attack_timer = 1.0 / max(0.1, float(stats.get("attack_speed", 0.8)) * _status_attack_speed_multiplier())
	velocity = movement + crowd_push + map_impulse_velocity
	move_and_slide()
	main.resolve_wall_contact(self)
	_update_visual_fx(delta, velocity, facing_hint)
	queue_redraw()

func _combat_movement(target: Node, distance: float, attack_range: float, delta: float) -> Vector2:
	if target == null or not is_instance_valid(target):
		return _survival_movement(delta)
	var to_target: Vector2 = target.global_position - global_position
	if to_target.length_squared() <= 0.001:
		return Vector2.ZERO
	var forward: Vector2 = to_target.normalized()
	var center_bias := _center_bias()
	var side_attack: Vector2 = forward.rotated(survival_turn * PI * 0.5)
	var desired: Vector2 = forward * 1.25 + center_bias * 0.58
	if distance <= attack_range * 0.86:
		desired = forward * 0.50 + side_attack * 0.52 + center_bias * 0.72

	var immediate_away := Vector2.ZERO
	var nearest_distance: float = INF
	for monster in main.get_active_monsters():
		var offset: Vector2 = global_position - monster.global_position
		var d: float = offset.length()
		nearest_distance = min(nearest_distance, d)
		if d > 0.01 and d < 108.0:
			immediate_away += offset.normalized() * ((108.0 - d) / 108.0)
	if immediate_away.length_squared() > 0.001:
		var dodge := immediate_away.normalized()
		var strafe := dodge.rotated(survival_turn * 0.62)
		desired += dodge * (0.42 if nearest_distance < 54.0 else 0.18)
		desired += strafe * 0.32

	var edge_push := _edge_push(118.0)
	if edge_push.length_squared() > 0.001:
		desired += edge_push.normalized() * 1.22
	if desired.length_squared() <= 0.001:
		desired = forward
	desired = desired.normalized()
	return desired * _move_speed()


func _no_enemy_patrol_movement(delta: float) -> Vector2:
	no_enemy_patrol_timer -= delta
	if no_enemy_patrol_target == Vector2.ZERO or no_enemy_patrol_timer <= 0.0 or global_position.distance_to(no_enemy_patrol_target) < 38.0:
		_choose_no_enemy_patrol_target()
	var desired: Vector2 = no_enemy_patrol_target - global_position
	if desired.length_squared() <= 16.0:
		_choose_no_enemy_patrol_target()
		desired = no_enemy_patrol_target - global_position
	if desired.length_squared() <= 16.0:
		return Vector2.ZERO
	var edge_push: Vector2 = _edge_push(118.0)
	if edge_push.length_squared() > 0.001:
		desired = (desired.normalized() * 0.42 + edge_push.normalized() * 1.28).normalized()
	else:
		desired = desired.normalized()
	return desired * (_move_speed() * 0.58)

func _choose_no_enemy_patrol_target() -> void:
	var safe_rect: Rect2 = main.ARENA_BOUNDS.grow(-118.0)
	var center: Vector2 = safe_rect.get_center()
	var radius_x: float = float(max(72.0, safe_rect.size.x * 0.32))
	var radius_y: float = float(max(58.0, safe_rect.size.y * 0.28))
	var direction_sign: float = 1.0 if survival_turn >= 0.0 else -1.0
	no_enemy_patrol_angle += direction_sign * randf_range(0.75, 1.25)
	var best_point: Vector2 = global_position
	var best_score: float = -INF
	for i in range(8):
		var angle: float = no_enemy_patrol_angle + float(i) * direction_sign * 0.42
		var candidate: Vector2 = center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		candidate += Vector2(randf_range(-42.0, 42.0), randf_range(-30.0, 30.0))
		candidate = _clamp_point_to_rect(candidate, safe_rect)
		var travel: float = global_position.distance_to(candidate)
		var center_distance: float = candidate.distance_to(center)
		var score: float = travel * 0.68 + center_distance * 0.18
		if travel < 86.0:
			score -= 180.0
		if score > best_score:
			best_score = score
			best_point = candidate
	no_enemy_patrol_target = best_point
	no_enemy_patrol_timer = randf_range(1.15, 2.05)
	if randf() < 0.18:
		survival_turn *= -1.0

func _clamp_point_to_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(float(clamp(point.x, rect.position.x, rect.end.x)), float(clamp(point.y, rect.position.y, rect.end.y)))

func _survival_movement(delta: float) -> Vector2:
	survival_retarget_timer -= delta
	if survival_target == Vector2.ZERO or survival_retarget_timer <= 0.0 or global_position.distance_to(survival_target) < 34.0:
		_choose_survival_target()
	var desired: Vector2 = survival_target - global_position
	if desired.length_squared() <= 0.001:
		desired = _center_bias()
	desired = desired.normalized()
	var away: Vector2 = Vector2.ZERO
	var closest_distance: float = INF
	for monster in main.get_active_monsters():
		var offset: Vector2 = global_position - monster.global_position
		var distance: float = offset.length()
		closest_distance = min(closest_distance, distance)
		if distance > 0.01 and distance < 124.0:
			away += offset.normalized() * ((124.0 - distance) / 124.0)
	if away.length_squared() > 0.001:
		var strafe = away.normalized().rotated(survival_turn * 0.72)
		desired = (desired * 0.68 + _center_bias() * 0.86 + away.normalized() * 0.42 + strafe * 0.38).normalized()
		if closest_distance < 58.0:
			survival_retarget_timer = min(survival_retarget_timer, 0.35)
	else:
		desired = (desired * 0.58 + _center_bias() * 0.82).normalized()
	var edge_push = _edge_push(132.0)
	if edge_push.length_squared() > 0.001:
		desired = (desired * 0.46 + edge_push.normalized() * 1.45).normalized()
	return desired * _move_speed()

func _choose_survival_target() -> void:
	var safe_rect: Rect2 = main.ARENA_BOUNDS.grow(-108.0)
	var center: Vector2 = main.ARENA_BOUNDS.get_center()
	var best_point: Vector2 = global_position
	var best_score: float = -INF
	for _i in range(10):
		var candidate: Vector2 = Vector2(randf_range(safe_rect.position.x, safe_rect.end.x), randf_range(safe_rect.position.y, safe_rect.end.y))
		var nearest: float = 260.0
		for monster in main.get_active_monsters():
			nearest = min(nearest, candidate.distance_to(monster.global_position))
		var travel: float = global_position.distance_to(candidate)
		var center_distance: float = candidate.distance_to(center)
		var score: float = nearest * 0.58 - center_distance * 1.05 - min(travel, 220.0) * 0.10
		if score > best_score:
			best_score = score
			best_point = candidate
	survival_target = best_point
	survival_retarget_timer = randf_range(0.9, 1.8)
	if randf() < 0.52:
		survival_turn *= -1.0

func _center_bias() -> Vector2:
	var center: Vector2 = main.ARENA_BOUNDS.get_center()
	var to_center: Vector2 = center - global_position
	if to_center.length_squared() <= 0.001:
		return Vector2.ZERO
	return to_center.normalized()

func _edge_push(margin: float) -> Vector2:
	var bounds: Rect2 = main.ARENA_BOUNDS
	var result := Vector2.ZERO
	var left_distance := global_position.x - bounds.position.x
	var right_distance := bounds.end.x - global_position.x
	var top_distance := global_position.y - bounds.position.y
	var bottom_distance := bounds.end.y - global_position.y
	if left_distance < margin:
		result.x += (margin - left_distance) / margin
	if right_distance < margin:
		result.x -= (margin - right_distance) / margin
	if top_distance < margin:
		result.y += (margin - top_distance) / margin
	if bottom_distance < margin:
		result.y -= (margin - bottom_distance) / margin
	return result

func _tick_environment(delta: float) -> void:
	var effects: Dictionary = main.get_environment_effects_at(global_position)
	in_poison_pool = bool(effects.get("poison", false))
	environment_tick += delta
	if environment_tick < 1.0:
		return
	environment_tick -= 1.0
	if in_poison_pool:
		var poison_multiplier = float(stats.get("poison_damage_multiplier", 1.0))
		take_damage(float(effects.get("poison_dps", 6.0)) * poison_multiplier, null, {"source": "poison_pool", "dot": true, "always_hit": true})
	if bool(effects.get("light", false)):
		take_damage(float(effects.get("light_burn", 2.0)), null, {"source": "sun_beam", "dot": true, "always_hit": true})

func _attack(target: Node) -> void:
	attack_pose_time = ATTACK_POSE_DURATION
	var damage = float(stats.get("attack", 12.0))
	if statuses.has("weak"):
		damage *= 0.75
	if target.has_method("take_damage"):
		if main != null and main.audio_manager != null:
			main.audio_manager.play_sfx("punch")
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
	var seals: int = main.hero_seal_count()
	if seals >= 4:
		life_regen_timer += delta
		if life_regen_timer >= 3.0:
			life_regen_timer = 0.0
			heal(max_hp * 0.10)
			main.combat_system.spawn_floating_text(global_position + Vector2(-30, -78), _loc("生命圣泉", "LIFE SPRING"), Color("#7dffb3"), false)
	# Seal 6 is a final-life, low-health check: kill the hero during this window or it returns to full health once.
	if seals >= 5 and current_form_lives <= 1 and not eternal_used:
		if hp_ratio() <= 0.20:
			if eternal_countdown < 0.0:
				eternal_countdown = 3.0
				main.combat_system.spawn_floating_text(global_position + Vector2(-42, -92), _loc("永恒倒计时", "ETERNAL COUNTDOWN"), Color("#f5d477"), true)
			else:
				eternal_countdown -= delta
				if eternal_countdown <= 0.0 and active:
					eternal_used = true
					heal(max_hp)
					main.combat_system.spawn_floating_text(global_position + Vector2(-34, -92), _loc("永恒神血", "ETERNAL BLOOD"), Color("#fff3b1"), true)
		else:
			eternal_countdown = -1.0

func _move_speed() -> float:
	var value = float(stats.get("move_speed", 88.0))
	if statuses.has("slow"):
		value *= 1.0 - clamp(float(statuses["slow"]["value"]), 0.0, 0.85)
	var effects: Dictionary = main.get_environment_effects_at(global_position)
	if bool(effects.get("slow", false)):
		value *= 0.55
	return value

func _status_attack_speed_multiplier() -> float:
	var value = 1.35 if statuses.has("momentum") else 1.0
	if main != null:
		var effects: Dictionary = main.get_environment_effects_at(global_position)
		if bool(effects.get("light", false)):
			value *= 1.25 + float(stats.get("light_attack_speed_bonus", 0.0))
	return value

func _update_visual_fx(delta: float, current_velocity: Vector2, facing_hint_x: float) -> void:
	visual_time += delta
	attack_pose_time = max(0.0, attack_pose_time - delta)
	hurt_flash_time = max(0.0, hurt_flash_time - delta)
	hit_shake_time = max(0.0, hit_shake_time - delta)
	facing_change_cooldown = max(0.0, facing_change_cooldown - delta)
	var desired_facing: float = float(visual_facing)
	if abs(current_velocity.x) > 3.0:
		desired_facing = sign(current_velocity.x)
	elif abs(facing_hint_x) > 3.0:
		desired_facing = sign(facing_hint_x)
	if is_zero_approx(desired_facing):
		desired_facing = 1.0
	if sign(desired_facing) != sign(visual_facing) and facing_change_cooldown <= 0.0:
		visual_facing = desired_facing
		facing_change_cooldown = 1.0
	elif is_zero_approx(visual_facing):
		visual_facing = 1.0

	var move_speed = current_velocity.length()
	var move_amount = clamp(move_speed / 110.0, 0.0, 1.0)
	var bob = 0.0
	if not no_enemy_idle:
		bob = sin(visual_time * (3.2 if move_amount < 0.08 else 9.0 + move_amount * 3.0)) * (0.9 if move_amount < 0.08 else 2.4 + move_amount * 1.8)
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

	# Hero-to-monster red targeting line removed for a cleaner battlefield.

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

	# Armor visuals are disabled because the current build removed the hero armor mechanic.
	# Keeping the old broken-armor drawing caused two permanent white slash lines above the hero.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if in_poison_pool:
		draw_string(ThemeDB.fallback_font, Vector2(-28, 62), _loc("毒池侵蚀", "POISON POOL"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#baff86"))

	# Seal readout keeps the current boss rule visible during battle.
	if main != null and main.has_method("hero_seal_names"):
		var seal_text = "、".join(main.hero_seal_names())
		if main.hero_seal_count() >= 5 and current_form_lives <= 1 and not eternal_used:
			seal_text += _loc("、永恒", " · Eternal")
		draw_string(ThemeDB.fallback_font, Vector2(-46, 76), _loc("封印：", "SEALS: ") + seal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe4a3"))

	# v10.27: ordinary hero HP/armor bars are hidden; UIController shows the boss-style HP bar.
	# draw_rect(Rect2(Vector2(-31, -53), Vector2(62, 5)), Color("#3a1517"), true)
	# draw_rect(Rect2(Vector2(-31, -53), Vector2(62 * hp_ratio(), 5)), Color("#ef5549"), true)
	# draw_rect(Rect2(Vector2(-31, -61), Vector2(62, 4)), Color("#1e2934"), true)
