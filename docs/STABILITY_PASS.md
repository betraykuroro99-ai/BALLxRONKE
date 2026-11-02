# Stability pass: requested items 1–11 and ball size

30 October 2026. Local Godot source only. No APK export, deployment or GitHub push. All 23 character textures are preserved; the Twitch-only character remains disabled.

## Completion and reference status

“Implemented and tested” below describes BALLxRONKE's behavior. It does not turn an undocumented original-game value into a verified fact.

| Requested item | Result | Still requires original-game evidence |
| --- | --- | --- |
| 1. Ball level scaling | All 90 balls now have explicit, snapshotted level parameters. Verified per-level effect fields are implemented for 32 balls. Removed the invented universal +15% impact increase. Upgrade cards describe the actual parameter changes. | Remaining 58 balls lack independently verified complete effect curves; some fields within the 32 also remain unverified. Those values retain the documented first-level behavior, with field-level provenance in `ball_rules`. This item is partially complete. |
| 2. Character stats | Starting values and signature modifiers now come from a central character profile. Existing local values are preserved rather than guessed. | Original clean-save base attributes, their derived values and character-level growth. Shared local health/damage values are not certified original stats. This item is partially complete. |
| 3. Character edge rules | Empty Nester uses a separate live-instance pool, refills returned instances, cycles equipped types, and permits effect-generated babies. Equipping extra types no longer shrinks the pool. Its pool can use the local reserves bonus. Sisyphus also permits effect-generated babies, which still deal zero direct impact damage. Spawned clones no longer hold original special reloads hostage. | Exact original Leadership-derived pool formula; gravity acceleration; orbit duration/force; shield increment formula in ambiguous source descriptions. These physics values remain explicit local parameters. This item is partially complete. |
| 4. Damage categories | Separated summon attacks from area explosions. Mosquitoes, bats, zombie melee and reflected/allied shots no longer receive area bonuses merely because they are secondary attacks. Erosion's health-based bonus uses impact rules and is suppressed for Sisyphus. Lightning Bug's multi-target burst remains area damage. | Exact original classification of every secondary attack and all vulnerability-stacking exceptions. Tests establish the chosen categories, not access to original game internals. |
| 5. Duplicate evolutions | Deduplicate by resulting evolution before limiting the offer list. The selected offer retains its ingredient list. Multiple Assassin recipes cannot fill the panel with duplicate Assassin offers. | No known duplicate-offer issue in the tested cases. |
| 6. Ammo during flight | Capacity gives only two additional available charges. Flying refundable balls remain accounted for. Dead balls free entity capacity immediately. Returns are idempotent. | No known charge-duplication issue in tested cases. |
| 7. Hit/death ordering | Complete impact effects before finalizing deaths and XP. Bleed/curse or direct damage cannot suppress a lethal Egg Sac's children or a Time ball's snare. Death finalization and rewards run once. | Broader comparison of original trigger-order exceptions. |
| 8. Summoned allies | Zombies are actual pieces with health, upward movement, blocking, melee exchanges, hostile-projectile collision and death. They are no longer a twelve-second damage circle. They have distinct allied visuals and cannot be homing targets of friendly summons. | Original zombie health/damage/scaling; current zombie health inherits the converted enemy's maximum health, and melee values remain local tuning. |
| 9. Clocks and pause | Fixed 120 Hz simulation with retained input pulses at higher display rates. Tactician aim/volley pauses field status, hazards and reload clocks; enemy turns advance them. Time stop pauses hostile motion. Completed-hit boundaries stop subsequent ball updates on a level-up. | Exact original Tactician cadence and all original time-stop/status exceptions. |
| 10. Collision edges | Exact swept-circle/square contacts, including rounded corners; contacts sorted in travel order; bounded travel segments; piercing contact persistence; clone birth-contact suppression. Broad-phase bounds keep expensive contact calculations near the ball. | Original contact geometry and any special projectile-specific exceptions. |
| 11. Entity limits | 96 balls, 64 seekers, 64 areas and 32 allied pieces. Admission failures are counted. A rejected shot does not spend ammo or create a reload group; a rejected clone does not spend a division. Areas reject new admission rather than erase an existing effect. Iteration uses snapshots where a callback can add/remove entities. Hit-history storage is bounded. | Physical Android stress testing and whether these ceilings should change after profiling. At a limit, new generated effects can still be rejected; this is an intentional, counted local performance limit. |

