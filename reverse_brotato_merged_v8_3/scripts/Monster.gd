extends CharacterBody2D
class_name Monster

const WARRIOR_IDLE_TEXTURE = preload("res://assets/monster_forms/warrior/warrior_idle.png")
const WARRIOR_ATTACK_TEXTURE = preload("res://assets/monster_forms/warrior/warrior_attack.png")
const WARRIOR_DRAW_RECT = Rect2(Vector2(-42, -52), Vector2(84, 84))
const WARRIOR_ATTACK_DRAW_RECT = Rect2(Vector2(-50, -58), Vector2(100, 100))
const WARRIOR_ATTACK_POSE_DURATION = 0.20
const WARRIOR_ATTACK_HIT_TIME = 0.09
const WARRIOR_DEFAULT_FACING = -1.0
const ARCHER_IDLE_TEXTURE = preload("res://assets/monster_forms/archer/archer_idle.png")
const ARCHER_WALK_TEXTURES = [
	preload("res://assets/monster_forms/archer/archer_walk_1.png"),
	preload("res://assets/monster_forms/archer/archer_walk_2.png")
]
const ARCHER_ATTACK_TEXTURES = [
	ARCHER_IDLE_TEXTURE,
	preload("res://assets/monster_forms/archer/archer_attack_1.png"),
	preload("res://assets/monster_forms/archer/archer_attack_2.png"),
	preload("res://assets/monster_forms/archer/archer_attack_3.png"),
	preload("res://assets/monster_forms/archer/archer_attack_4.png"),
	ARCHER_IDLE_TEXTURE
]
const ARCHER_HIT_TEXTURE = preload("res://assets/monster_forms/archer/archer_hit.png")
const ARCHER_DRAW_RECT = Rect2(Vector2(-42, -64), Vector2(84, 92))
const ARCHER_ATTACK_DRAW_RECT = Rect2(Vector2(-48, -68), Vector2(96, 96))
const ARCHER_HIT_DRAW_RECT = Rect2(Vector2(-46, -66), Vector2(92, 94))
const ARCHER_ATTACK_POSE_DURATION = 0.54
const ARCHER_ATTACK_HIT_TIME = 0.18
const ARCHER_DEFAULT_FACING = 1.0
const ARCHER_WALK_FPS = 6.0
const SLIME_IDLE_TEXTURE = preload("res://assets/monster_forms/slime/slime_walk_1.png")
const SLIME_WALK_TEXTURES = [
	preload("res://assets/monster_forms/slime/slime_walk_1.png"),
	preload("res://assets/monster_forms/slime/slime_walk_2.png"),
	preload("res://assets/monster_forms/slime/slime_walk_3.png"),
	preload("res://assets/monster_forms/slime/slime_walk_1.png")
]
const SLIME_ATTACK_TEXTURES = [
	SLIME_IDLE_TEXTURE,
	preload("res://assets/monster_forms/slime/slime_attack.png"),
	SLIME_IDLE_TEXTURE
]
const SLIME_HIT_TEXTURE = preload("res://assets/monster_forms/slime/slime_hit.png")
const SLIME_DRAW_RECT = Rect2(Vector2(-48, -58), Vector2(96, 96))
const SLIME_ATTACK_DRAW_RECT = Rect2(Vector2(-56, -60), Vector2(112, 100))
const SLIME_HIT_DRAW_RECT = Rect2(Vector2(-50, -60), Vector2(100, 100))
const SLIME_ATTACK_POSE_DURATION = 0.34
const SLIME_ATTACK_HIT_TIME = 0.17
const SLIME_DEFAULT_FACING = -1.0
const SLIME_WALK_FPS = 5.5
const BOMBER_IDLE_TEXTURE = preload("res://assets/monster_forms/bomber/bomber_idle.png")
const BOMBER_WALK_TEXTURES = [
	preload("res://assets/monster_forms/bomber/bomber_walk_1.png"),
	preload("res://assets/monster_forms/bomber/bomber_walk_2.png"),
	preload("res://assets/monster_forms/bomber/bomber_walk_1.png")
]
const BOMBER_HIT_TEXTURE = preload("res://assets/monster_forms/bomber/bomber_hit.png")
const BOMBER_EXPLOSION_TEXTURE = preload("res://assets/monster_forms/bomber/bomber_explosion.png")
const BOMBER_DRAW_RECT = Rect2(Vector2(-52, -64), Vector2(104, 104))
const BOMBER_HIT_DRAW_RECT = Rect2(Vector2(-58, -68), Vector2(116, 112))
const BOMBER_EXPLOSION_DRAW_RECT = Rect2(Vector2(-68, -76), Vector2(136, 132))
const BOMBER_DEFAULT_FACING = -1.0
const BOMBER_WALK_FPS = 6.0
const BOMBER_DETONATION_DELAY = 0.16
const BOMBER_EXPLOSION_POSE_DURATION = 0.24
const SHAMAN_IDLE_TEXTURE = preload("res://assets/monster_forms/shaman/shaman_idle.png")
const SHAMAN_WALK_TEXTURES = [
	preload("res://assets/monster_forms/shaman/shaman_walk_1.png"),
	preload("res://assets/monster_forms/shaman/shaman_walk_2.png"),
	preload("res://assets/monster_forms/shaman/shaman_walk_1.png")
]
const SHAMAN_ATTACK_TEXTURE = preload("res://assets/monster_forms/shaman/shaman_attack.png")
const SHAMAN_IMPACT_TEXTURE = preload("res://assets/monster_forms/shaman/shaman_impact.png")
const SHAMAN_HEAL_TEXTURE = preload("res://assets/monster_forms/shaman/shaman_heal.png")
const SHAMAN_DRAW_RECT = Rect2(Vector2(-50, -70), Vector2(100, 104))
const SHAMAN_ATTACK_DRAW_RECT = Rect2(Vector2(-60, -74), Vector2(120, 108))
const SHAMAN_DEFAULT_FACING = -1.0
const SHAMAN_WALK_FPS = 6.0
const SHAMAN_ATTACK_POSE_DURATION = 0.34
const SHAMAN_ATTACK_HIT_TIME = 0.16
const SHAMAN_IMPACT_FX_SIZE = Vector2(84, 84)
const SHAMAN_HEAL_FX_SIZE = Vector2(56, 56)
const SHAMAN_IMPACT_FX_LIFE = 0.24
const SHAMAN_HEAL_FX_LIFE = 0.30
const OGRE_IDLE_TEXTURE = preload("res://assets/monster_forms/ogre/ogre_idle.png")
const OGRE_WALK_TEXTURES = [
	preload("res://assets/monster_forms/ogre/ogre_walk_1.png"),
	preload("res://assets/monster_forms/ogre/ogre_walk_2.png"),
	preload("res://assets/monster_forms/ogre/ogre_walk_1.png")
]
const OGRE_ATTACK_TEXTURES = [
	preload("res://assets/monster_forms/ogre/ogre_attack_1.png"),
	preload("res://assets/monster_forms/ogre/ogre_attack_2.png")
]
const OGRE_DRAW_RECT = Rect2(Vector2(-58, -72), Vector2(116, 108))
const OGRE_ATTACK_DRAW_RECT = Rect2(Vector2(-60, -74), Vector2(120, 110))
const OGRE_DEFAULT_FACING = -1.0
const OGRE_WALK_FPS = 4.8
const OGRE_ATTACK_POSE_DURATION = 0.32
const OGRE_ATTACK_HIT_TIME = 0.14
const SUMMON_FX_TEXTURES = [
	preload("res://assets/effects/summon/summon_fx_1.png"),
	preload("res://assets/effects/summon/summon_fx_2.png")
]
const SUMMON_FX_FRAME_DURATION = 0.08
const SUMMON_FX_FADE_DURATION = 0.12
const SUMMON_FX_TOTAL_DURATION = SUMMON_FX_FRAME_DURATION * 2.0 + SUMMON_FX_FADE_DURATION

