# Premium artwork beta — 0.3.0+3

## Usability update — 0.3.2+5

Each artwork now has eight named suggested colours plus a reset swatch and the full colour mixer. Swatches have 44px touch targets in a scrolling strip. Colour selection exits Move and Eraser. Premium pen is labelled Paint; brush size/opacity controls appear only when relevant, not in Fill mode.

Fill masks preserve the original component IDs. Previously discarded texture specks and barrier pixels are assigned to the nearest existing region beneath the locked ink, closing white gaps without adding thousands of tiny tap targets. Near-line taps search up to eight screen pixels, capped at 12 artwork units; distant whitespace outside the artwork is not selected. Very fine source boundaries still need device review. Existing saves reopen against the improved masks with the same colours and area counts.

Validation adds a botanical bright-pixel fill-coverage check (>95%), near-line versus distant hit tests, and controls tests for suggested colours, Move/Paint switching and hidden Fill sliders. Physical device finger feel is still user testing.

The colouring library now shows the six approved detailed concepts: Botanical Reverie, Forest Guardian, Celestial Lotus, Moonlit Conservatory, Alpine Stillness and Amalfi Afternoon. Legacy procedural pages remain resolvable for previously saved documents but are no longer offered in the new library.

Artwork is bundled offline. The renderer uses the left half of each approved sheet as the locked outline and the right half as the expandable colour reference. The panels are illustrative pairs, not guaranteed pixel-identical colour maps. Tap-fill regions are derived only from the outline, using conservative dark-pixel barriers, four-connected components and a minimum component area. Tiny details remain available to brush painting and zoom. Region IDs and assets must remain stable for saved sessions.

This is a testing beta, not a 2,000-artwork release. The source sheets are 1536×1024: each portrait panel is about 768×1024. Export is 2048×2048 with the portrait centered, so it does not add native artwork detail. Full native 2K production masters, tighter masks and phone performance validation remain before broad library expansion. Reference shading is inspiration, not an automatic effect applied by tap fill.

Device test: open each artwork, zoom into petals/foliage/architecture, fill adjacent areas, brush then erase, undo/redo, close and reopen, expand/minimise the sample, export PNG and finish with applause. Watch for open ink boundaries causing larger connected fills and very small regions requiring zoom. No physical Android/iOS device performance or audio verification is claimed. iOS needs a macOS/Xcode build.

Prompts and provenance: ../design/premium-review/README.md. Generated with built-in image_gen, not a runtime AI service.
