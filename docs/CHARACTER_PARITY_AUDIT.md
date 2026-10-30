# Character, attack and defense parity audit

Reviewed 30 October 2026 against BALLxRONKE **0.1.1**, source commit
`90dd073d96565f6c0c8299fbb42f3ea6c62acbbf`.

**Finding: the roster is inspired by BALL x PIT, but is not a mechanically faithful
implementation.** Shared visual names and related starter themes must not be read
as proof of equivalent gameplay. No gameplay, art, balance or APK changes were
made for this audit.

This compares the actual native GDScript/data with public documentation, not an
instrumented copy of the original executable. Original base-stat numbers, exact
orbit/gravity tuning and patch-specific edge cases still need direct in-game
verification. Several wiki articles are stubs; direct wiki access sometimes
returned 403, so indexed text and independent guides were cross-checked. Do not
claim full parity from the existing automated tests: they check our game, not
BALL x PIT's rules.

## All 23 counterparts

“Partial” means the recognizable signature idea exists with significant missing
rules or changed values. “Different” means a central mechanic was replaced.
Neither label means full parity. Starter arrows show **original → current**;
matching themes still have the ball-effect differences listed below.

| Our runner / counterpart | Starter | Reference signature | Current native implementation | Verdict |
| --- | --- | --- | --- | --- |
| Ronke / Warrior | Bleed → Stone | No signature perk. [D] | Flat +15% damage; no Bleed implementation. | Different |
| Hotshot / Itchy Finger | Burn → Ember | Forced rapid fire, scatter and full movement while firing. [D] | 0.17s versus normal 0.28s interval (about 1.65×, not 2×); scatter exists. Auto-fire can be disabled; full-speed movement is shared by everyone. | Partial |
| Blue Monday / Repentant | Freeze → Frost | Bounce scaling and piercing recall from the far wall. [R] | +8% on wall bounces only. Enemy ricochets give no bonus; far wall reflects normally, without the recall pass. Reference describes +5% on bounces. | Partial |
| The Whole Family / Cohabitants | Brood Mother → Brood | Mirrored pair with reduced damage and linked return. [C] | Both balls deal 60%, rather than 50%. Only the main ball refunds its charge; the mirrored copy need not return first. | Partial |
| Professor Bonk / Cogitator | Laser (Vertical) → Beam | Automatic upgrade selection. [G] | Automatic choice exists, always selecting choice index 0 after a delay. Adds a custom +20% damage bonus. Full original upgrade/fusion selection is absent. | Partial |
| Old Irons / Embedded | Poison → Venom | Pierce until a wall is reached. [A] | Two piercing hits per orb lifetime, then normal collisions; wall hits do not reset the piercing budget. | Partial |
| Nightshift / Shade | Dark → Void | Rear-origin shots with a base 10% crit rate. [A] | Shots originate at y=35 but the player stays near the bottom. Crit chance is 25%. Void does not reproduce Dark ball behavior. | Partial |
| The Wall / Shieldbearer | Iron → Iron | Repeated shield catches add damage. [D] | A radius check catches a descending friendly orb once for 2× damage. It is not repeatable. Starts with 140 HP. Hostile shots still damage the player. | Partial |
| Big Spender / Spendthrift | Vampire → Sanguine | One arc launches the available ball collection together. [A] | A fixed fan of three copies of one round-robin element, spending one ammo charge. Does not launch the equipped collection together. | Different |
| Jinx / Juggler | Lightning → Spark | Aerial lob, then ground ricochets. [D] | Instantly places an orb at the aim point and adds splash damage. No airborne travel, landing delay or collision-free flight phase. | Partial |
| Auntie Blue / Empty Nester | Ghost → Wisp | Multiple special copies instead of the standard baby volley. [D] | Fixed three-shot fan; central copy has full damage and side copies 70%. Brood splitting is disabled. No general special-versus-baby loadout model. | Partial |
| Brother Bounce / Flagellant | Egg Sac → Spore | Bottom-edge reflection. [D] | Bottom reflection exists. Shared 8-second lifetime and 28-wall-bounce return cap still apply; Spore is splash, not an egg that produces babies. | Partial |
| King Again / Makeshift Sisyphus | Earthquake → Quake | No direct/baby damage; fourfold area and status scaling. [D] | Direct-hit damage is suppressed, but every hit gains custom 3× splash. Burn/poison lack the fourfold bonus. Brood can still spawn babies. | Partial |
| Dr. Orbit / Physicist | Light → Light | Gravity reverses toward the far end. [D] | Upward acceleration is implemented (-165 y/s², speed capped at 880). Core idea is present; Light itself is an anti-granite bonus instead of blind. Exact original physics not verified. | Partial |
| The General / Tactician | Iron → Iron | Alternating player and enemy turns. [T] | Enemy time runs for 0.16s after each shot; player movement and own balls continue in real time. Enemies can move while the player volley is active. No complete turn phases. | Different |
| Wild Thing / Radical | Wind → Gale | Automated play and upgrades. [A] | Auto-aim, forced shooting and automatic upgrades exist. Movement is still taken from player input; no autonomous movement/dodging controller. | Partial |
| Birdwatch / Falconer | Lightning → Spark | Two side birds serve as launch origins. [A] | Twin side origins exist at x=30 and 570, each producing a 70%-damage copy. No separate moving bird actors; quantitative parity not established. | Partial |
| Last Call / Carouser | Charm → Charm | Returning balls orbit near the player. [A] | Core orbit exists (1.1s, elliptical radii 46/30), then the charge returns. Original timing/range not verified; Charm is mechanically different. | Partial |
| Digby / Tunneller | Earthquake → Quake | Vertical boundary wrapping. [A] | Wraps top↔bottom only twice per orb, subject to the shared lifetime/return limits. Core idea is present, not unrestricted wrapping. | Partial |
| Softstep / Tiptoer | Laser (Horizontal) → Beam | Ordinary enemies cannot detect the low-health character. [A] | 65 HP and wider aim scatter for all shooters, including guardians. Normal shooters still target the player. No stealth or separate horizontal laser. | Different |
| Grandpa Gold / Hoary Hoarder | No assigned starter → Stone | Two special slots; additional passive equipment space. [O] | Five ammo charges and +65% damage. There is no two-special-slot limit or passive inventory conversion. | Different |
| Ball Boy / Ballbearer | Stone → Stone | More special slots in exchange for passive items. [O] | Sixteen ammo charges instead of nine. No doubled special inventory or passive-item prohibition; Stone has different attack behavior. | Different |
| The Showman / False Messiah | Bleed → Void | PC streaming audience influences choices/events. [A] | An extra fourth upgrade choice every third level. No Twitch integration or audience voting; wrong starter. This is a custom offline adaptation. | Different |