const HIT_POSE_DURATION = 0.16

signal died(monster)

var active = false
var data
var main: Node
var hp = 1.0
var max_hp = 1.0
var attack_timer = 0.0
var berserk = false
var last_damage_source = null

# Physical movement state. Knockback is an impulse layered over ordinary pathing.
var collision_radius = 16.0
var knockback_velocity = Vector2.ZERO
var environment_tick = 0.0
var pool_empowered = false
var collision_shape: CollisionShape2D
var attack_pose_time = 0.0
var visual_facing = 1.0
var attack_hit_pending = false
var hit_pose_time = 0.0
var walk_cycle_time = 0.0
var bomber_detonation_time = 0.0
var bomber_detonation_exploded = false
var bomber_explosion_damage = 0.0
var bomber_explosion_radius = 0.0
var bomber_explosion_stun = 0.0
var bomber_explosion_tags = {}
var bomber_explosion_apply_damage = true
var wall_hit_cooldown = 0.0
var wall_charged_attack = false
var archer_shot_count = 0
var inherited_meals = []
var devour_cooldown = 0.0
var summon_lock_time = 0.0

func setup(monster_data, world_position: Vector2, owner: Node) -> void:
	data = monster_data
	main = owner
	global_position = world_position
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_radius = float(data.collision_radius)
	_ensure_collision_shape()
	collision_shape.set_deferred("disabled", false)
	max_hp = _max_hp()
	hp = max_hp
	attack_timer = randf_range(0.0, 0.35)
	active = true
	berserk = false
	modulate = Color.WHITE
	last_damage_source = null
	knockback_velocity = Vector2.ZERO
	environment_tick = 0.0
	pool_empowered = false
	attack_pose_time = 0.0
	visual_facing = 1.0
	attack_hit_pending = false
	hit_pose_time = 0.0
	walk_cycle_time = 0.0
	bomber_detonation_time = 0.0
	bomber_detonation_exploded = false
	bomber_explosion_damage = 0.0
	bomber_explosion_radius = 0.0
	bomber_explosion_stun = 0.0
	bomber_explosion_tags = {}
	bomber_explosion_apply_damage = true
	wall_hit_cooldown = 0.0
	wall_charged_attack = false
	archer_shot_count = 0
	inherited_meals.clear()
	devour_cooldown = 0.0
	summon_lock_time = SUMMON_FX_TOTAL_DURATION
	visible = true
	set_physics_process(true)
	set_process(true)
	queue_redraw()

func deactivate() -> void:
	active = false
	visible = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	pool_empowered = false
	attack_pose_time = 0.0
	attack_hit_pending = false
	hit_pose_time = 0.0
	walk_cycle_time = 0.0
	bomber_detonation_time = 0.0
	bomber_detonation_exploded = false
	wall_charged_attack = false
	inherited_meals.clear()
	summon_lock_time = 0.0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	set_process(false)

