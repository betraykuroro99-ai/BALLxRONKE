# Display and performance settings

The header and pause-menu Settings button now opens sound, motion and display
preferences in one modal. Display controls offer:

- 30, 60 (default) or 120 FPS limits via Godot Engine.max_fps. VSync and device
  capability can lower the actual frame rate. This is a cap, not a guarantee.
- Extra visual effects: optional particles, glow, ambience, rings/chains and
  screen shake. Disabling clears existing effect instances immediately.
- Floating damage numbers, independent of extra effects. Disabling also clears
  any already-visible damage labels.

The app loads saved preferences before play and applies changes immediately.
The existing JSON save gains optional fields; old saves get defaults. Invalid
frame caps fall back to 60 rather than allowing an unbounded or malformed value.
No device-specific automatic quality assumption is made.

Essential attack lanes/arrows/charge rings, hostile bullets, health bars,
guardian phase labels/notices, breach warnings and hit flashes remain visible.
Orb trails remain as a direction cue. Gameplay state, damage, spawning and
skill/fusion logic are unchanged. Existing simulation substepping is retained.

Tests cover save defaults/validation, live frame cap, suppression/restoration and
clearing of feedback, settings pausing, essential cues, desktop/mobile layouts,
resource-pack export and startup. The installed editor is Godot 4.6.3. Actual
battery life, FPS, graphical presentation and physical Android/PC performance
still need device testing with the user's requested 4.7.2 setup.
