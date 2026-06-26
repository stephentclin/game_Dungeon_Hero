extends Resource
class_name HeroUpgradeData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var stat_changes: Dictionary = {}

func apply_to(stats: Dictionary) -> void:
	for key in stat_changes.keys():
		var value = stat_changes[key]
		if typeof(value) == TYPE_BOOL:
			stats[key] = value
		elif typeof(value) == TYPE_STRING:
			stats[key] = value
		elif stats.has(key):
			stats[key] += value
		else:
			stats[key] = value
