# Flip the Script v9 — Five-Room Map System

## The rewritten core loop
You play the dungeon. You deploy monsters instantly using **Cast Slots / 剧本席位**.
- Every living monster uses slots.
- Monster death returns the slots immediately.
- There is no command-point regeneration or rage meter.
- Defeating one hero life increases the cap: 8 → 10 → 12 → 15 → 18 → 22.

The hero is trying to survive a 90-second chapter timer.
- If the timer reaches zero, the hero escapes with the room relic, grows stronger, and enters the next room.
- If the hero dies, you reclaim every relic he was carrying, take a dungeon-upgrade choice, gain a larger slot cap, and fight his next life in the same room.

The red button is now **Rewrite Scene / 改写剧本**. It unlocks eight seconds after the battle begins and is usable once per room.

## Five room rules on the same arena
1. **Spore Fog Chamber / 毒雾孢子室**: two fog regions poison everyone except slime-style pool immunity. At 60 and 30 seconds, the fog flips sides.
2. **Lightless Archive / 无光档案室**: player vision stays global. The hero only notices targets inside lantern range; lantern sweeps periodically reveal much more.
3. **Sunlit Tribunal / 日耀审判室**: a moving light beam speeds attacks and makes monster strikes sure-hit, but burns creatures in the beam.
4. **Mirror Tribunal / 镜像审判厅**: at 60 and 30 seconds a warning appears, then hero and monsters swap horizontal positions. Terrain objects remain fixed.
5. **Inverse Gravity Forge / 逆重力铸炉**: periodic pulses pull bodies to the centre, then push them outward into wall-contact rules.

## Existing gameplay carried forward
- Wall collision: ordinary units and the hero take damage and rebound. Bombers detonate. Slimes take no wall damage and bank +10 next-hit damage.
- Shaman impact healing and poison.
- Ogre lifesteal, devour at <=5% friendly HP, three-meal inheritance.
- Hero seals remain active: Void, Element, Energy, Life, Reincarnation, and final-life Eternal.
- Unit upgrades remain limited by current hero level. Gold conversion remains available after all units are unlocked.

## Practical test checklist
1. Start a room, deploy until Cast Slots reaches cap, then kill a monster and confirm the count immediately frees.
2. Press **Rewrite Scene** after 8 seconds and verify its room-specific effect.
3. Let each room reach 60 and 30 seconds and observe the rule inversion.
4. Let the timer reach 0 and use the next-room overlay.
5. Kill the hero, choose a dungeon boon, and check that population cap increased.

No Godot executable was available in this environment, so this package received source-level consistency checks rather than a live F5 run.
