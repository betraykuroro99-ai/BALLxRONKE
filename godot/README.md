# BALLxRONKE — native Godot project

Open **`project.godot`** in your Godot **4.7.2** editor, let assets import, then
press **F5**. This is a native GDScript game; it does not embed the browser app.
The browser version is preserved separately in `../prototype/browser/`.

The main interface is constructed by `app.gd` at runtime, so the 2D editor shows
the root Control before play. Press F5 to create the menu and HUD; use the Remote
scene tree to inspect them while running. Runner scenes can be previewed directly
in the editor. Input actions are configured by `controls.gd` at startup.

## Implemented

- All 23 playable gorillas and their character perks.
- Ten waves, two distinct guardians, and three ruin themes. Gatekeeper uses focused fans; Rootheart alternates downward spreads and aimed fans. Both widen future volleys below half health.
- Illustrated stone arenas for Verdant, Ember, and Astral; six painted enemy/boss
  designs; outlined orb trails, distinct hostile shots, and lightweight ambience.
- Aimed attack warnings: Prism enemies charge for 0.55 seconds; Gatekeeper for 0.75 seconds, and Rootheart for 0.95 seconds. Dashed lanes match the released volley. Breach danger markers stay visible with optional effects disabled.
- Ronke-inspired deep-blue menus, cyan highlights, banana-yellow actions and warm cream text. Small banana/mango flourishes in home/camp and one faint arena-corner stamp.
- Bundled display typography and color-coded orb loadouts.
- Bouncing orbs, charge return, elemental effects, and three evolutions.
- Experience, upgrade selection, dash, Rift Surge, and between-wave countdowns.
- Practice controls from home: stationary respawning targets, safe movement/dash/Surge practice, and no progression rewards.
- Optional saved FPS counter in Settings for on-device checks.
- Expedition reports: final orbit, upgrade path, action counts, guardian defeats, damage taken, and outcome-specific advice. The last report can be reopened from Camp after restarting the game.
- Permanent basecamp upgrades and versioned `user://` saves with backup recovery.
- Keyboard/mouse and controller bindings, multi-touch controls, portrait and
  landscape layouts, cutout margins on Android, and focus/background pausing.
- Fifteen original synthesized combat cues, muted by default. Open **Settings** at basecamp or in the pause menu to enable sound, adjust volume, or turn screen shake down to zero. Preferences persist locally.
- Critical hits, player damage, surge, and guardian defeats trigger bounded arena motion; HUD and touch controls remain stationary. Damage warnings remain visible when motion is disabled.
- Saved display controls: 30/60/120 FPS limits, optional extra effects and floating damage numbers. The default is 60 FPS; actual rates depend on hardware and VSync. Essential combat warnings remain visible.
- 23 native SpriteFrames resources and 23 AnimatedSprite2D runner scenes.

The Compatibility renderer is configured for PC and Android. The Android preset
targets Android 7.0/API 24 and later, with OpenGL ES 3-capable hardware and ARM
32/64-bit exports. Device performance still needs real-device testing.

## Controls

| Action | Keyboard/mouse | Controller | Touch |
| --- | --- | --- | --- |
| Move | WASD / arrows | Left stick | Left stick area |
| Aim | Pointer | Right stick | Drag elsewhere in arena |
| Throw | Automatic; hold pointer/Space when Auto is off | Automatic; right trigger when Auto is off | Automatic; aim touch when Auto is off |
| Dash | Shift | A / south button | DASH |
| Rift Surge | E | X / west button | SURGE |
| Pause | P / Escape | Start | Pause / Android Back |

Idle touch/controller aim assistance targets a threat after 1.8 seconds without
manual aiming. Releasing one touch does not cancel the other. Backgrounding the
game pauses the run. Ongoing runs do not survive process termination; permanent
basecamp progress does. Browser localStorage saves are not imported.

## Native structure