func collision_size() -> float:
	return collision_radius

func can_push_hero() -> bool:
	return active and data != null and not _is_bomber_detonating() and not _is_summoning() and not data.tags.has("ranged")

func push_weight() -> float:
	if _is_bomber_detonating() or _is_summoning():
		return 0.0
	return float(data.push_power) if data != null else 0.0

func apply_knockback(from_position: Vector2, strength: float) -> void:
	if not active or data == null:
		return
	var resistance = clamp(float(data.knockback_resistance), 0.0, 1.0)
	if resistance <= 0.0:
		# Slimes are deliberately rooted: the sword can wobble them, but not move them.
		return
	var direction = global_position - from_position
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT.rotated(randf() * TAU)
	knockback_velocity += direction.normalized() * strength * resistance
	knockback_velocity = knockback_velocity.limit_length(280.0)

func apply_map_impulse(direction: Vector2, strength: float) -> void:
	if not active or direction.length_squared() <= 0.001:
		return
	var resistance = 1.0
	if data != null:
		resistance = max(0.18, float(data.knockback_resistance))
	knockback_velocity += direction.normalized() * strength * resistance
	knockback_velocity = knockback_velocity.limit_length(320.0)

func on_wall_contact(inward_direction: Vector2) -> void:
	if not active or data == null or wall_hit_cooldown > 0.0:
		return
	wall_hit_cooldown = 0.42
	if data.id == "bomber":
		_start_bomber_detonation(0.0, float(data.balance.get("radius", 82.0)), current_attack(), 0.35, {"armor_bonus": data.armor_damage, "source": "wall_bomber", "trap": true, "always_hit": true})
		return
	if data.id == "slime":
		# Slimes ignore the wall penalty and bank a stronger next hit.
		wall_charged_attack = true
		knockback_velocity += inward_direction.normalized() * 55.0
		if main != null:
			main.combat_system.spawn_floating_text(global_position + Vector2(-20, -58), "墙弹 +10", Color("#b6ffcf"), false)
		return
	take_damage(6.0, null)
	knockback_velocity += inward_direction.normalized() * 220.0
	knockback_velocity = knockback_velocity.limit_length(280.0)
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-14, -58), "撞墙", Color("#f4ca7c"), false)

func _ensure_collision_shape() -> void:
	collision_layer = 2
	collision_mask = 6 # Other monsters (2) and the hero (4).
	if collision_shape == null or not is_instance_valid(collision_shape):
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	var circle = CircleShape2D.new()
	circle.radius = collision_radius
	collision_shape.shape = circle

func take_damage(amount: float, source = null, critical = false) -> void:
	if not active:
		return
	if _is_bomber_detonating():
		return
	last_damage_source = source
	hp -= amount
	hit_pose_time = HIT_POSE_DURATION
	if main != null:
		main.combat_system.spawn_floating_text(global_position + Vector2(-12, -26), "-%d" % int(amount), Color(1.0, 0.86, 0.48), critical)
	if hp <= 0.0:
		if data != null and data.ability == "suicide":
			var radius = float(data.balance.get("radius", 76.0))
			var death_damage = float(data.balance.get("death_damage", 8.0))
			_start_bomber_detonation(BOMBER_DETONATION_DELAY, radius * 0.75, death_damage, 0.0, {"source": "bomber_death"})
			queue_redraw()
			return
		die()
	queue_redraw()

func heal(amount: float, popup_offset := Vector2(-10, -48)) -> float:
	if not active or amount <= 0.0:
		return 0.0
	var restored = min(max_hp - hp, amount)
	if restored <= 0.0:
		return 0.0
	hp += restored
	if main != null:
		main.combat_system.spawn_floating_text(global_position + popup_offset, "+%d" % max(1, int(ceil(restored))), Color(0.42, 1.0, 0.48))
	queue_redraw()
	return restored

func die() -> void:
	if not active:
		return
	active = false
	visible = false
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	died.emit(self)

func apply_berserk(extra = 1.0) -> void:
	if not active:
		return
	berserk = true
	modulate = Color(1.0, 0.56, 0.30)
	queue_redraw()

func current_attack() -> float:
	var value = data.attack_with_level()
	if main != null:
		value *= main.monster_damage_multiplier(data)
		value *= main.guardian_damage_multiplier_for(self)
	if berserk:
		value *= main.berserk_damage_multiplier()
	# Slimes do not suffer from either pool. They metabolise it into a visible damage bonus.
	if pool_empowered:
		value += 10.0
	if wall_charged_attack:
		value += 10.0
	if data != null and data.id == "ogre":
		for meal in inherited_meals:
			value += float(meal.get("attack", 0.0))
	return value

func current_attack_speed() -> float:
	var value = data.attack_speed * (1.0 + float(data.level) * 0.04)
	if main != null:
		value *= main.monster_attack_speed_multiplier(data)
		value *= main.guardian_attack_speed_multiplier_for(self)
	if berserk:
		value *= main.berserk_attack_speed_multiplier()
	if main != null:
		var effects = main.get_environment_effects_at(global_position)
		if bool(effects.get("light", false)):
			value *= 1.30
	if data != null and data.id == "ogre":
		for meal in inherited_meals:
			value = max(value, float(meal.get("attack_speed", 0.0)))
	return value

