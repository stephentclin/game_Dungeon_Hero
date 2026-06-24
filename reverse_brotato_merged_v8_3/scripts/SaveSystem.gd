extends Node
class_name SaveSystem

const BalanceConfigScript = preload("res://scripts/data/BalanceConfig.gd")
const SAVE_PATH = "user://goblin_commander_save.json"
const SAVE_VERSION = 4

func load_progress(monster_catalog: Dictionary) -> Dictionary:
	var fallback = _default_data(monster_catalog)
	if not FileAccess.file_exists(SAVE_PATH):
		return fallback
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return fallback
	var data: Dictionary = parsed
	if not data.has("gold"):
		data["gold"] = 0
	if not data.has("skill_points"):
		data["skill_points"] = 0
	if not data.has("unlocked"):
		data["unlocked"] = fallback["unlocked"].duplicate()
	if not data.has("upgrades"):
		data["upgrades"] = fallback["upgrades"].duplicate(true)
	for id in monster_catalog.keys():
		if not data["upgrades"].has(id):
			data["upgrades"][id] = 0
	for id in BalanceConfigScript.DEFAULT_UNLOCKED:
		if not data["unlocked"].has(id):
			data["unlocked"].append(id)
	if not data.has("settings") or typeof(data["settings"]) != TYPE_DICTIONARY:
		data["settings"] = fallback["settings"].duplicate(true)
	var settings: Dictionary = data["settings"]
	if not settings.has("language"):
		settings["language"] = "zh"
	if not settings.has("hero_lives"):
		settings["hero_lives"] = 5
	if not settings.has("deploy_tutorial_seen"):
		settings["deploy_tutorial_seen"] = false
	settings["hero_lives"] = clampi(int(settings["hero_lives"]), 1, 5)
	data["save_version"] = SAVE_VERSION
	return data

func save_progress(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))

func _default_data(monster_catalog: Dictionary) -> Dictionary:
	var upgrades = {}
	for id in monster_catalog.keys():
		upgrades[id] = 0
	return {
		"save_version": SAVE_VERSION,
		"gold": 0,
		"skill_points": 0,
		"unlocked": BalanceConfigScript.DEFAULT_UNLOCKED.duplicate(),
		"upgrades": upgrades,
		"settings": {
			"language": "zh",
			"hero_lives": 5,
			"deploy_tutorial_seen": false
		}
	}