## Ball attacks and status effects

All reference summaries in this table are from [B]. Numbers below in the current
column are our implementation, not promises about the original's present tuning.
The original ball list includes stat/upgrade-dependent values; these should not
be copied as fixed universal damage without checking its attribute model.

| Current / reference type | Reference effect | Current native effect |
| --- | --- | --- |
| Stone | High initial damage erodes on successive hits. | Ordinary impact damage; no erosion. |
| Ember / Burn | Stacking burning damage. | Single refreshed 3s timer, 4 × damage stat DPS; no stacks. |
| Frost / Freeze | Occasional freeze and increased damage against frozen targets. | Every hit slows descent for 3s; no hard freeze or vulnerability bonus. |
| Brood / Brood Mother | Chance-based baby generation on successive hits. | Exactly two weak Stone children once per refundable parent; children cannot reproduce. |
| Beam / Laser H and V | Row or column attacks. | One extra pierced target; no beam or horizontal/vertical distinction. |
| Venom / Poison | Stacking poison damage over time. | Single refreshed 4s timer, 3.5 × damage stat DPS; no stacks. Our Venom name is not the original evolved Venom. |
| Void / Dark | Large damage bonus, destruction on impact and cooldown. | 18% crit chance, normal persistence and shared shot timing. |
| Iron | Double damage and slower travel. | Normal initial damage/speed; +4% damage on wall bounces. |
| Sanguine / Vampire | A chance to heal on impact. | Every hit heals 0.5 HP up to max HP. |
| Spark / Lightning | Several nearby targets can be struck. | At most one additional target, within 125 units, at 65% hit damage. |
| Wisp / Ghost | Continuous passage through enemies. | One piercing hit before ordinary collision. |
| Quake / Earthquake | Area damage across a tile square. | Circular 53-unit splash at 55% hit damage, plus normal impact. |
| Light | Blind reduces detection and attack accuracy. | 1.6× hit damage against the granite enemy type; no blind state. |
| Gale / Wind | Piercing slow with reduced damage. | Pushes the target upward, with a smaller push for bosses; no slow/pierce package. |
| Charm | Enemy conversion changes allegiance and movement. | A 4s weaken timer halves enemy projectile damage; no conversion. |
| Spore / Egg Sac | Breaks into baby balls, then needs cooldown. | Splash damage; no destruction, baby generation or independent cooldown. |