func current_move_speed() -> float:
	var value = data.move_speed * (1.0 + float(data.level) * 0.03)
	if main != null:
		value *= main.monster_move_speed_multiplier(data)
		value *= main.guardian_move_speed_multiplier_for(self)
	if berserk and main != null:
		value *= main.berserk_move_speed_multiplier()
	if main != null:
		var effects = main.get_environment_effects_at(global_position)
		if bool(effects.get("slow", false)) and not _is_pool_immune():
			value *= 0.55
	return value

func _is_bomber_detonating() -> bool:
	return data != null and data.id == "bomber" and bomber_detonation_time > 0.0

func _start_bomber_detonation(delay: float, radius: float, damage: float, stun: float, tags: Dictionary, apply_damage = true) -> void:
	if data == null or data.id != "bomber":
		return
	bomber_detonation_time = max(0.0, delay) + BOMBER_EXPLOSION_POSE_DURATION
	bomber_detonation_exploded = false
	bomber_explosion_radius = radius
	bomber_explosion_damage = damage
	bomber_explosion_stun = stun
	bomber_explosion_tags = tags.duplicate(true)
	bomber_explosion_apply_damage = apply_damage
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	attack_pose_time = 0.0
	attack_hit_pending = false
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if delay <= 0.0:
		_perform_bomber_explosion()
	queue_redraw()

func _tick_bomber_detonation(delta: float) -> bool:
	if not _is_bomber_detonating():
		return false
	bomber_detonation_time = max(0.0, bomber_detonation_time - delta)
	if not bomber_detonation_exploded and bomber_detonation_time <= BOMBER_EXPLOSION_POSE_DURATION:
		_perform_bomber_explosion()
	if bomber_detonation_time <= 0.0:
		die()
	else:
		queue_redraw()
	return true

func _perform_bomber_explosion() -> void:
	if bomber_detonation_exploded:
		return
	bomber_detonation_exploded = true
	if main != null and main.combat_system != null:
		main.combat_system.spawn_explosion(
			global_position,
			bomber_explosion_radius,
			bomber_explosion_damage,
			bomber_explosion_stun,
			bomber_explosion_tags,
			bomber_explosion_apply_damage
		)

func _process(delta: float) -> void:
	if not active:
		return
	if summon_lock_time > 0.0:
		summon_lock_time = max(0.0, summon_lock_time - delta)
		queue_redraw()

func _physics_process(delta: float) -> void:
	if not active or main == null or main.phase != "battle":
		return
	wall_hit_cooldown = max(0.0, wall_hit_cooldown - delta)
	devour_cooldown = max(0.0, devour_cooldown - delta)
	_try_devour_low_hp_ally()
	var previous_attack_pose_time = attack_pose_time
	attack_pose_time = max(0.0, attack_pose_time - delta)
	hit_pose_time = max(0.0, hit_pose_time - delta)
	var hit_time = _current_attack_hit_time()
	if attack_hit_pending and previous_attack_pose_time > hit_time and attack_pose_time <= hit_time:
		attack_hit_pending = false
		_perform_attack_hit()
	if _tick_bomber_detonation(delta):
		return
	if _is_summoning():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	_tick_environment(delta)
	if not active or main.hero == null or not main.hero.active:
		return
	attack_timer = max(0.0, attack_timer - delta)
	var hero_pos: Vector2 = main.hero.global_position
	var distance = global_position.distance_to(hero_pos)
	var attack_range = data.attack_range
	var movement = Vector2.ZERO
	if data.ability == "suicide" and distance <= float(data.balance.get("trigger_range", 38.0)):
		_start_bomber_detonation(0.0, float(data.balance.get("radius", 82.0)), current_attack(), 0.35, {"armor_bonus": data.armor_damage, "source": "bomber"})
		return
	if distance > attack_range:
		var desired = (hero_pos - global_position).normalized()
		if abs(desired.x) > 0.01:
			visual_facing = sign(desired.x) * _default_texture_facing()
		desired += _avoidance_vector() * 0.7
		movement = desired.normalized() * current_move_speed()
	else:
		if abs(hero_pos.x - global_position.x) > 1.0:
			visual_facing = sign(hero_pos.x - global_position.x) * _default_texture_facing()
		if attack_pose_time > 0.0:
			movement = Vector2.ZERO
		elif attack_timer <= 0.0:
			_begin_attack()
			attack_timer = 1.0 / max(0.1, current_attack_speed())
	if movement.length_squared() > 0.1 and attack_pose_time <= 0.0:
		walk_cycle_time += delta
	velocity = movement + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	move_and_slide()
	main.resolve_wall_contact(self)
	queue_redraw()

func _is_pool_immune() -> bool:
	return data != null and data.id == "slime"

func _tick_environment(delta: float) -> void:
	var effects = main.get_environment_effects_at(global_position)
	var any_pool = bool(effects.get("slow", false)) or bool(effects.get("poison", false))
	pool_empowered = _is_pool_immune() and any_pool
	environment_tick += delta
	if environment_tick < 1.0:
		return
	environment_tick -= 1.0
	if pool_empowered:
		heal(max_hp * 0.01)
	elif bool(effects.get("poison", false)):
		# The toxic pool damages player units too, so dragging the fight through it is a decision.
		take_damage(float(effects.get("poison_dps", 6.0)), null)
	if bool(effects.get("light", false)) and not _is_pool_immune():
		take_damage(float(effects.get("light_burn", 2.0)), null)

