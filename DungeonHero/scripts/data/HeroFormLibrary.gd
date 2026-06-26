extends RefCounted
class_name HeroFormLibrary

const HERO_LIFE_ORDER := [5, 4, 3, 2, 1]

const HERO_FORM_TEXTURES := {
	5: preload("res://assets/hero_forms/hero_5.png"),
	4: preload("res://assets/hero_forms/hero_4.png"),
	3: preload("res://assets/hero_forms/hero_3.png"),
	2: preload("res://assets/hero_forms/hero_2.png"),
	1: preload("res://assets/hero_forms/hero_1.png")
}

const HERO_ATTACK_TEXTURES := {
	5: preload("res://assets/hero_attacks/hero_5_attack.png"),
	4: preload("res://assets/hero_attacks/hero_1_attack.png"),
	3: preload("res://assets/hero_attacks/hero_3_attack.png"),
	2: preload("res://assets/hero_attacks/hero_2_attack.png"),
	1: preload("res://assets/hero_attacks/hero_4_attack.png")
}

const HERO_ATTACK_FRAME_COUNT := 4

static func texture_for_lives(lives_remaining: int) -> Texture2D:
	var clamped_lives = clampi(lives_remaining, 1, 5)
	return HERO_FORM_TEXTURES.get(clamped_lives, HERO_FORM_TEXTURES[5])

static func attack_texture_for_lives(lives_remaining: int) -> Texture2D:
	var clamped_lives = clampi(lives_remaining, 1, 5)
	return HERO_ATTACK_TEXTURES.get(clamped_lives, HERO_ATTACK_TEXTURES[5])
