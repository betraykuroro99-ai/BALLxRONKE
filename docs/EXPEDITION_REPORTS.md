# Expedition reports and run flow

Results now show the runner and ruin, depth/time/shard reward, enemies and
guardians defeated, throws/bounces, dashes/Surges, breaches and health lost to
hits, best combo, final orbit and upgrade path. The outcome identifies fatal
projectiles, ordinary breaches, guardian breaches, a camp return or victory and
offers matching advice. Damage counts health actually lost, excluding blocked
hits and overkill; a guardian breach is a fatal hazard, not hit damage.

Only performed actions count, so holding dash or Surge through cooldown does
not inflate totals. Defeated guardians count once. Terminal outcomes cannot be
overwritten, and a fatal event stops later projectiles/orbs in that simulation
step from adding post-defeat kills or changing earned rewards.

Settlement stores the latest report alongside normal progress. Open Camp and
choose View last expedition to inspect it after restarting. Viewing a report
does not award shards again. Saves without this optional field still load;
report identifiers, numeric limits, loadouts and upgrade strings are validated.
No run history or cloud synchronization is introduced.

When a wave is empty, the arena shows the existing 1.6-second transition timer.
The last wave says the exit is opening; other waves show the next depth.
Remaining hostile projectiles still matter during that interval, so the cue
says Stay alert. No extra delay or recovery bonus is added.

Tests cover accounting, outcome causes, snapshot independence, terminal-step
behavior, persistence/validation and result/journal/countdown UI. Validation is
headless on Godot 4.6.3. Actual graphical, audio and device testing on the user's
requested Godot 4.7.2 setup remains necessary.