func _begin_attack() -> void:
	if data.id == "warrior":
		attack_pose_time = WARRIOR_ATTACK_POSE_DURATION
		attack_hit_pending = true
		return
	if data.id == "archer":
		attack_pose_time = ARCHER_ATTACK_POSE_DURATION
		attack_hit_pending = true
		return
	if data.id == "slime":
		attack_pose_time = SLIME_ATTACK_POSE_DURATION
		attack_hit_pending = true
		return
	if data.id == "shaman":
		attack_pose_time = SHAMAN_ATTACK_POSE_DURATION
		attack_hit_pending = true
		return
	if data.id == "ogre":
		attack_pose_time = OGRE_ATTACK_POSE_DURATION
		attack_hit_pending = true
		return
	_perform_attack_hit()

func _current_attack_hit_time() -> float:
	if data == null:
		return 0.0
	match data.id:
		"warrior":
			return WARRIOR_ATTACK_HIT_TIME
		"archer":
			return ARCHER_ATTACK_HIT_TIME
		"slime":
			return SLIME_ATTACK_HIT_TIME
		"shaman":
			return SHAMAN_ATTACK_HIT_TIME
		"ogre":
			return OGRE_ATTACK_HIT_TIME
		_:
			return 0.0

func _default_texture_facing() -> float:
	if data == null:
		return WARRIOR_DEFAULT_FACING
	match data.id:
		"archer":
			return ARCHER_DEFAULT_FACING
		"slime":
			return SLIME_DEFAULT_FACING
		"bomber":
			return BOMBER_DEFAULT_FACING
		"shaman":
			return SHAMAN_DEFAULT_FACING
		"ogre":
			return OGRE_DEFAULT_FACING
	return WARRIOR_DEFAULT_FACING

func _perform_attack_hit() -> void:
	if data.tags.has("ranged"):
		var critical = false
		if main != null:
			critical = randf() < main.ranged_crit_chance()
		var amount = current_attack() * (1.75 if critical else 1.0)
		var tags = _attack_tags(critical)
		if data.id == "archer":
			archer_shot_count += 1
			if archer_shot_count % 3 == 0:
				tags["marked_arrow"] = true
				tags["always_hit"] = true
				if main != null:
					main.combat_system.spawn_floating_text(global_position + Vector2(-18, -62), "标记箭", Color("#fff2a0"), false)
		main.combat_system.fire_projectile(global_position, main.hero, amount, data.color, tags, self)
		wall_charged_attack = false
		return
	var tags = _attack_tags(false)
	var dealt = main.apply_damage_to_hero(current_attack(), self, tags)
	if data.id == "ogre" and dealt > 0.0:
		heal(dealt * 0.35)
	_apply_special_status()
	wall_charged_attack = false

func on_projectile_hit(hit_position: Vector2, _target: Node2D, _damage: float, _tags: Dictionary) -> void:
	if not active or data == null or main == null or main.combat_system == null:
		return
	if data.id == "shaman":
		main.combat_system.spawn_sprite_fx(hit_position, SHAMAN_IMPACT_TEXTURE, SHAMAN_IMPACT_FX_SIZE, SHAMAN_IMPACT_FX_LIFE)
		# A shaman heals allies around the enemy it struck, but only allies inside the shaman's own attack range qualify.
		var heal_radius = float(data.balance.get("heal_radius", 92.0))
		var heal_amount = float(data.balance.get("heal_amount", 10.0)) + float(data.level) * 2.0
		for ally in main.get_active_monsters():
			if ally == null or not is_instance_valid(ally) or not ally.active:
				continue
			if ally.global_position.distance_to(hit_position) > heal_radius:
				continue
			if ally.global_position.distance_to(global_position) > data.attack_range:
				continue
			main.combat_system.spawn_sprite_fx(ally.global_position, SHAMAN_HEAL_TEXTURE, SHAMAN_HEAL_FX_SIZE, SHAMAN_HEAL_FX_LIFE, Vector2(0, 10))
			ally.heal(heal_amount)
		# Voodoo impact also supplies the poison needed to break the Element seal.
		main.hero.apply_status("poison", 5.0, 2.0)

func _attack_tags(critical: bool) -> Dictionary:
	return {
		"armor_bonus": data.armor_damage,
		"source": data.id,
		"critical": critical,
		"ability": data.ability,
		"ranged": data.tags.has("ranged")
	}

func _apply_special_status() -> void:
	if main == null or main.hero == null:
		return
	match data.ability:
		"slow":
			main.hero.apply_status("slow", float(data.balance.get("slow_duration", 3.0)), float(data.balance.get("slow_strength", 0.45)))
			main.rage_system.reduce(2.4)
		"poison":
			main.hero.apply_status("poison", float(data.balance.get("poison_duration", 5.0)), float(data.balance.get("poison_dps", 2.0)))
			main.rage_system.reduce(4.0 + main.poison_rage_bonus())
		"armor_breaker":
			main.rage_system.reduce(1.2)
			_apply_inherited_ogre_traits()

func _try_devour_low_hp_ally() -> void:
	if data == null or data.id != "ogre" or devour_cooldown > 0.0:
		return
	for ally in main.get_active_monsters():
		if ally == self or ally.data == null or ally.data.id == "ogre" or not ally.active:
			continue
		if ally.global_position.distance_to(global_position) > data.attack_range:
			continue
		if ally.hp / max(1.0, ally.max_hp) > 0.05:
			continue
		var meal = {
			"attack": ally.current_attack(),
			"attack_speed": ally.current_attack_speed(),
			"ability": str(ally.data.ability),
			"name": str(ally.data.display_name)
		}
		inherited_meals.append(meal)
		while inherited_meals.size() > 3:
			inherited_meals.pop_front()
		ally.deactivate()
		heal(max_hp * 0.10)
		devour_cooldown = 0.8
		if main != null:
			main.combat_system.spawn_floating_text(global_position + Vector2(-24, -78), "吞噬：%s" % meal["name"], Color("#ffce77"), true)
		return