## Ball-size check

The previous collision radii were arbitrary local values. They must not be described as measured BALL x PIT sizes.

- Ordinary baby-ball radius: 4 local units; diameter 8 / 58 = approximately 0.138 tile widths.
- Special-ball radius: 5.5 local units; diameter 11 / 58 = approximately 0.190 tile widths.
- Existing pellet and fleshy-baby radii remain 5.5 local units.
- Size configuration is centralized in `ball_geometry` and consumed by collision and drawing. Trails and glow are decorative; they do not expand the hitbox. The outline is configured independently.

Original collision radii were not found in the verified reference material. Official gameplay images were located, but full-resolution retrieval was blocked by the image hosts in the available tools. No pixel measurement was performed, and no visual/hitbox parity is claimed. The previous radii were preserved. An unscaled gameplay capture can support a visual ratio comparison; exact collision parity needs authoritative constants or controlled collision measurements, especially because the original camera has perspective.

## Reference data

`godot/data/game_data.json` now contains `ball_rules`, `character_rules` and `ball_geometry`. Each ball has three explicit parameter dictionaries, a reference URL, verified effect-level fields and unresolved fields. Projectiles, seekers, hazards and status stacks keep their launch/source parameters; changing an equipped ball's level does not retroactively rewrite an attack already in flight.

Verified effect-level fields cover Bleed, Brood Mother, Burn, Iron, Stone, Egg Sac, Time, Blizzard, Freeze Ray, Frozen Flame, Glacier, Noxious, Phantom, Virus, Fireworks, Magma, Swamp, Satan, Radiation Beam, Lightning Rod, Vertical Laser, Mosquito King, Mosquito Swarm, Mosquito Kingdom, Nosferatu, Vampire, Ghost, Black Hole, Berserk, Hemorrhage, Incubus and Banished Flame. A verified field may be constant across all three levels; “verified” does not imply every other parameter on that ball has been measured.

## Verification

The project checker runs focused mechanics, catalogue, defense and stability tests, then the 22-runner simulations, desktop/mobile UI checks, resource-pack export and packaged startup. It does not export an APK. Tests use isolated save profiles.

`stability_test.gd` runs all 90 ball types at all three levels and adds regression cases for parameter snapshots, duplicate recipes, flying-ammo accounting, lethal hit/death ordering, Nester's instance pool, Sisyphus impact suppression, clone reload ownership, high-speed and corner collisions, frame-rate invariance at 30/60/120/144 FPS, input pulses, Tactician clocks, upgrade pause, zombie combat and admission limits. See `STABILITY_VERIFICATION.json` for the final executed checks.

The installed editor is Godot 4.6.3. Godot 4.7.2 and physical Android hardware remain untested here.

## References

- [Character abilities](https://ballxpit.wiki.gg/wiki/Characters) and [character guide with explicit spawned-baby exceptions](https://gamefaqs.gamespot.com/pc/539487-ball-x-pit/faqs/82265).
- [Empty Nester instance-pool observations](https://steamcommunity.com/app/2062430/discussions/0/624436409752642494/) and [cooldown/Leadership observations](https://steamcommunity.com/app/2062430/discussions/0/690872195393652830/). These are player observations, not published engine constants.
- Individual ball reference URLs are stored with each profile. Examples: [Bleed](https://ballxpit.wiki.gg/wiki/Bleed), [Stone](https://ballxpit.wiki.gg/wiki/Stone), [Mosquito King](https://ballxpit.wiki.gg/wiki/Mosquito_King), [Radiation Beam](https://ballxpit.wiki.gg/wiki/Radiation_Beam).
- [Publisher game page](https://www.devolverdigital.com/games/ball-x-pit) and [Steam game page](https://store.steampowered.com/app/2062430/BALL_x_PIT/) provide visual references, not collision-radius specifications.
