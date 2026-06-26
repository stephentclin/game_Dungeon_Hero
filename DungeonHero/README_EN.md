# Goblin Commander: Flip the Script

A 2D top-down action + Match Board hybrid game made with Godot 4.7 / GDScript.  
The player is not the hero, but the Goblin Commander: the battlefield on the left runs automatic combat, while the Match Board on the right summons monsters through blocks and clearing rules. The goal is to completely defeat the constantly reviving and gradually strengthening hero.

---

## Current Version Highlights

- The default interface is English, and players can still switch to Chinese in Settings.
- After pressing START on the main screen, the beginner guide `Introduction.png` is shown first.
- After pressing NEXT, the game starts, and the Match Board Guide is shown the first time the player enters the game.
- After closing the Guide, the `3, 2, 1, GO` countdown begins, and gameplay officially starts only after the countdown ends.
- During gameplay, players can press `H` to open / close the Match Board Guide again.
- When entering new rooms later, the Guide will no longer be shown automatically and the countdown will start directly.
- Match Board blocks are generated from random columns at the top instead of always falling from the center.
- When any Match Board column reaches the top, the hero is considered to have cleared the room and the next-room flow begins.
- When there are no small monsters, the hero patrols within the map and no longer shakes at the center point.
- The HP title bar displays heart lives on the left, room information remains centered, and the HERO LV display has been removed.
- The Skill Tree page now includes the `skill_tree_sound.mp3` sound effect, and the English translation has been completed.
- A 4-frame pixel-style revival effect has been added when the hero revives.
- Final endings now include video and sound playback, and the issue where the game could still be controlled after the ending has been fixed.

---

## Game Flow

1. Open the main menu.
2. Press START.
3. Show the Beginner Guide / Introduction.
4. Press NEXT.
5. Enter the game and show the Match Board Guide.
6. Press Close.
7. Play the `3 → 2 → 1 → GO` countdown.
8. Officially start: the hero automatically fights on the left, while the player controls the Match Board on the right.
9. Clearing Match Board blocks summons monsters to the battlefield on the left.
10. Defeat the hero, trigger revival, choose a Power Item, and continue challenging the next stage.
11. After the final hero kill or after the commander is killed, the corresponding ending video and sound effect will play.

---

## Controls

### Main Menu and System

| Action | Function |
|---|---|
| START | Start the game and enter the Introduction |
| Settings | Adjust language and game settings |
| H | Open / close the Match Board Guide during gameplay |
| Left Mouse Button | Click UI, choose rewards, and operate buttons |

### Match Board

| Action | Function |
|---|---|
| ← / → or A / D | Move the falling block |
| ↑ or W | Rotate the block |
| ↓ or S | Soft drop |
| Space / Enter | Hard Drop |
| Mouse drag / click adjacent blocks | Swap blocks |
| Click special blocks | Detonate / clear special blocks |

---

## Match Board Rules

- Falling blocks are similar to Tetris, but combined with Candy Crush-style Match-3 clearing.
- After blocks land, adjacent blocks can be swapped to create matches.
- Three or more identical icons connected in a row or column can be cleared.
- Clearing results summon different monsters to the battlefield on the left.
- When any column reaches the top, it means the hero has cleared the room and the next-room flow begins.

### Summoning Rules

| Condition | Summon |
|---|---|
| Match 3 | Skeleton Warrior |
| Match 4 | Goblin Archer |
| Match 5 | Bomber Imp |
| L Shape | Slime Guard |
| T Shape | Voodoo Shaman |
| Cross Shape | Ogre |

Priority order: `Cross > T > L > 5 > 4 > 3`

---

## Left Battlefield Rules

- The left battlefield uses automatic combat.
- The player only controls the Match Board on the right and does not directly control the hero or monsters.
- The hero automatically patrols, chases, and attacks monsters.
- When there are no monsters, the hero patrols within a safe area.
- Monsters automatically attack the hero.
- When the hero dies but still has remaining lives, the revival and Power Item flow begins.
- When the hero revives, a pixel magic-circle revival effect is played.

---

## Lives, Rooms, and Endings

- The HP title bar displays heart lives on the left.
- Room name, INK, WARNING, and other information are displayed in the center.
- The hero gradually becomes stronger in different rooms.
- After the game ends, Match Board input, monster placement, hotkeys, rewards, and summoning logic are locked.
- The ending lock is only removed when starting a new game.

### Final Videos and Sound Effects

| Ending | Video | Sound Effect |
|---|---|---|
| The hero successfully kills the commander | `res://assets/videos/fail.mp4` | `res://assets/audio/Wilhelm Scream.ogg` |
| The hero is finally killed | `res://assets/videos/success.mp4` | `res://assets/audio/Tom Screaming.ogg` |

---

## Main Asset Paths

| Type | Path |
|---|---|
| Introduction Image | `res://assets/ui/Introduction.png` |
| Match Board Guide | Dynamically created by `PuzzleBoard.gd` |
| Main Menu Music | `res://assets/audio/Crusade.mp3` |
| Skill Tree Sound Effect | `res://assets/audio/skill_tree_sound.mp3` |
| Hero Revival Effect | `res://assets/effects/hero_revive_effect_4f.png` |
| Failure Video | `res://assets/videos/fail.mp4` |
| Victory Video | `res://assets/videos/success.mp4` |

---

## Main Program Files

| File | Purpose |
|---|---|
| `scenes/Main.tscn` | Main game scene |
| `scenes/MainMenu.tscn` | Main menu scene |
| `scripts/Main.gd` | Main game flow, rooms, endings, and reward flow |
| `scripts/UIController.gd` | UI, language, results, Skill Tree, and popup flow |
| `scripts/PuzzleBoard.gd` | Match Board, Guide, countdown, falling blocks, and input lock |
| `scripts/Hero.gd` | Hero AI, patrol, combat, and revival logic |
| `scripts/Monster.gd` | Monster AI, attacks, and special abilities |
| `scripts/PlacementSystem.gd` | Summoning and placement system |
| `scripts/SaveSystem.gd` | Save data, language, and permanent progress |
| `scripts/data/BalanceConfig.gd` | Balance configuration |

---

## How to Run

1. Install Godot 4.7 stable or a compatible Godot 4.x version.
2. Extract this project.
3. Open `project.godot` with Godot.
4. Run the main scene.

Command-line example:

```bash
godot --path .
```

---

## Testing Checklist

It is recommended to check the following items after every modification:

- The main menu defaults to English.
- After pressing START, the Introduction is shown first.
- After pressing NEXT, the game starts and shows the Match Board Guide.
- The `3, 2, 1, GO` countdown only starts after pressing Close.
- Pressing `H` during gameplay can open the Guide again.
- Later rooms no longer show the Guide automatically and directly start the countdown.
- Match Board falling blocks spawn from random columns.
- When the Match Board reaches the top, the next-room flow begins.
- When there are no small monsters, the hero patrols and does not shake.
- The Skill Tree plays the sound effect when opened, and the English translation displays correctly.
- The hero revival effect plays when the hero revives.
- Final victory / failure videos and sound effects play correctly.
- After the game ends, the player cannot continue playing by closing the result UI.

---

## Latest Integration Record

This README has been organized and merged from previously scattered version README files. It keeps the gameplay, controls, asset paths, main files, and acceptance checklist needed for the current version. Old scattered README files have been removed to avoid too many duplicate documents in the project root.
