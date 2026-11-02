> Updated by the [stability pass](STABILITY_PASS.md). Earlier descriptions below record the preceding revision; the latest pass corrects spawned-baby restrictions, level parameters, damage categories, clocks, allies and collisions.

# Character and ball mechanics correction

Local source revision, 30 October 2026. No APK build or deployment is part of this revision. The Android Actions workflow is manual-only so a later source push cannot accidentally publish a build.

This replaces the behavior recorded in [the historical audit](CHARACTER_PARITY_AUDIT.md). Character artwork, names and Ronkeverse presentation are preserved.

## Implemented scope

- 23 character definitions and unchanged sprite sets. 22 playable runners. The False Messiah counterpart (The Showman) is disabled, including saved-selection fallback, until real Twitch voting exists. There is no simulated local audience.
- All 21 base balls and 69 named evolved balls. Every evolution has a reachable recipe; alternate recipes, three-input Nosferatu and four-input Elemental are supported. Ingredients must reach level 3 and are consumed once; the result starts at level 1. Evolved balls can then be levelled and evolved again.
- A searchable 90-ball catalogue includes effects, ingredients and reward-free practice previews. Available from home and pause. Practice previews preserve the selected character's restrictions.
- Separate baby ammo, special inventory, special reload groups and passive inventory. Normal inventory: five balls/five passives; Hoarder: two/ten; Ballbearer: ten/zero. Hoarder has no prescribed starter. Capacity upgrades increase baby ammo, not equipment slots.
- 18 passive items support useful offensive and defensive choices. This is not the full original passive-item catalogue. These passives use their documented first-level behavior; their slot limits are enforced. Protective Charm recharges after 60 seconds; projectile reflection and healing are resolved before player damage.

## Character behavior

| Counterpart | Implemented correction |
| --- | --- |
| Warrior | Bleed starter; removed invented character damage bonus. |
| Itchy Finger | Burn, forced firing at double rate, scattered aim, unrestricted firing movement. |
| Repentant | Freeze; enemy, wall and projectile bounces add 5%; far wall triggers a damaging piercing return. |
| Cohabitants | Brood Mother; mirrored half-damage copies; linked special reload waits for both copies. |
| Cogitator | Vertical Laser; automatic upgrades and evolutions; removed invented damage bonus. |
| Embedded | Poison; unlimited enemy piercing until the first wall. |
| Shade | Dark; rear launch with 10% base critical chance. |
| Shieldbearer | Iron; directional front shield repeatedly reflects friendly balls and adds another launch-damage increment per catch. |
| Spendthrift | Vampire; fires every available equipped special and baby together. |
| Juggler | Lightning; actual airborne travel, collision-free flight, then ground ricochets. Landing consumes only the airborne portion of a frame. |
| Empty Nester | Ghost; no babies, multiple linked copies of the selected special, constrained by special capacity. |
| Flagellant | Egg Sac; unlimited bottom-wall ricochets, explicit recall available. |
| Makeshift Sisyphus | Earthquake; zero impact damage, no babies, four times area and status damage. |
| Physicist | Light; gravity accelerates balls toward the far wall. |
| Tactician | Iron; aim, player volley, enemy action, aim. Player movement locks during resolution; hostile motion pauses during player action. Recall ends a stalled volley. |
| Radical | Wind; automatic movement, projectile avoidance, aiming, firing and upgrade choice. |
| Falconer | Lightning; two moving bird origins; removed arbitrary damage reduction. |
| Carouser | Charm; returning balls circle the player before catch. |
| Tunneller | Earthquake; unlimited top/bottom wrapping until catch or recall. |
| Tiptoer | Horizontal Laser; ordinary shooters cannot detect the runner, guardians and minibosses can. Lower health and damage profile. |
| Hoary Hoarder | No starter; two ball and ten passive slots. |
| Ballbearer | Stone; ten ball slots, no passive slots. |
| False Messiah | Disabled by the user's explicit choice, pending real Twitch support. |

## Ball systems

Impact, area and status damage use separate paths, so Sisyphus modifies damage categories rather than ball speed or status duration. Burn and poison stacks have individual lifetimes. Freeze stops movement and firing and increases damage taken. Bleed triggers on later hits. Charm makes enemies move and attack against their former allies; Succubus can heal by hitting a charmed target without damaging it.

