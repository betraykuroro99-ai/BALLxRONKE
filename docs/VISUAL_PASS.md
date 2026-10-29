# Illustrated ruins visual pass

The approved playable gorillas are preserved. Their 23 runtime texture files
were compared by SHA-256 before and after this pass; no pixels changed.

## New visual assets

- **Verdant Ruins:** worn mossy stone, fern roots, turquoise inlays and warm lamps.
- **Ember Vault:** basalt, copper edging, amber runes and restrained ember light.
- **Astral Hollow:** slate-blue stone, silver-brass trim and violet crystal inlays.
- **Enemy atlas:** moss golem, granite brute, prism sentinel, swift idol,
  Gatekeeper, and Rootheart guardian.

The quiet central floor is retained for readability. Runtime nine-region drawing
compresses the painted border to match the existing bounce boundaries; gameplay
coordinates and collision sizes are not changed. Tight enemy source regions
include the floating crystal fragments and root crowns without clipping them.

The floor/atlas textures generate mipmaps for smaller PC windows and Android
viewports. Only the selected arena texture is loaded for a run. Enemy art shares
one atlas. The pass adds no Light2D systems, full-screen animated shaders, or
changes to the existing particle/orb budgets.

## Rendering and interface

- Layered round orbs and colored trails; hostile projectiles use diamond shapes.
- Evolved orbs have a light rotating accent.
- Textured enemy shadows, subtle idle motion, hit flashes, status tint, and
  health bars positioned below the actual illustrated silhouette.
- Darker edges, subtle motes, a more legible breach line, and framed wave banners.
- Bundled condensed display font, warm brass borders, shallow panel/button
  shadows, stronger gold actions, and colored loadout labels.
- Upgrade cards identify their category and use larger touch-friendly rows.

The font license is at `godot/assets/fonts/LICENSE-DejaVu.txt`. Visual metadata
is at `godot/data/visual_data.json`. Enemy and arena images were generated for
this project; the original generated files were preserved in the workspace.

## Validation limits

The source art was visually inspected. Godot's headless checks verify drawing
command paths, resources, layouts, gameplay flow and packaging. A local graphical
display could not start because its socket listener is blocked by the sandbox.
An actual native visual playtest in the user's Godot 4.7.2 editor and on target
devices is still required; no mockup is represented as a native screenshot.
