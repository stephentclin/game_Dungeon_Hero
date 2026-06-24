# Dungeon Fighter v8 — UI Buttons, Walls, and Hero Seals

## UI
- Added a real MainMenu scene using the new dungeon background.
- Split the supplied blue, purple, red, arrow, gear and lock sprites into normal / hover / pressed / disabled textures.
- Main menu, settings menu, battle buttons, upgrade/unlock buttons and the red button use TextureButton state textures instead of transparent click zones.
- Settings persist language and hero lives (1–5). Left/right arrow buttons and keyboard Left/Right both adjust lives.
- Battle HUD is reorganised: hero stats top-left, resources/rage/command points top-centre, unit growth right, and command/start controls near the goblin post.

## Wall contact
- Hero and ordinary monsters take wall-contact damage and rebound into the arena.
- Bombers explode immediately when they touch an outer wall.
- Slimes ignore wall damage and gain +10 damage on their next attack.

## Unit mechanics
- Archer: every third arrow is a Marked Arrow and ignores the Void miss check.
- Shaman: after its projectile reaches the hero, it heals allies around the impact point if they are also inside the shaman's attack range. It also applies poison.
- Ogre: steals health from actual damage dealt to the hero. If a non-ogre ally within attack range falls below 5% HP, the ogre devours it, restores 10% max HP, and retains up to three recent meals. Meals add attack, preserve the best attack speed, and pass on selected traits.
- All monsters unlocked: manual conversion at 25 gold → 1 skill point.
- Permanent unit upgrade level is capped at the current hero level.

## Hero seals
The hero starts with Void. Each lost life unlocks one more seal:
1. Void: ordinary attacks have a 70% MISS chance. Marked arrows, traps and future true/backstab attacks bypass it.
2. Element: direct damage is blocked unless the hero has an elemental ailment, such as poison.
3. Energy: direct single-hit damage is capped at 30.
4. Life: the hero restores 10% max HP every 3 seconds.
5. Reincarnation: the final form blocks ranged damage while its multiple-life structure remains active.
6. Eternal: on the final life, after all five base seals are active, dropping below 20% HP starts a 3-second recovery window. Defeat the hero during that window or it heals to full once.

## Note
This package was checked for missing resource references and basic script delimiter errors. It still needs an in-editor Godot run on your machine for runtime verification.
