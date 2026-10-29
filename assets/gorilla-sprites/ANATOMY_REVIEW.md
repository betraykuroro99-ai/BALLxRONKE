# Anatomy review

## Concept sheets

Reviewed all 23 roster entries, including the family group and companions.
The original Cogitator had a third cyan hand and forearm at his waist. The
corrected board in `concepts/roster_01_corrected.png` removes that limb and
retains the hand at his chin and the hand holding his orb. The original
generated source remains preserved outside this pack.

No other obvious supernumerary arms, hands, legs, or feet were found on the
concept boards. Some limbs are naturally hidden by robes, shields, or another
member of the family group; hidden limbs are not additional visible limbs.

## Sprite frames

The v1 review covered six generated atlases and the exported contact sheet,
covering all 23 entries × 4 poses = 92 frames. No obvious extra limbs were
found. The Cogitator has a maximum of two visible hands in each pose. The
Cohabitants intentionally contain two adults and one baby. The Falconer's
two birds are intentional companions, not additional gorilla limbs.

The v2 expansion adds two walking contact poses, one hurt pose, and one seated
defeat pose per entry. The final review covers 23 entries × 8 poses = 184
frames. Props attach to existing arms or clothing; the new poses have no
magical balls held in the hands.

Reviewed all six expansion atlases and the final eight-frame exported strips
and contact sheet. No obvious unwanted extra arms, hands, legs, or feet were
found. The final Cogitator has only two hands across both animation sets.

Source art was generated with explicit two-arm/two-leg constraints and no
motion-smear copies of limbs. Handheld props were reduced or strapped to
clothing where needed to keep the silhouettes clear.

## Export checks

Automated checks verify that all 184 frames exist, are nonempty RGBA PNGs,
measure 128 × 128, retain transparent backgrounds, and fit within their
frame and common foot baseline. Main alpha silhouettes are extracted as
whole figures, preventing a nominal grid boundary from cutting off an
extended hand or picking up a neighboring sprite.

These automated checks do not count limbs or prove anatomical correctness;
that review is visual. Eight generated poses provide a first animation pass,
not a rigged or fully in-betweened animation. There can still be minor
costume, hand-shape, and pose-continuity differences between frames. Inspect
the included preview at the intended game size before final production use.
