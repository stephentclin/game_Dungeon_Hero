extends Resource
class_name MonsterData

@export var id: String = ""
@export var display_name: String = ""
@export var unlock_cost: int = 0
@export var command_cost: int = 10
@export var max_hp: float = 20.0
@export var attack: float = 4.0
@export var armor_damage: float = 0.0
@export var attack_range: float = 44.0
@export var attack_speed: float = 1.0
@export var move_speed: float = 70.0
@export var tags: Array[String] = []
@export var ability: String = ""
@export var color: Color = Color.WHITE
@export var level: int = 0
@export var balance: Dictionary = {}

# Physical identity. These are deliberately data-driven so future monsters can be
# heavy, tiny, immune to knockback, or better at crowd-pushing without new scripts.
@export var collision_radius: float = 16.0
@export var knockback_resistance: float = 1.0
@export var push_power: float = 1.0

func leveled_copy(level_value: int):
	var copy = duplicate(true)
	copy.level = level_value
	return copy

func hp_with_level() -> float:
	return max_hp * (1.0 + float(level) * 0.08)

func attack_with_level() -> float:
	return attack * (1.0 + float(level) * 0.08)

func cost_label() -> String:
	return "%s  CP:%d" % [display_name, command_cost]
