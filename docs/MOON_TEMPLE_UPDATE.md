# Moon Temple visual update

Date: 2026-11-02 (Asia/Manila).

The user selected the third look concept. The native Godot game now uses a new painted navy stone court and a moonlit temple backdrop, with cyan highlights, distant mist, small gold crescents and lanterns. The interface uses darker blue panels, pale moonlight accents and softer gold. Existing character artwork and enemies remain intact.

The court uses nine regions so its decorative walls align with the existing collision boundaries. All three stages share the Moon Temple court with subtle cool tint variations; their gameplay, names, enemies and progression are unchanged. The original Verdant/Ember/Astral textures are retained for future use. Ambient motes now remain along the side edges. Essential warning colors, ball glyph colors and touch controls are preserved. No shaders or dynamic lights were added; the mist and lighting are painted into two static textures.

## Changed files

- `godot/assets/art/arenas/moon_temple_backdrop.png`: new original generated surrounding art, 1536 x 1024.
- `godot/assets/art/arenas/moon_temple_court.png`: new original generated court art, 1024 x 1536.
- `godot/data/visual_data.json`: theme, floor selection, slice margins and stage tints.
- `godot/scripts/arena.gd`: data-driven floor selection and slices, boundary highlights, peripheral ambient motes.
- `godot/scripts/app.gd`: surrounding backdrop, moonlight UI palette and small home/depth copy updates.

## Verification

Godot 4.6.3 headless import completed. The 345 ball appearance/environment assertions passed, including native draw calls for all three stages with effects enabled and disabled. Desktop and mobile UI/input/layout checks passed, along with exported resource-pack asset loading and packaged startup. The full long combat simulation was not rerun because this pass changes presentation only. Core simulation, ball effects, collision geometry, controls and save scripts match the prior verified hashes.

The generated artwork was visually inspected as source art. This is not an interactive in-game visual playtest; Godot 4.7.2 and Android device appearance/performance remain unverified. The landscape surrounding background uses aspect-cover cropping on narrow screens; the portrait court remains visible in the arena. APK building, deployment and GitHub publishing remain paused.

See `MOON_TEMPLE_VERIFICATION.json` and `MOON_TEMPLE_TEST_LOG.txt` for current evidence. Older verification reports describe earlier snapshots.
