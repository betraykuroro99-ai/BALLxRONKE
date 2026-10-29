# RONKE: Orbfall

A playable browser prototype built from the Ronke-inspired 23-character sprite
roster. It includes ten waves, two bosses, three ruin themes, character perks,
elemental damage, three evolutions, a charged surge, dash invincibility, upgrades,
touch movement and aiming, optional synthesized sound, and local basecamp saves.

## Play

Open the standalone `ronke-orbfall-play.html` file in a current desktop or mobile
browser. The artwork and game code are embedded, so it does not need a server.
Online display fonts are optional; system fonts work offline. Download the file
before opening if your chat client does not allow scripts in file previews.

For the modular source, run `node server.mjs` in this directory and open
`http://localhost:4173`. No package installation is required. Run checks with
`npm test`. Rebuild the standalone version with `python build-offline.py`.

## Controls

- WASD / arrows: movement in the lower part of the pit.
- Pointer: aim. Automatic throws start enabled; toggle with the AUTO button.
- Hold pointer / Space: throw when automatic throwing is disabled.
- Shift: dash, with a brief invulnerability window.
- E: Rift Surge when charged. Also available as an on-screen button.
- P / Escape: pause. Number keys choose upgrade cards.
- Touch: left movement stick, arena drag to aim, on-screen dash and surge.

## Scope and limits

All 23 crew entries are available. Their perks are prototype adaptations, not
pixel-for-pixel reproductions of BALL x PIT. The Showman has an extra-choice perk
and does not connect to Twitch. Three ruin themes vary color and enemy health;
they share the wave structure. Movement uses two illustrated contact poses and
one facing direction. Enemies are original Canvas-drawn creatures.

Progress stays in this browser's local storage. It is not synced between devices.
No payment or account is required for the standalone build. Clearing browser
storage resets the save. There is no backend or multiplayer.

The Sites project is registered privately, but publication is incomplete because
the workspace cannot connect to its configured networking proxy. The standalone
download remains playable independently of hosting.