Evolutions have independent launch, impact, bounce, death and timer triggers. Implemented systems include curses with hit counters; disease spreading; radiation stacks; leeches; delayed tumor deaths; zombie allies; lightning rods; homing mosquitoes, bats, fireflies and fireworks; fragile and piercing pellets; offspring clones; lava, tar and ice patches; meteor showers; delayed time bombs; global time stop; teleporting balls; continuous and diagonal beams.

Friendly balls intercept blockable hostile projectiles. Balls no longer expire after eight seconds or a fixed bounce count. Explicit recall prevents Flagellant, Tunneller and gravity builds from stalling indefinitely. Performance bounds are visible implementation limits: 96 balls, 64 seeking attacks and 64 persistent areas, with a 2,400-pixel/s numerical speed ceiling.

## Reference limits and intentional adaptations

This is a mechanics-based implementation in BALLxRONKE's existing ten-wave arenas, not a claim of binary-identical behavior or perfect original-game balance. The original game's exact per-character attribute growth, every level-2/3 numeric curve, exact gravity/orbit tuning and all environmental/projectile exceptions have not been independently reproduced. BALLxRONKE retains its own damage scale, enemy balance, dash, Surge, camp upgrades and run progression. Ball levels currently improve local impact damage; specific effect-level changes are implemented where verified (including Burn, Blizzard and Time).

Public descriptions disagree on some details. The individual Time page specifies a 2 / 2.5 / 3-second snare; the overview's older 20-second value is not used. Evolved damage values use the wiki's first-level descriptions rather than guides displaying upgraded damage. Shield catches use additive +100% launch damage, rather than assuming exponential doubling. Empty Nester's exact copy-count curve and spawned-child edge cases still need direct comparison with the original game; the current implementation scales copies with free ball capacity and blocks baby spawning.

Ordinary arbitrary two-ball fusion, paired characters, the full passive evolution tree, all eight original stages and unreleased expansion content are outside this character/ball correction. Named ball evolutions, including multi-stage recipes, are included.

## Verification

Run `python godot/tools/check_project.py --godot /path/to/godot`. Tests use isolated save profiles. The runner imports resources, executes character/base-ball, evolved-catalogue, equipment, seeded-roster and UI tests, checks desktop/mobile layouts, exports a temporary Linux resource pack and starts the packaged game. It does not build an APK.

- `parity_test.gd`: 111 checks of starters, abilities, slot rules, status stacks, ball physics and turns.
- `evolution_test.gd`: 485 checks, including all 69 evolved types, all recipe routes, ingredient consumption, bounded simulation and behavioral fixtures.
- `defense_test.gd`: 67 checks of shields, recharge, reflection, healing, catch triggers and capacity.
- `engine_test.gd`: 22 seeded runner simulations plus saves, guardian phases, warnings, practice, reports and all 23 sprite resources. Simulations check valid progress and state; victory is not asserted for every automated input policy.
- `ui_test.gd`: menu/run/upgrade/pause/result/camp flow, disabled Twitch character, 90-entry catalogue, search, practice preview, focus and desktop/mobile layouts.

Godot 4.6.3 is installed here. The requested Godot 4.7.2 editor and physical Android hardware have not been tested in this environment.

## Sources

- [Character reference](https://ballxpit.wiki.gg/wiki/Characters), [ball catalogue and recipes](https://ballxpit.wiki.gg/wiki/Balls), [passive effects](https://ballxpit.wiki.gg/wiki/Passives).
- [Individual Time page](https://ballxpit.wiki.gg/wiki/Time), [Burn levels](https://ballxpit.wiki.gg/wiki/Burn), [Blizzard levels](https://ballxpit.wiki.gg/wiki/Blizzard).
- [Update history](https://ballxpit.wiki.gg/wiki/Game_Updates), [official Naturalist description](https://store.steampowered.com/app/2062430/delivery?l=english), [official Shadow announcement](https://www.devolverdigital.com/propaganda/darkness-falls-in-ball-x-pit).
- [Alternate evolution reference](https://www.dexerto.com/wikis/ball-x-pit/all-evolution-recipes-combinations/), [independently enumerated catalogue](https://github.com/Cryphixi/ballxpit-tracker). Game facts were cross-checked; no original game art was imported.

The previous `CHARACTER_PARITY_PROBES.json` remains a historical snapshot of the audited source. It is not a report of the corrected behavior.
