# Ball appearance and environment response pass

Date: 2026-10-30. Changes are local; APK building, deployment and GitHub publishing remain paused.

## Corrections

- Top/bottom Tunneller wraps and Warp teleports reset their collision sweep and trail at the destination. They no longer damage enemies along a fictitious path across the arena.
- Orbiting balls now check enemies and hostile projectiles. Their positions stay inside the physical arena near side walls.
- The bottom boundary uses the ball radius, matching the top and side boundaries. Destroyed fragile balls stop processing immediately.
- Hostile projectile movement is swept against ball movement before resolving damage to the player. Grounded balls and stationary Tactician balls can intercept shots; airborne and manually recalled balls cannot. Unblockable shots retain their exception. Shots already touching a target resolve first, preserving fatal-hit reporting and preventing post-defeat kills.
- Lob landing resets its ground collision path. Trails retain recent actual movement, reset on teleports and clones, and follow bounces instead of pointing through walls.
- Freeze Ray uses its configured level duration. Laser Cutter emits a forward ray. Beam drawing clips to the physical arena.

## Appearance

All 90 catalogue entries now use effect-family glyphs with readable contrast. The 16 families distinguish fire, ice, poison, laser, metal, stone, spirit, healing/charm, light, lightning, eggs, cells, time, wind, bleeding and flesh. Related balls share a family symbol; these are not 90 individually unique illustrations. Evolved colors follow their effect family, with small ingredient-color accents where useful.

Trails and glow are smaller, friendly/reflected projectiles have a separate color, and hazard areas have distinct colors and marks. Aim guides use the actual launch position, including special character launch rules. Character artwork is unchanged.

Physical ball radii are unchanged: baby balls use radius 4; special balls and existing pellet/fleshy variants use radius 5.5 in local game units, with tile size 58. Outline and glow are decoration. Exact original BALL x PIT pixel sizes remain unverified. Existing arena biomes are visual themes; this pass does not invent elemental reactions to decorative floor tiles.

## Verification and limits

Run `python godot/tools/check_project.py` with an installed Godot 4 editor. The new `tests/ball_environment_test.gd` covers 345 assertions, including wraps, orbits, interception, landing, trails, beam clipping, glyph bounds, all 90 entries, and arena draw calls across three biome themes with full and reduced effects.

The accompanying glyph sheet shows shared drawing primitives at actual local size and at 3x inspection scale. It is not an in-game screenshot. It can be regenerated using `tools/preview_ball_visuals.gd` to export primitive data. Render the exported JSON with `python godot/tools/render_ball_sheet.py INPUT.json OUTPUT.png` (Pillow required; use `--font` for another TrueType font). Native headless tests exercise the drawing code, but an interactive graphical playtest and Android device checks are still needed. The available engine is Godot 4.6.3; the requested 4.7.2 editor has not been tested here.

The expanded simulation stage has a 600-second timeout; the original 240-second limit was reached during this pass. Focused tests passed after the projectile ordering correction, and the remaining stages were resumed separately. See BALL_APPEARANCE_VERIFICATION.json for the final regression results. Earlier stability and mechanics reports remain historical snapshots; this pass does not establish full original numeric parity.