- `scripts/run_state.gd`: seeded, display-independent combat simulation.
- `scripts/arena.gd`: native drawing, checked sprite frames, and arena input.
- `scripts/app.gd`: responsive native menus, HUD, upgrades, pause, results, camp.
- `scripts/save_store.gd`: validation, versioning, temp-write and backup recovery.
- `scripts/controls.gd`: keyboard/controller input map.
- `scripts/sound_bank.gd`: small generated PCM sound bank.
- `data/game_data.json`: crew, elements, upgrades, fusions, and theme data.
- `data/visual_data.json`: arena textures and tight enemy atlas regions.
- `assets/art/arenas/` and `assets/art/enemies/`: illustrated environments and NPCs.
- `assets/animations/`: five animations per character as SpriteFrames resources.
- `scenes/runners/`: editor-ready visual runner scenes, feet anchored at origin.

The main game uses custom bounded circle/AABB simulation rather than RigidBody2D.
This makes the first port easy to test separately from rendering and UI.

### Animation resources

The eight source cells are 128 × 128 in each 1024 × 128 strip. Idle uses 0; walk
uses 4/5; throw uses 1/2/3/0; hurt uses 6/0; defeat uses 6/7 and holds. Runner
scenes use an AnimatedSprite2D offset of `(0, -56)` so the foot anchor is at the
parent origin. The main arena synchronizes frames to the simulation timers.

Resources and visual runner scenes are generated by:

```sh
godot --headless --path godot --script res://tools/build_sprite_resources.gd
```

Run that from the repository root after changing strips or animation definitions.
If using the standalone project ZIP, run from its folder with `--path .` instead.
The generator overwrites its generated scenes/resources. Put custom gameplay
scene changes in separate wrapper scenes rather than these generated files.

## Checks

From the repository root, with Python 3 and your editor installed:

```sh
python godot/tools/check_project.py --godot /path/to/your/Godot
```

Tests use isolated `user://qa/` profiles and do not overwrite the player's normal
save. Checks cover all 23 full runs, core mechanics, save recovery, all sprite
resources, menu/run transitions, actual input bindings, multi-touch, layout,
resource packaging, and packaged startup.

This environment supplied Godot **4.6.3**, which passed the native checks. A
final check in your **4.7.2** editor, a real graphical playtest, physical controller
testing, and physical Android device testing are still required.

## Android test download

The **Android test APK** GitHub Actions workflow exports a debug-signed APK for
ARM32/ARM64 phones. See [installation and phone checks](../docs/ANDROID_TEST.md).
It uses Godot 4.6.3 and does not build Windows/Linux binaries.

## PC and Android exports

Presets are provided for **Windows**, **Linux**, and **Android**. Install export
templates matching the editor version you actually use. For Android, configure
the Java SDK and Android SDK in the editor's Android export settings, then
create a debug APK with the Android preset. No signing keys are stored here.

Example commands from the repository root, after creating an `exports` folder:

```sh
godot --headless --path godot --export-debug Windows ../exports/BALLxRONKE.exe
godot --headless --path godot --export-debug Linux ../exports/BALLxRONKE.x86_64
godot --headless --path godot --export-debug Android ../exports/BALLxRONKE.apk
```

Copy the complete exported PC folder, including its PCK when present. Store
release signing configuration in editor settings or untracked export credentials.
An Android store release also needs the store's current signing/bundle settings.

The game does not request Internet/network permissions. The JSON data include
filter in each preset is intentional: dynamically loaded game data must ship.
Development tests and resource-generation tools are excluded from exports.

## Known limits

One illustrated facing direction; two walking contact frames; one hurt and one
seated defeat pose. Enemies use illustrated atlas sprites. Ruin themes share a wave
structure. The Showman's perk does not connect to Twitch. No multiplayer,
cloud saves, store integration, or shipping APK/EXE is included in this source
delivery. See `VALIDATION.md` for exactly what was tested.

Display typography uses DejaVu Sans Condensed Bold. Its font license is included
under `assets/fonts/` and included by the export presets.
