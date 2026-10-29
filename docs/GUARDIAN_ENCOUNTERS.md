# Distinct guardian encounters

Guardian identity is now explicit and based on the encounter (depth 5 or 10),
so health scaling cannot change which art or attacks a guardian uses.

| Guardian | Phase I | Phase II | Warning | Cooldown |
| --- | --- | --- | --- | --- |
| Gatekeeper | Aimed fan of 3 | Aimed fan of 5 | 0.75s | 1.5s |
| Rootheart | Alternates downward spread of 5 and aimed fan of 3 | Alternates downward spread of 7 and aimed fan of 5 | 0.95s | 1.9s / 1.7s |

Phase II starts at 50% health or below. A one-time notice and audio cue mark
the change. The health bar has a half-health marker, changes accent in phase II,
and the guardian title displays I or II. Phase notices stay visible with optional
effects disabled. The field guide explains both encounters.

Pattern, phase and aim are captured at the beginning of each windup. Crossing
the threshold while charging does not change the already-visible lanes or the
pending projectile count. The next windup uses phase II. Rootheart's downward
spread points straight down; aimed patterns lock on the player's windup position
with the existing aim scatter. Projectiles still originate from the moving
shooter, and the preview moves with it.

No extra invulnerability, healing, contact damage or hidden projectiles are added.
Bullet speed/damage, player abilities, character textures and fusion rules remain
unchanged. Rootheart's longer warning and slower cadence offset its wider spreads;
physical control feel and encounter difficulty still need human playtesting.

Tests cover both guardians and phases in all three worlds, distinct identity
independent of HP, Rootheart alternation, one-time transition notification,
unchanged pending lanes, and actual released counts/directions. Standard native
simulation/UI/resource-pack checks use the installed Godot 4.6.3 editor. The
requested 4.7.2 setup and physical PC/Android testing remain unverified.
