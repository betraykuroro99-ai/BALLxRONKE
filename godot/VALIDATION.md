# Native validation

Validated with the installed **Godot 4.6.3 stable** editor. The requested
**4.7.2** editor is not installed in this environment; check it on the user's
setup before release. The project uses Godot 4 APIs and the Compatibility
renderer.

## Passed

- Project import and native main-scene startup, with no GDScript parse/runtime errors.
- All 23 crews completed seeded ten-wave native simulation runs.
- Bounded finite orb state, ricochet reflection/damage, charge recovery, evolution
  ingredient replacement, dash protection, breach defeat, stable terminal state.
- Manual upgrade freeze/resume and automatic character upgrade selection.
- All 23 strips, 23 SpriteFrames resources, and 23 visual runner scenes.
- Save validation, safe round-trip, and recovery from a corrupt primary using
  the previous good backup. Tests use isolated `user://qa/` profiles.
- Native crew buttons, run start, upgrade buttons, pause/resume, results, reward
  banking exactly once, camp purchases, and return to home.
- Real input-map keyboard press/release and scaled pointer aiming.
- Simulated separate movement/aim touch IDs, independent releases, dash/surge
  queues, focus-loss pausing, and modal focus isolation.
- Portrait/desktop container layouts, arena aspect ratio, start-button
  visibility, and arena viewport bounds in the native layout engine.
- Windows/Linux/Android export preset data, ARM64 setting, dynamic JSON inclusion,
  and no requested Android Internet permission.
- Resource-pack export without platform binary templates.
- Packaged asset verification and run startup from an empty working directory,
  with no `--path` fallback to source files. All 23 animation resources, runner
  scenes, and game data were present in the pack.
- Visual-pass assets: three arena textures, six atlas regions, display font and
  bundled license. UI checks exercise all three biome and both boss drawing paths.
- The 23 playable character textures retain their pre-pass SHA-256 checksums.

- Combat feedback: generated PCM cues and bounded voice pool; guardian/victory event routing; settings persistence; zero-motion damage warning; bounded impact motion; settings keep combat paused.

- Attack warnings: aim locks before release; actual projectile directions match preview lanes; freeze/upgrade pause the windup; destruction/breach cancels pending fire; warnings render with optional effects disabled.

- Expedition reporting: action counts, damage excluding blocked/overkill damage, fatal projectile/breach/guardian causes, terminal-state stability, saved report round-trip, malformed report validation, old-save compatibility, result/journal UI and no repeat banking.

- Guardian encounters: encounter-based identity, both phases in all three worlds, Rootheart alternation, single half-health transition, immutable in-flight warning lanes and matching projectile counts/directions, second-phase presentation with optional effects disabled.

- Theme pass: updated home/camp and all three arena draw paths; packaged transparent fruit accent; desktop/mobile layout checks. Gameplay/data and playable character textures retain their prior Git blob hashes.

- Performance preferences: saved frame-limit selection and validation, reduced-effects/number suppression, clearing active feedback, restoring effects while paused, essential guardian cues and old-save defaults.

- Android test APK exported on GitHub Actions with Godot 4.6.3, JDK 17 and Android SDK tools. APK v2/v3 signature, ZIP/manifest/DEX/assets and ARM32/ARM64 runtime checks passed. [Successful build](https://github.com/betraykuroro99-ai/BALLxRONKE/actions/runs/40985470994).

- Practice/FPS tools: safe targets, target respawn, no wave/XP/reward progression, unchanged normal default, pause/return without changing saved progression or last report, and persistent optional FPS display.

## Not yet verified

- A real graphical playtest of the native game and its presentation.
- Physical keyboard/mouse/controller feel, audio output, and hardware performance.
- An actual Android device: multitouch, cutouts, rotation, app background/resume.
- The user's exact 4.7.2 editor and matching export templates.
- Windows/Linux executable export, physical Android installation/runtime, production release signing or store submission. The local workspace still lacks an Android SDK; the test APK is built and debug-signed by GitHub Actions.

The headless editor/export process reported blocked local debugger TCP listeners
in this sandbox. Imports, tests, resource-pack export, and packaged runtime still
completed. These environment messages are separate from the native script checks.

Run `python godot/tools/check_project.py --godot /path/to/Godot` from the
repository root to repeat the checks with the target editor.