func _has_inherited_trait(ability_id: String) -> bool:
	for meal in inherited_meals:
		if str(meal.get("ability", "")) == ability_id:
			return true
	return false

func _apply_inherited_ogre_traits() -> void:
	if main == null or main.hero == null:
		return
	if _has_inherited_trait("slow"):
		main.hero.apply_status("slow", 2.0, 0.35)
	if _has_inherited_trait("ritual_heal"):
		for ally in main.get_active_monsters():
			if ally.active and ally.global_position.distance_to(main.hero.global_position) <= 84.0 and ally.global_position.distance_to(global_position) <= data.attack_range:
				ally.heal(8.0)
	if _has_inherited_trait("suicide"):
		main.apply_damage_to_hero(8.0, self, {"source": "ogre_inherited_bomb", "trap": true, "always_hit": true})

func _avoidance_vector() -> Vector2:
	var result = Vector2.ZERO
	for other in main.get_active_monsters():
		if other == self:
			continue
		var distance = global_position.distance_to(other.global_position)
		if distance > 0.1 and distance < 25.0:
			result += (global_position - other.global_position).normalized() * (25.0 - distance) / 25.0
	return result

func _max_hp() -> float:
	var value = data.hp_with_level()
	if main != null:
		value *= main.monster_hp_multiplier(data)
	return value

func _is_summoning() -> bool:
	return summon_lock_time > 0.0

func _draw_summon_fx() -> void:
	if not _is_summoning() or SUMMON_FX_TEXTURES.is_empty():
		return
	var elapsed = SUMMON_FX_TOTAL_DURATION - summon_lock_time
	var frame = 0 if elapsed < SUMMON_FX_FRAME_DURATION else 1
	frame = clampi(frame, 0, SUMMON_FX_TEXTURES.size() - 1)
	var alpha = 1.0
	var fade_start = SUMMON_FX_FRAME_DURATION * 2.0
	if elapsed > fade_start:
		alpha = clamp(1.0 - (elapsed - fade_start) / SUMMON_FX_FADE_DURATION, 0.0, 1.0)
	var size_value = max(44.0, collision_radius * 3.2)
	var size = Vector2.ONE * size_value
	var center = Vector2(0, 14)
	draw_texture_rect(SUMMON_FX_TEXTURES[frame], Rect2(center - size * 0.5, size), false, Color(1.0, 1.0, 1.0, alpha))

