# Combat feedback pass

The native Godot project now has fifteen original synthesized cues: throw,
wall bounce, impact, critical impact, defeat of an enemy, player damage, dash,
shield, wave arrival, guardian arrival, level-up, surge, victory, defeat and attack windup.
Samples are generated once at startup. Ten reusable voices, per-cue cooldowns
and priority-based voice replacement keep dense combat bounded; routine impacts
cannot replace a guardian warning or result cue. Sound remains muted by default.

Open **Settings** from the header or pause menu to enable audio and adjust
volume and motion. Values persist in the existing local save, with defaults for
older saves and validation for invalid values. Muting stops active voices.

Critical impacts, damage, surge and guardian defeats add brief, bounded arena
motion. The HUD and touch targets stay fixed. A border warning shows player
damage even with motion disabled. Guardian defeats get a banner and shockwave.
Chain/ring effects now have explicit caps alongside the existing particle cap.

No gameplay timing, collision, skill, fusion, progression or character texture
changes are included. Validation uses the installed Godot 4.6.3 editor; actual
audio quality, graphical presentation and device feel need a real PC/Android
playtest, including the user's requested 4.7.2 setup.
