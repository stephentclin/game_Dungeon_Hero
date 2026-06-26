extends RefCounted
class_name PuzzleToUnitMapper

const PIECE_KEYS := [
	"soldier_block",
	"archer_block",
	"bomber_block",
	"shaman_block",
	"ogre_block",
	"slime_block"
]

const MATCH_SUMMON_PREVIEW := "warrior"

const PIECE_LABELS := {
	"soldier_block": "MON",
	"archer_block": "ARC",
	"bomber_block": "BOM",
	"shaman_block": "SHA",
	"ogre_block": "OGR",
	"slime_block": "SLM"
}

const PIECE_COLORS := {
	"soldier_block": Color("#4aa3ff"),
	"archer_block": Color("#9a6a3a"),
	"bomber_block": Color("#ff4a4a"),
	"shaman_block": Color("#ffd64a"),
	"ogre_block": Color("#4fe06f"),
	"slime_block": Color("#b45cff")
}

const PIECE_TEXTURES := {
	"soldier_block": "res://assets/ui/puzzle_blocks/blue.png",
	"archer_block": "res://assets/ui/puzzle_blocks/brown.png",
	"bomber_block": "res://assets/ui/puzzle_blocks/red.png",
	"shaman_block": "res://assets/ui/puzzle_blocks/yellow.png",
	"ogre_block": "res://assets/ui/puzzle_blocks/green.png",
	"slime_block": "res://assets/ui/puzzle_blocks/purple.png"
}

func piece_key(piece_type: int) -> String:
	piece_type = _base_type(piece_type)
	if piece_type < 0 or piece_type >= PIECE_KEYS.size():
		return PIECE_KEYS[0]
	return PIECE_KEYS[piece_type]

func preview_unit_for_piece(piece_type: int) -> String:
	return MATCH_SUMMON_PREVIEW

func piece_label(piece_type: int) -> String:
	return str(PIECE_LABELS.get(piece_key(piece_type), "MON"))

func piece_color(piece_type: int) -> Color:
	return PIECE_COLORS.get(piece_key(piece_type), Color.WHITE)

func texture_path(piece_type: int) -> String:
	return str(PIECE_TEXTURES.get(piece_key(piece_type), ""))

func resolve_match(piece_type: int, shape: String, combo_count: int) -> Dictionary:
	piece_type = _base_type(piece_type)
	var result := {
		"unit_type": "",
		"amount": 0,
		"power_level": 1,
		"reward_ink": 1,
		"reward_gold": 1,
		"match_label": _label_for_shape(shape),
		"sfx_name": "match_3"
	}

	match shape:
		"cross":
			result.reward_ink = 5
			result.reward_gold = 4
			result.power_level = 3
			result.sfx_name = "match_special"
			result.unit_type = "ogre"
			result.amount = 1
		"t":
			result.reward_ink = 3
			result.reward_gold = 2
			result.power_level = 2
			result.sfx_name = "match_special"
			result.unit_type = "shaman"
			result.amount = 1
		"l":
			result.reward_ink = 3
			result.reward_gold = 2
			result.power_level = 2
			result.sfx_name = "match_special"
			result.unit_type = "slime"
			result.amount = 1
		"five":
			result.reward_ink = 4
			result.reward_gold = 3
			result.power_level = 3
			result.sfx_name = "match_5"
			result.unit_type = "bomber"
			result.amount = 1
		"four":
			result.reward_ink = 2
			result.reward_gold = 2
			result.power_level = 1
			result.sfx_name = "match_4"
			result.unit_type = "archer"
			result.amount = 1
		_:
			result.reward_ink = 1
			result.reward_gold = 1
			result.power_level = 1
			result.sfx_name = "match_3"
			result.unit_type = "warrior"
			result.amount = 1

	if combo_count >= 2:
		result.reward_gold += combo_count - 1
	if combo_count >= 4:
		result.reward_ink += 1
	return result

func _label_for_shape(shape: String) -> String:
	match shape:
		"cross":
			return "CROSS MATCH"
		"t":
			return "T MATCH"
		"l":
			return "L MATCH"
		"five":
			return "5 MATCH"
		"four":
			return "4 MATCH"
		_:
			return "3 MATCH"

func _base_type(value: int) -> int:
	if value < 0:
		return value
	return value % 100
