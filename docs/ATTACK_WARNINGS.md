# Enemy attack readability

Prism enemies now warn for the final 0.55 seconds of their firing cooldown;
Gatekeeper warns for 0.75 seconds and Rootheart for 0.95 seconds. A ring fills around the shooter while dashed
lanes and arrowheads preview the upcoming volley. The angle locks
when charging starts, so moving during the warning is a useful dodge. A shared
direction helper feeds drawing and bullet creation. The firing origin remains
the enemy's current position as it moves; the lane moves with that origin.

Prism cooldowns and projectile speed/damage are unchanged. Guardian patterns and
cadence are described in GUARDIAN_ENCOUNTERS.md.
These are world-time durations: Surge slow motion and the Tactician's time
freeze affect both the warning and the attack. Upgrade/pause also hold the
windup. Defeating a charging enemy cancels its volley. A breached enemy no
longer gets a final shot after being removed.

Enemies within 70 world units of crossing the breach line produce a labeled
warning and downward danger markers; guardians get a distinct fatal-breach
message. These cues are essential information and render even with optional
particles/motion disabled. The field guide explains both warnings.

Tests cover matching preview/release directions, both shooter types, warning
lead time, no retargeting, pause/freeze, cancellation and native drawing across
all worlds. Native checks run on the installed Godot 4.6.3 editor; actual
presentation and control feel still need PC/Android playtesting on the user's
requested 4.7.2 setup. Existing characters and fusion rules are unchanged.
