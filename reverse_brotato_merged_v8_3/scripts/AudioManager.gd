extends Node

const BACKGROUND_PATH = "res://assets/audio/background.ogg"
const MONSTER_APPEAR_PATH = "res://assets/audio/monster_appear_sound.ogg"
const SELECT_PATH = "res://assets/audio/select_sound.ogg"
const ERROR_PATH = "res://assets/audio/error_sound.ogg"
const PUNCH_PATH = "res://assets/audio/punch_sound.mp3"
const BOMB_PATH = "res://assets/audio/bomb.mp3"
const HERO_UPGRADE_PATH = "res://assets/audio/hero_upgrade_sound.mp3"

var background_player: AudioStreamPlayer
var monster_player: AudioStreamPlayer
var select_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var punch_player: AudioStreamPlayer
var bomb_player: AudioStreamPlayer
var hero_upgrade_player: AudioStreamPlayer

func _ready() -> void:
	background_player = _make_player(BACKGROUND_PATH, -14.0)
	monster_player = _make_player(MONSTER_APPEAR_PATH, -6.0)
	select_player = _make_player(SELECT_PATH, -4.0)
	error_player = _make_player(ERROR_PATH, -3.0)
	punch_player = _make_player(PUNCH_PATH, -4.0)
	bomb_player = _make_player(BOMB_PATH, -2.0)
	hero_upgrade_player = _make_player(HERO_UPGRADE_PATH, -4.0)
	if background_player != null and background_player.stream != null:
		background_player.stream.loop = true
		background_player.play()

func play_background() -> void:
	if background_player != null and not background_player.playing:
		background_player.play()

func play_monster_appear() -> void:
	_play_once(monster_player)

func play_select() -> void:
	_play_once(select_player)

func play_error() -> void:
	_play_once(error_player)

func play_punch() -> void:
	_play_once(punch_player)

func play_bomb() -> void:
	_play_once(bomb_player)

func play_hero_upgrade() -> void:
	_play_once(hero_upgrade_player)

func _make_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.volume_db = volume_db
	if ResourceLoader.exists(path):
		player.stream = load(path)
	add_child(player)
	return player

func _play_once(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()
