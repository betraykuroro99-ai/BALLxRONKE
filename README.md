# BALLxRONKE

Ronke-inspired gorilla roguelite project, with a playable browser prototype and
the complete character artwork prepared for continued development in Godot.

## Project contents

- [`prototype/browser/`](prototype/browser/): modular JavaScript game, renderer,
  interface, offline bundler, and simulation tests.
- [`assets/gorilla-sprites/`](assets/gorilla-sprites/): all 23 characters, 184
  transparent frames, character strips, atlas metadata, concept boards, and
  original generated sprite atlases.
- [`assets/reference/`](assets/reference/): the user-provided Ronke model sheet.
- [`docs/GODOT_HANDOFF.md`](docs/GODOT_HANDOFF.md): animation coordinates,
  gameplay mappings, and the proposed Godot migration order.

## Run the browser prototype

Requires Node.js 18 or newer. No dependency installation is needed.

```sh
npm run dev
```

Open `http://localhost:4173`. Run the simulation checks with `npm test`.

To build the standalone HTML version, run:

```sh
python prototype/browser/build-offline.py
```

Then open `ronke-orbfall-play.html` in a browser. The generated HTML embeds the
game code and images. It is deliberately excluded from Git because it can be
rebuilt from the tracked source and assets.

## Current prototype

All 23 runners are selectable. Ten waves, two bosses, three ruin themes,
elemental effects, three evolutions, run upgrades, dash, Rift Surge, optional
sound, touch controls, and browser-local basecamp progression are implemented.

Simulation tests and direct Canvas rendering passed. A full interactive browser
playtest is still pending. Character art uses one facing direction, with two
walking contact poses and single hurt/seated-defeat poses.

## Next: Godot

The current game is a browser prototype; it has not yet been converted into a
Godot project. The next step is to integrate these assets and mechanics into
the user's existing Godot project. See the handoff document before importing.

The original workspaces are retained locally as backups. This repository is the
continuation point for the project. No deployment credentials or personal
browser save data are included.

This is a fan prototype inspired by BALL x PIT, with original gorilla
reinterpretations and no affiliation with its creators. No license has been
selected; third-party names and references remain attributed to their owners.
