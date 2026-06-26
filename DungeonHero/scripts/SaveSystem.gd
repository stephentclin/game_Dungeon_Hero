extends Node
class_name SaveSystem

const BalanceConfigScript = preload("res://scripts/data/BalanceConfig.gd")
const SAVE_PATH = "user://goblin_commander_save.json"
const SAVE_VERSION = 9
const DEFAULT_SKILL_LEVELS := {
	"army_rewrite": 0,
	"attack": 0,
	"attack_speed": 0,
	"crit_chance": 0,
	"crit_damage": 0,
	"ink_yield": 0,
	"ink_reflux": 0,
	"normal_dice_unlock": 0,
	"power_dice_unlock": 0,
	"cooldown": 0,
	"quick_entrance": 0,
	"unlock_bomber": 0,
	"unlock_shaman": 0,
	"unlock_ogre": 0
}

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
	if not data.has("skill_levels") or typeof(data["skill_levels"]) != TYPE_DICTIONARY:
		data["skill_levels"] = DEFAULT_SKILL_LEVELS.duplicate(true)
	else:
		for skill_id in DEFAULT_SKILL_LEVELS.keys():
			if not data["skill_levels"].has(skill_id):
				data["skill_levels"][skill_id] = int(DEFAULT_SKILL_LEVELS[skill_id])
	if not data.has("settings") or typeof(data["settings"]) != TYPE_DICTIONARY:
		data["settings"] = fallback["settings"].duplicate(true)
	if not data.has("scores") or typeof(data["scores"]) != TYPE_ARRAY:
		data["scores"] = []
	var settings: Dictionary = data["settings"]
	if not settings.has("language"):
		settings["language"] = "en"
	if not settings.has("hero_lives"):
		settings["hero_lives"] = 5
	if not settings.has("deploy_tutorial_seen"):
		settings["deploy_tutorial_seen"] = true
	if not settings.has("player_name"):
		settings["player_name"] = "Player"
	settings["hero_lives"] = clampi(int(settings["hero_lives"]), 1, 5)
	# v9: default interface is English after updating this build.
	# After the player manually changes language in Settings, the saved v9 data keeps that choice.
	if int(data.get("save_version", 0)) < 9:
		settings["language"] = "en"
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
		"skill_levels": DEFAULT_SKILL_LEVELS.duplicate(true),
		"settings": {
			"language": "en",
			"hero_lives": 5,
			"deploy_tutorial_seen": true,
			"player_name": "Player"
		},
		"scores": []
	}