Relative to the published 21-base-ball list [B,U], our 16 base categories omit
**Bleed, Cell, a distinct Horizontal Laser, Time and Flesh**. The three remaining
element entries are our custom evolutions, not additional base types. Fusion
recipes were not exhaustively re-audited in this pass; the three custom recipes
remain unchanged.

## Defense and shared system gaps

- Normal starting health is one template (100), with Shieldbearer 140 and
  Tiptoer 65, before camp vitality. Movement is the same 250 base speed. There is
  no faithful per-character attribute-growth model or armor/evasion system.
- All characters receive our shared dash protection (0.25s), Surge protection
  (1.2s plus 6 healing), and post-hit protection (0.85s). These are custom common
  mechanics, not evidence of original character-specific defensive parity.
- Shieldbearer's friendly-ball catch does not intercept hostile shots. A probe
  measured 10 damage from a hostile shot while using Shieldbearer. The documented
  counterpart ability establishes ball rebounds; it does **not** justify assuming
  universal enemy-shot immunity. A projectile-blocking requirement needs direct
  source/game confirmation before changing that behavior.
- Friendly orbs do not collide with hostile projectiles in our simulation. Specific original blocking/ricochet interactions need per-projectile confirmation.
- Tiptoer has no undetected state; guardian and normal aiming both receive the
  same scatter rule. Light has no blindness; Charm has no converted-enemy AI.
- BALL x PIT's passive equipment can supply defensive effects [P]. Our six generic
  upgrades and three camp ranks are not that equipment system. This also blocks
  faithful Hoarder/Ballbearer slot trade-offs.
