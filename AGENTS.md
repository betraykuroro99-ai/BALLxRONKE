# BALLxRONKE project guidance

Updated: 2026-11-02 (Asia/Manila).

## Goal and current priority

Build BALLxRONKE as a native Godot game for Android and PC. The user wants gameplay closer in feel to BALL x PIT while keeping the established Ronke gorilla characters and restrained Ronkeverse theme.

The next development pass should examine volley cadence, ball movement and rebound/return timing, enemy formations and advance pressure, arena spacing, and hit feedback. Improve the existing combat loop before adding more features or expanding fusion work. Preserve character-specific exceptions when tuning shared rules.

Reference supplied by the user: https://youtube.com/shorts/DfydzIsAQTM
The video could not be inspected in the previous turn because the fetch was throttled. Do not describe it as watched or invent observations from it. No gameplay-feel changes were made in that turn. Inspect the clip when accessible; distinguish observed behavior from proposed tuning.

## User decisions and boundaries

- The user selected the third look concept: Moon Temple. Use navy stone, pale cyan moonlight, outer-edge mist, and restrained gold crescent/banana details. Keep the combat center quiet and preserve character artwork.

- Keep the existing character artwork. Characters reinterpret BALL x PIT counterparts as Ronke gorillas. Check sprite edits for unwanted extra limbs if any are requested later.
- Keep the blue/cyan Ronke theme, with modest banana and other fruit accents. Avoid overwhelming the arena with decoration.
- Preserve Android touch controls and PC keyboard/mouse/controller support, portrait and landscape layouts, safe-area handling, and background pausing.
- The requested editor is Godot 4.7.2. Available verification previously used Godot 4.6.3; do not claim 4.7.2 compatibility was tested without running it.
- Keep the Twitch-dependent False Messiah counterpart (Showman) disabled until real Twitch support is available. Do not substitute local voting.
- Character, ball, defense, and fusion corrections cover the full catalogue: 21 base balls and 69 evolved balls. Do not silently reduce the scope to base balls.
- APK building and deployment remain paused. The user authorized publishing the current Moon Temple source and AGENTS.md to GitHub on 2026-11-02. Source uploads can proceed within that scope; do not trigger APK workflows or deploy a build. Keep Android CI manual-only while the pause remains in effect. Local code changes, checks, previews, and source archives can proceed.
- Intended GitHub repository: https://github.com/betraykuroro99-ai/BALLxRONKE. Do not assume local changes are already pushed or that a remote checkout matches this workspace.

## Project layout

- `godot/project.godot`: primary project entry point.
- `godot/scripts/run_state.gd`: seeded combat simulation.
- `godot/scripts/ball_rules.gd`, `ball_effects.gd`, `evolved_effects.gd`, `combat_geometry.gd`: ball rules, effects, and collision helpers.
- `godot/scripts/arena.gd`, `ball_visuals.gd`: arena presentation and shared ball glyph primitives.
- `godot/scripts/app.gd`, `controls.gd`, `sound_bank.gd`: UI, input, and audio.
- `godot/data/game_data.json`: character, ball, fusion, geometry, and visual definitions.
- `godot/tests/` and `godot/tools/check_project.py`: native regression suite.
- `prototype/browser/`: preserved browser prototype; native Godot is the active development target. State explicitly which version any change affects.
- `docs/`: mechanics references, known gaps, change notes, and verification snapshots.

## Preserve the interaction corrections

- Teleports and wrapping must reset collision sweeps and trails at the destination; they must not hit enemies along the teleport path.
- Orbiting balls retain enemy/projectile collisions and stay visible within the arena.
- Boundaries account for physical ball radius. Dead fragile balls stop processing immediately.
- Grounded balls can intercept moving blockable hostile shots before player damage. Airborne and manually recalled balls cannot. Preserve unblockable exceptions and stationary Tactician interception.
- Shots already touching their target resolve before future ball hits, preserving fatal-hit reports and preventing post-defeat kills or rewards.
- Lob landing resets its ground sweep. Clones and teleports reset trails. Trails follow actual movement and remain bounded.
- Beams clip to the physical arena. Freeze Ray uses configured level duration; Laser Cutter draws a forward ray.
- Keep essential warnings readable when optional effects, floating numbers, or screen shake are disabled.

## Appearance and reference accuracy

The 90 catalogue entries have 16 effect-family glyphs, not 90 unique illustrations. Physical radii were preserved: baby radius 4, special/pellet/fleshy variants radius 5.5, tile size 58 in local game units. Outline and glow do not enlarge collision geometry.

Exact BALL x PIT ball dimensions and complete original numeric parity remain unverified. Consult `docs/MECHANICS_REFERENCE_GAPS.json` and current correction notes before making parity claims. Decorative arena biomes do not imply elemental floor reactions.

`docs/BALL_GLYPH_PREVIEW.png` is a rendering of shared glyph primitives, not an in-game screenshot. Do not present headless rendering checks as an interactive graphical playtest or Android device validation.

## Verification workflow

Read the relevant code and tests before changing mechanics. Use focused native checks for the affected interactions, then run the full checker for material combat changes:

```sh
python godot/tools/check_project.py
```

Set `GODOT_BIN` or pass `--godot /path/to/godot` when needed. In restricted environments, use task-specific writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` directories. The long simulation stage has a 600-second timeout; other stages normally use 240 seconds. Resource-pack verification is separate from Android APK export.

The recorded appearance/response pass passed 1,442 focused assertions, 22 seeded character simulations, desktop/mobile UI checks, resource-pack assets, and packaged startup. This is a historical baseline, not proof that subsequent edits pass. See `docs/BALL_APPEARANCE_VERIFICATION.json` and `docs/BALL_APPEARANCE_TEST_LOG.txt`; the focused and resumed stages completed after a fatal-hit ordering fix and a simulation timeout retry.

For new changes, record the engine version, checks actually run, failures or limitations, and whether graphical/device testing occurred. Update verification snapshots only with current evidence. Do not rerun long suites for documentation-only edits.

## Working approach

Make reversible local changes autonomously within the requested scope. Avoid unrelated feature additions and broad rewrites. Preserve saves and user settings. Do not overwrite existing source archives as though they contain newer changes; name new bundles clearly when requested or useful for a handoff.

If a reference or execution environment is unavailable, report the limitation accurately and continue independent work that can be completed. Do not claim implementation, viewing, testing, exporting, or publishing that did not happen.
