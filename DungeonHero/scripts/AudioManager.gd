extends Node
class_name AudioManager

const SFX_PATHS = {
	"match_3": "res://assets/audio/match_3.wav",
	"match_4": "res://assets/audio/match_4.wav",
	"match_5": "res://assets/audio/match_5.wav",
	"match_special": "res://assets/audio/match_special.wav",
	"piece_swap": "res://assets/audio/piece_swap.wav",
	"piece_invalid": "res://assets/audio/piece_invalid.wav",
	"unit_summon": "res://assets/audio/unit_summon.wav",
	"combo_chain": "res://assets/audio/combo_chain.wav",
	"booster_create": "res://assets/audio/booster_create.wav",
	"booster_blast": "res://assets/audio/booster_blast.wav",
	"board_shuffle": "res://assets/audio/board_shuffle.wav",
	"punch": "res://assets/audio/punch_sound.mp3",
	"bomb": "res://assets/audio/bomb.mp3",
	"hero_upgrade": "res://assets/audio/hero_upgrade_sound.mp3",
	"monster_appear": "res://assets/audio/monster_appear_sound.ogg",
	"monster_appear_mp3": "res://assets/audio/monster_appear_sound.mp3",
	"select": "res://assets/audio/select_sound.ogg",
	"error": "res://assets/audio/error_sound.ogg",
	"warning": "res://assets/audio/beep-warning-6387.mp3",
	"button_click": "res://assets/audio/select_sound.ogg",
	"piece_drop": "res://assets/audio/piece_swap.wav",
	"special_clear": "res://assets/audio/special_clear.wav",
	"race_countdown_beep": "res://assets/audio/race_countdown_beep.wav",
	"race_countdown_go": "res://assets/audio/race_countdown_go.wav"
}

const MUSIC_PATH = "res://assets/audio/background.ogg"

# Central audio balance table (dB). 0.0 means original loudness; negative values are quieter.
# Edit this table when you want to rebalance audio without touching the source audio files.
const MASTER_SFX_GAIN_DB := -1.5
const SFX_GAIN_DB = {
	"bomb": -15.0,
	"warning": -10.0,
	"booster_blast": -5.0,
	"special_clear": -4.5,
	"race_countdown_beep": -4.0,
	"race_countdown_go": -3.5,
	"match_special": -3.0,
	"match_5": -3.0,
	"match_4": -3.5,
	"match_3": -4.0,
	"combo_chain": -5.0,
	"booster_create": -5.0,
	"piece_swap": -7.0,
	"piece_drop": -7.0,
	"piece_invalid": -6.0,
	"unit_summon": -4.0,
	"punch": -5.0,
	"hero_upgrade": -4.0,
	"monster_appear": -7.0,
	"monster_appear_mp3": -7.0,
	"select": -7.0,
	"button_click": -7.0,
	"error": -6.0
}

var sfx_library := {}
var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -12.0
	add_child(music_player)
	for _index in range(10):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		players.append(player)
	for id in SFX_PATHS.keys():
		var path := str(SFX_PATHS[id])
		if ResourceLoader.exists(path):
			sfx_library[id] = load(path)
	# Prefer the requested OGG monster-appear file; fall back to the bundled MP3 if needed.
	if not sfx_library.has("monster_appear") and sfx_library.has("monster_appear_mp3"):
		sfx_library["monster_appear"] = sfx_library["monster_appear_mp3"]
	_play_background_music()

func play_sfx(id: String, pitch_scale := 1.0, volume_db := 0.0) -> void:
	var stream: AudioStream = sfx_library.get(id, null)
	if stream == null:
		return
	var player := _available_player()
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db + MASTER_SFX_GAIN_DB + float(SFX_GAIN_DB.get(id, 0.0))
	player.play()

func has_sfx(id: String) -> bool:
	return sfx_library.has(id)

func _available_player() -> AudioStreamPlayer:
	for player in players:
		if not player.playing:
			return player
	if players.is_empty():
		var fallback := AudioStreamPlayer.new()
		add_child(fallback)
		players.append(fallback)
		return fallback
	return players[0]

func _play_background_music() -> void:
	if music_player == null:
		return
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var stream = load(MUSIC_PATH)
	if stream == null:
		return
	stream.set("loop", true)
	music_player.stream = stream
	music_player.play()
