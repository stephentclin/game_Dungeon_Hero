extends Node
class_name MonsterSpawner

const MonsterScene = preload("res://scenes/Monster.tscn")

var main: Node
var parent_node: Node
var pool: Array = []

func setup(owner: Node, spawn_parent: Node) -> void:
	main = owner
	parent_node = spawn_parent

func spawn(data, level: int, world_position: Vector2):
	var monster = _get_monster()
	monster.setup(data.leveled_copy(level), world_position, main)
	return monster

func get_active_monsters() -> Array:
	var result: Array = []
	for monster in pool:
		if monster.active:
			result.append(monster)
	return result

func despawn_all() -> void:
	for monster in pool:
		monster.deactivate()

func _get_monster():
	for monster in pool:
		if not monster.active:
			return monster
	var monster = MonsterScene.instantiate()
	pool.append(monster)
	parent_node.add_child(monster)
	var callback = Callable(main, "_on_monster_died")
	if not monster.died.is_connected(callback):
		monster.died.connect(callback)
	return monster
