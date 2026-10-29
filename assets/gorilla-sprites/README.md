# Gorilla sprite pack — animation expansion (v2)

23 roster entries, eight 128 × 128 transparent PNG frames per entry. Original
Ronke-inspired concept art is adapted into compact cel-shaded sprites.

Open `preview.html` directly in a browser to preview every animation. It embeds
the atlas and needs no server or internet connection.

## Files

- `characters/<id>/sprites.png`: eight frames horizontally, 1024 × 128.
- `characters/<id>/{idle,windup,release,recovery,walk_a,walk_b,hurt,defeated}.png`: separate frames.
- `characters/<id>/sprites.json`: coordinates for that character.
- `roster-atlas.png`: all 23 character strips stacked, 1024 × 2944.
- `manifest.json`: roster, frame coordinates, anchors, and animation timing.
- `source/`: untouched generated sprite atlases.
- `concepts/`: corrected first concept board and other original concept boards.
- `ANATOMY_REVIEW.md`: manual inspection findings and limitations.

## Engine integration

Frame size: 128 × 128. Anchor: (64, 120), or normalized (0.5, 0.9375).
All characters face three-quarter right. Use frame 0 for idle. For a throw,
play frames 1, 2, 3, then return to 0 at 8 fps as a starting point. Emit the
projectile on frame 2; the projectile should be its own moving game object.

Each character has eight frames: idle (0), wind-up (1), release (2), recovery
(3), walk A (4), walk B (5), hurt (6), defeated (7). The master
atlas uses a character's `master_row` for the Y coordinate. Individual strips
always start at Y = 0. Coordinates and sizes are in pixels.

Walk loops frames 4 and 5 at 6 fps. Hurt plays 6 then 0 at 5 fps. Defeat plays
6 then 7 at 5 fps and holds frame 7. These are starting timings; tune them in
the game. The preview repeats non-looping animations to make them easy to inspect.

This is an initial sprite library with two walking contact poses, a hurt pose,
and a seated defeat pose. Other facing directions and additional in-betweens
are not included. Timing and silhouette readability should be checked in the
eventual game camera. The v1 archive is preserved separately.

## Rebuild

With Python 3, Pillow, NumPy, and SciPy installed, run `python build_pack.py` from this folder.
This only extracts cells, scales them uniformly per character, aligns the
feet, and packages the generated artwork. It isolates complete alpha silhouettes
rather than cutting blindly at the nominal grid, so extended hands remain intact.
Faint glow pixels and detached sparks are assigned to the nearest main figure.
It does not paint or repair anatomy.
The original generated art is preserved.

## References

- User-provided Ronke model sheet.
- Roster: https://ballxpit.wiki.gg/wiki/Characters
- Character selection screenshots: https://www.destructoid.com/all-characters-in-ball-x-pit/

These are fan concept adaptations of BALL x PIT roles. The project has no
affiliation with the original game's creators.
