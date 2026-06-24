# v10 — Room Flow, Choices, Final Tower, Survival Hero

## Room outcomes
- **Hero dies:** loses one life; the next seal effect becomes active. The player reclaims carried relics, receives resources and one **power item** choice, then advances to the next room. The final room stays the final room when the hero revives there.
- **Hero clears rooms 1–4:** takes that room's relic and grows stronger. The player receives one **normal item** choice, then advances to the next room.
- **Final room:** if its timer reaches zero while the hero is alive, the player loses immediately.

## Population
Population is fixed at **8** for this version. It does not increase on hero deaths or item choices. The immediate-summon / return-on-death behavior remains.

## HUD and tower
- The top-left hero panel now shows only remaining lives and active seals.
- Hero HP, armor and command-post HP bars are removed.
- Rooms 1–4 hide the player command post.
- The last room shows the guardian tower, without an HP display. All player units receive **+15% damage, +15% attack speed and +10% move speed** from the tower's global inspiration.

## Hero movement
The hero no longer walks toward the player tower. It follows a Brotato-inspired survival movement: chooses safe random points, flees nearby monsters, strafes around crowds, turns away from walls, and auto-attacks targets within range.