- Dual-character pairing/combined passives are also absent: our run has one crew entry. The original [Matchmaker](https://ballxpit.wiki.gg/wiki/Matchmaker) supports paired characters.
- Our ammo capacity is not a count of equipped special balls. We rotate through
  an element list, use a shared firing interval and share a refundable ammo pool.
  Special-ball slots, baby-ball volleys, individual cooldowns and return locks
  need a defined model before several character abilities can match.
- Shared limits are 96 active orbs, 8 seconds of life and return after more than
  28 wall bounces. These safety limits can remain deliberate mobile adaptations,
  but they should be documented and tested for their effects on wrapping,
  orbiting, reflection and baby-ball builds.
- Empty Nester baby-spawn interactions are inconsistent across public guides.
  The broad special-only firing rule is supported; whether every item-created
  baby is suppressed should be checked in the original before implementing it.
- The False Messiah's PC streaming feature cannot be described as reproduced by
  the current offline fourth-choice perk. Android needs an explicitly named
  adaptation if that feature is retained.

## Native probes

[Raw probe output](CHARACTER_PARITY_PROBES.json) was generated with isolated
Godot 4.6.3 run models, seed 4242, no camp bonuses. It confirms:

- Repentant: enemy reflection did not increase damage; a wall bounce applied 1.08×.
- Embedded: a two-hit piercing budget.
- Spendthrift: three orbs for one charge, leaving 8 of 9 charges.
- Shieldbearer: first catch 2×, repeated catch 1×; hostile shot still dealt 10 HP.
- Vampire-type orb: one hit healed 0.5 HP.
- Egg/Spore hit: zero children; Sisyphus with Brood: two children.
- Tactician: an enemy moved while the player's shot was still active.
- Hoarder/Ballbearer capacities: 5/16 charges; ordinary capacity 9.

These probes validate current behavior only. Source inspection additionally
covers all roster branches, return/wrap logic, status timers, selection logic,
orb creation and direct/area damage handling. No player's save was written.

## Recommended correction order

1. Define distinct baby/special balls, equipped ball/passive slots, per-ball
   cooldown/return rules and clear damage/status categories. Preserve mobile
   performance limits explicitly rather than hiding them inside character perks.
2. Correct starters and base effects: Bleed for Warrior/Messiah, separate lasers,
   actual Iron/Dark/Light/Charm/Egg behavior, true freeze/poison/burn rules.
3. Correct signature mechanics: Repentant recall/bounce scope, Embedded piercing,
   repeated shield catches, Spendthrift volley, Juggler airtime, Sisyphus damage
   categories, Tactician turns and Tiptoer detection exceptions.
4. Implement Hoarder/Ballbearer inventory trade-offs and Radical movement AI.
   Label the streaming-exclusive character's offline alternative clearly.
5. Add parity-focused tests per mechanic, then rebalance and rebuild the Android
   APK. Current full-run tests passing is not a substitute for those comparisons.

## Evidence and sources

Native code inspected:

- [Character data](../godot/data/game_data.json): starter assignments and displayed perks.
- [Run state](../godot/scripts/run_state.gd): `_init`, `_step`, `_update_enemies`,
  `_update_ball`, `shoot`, `add_ball`, `wall`, `return_ball`, `hit`,
  `get_choices`, `choose_upgrade`, `hurt`.
- [Arena input/rendering](../godot/scripts/arena.gd): shared automatic fire/aim
  controls and presentation. Character sprite art alone is not a mechanic test.

Reference keys (community documentation unless marked official):

- **A:** [BALL x PIT Wiki character roster](https://ballxpit.wiki.gg/wiki/Characters).
- **B:** [BALL x PIT Wiki ball effects](https://ballxpit.wiki.gg/wiki/Balls), cross-checked with
  [Destructoid's base-ball guide](https://www.destructoid.com/all-special-balls-in-ball-x-pit/).
- **C:** [Cohabitants](https://ballxpit.wiki.gg/wiki/The_cohabitants).
- **D:** [Destructoid's character guide](https://www.destructoid.com/all-characters-in-ball-x-pit/).
- **G:** [Cogitator](https://ballxpit.wiki.gg/wiki/The_Cogitator).
- **O:** [Official Steam Naturalist update description](https://store.steampowered.com/app/2062430/delivery?l=english).
- **P:** [Passive equipment reference](https://ballxpit.wiki.gg/wiki/Passives).
- **R:** [Repentant](https://ballxpit.wiki.gg/wiki/The_Repentant).
- **T:** [GameFAQs character guide](https://gamefaqs.gamespot.com/ps5/551362-ball-x-pit/faqs/82265).
- **U:** [Update coverage, including Stone/Time/Flesh](https://ballxpit.wiki.gg/wiki/Game_Updates).

Sources are not all equally current. The Destructoid character article covers 20
characters, so the newer roster and official Naturalist description supply the
later characters. Numerical reference claims above are limited to those
consistently documented; unverified details are expressly left unverified.
