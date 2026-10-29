# Prototype validation

## Passed

- All 23 crews completed a seeded ten-wave simulated expedition, including both
  bosses, without invalid orb coordinates or a stuck progression state.
- Deterministic seeds and input streams reproduce combat outcomes.
- Manual upgrade selection freezes the simulation and resumes it correctly.
- Toxic Sun evolution replaces Ember/Venom and applies burn, poison, and damage.
- Wall collisions reflect orbs and apply ricochet bonuses.
- Expiring orbs return charges, preventing an empty-supply soft lock.
- Enemy breaches can cause defeat; terminal simulation rewards are stable.
- Dash grants a brief shield, and movement remains inside its permitted zone.
- Every crew has its strip, idle portrait, and seated-defeat portrait.
- All application JavaScript and the standalone bundled script compile.
- The standalone build embeds its image assets and requires no module fetches.
- A live simulated game was rendered through the actual Canvas renderer with
  the real character sprite strip. The output was inspected visually.

## Verification limits

The local preview/network permission step was interrupted. A subsequent direct
connection to the configured proxy failed. No live browser interaction or hosted
deployment was verified. The registered private Sites project is unpublished.
Do not treat its expected URL as a playable deployment.

The standalone HTML download is the primary playable artifact for this build.
It can be opened directly in a current browser; no server or account is needed.
User interaction, layout on physical devices, audio, and local-storage behavior
still need a real-browser playtest. The engine and Canvas checks are not a
substitute for that playtest.