func _draw() -> void:
	if not active or data == null:
		return

	var radius = 14.0
	if data.tags.has("tank"):
		radius = 20.0
	elif data.ability == "suicide":
		radius = 13.0

	# All player units share a green base ring, so allegiance is readable at a glance.
	_draw_summon_fx()
	draw_ellipse_shadow(radius)
	draw_arc(Vector2(0, 14), radius + 5.0, 0.0, TAU, 24, Color(0.30, 1.0, 0.46, 0.70), 2.0)

	match data.id:
		"warrior":
			_draw_warrior(radius)
		"archer":
			_draw_archer(radius)
		"slime":
			_draw_slime_guard(radius)
		"bomber":
			_draw_bomber(radius)
		"shaman":
			_draw_shaman(radius)
		"ogre":
			_draw_ogre(radius)
		_:
			draw_circle(Vector2.ZERO, radius, data.color)

	if _is_bomber_detonating():
		return

	if berserk:
		draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 28, Color(1.0, 0.42, 0.12, 0.95), 2.8)
		draw_string(ThemeDB.fallback_font, Vector2(-18, 34), "狂暴", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffb058"))
	if pool_empowered:
		draw_arc(Vector2.ZERO, radius + 13.0, 0.0, TAU, 28, Color(0.30, 1.0, 0.74, 0.90), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-22, 47), "沼泽强化 +10", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#baffce"))
	if main != null and main.guardian_inspiration_for(self):
		draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 28, Color(0.52, 1.0, 0.66, 0.96), 2.2)
		draw_string(ThemeDB.fallback_font, Vector2(-16, 60), "鼓舞", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#caffb7"))

	# Health bar and compact unit name.
	var ratio = clamp(hp / max_hp, 0.0, 1.0)
	var bar_y = -31.0
	var label_y = -37.0
	if data.id == "archer":
		bar_y = -78.0
		label_y = -84.0
	elif data.id == "slime":
		bar_y = -68.0
		label_y = -74.0
	elif data.id == "bomber":
		bar_y = -58.0
		label_y = -64.0
	elif data.id == "shaman":
		bar_y = -80.0
		label_y = -86.0
	elif data.id == "ogre":
		bar_y = -82.0
		label_y = -88.0
	draw_rect(Rect2(Vector2(-20, bar_y), Vector2(40, 5)), Color("#17311e"), true)
	draw_rect(Rect2(Vector2(-20, bar_y), Vector2(40 * ratio, 5)), Color("#57e365"), true)
	draw_string(ThemeDB.fallback_font, Vector2(-22, label_y), _short_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d8ffe0"))

func draw_ellipse_shadow(radius: float) -> void:
	draw_circle(Vector2(0, 15), radius * 0.78, Color(0.02, 0.05, 0.04, 0.50))

func _draw_warrior(radius: float) -> void:
	if WARRIOR_IDLE_TEXTURE != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_facing, 1.0))
		if attack_pose_time > 0.0 and WARRIOR_ATTACK_TEXTURE != null:
			draw_texture_rect(WARRIOR_ATTACK_TEXTURE, WARRIOR_ATTACK_DRAW_RECT, false)
		else:
			draw_texture_rect(WARRIOR_IDLE_TEXTURE, WARRIOR_DRAW_RECT, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_circle(Vector2(0, 1), radius, Color("#5bc95d"))
	draw_circle(Vector2(0, -7), radius * 0.58, Color("#88e26f"))
	draw_circle(Vector2(-4, -7), 1.7, Color("#173521"))
	draw_circle(Vector2(4, -7), 1.7, Color("#173521"))
	draw_circle(Vector2(-11, 5), 6.0, Color("#6d8f7a"))
	draw_line(Vector2(11, 6), Vector2(22, -16), Color("#ded8bc"), 3.0)
	draw_line(Vector2(17, -8), Vector2(26, -18), Color("#d9e6e6"), 2.0)

func _draw_archer(radius: float) -> void:
	var texture = _archer_texture()
	var rect = _archer_draw_rect()
	if texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_facing, 1.0))
		draw_texture_rect(texture, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	draw_circle(Vector2(0, 1), radius, Color("#5b9ed3"))
	draw_circle(Vector2(0, -7), radius * 0.58, Color("#9bd0e4"))
	draw_circle(Vector2(-4, -7), 1.7, Color("#172c39"))
	draw_circle(Vector2(4, -7), 1.7, Color("#172c39"))
	draw_arc(Vector2(13, 1), 11.0, -1.18, 1.18, 18, Color("#8a5d35"), 2.0)
	draw_line(Vector2(4, 1), Vector2(23, 1), Color("#f4e9bd"), 1.0)
	draw_circle(Vector2(13, 1), 1.7, Color("#f4e9bd"))

func _archer_texture():
	if hit_pose_time > 0.0:
		return ARCHER_HIT_TEXTURE
	if attack_pose_time > 0.0:
		var progress = 1.0 - attack_pose_time / ARCHER_ATTACK_POSE_DURATION
		var frame = clamp(int(floor(progress * ARCHER_ATTACK_TEXTURES.size())), 0, ARCHER_ATTACK_TEXTURES.size() - 1)
		return ARCHER_ATTACK_TEXTURES[frame]
	if velocity.length_squared() > 0.1 and ARCHER_WALK_TEXTURES.size() > 0:
		var frame = int(floor(walk_cycle_time * ARCHER_WALK_FPS)) % ARCHER_WALK_TEXTURES.size()
		return ARCHER_WALK_TEXTURES[frame]
	return ARCHER_IDLE_TEXTURE

func _archer_draw_rect() -> Rect2:
	if hit_pose_time > 0.0:
		return ARCHER_HIT_DRAW_RECT
	if attack_pose_time > 0.0:
		return ARCHER_ATTACK_DRAW_RECT
	return ARCHER_DRAW_RECT

func _draw_slime_guard(radius: float) -> void:
	var texture = _slime_texture()
	var rect = _slime_draw_rect()
	if texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_facing, 1.0))
		draw_texture_rect(texture, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	var jelly = PackedVector2Array([
		Vector2(-radius, 8), Vector2(-radius * 0.72, -7),
		Vector2(-radius * 0.28, -radius), Vector2(radius * 0.32, -radius * 0.92),
		Vector2(radius, -4), Vector2(radius * 0.78, 10),
		Vector2(radius * 0.20, 15), Vector2(-radius * 0.55, 14)
	])
	draw_colored_polygon(jelly, Color("#39c983"))
	draw_arc(Vector2.ZERO, radius * 0.84, 0.12, PI - 0.12, 18, Color("#b4ffd0"), 1.5)
	draw_circle(Vector2(-5, 0), 2.1, Color("#123f2c"))
	draw_circle(Vector2(5, 0), 2.1, Color("#123f2c"))

func _slime_texture():
	if hit_pose_time > 0.0:
		return SLIME_HIT_TEXTURE
	if attack_pose_time > 0.0:
		var progress = 1.0 - attack_pose_time / SLIME_ATTACK_POSE_DURATION
		var frame = clamp(int(floor(progress * SLIME_ATTACK_TEXTURES.size())), 0, SLIME_ATTACK_TEXTURES.size() - 1)
		return SLIME_ATTACK_TEXTURES[frame]
	if velocity.length_squared() > 0.1 and SLIME_WALK_TEXTURES.size() > 0:
		var frame = int(floor(walk_cycle_time * SLIME_WALK_FPS)) % SLIME_WALK_TEXTURES.size()
		return SLIME_WALK_TEXTURES[frame]
	return SLIME_IDLE_TEXTURE

func _slime_draw_rect() -> Rect2:
	if hit_pose_time > 0.0:
		return SLIME_HIT_DRAW_RECT
	if attack_pose_time > 0.0:
		return SLIME_ATTACK_DRAW_RECT
	return SLIME_DRAW_RECT

func _draw_bomber(radius: float) -> void:
	var texture = _bomber_texture()
	var rect = _bomber_draw_rect()
	if texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_facing, 1.0))
		draw_texture_rect(texture, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	draw_circle(Vector2(0, 3), radius, Color("#f29942"))
	draw_circle(Vector2(0, -6), radius * 0.52, Color("#ffd171"))
	draw_circle(Vector2(-4, -6), 1.5, Color("#482718"))
	draw_circle(Vector2(4, -6), 1.5, Color("#482718"))
	draw_circle(Vector2(12, 10), 8.0, Color("#32363b"))
	draw_line(Vector2(15, 3), Vector2(20, -4), Color("#f9d85e"), 1.8)
	draw_circle(Vector2(21, -5), 2.2, Color("#ffef88"))

func _bomber_texture():
	if _is_bomber_detonating():
		if not bomber_detonation_exploded and hit_pose_time > 0.0:
			return BOMBER_HIT_TEXTURE
		return BOMBER_EXPLOSION_TEXTURE
	if hit_pose_time > 0.0:
		return BOMBER_HIT_TEXTURE
	if velocity.length_squared() > 0.1 and BOMBER_WALK_TEXTURES.size() > 0:
		var frame = int(floor(walk_cycle_time * BOMBER_WALK_FPS)) % BOMBER_WALK_TEXTURES.size()
		return BOMBER_WALK_TEXTURES[frame]
	return BOMBER_IDLE_TEXTURE

func _bomber_draw_rect() -> Rect2:
	if _is_bomber_detonating() and (bomber_detonation_exploded or hit_pose_time <= 0.0):
		return BOMBER_EXPLOSION_DRAW_RECT
	if hit_pose_time > 0.0:
		return BOMBER_HIT_DRAW_RECT
	return BOMBER_DRAW_RECT

func _draw_shaman(radius: float) -> void:
	var texture = _shaman_texture()
	var rect = _shaman_draw_rect()
	if texture != null:
		var facing = visual_facing
		if attack_pose_time > 0.0:
			facing = -visual_facing
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
		draw_texture_rect(texture, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	draw_colored_polygon(PackedVector2Array([
		Vector2(-radius, 14), Vector2(-11, -2), Vector2(0, -17),
		Vector2(11, -2), Vector2(radius, 14)
	]), Color("#9b6bd3"))
	draw_circle(Vector2(0, -7), radius * 0.50, Color("#93d66d"))
	draw_circle(Vector2(-4, -7), 1.5, Color("#28203e"))
	draw_circle(Vector2(4, -7), 1.5, Color("#28203e"))
	draw_line(Vector2(16, 11), Vector2(20, -17), Color("#70553a"), 3.0)
	draw_circle(Vector2(20, -19), 4.0, Color("#d08cff"))

func _shaman_texture():
	if attack_pose_time > 0.0:
		return SHAMAN_ATTACK_TEXTURE
	if velocity.length_squared() > 0.1 and SHAMAN_WALK_TEXTURES.size() > 0:
		var frame = int(floor(walk_cycle_time * SHAMAN_WALK_FPS)) % SHAMAN_WALK_TEXTURES.size()
		return SHAMAN_WALK_TEXTURES[frame]
	return SHAMAN_IDLE_TEXTURE

func _shaman_draw_rect() -> Rect2:
	if attack_pose_time > 0.0:
		return SHAMAN_ATTACK_DRAW_RECT
	return SHAMAN_DRAW_RECT

func _draw_ogre(radius: float) -> void:
	var texture = _ogre_texture()
	var rect = _ogre_draw_rect()
	if texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual_facing, 1.0))
		draw_texture_rect(texture, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	draw_circle(Vector2.ZERO, radius, Color("#b59b5a"))
	draw_circle(Vector2(0, -8), radius * 0.65, Color("#d1ba72"))
	draw_circle(Vector2(-6, -8), 2.0, Color("#372f20"))
	draw_circle(Vector2(6, -8), 2.0, Color("#372f20"))
	draw_circle(Vector2(-7, 1), 2.0, Color("#f5f0d8"))
	draw_circle(Vector2(7, 1), 2.0, Color("#f5f0d8"))
	draw_line(Vector2(-radius + 2, 5), Vector2(-radius - 12, -8), Color("#7a6040"), 4.0)
	draw_circle(Vector2(-radius - 13, -9), 5.0, Color("#6c6c71"))

func _ogre_texture():
	if attack_pose_time > 0.0 and OGRE_ATTACK_TEXTURES.size() > 0:
		var progress = 1.0 - attack_pose_time / OGRE_ATTACK_POSE_DURATION
		var frame = clamp(int(floor(progress * OGRE_ATTACK_TEXTURES.size())), 0, OGRE_ATTACK_TEXTURES.size() - 1)
		return OGRE_ATTACK_TEXTURES[frame]
	if velocity.length_squared() > 0.1 and OGRE_WALK_TEXTURES.size() > 0:
		var frame = int(floor(walk_cycle_time * OGRE_WALK_FPS)) % OGRE_WALK_TEXTURES.size()
		return OGRE_WALK_TEXTURES[frame]
	return OGRE_IDLE_TEXTURE

func _ogre_draw_rect() -> Rect2:
	if attack_pose_time > 0.0:
		return OGRE_ATTACK_DRAW_RECT
	return OGRE_DRAW_RECT

func _short_name() -> String:
	match data.id:
		"warrior":
			return "战士"
		"archer":
			return "弓手"
		"slime":
			return "史莱姆"
		"bomber":
			return "炸弹"
		"shaman":
			return "萨满"
		"ogre":
			return "食人魔"
		_:
			return data.display_name
