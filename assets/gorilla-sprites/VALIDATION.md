# Validation results

- PASS: 23 distinct roster entries.
- PASS: 184 separate nonempty frames, each 128 × 128 RGBA PNG.
- PASS: transparent backgrounds and in-frame bounds.
- PASS: 23 strips at 1024 × 128; combined atlas at 1024 × 2944.
- PASS: shared foot baseline and per-character uniform scaling.
- PASS: visual review of source atlases and exported frames for obvious extra limbs.
- PASS: final Cogitator uses only two hands.
- PASS: walking contact A and B are distinct for every character.
- PASS: animation indices are valid and defeat is configured to hold the last frame.
- PASS: preview JavaScript renders all 23 rows and 8 frame coordinates in a
  mocked DOM; all animation demos, playback, and pixel controls execute correctly.

The HTML preview is self-contained and embeds the atlas; no network or server
is required. An automated Chromium check was attempted but could not launch
because the execution sandbox blocked a required socket operation. Browser
interaction in a real browser is therefore unverified here; the exported PNGs and JSON were
validated independently. This does not affect the sprite files.

Visual review is not a mathematical proof of anatomy. See
`ANATOMY_REVIEW.md` for findings and animation limitations.
