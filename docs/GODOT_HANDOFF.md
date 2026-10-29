# Godot continuation handoff

## Current state

The native implementation is now in `godot/`; open `godot/project.godot`.
The user targets Godot 4.7.2. The available 4.6.3 editor was used for native
checks, so a final check in 4.7.2 is still needed. No pre-existing Godot project
was supplied; the native project was created as a separate continuation folder.
The browser implementation in `prototype/browser/` remains a reference.

All 23 runners also have native SpriteFrames resources under
`godot/assets/animations/` and visual AnimatedSprite2D scenes under
`godot/scenes/runners/`. Gameplay input, UI, combat, progression, saves, and
platform export presets are implemented natively. See `godot/README.md`.

## Assets ready to import

`assets/gorilla-sprites/characters/<character_id>/sprites.png` is a horizontal
1024 × 128 strip with eight equal 128 × 128 cells. There are also separate
PNGs for every pose. `manifest.json` lists all 23 character IDs and metadata.

| Cell | Pose | Suggested playback |
| --- | --- | --- |
| 0 | idle | Hold |
| 1 | windup | Throw: 1 → 2 → 3 → 0 at 8 fps |
| 2 | release | Spawn projectile on this frame |
| 3 | recovery | Return to idle |
| 4 | walk_a | Walk: 4 ↔ 5 at 6 fps |
| 5 | walk_b | Second contact pose |
| 6 | hurt | Hurt: 6 → 0 at 5 fps |
| 7 | defeated | Defeat: 6 → 7, hold last |

Frame anchor is pixel `(64, 120)` relative to the top-left of the 128 × 128
cell. For a centered Sprite2D/AnimatedSprite2D, an offset of `(0, -56)` places
that anchor at the parent origin. Verify the appearance at the chosen camera
scale; do not place physics shapes around the empty transparent margins.

For Godot 4, use AtlasTexture regions or a SpriteFrames resource. The artwork
is cel-shaded illustration rather than low-resolution pixel art, so linear
filtering is the default recommendation. Switch to nearest only if the intended
presentation calls for it. All frames face three-quarter right; additional
directions are not supplied. Mirroring asymmetric costumes should be reviewed.

`roster-atlas.png` is 1024 × 2944, with one eight-frame strip per row.
`master_row` in the manifest identifies each character's row.

## Browser-to-Godot mapping

| Existing module | Godot responsibility |
| --- | --- |
| `dist/engine.mjs` | Run state, fixed-step movement, projectiles, enemy waves, combat, upgrades |
| `dist/data.mjs` | Character/orb/upgrade Resources or JSON data |
| `dist/renderer.mjs` | Node2D scene visuals, particles, damage labels, sprite animations |
| `dist/app.mjs` | Input actions, Control scenes, pause/upgrade/result flow, save service |
| `tests/engine.test.mjs` | Behavioral reference cases for port verification |

The prototype world is 600 × 820. Character movement is restricted to the bottom
190 pixels of the arena. WASD/arrows move, Shift dashes, E triggers Rift Surge,
and P/Escape pauses. Automatic throwing starts enabled. Pointer input aims.
On touch devices, movement uses a left stick and aiming uses arena dragging.

## Next development steps

1. Open the native project in the user's 4.7.2 editor and run the check script.
2. Playtest visually on PC and tune combat balance and presentation.
3. Install matching export templates and configure the Android SDK.
4. Export Windows/Linux debug builds and an Android debug APK.
5. Test a physical controller, multiple touch inputs, cutouts, rotation, and
   Android background/resume behavior on actual hardware.
6. Expand walking/directional animations, enemy art, and level variation after
   the native loop is approved in playtesting.

Browser localStorage does not automatically migrate into Godot. Save data should
use a versioned file under `user://`; avoid importing user save values implicitly.

## Known scope limits

- One illustrated facing direction and two walking contact poses.
- Three ruin themes share the same wave structure; enemy health and colors vary.
- The Showman's extra-choice perk has no Twitch integration.
- Enemy visuals currently use Canvas shapes and need Godot scenes or new art.
- Browser interaction and physical-device playtesting remain pending.
- The Cogitator's extra hand was removed; 184 exported frames were visually
  reviewed for obvious extra limbs. See the anatomy and validation notes.

## Artwork files

`assets/gorilla-sprites/source/` and `concepts/` preserve original art.
Keep them outside the active Godot import path or add `.gdignore` when choosing
the final Godot project root. Use the character strips and frame metadata for
runtime assets. Do not edit or overwrite original source images during a port.
