# BALLxRONKE

Ronke-inspired gorilla roguelite with a native Godot game for continued PC and
Android development. The browser prototype and complete character artwork are
preserved alongside it.

## Project contents

- [`godot/`](godot/): native GDScript project, main scene, gameplay, UI, saves,
  touch/controller controls, 23 native animation resources and runner scenes,
  tests, and Windows/Linux/Android export presets.
- [`prototype/browser/`](prototype/browser/): modular JavaScript game, renderer,
  interface, offline bundler, and simulation tests.
- [`assets/gorilla-sprites/`](assets/gorilla-sprites/): all 23 characters, 184
  transparent frames, character strips, atlas metadata, concept boards, and
  original generated sprite atlases.
- [`assets/reference/`](assets/reference/): the user-provided Ronke model sheet.
- [`docs/GODOT_HANDOFF.md`](docs/GODOT_HANDOFF.md): animation coordinates,
  gameplay mappings, and the proposed Godot migration order.

## Run the native Godot game

Open **`godot/project.godot`** in your **Godot 4.7.2** editor and press **F5**.
The native project was checked with the available Godot **4.6.3** editor;
4.7.2 and actual device/export testing remain to be completed on your setup.
See [`godot/README.md`](godot/README.md) for controls, checks, and exports.

## Run the browser reference

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

## Native status

The native game now includes the run loop, all 23 crews, upgrades, fusions,
basecamp progression, multi-touch input, and responsive menus. Native simulation
and interface checks are included. Source artwork remains unchanged. The browser
project remains a reference implementation rather than a runtime dependency.

The native resource pack can be generated without platform templates. Actual
Windows/Linux binaries and an Android APK still require matching export templates
and, for Android, the SDK configuration. They are not included in this source
delivery. See [`godot/VALIDATION.md`](godot/VALIDATION.md) for verification limits.

The original workspaces are retained locally as backups. This repository is the
continuation point for the project. No deployment credentials or personal
browser save data are included.

This is a fan prototype inspired by BALL x PIT, with original gorilla
reinterpretations and no affiliation with its creators. No license has been
selected; third-party names and references remain attributed to their owners.
