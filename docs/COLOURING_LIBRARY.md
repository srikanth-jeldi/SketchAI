# Colouring studio — 0.2.0

## User flow

Home offers **Free draw** and **Colour a design**. The library has search, category
chips and paged discovery. Pick a coloured preview, then Start colouring to open
an untouched black-and-white 2048×2048 document. Fill is selected initially.

Tap a closed area to fill it with the selected colour; brush tools allow freehand
painting. Outlines are kept above the colour and brush layers. The small Sample
card opens a zoomable full-screen colour guide; Minimise returns to the same
painting session. The palette is inspiration, not a required answer.

Region colours, artwork ID and completion state are stored with the editable
project. Undo/redo includes region fill and reset. White removes a region fill.
Clear resets a colouring page but retains its outline, and can be undone.
The eraser affects brush marks; choose white with Fill to erase a region colour.

Fill progress counts non-white assigned regions. Filling every region triggers
celebration. For brush painting or pages intentionally containing white, use the
celebration button to mark your work complete at any time after adding colour.
Completion first saves the project, then shows confetti, a rendered preview,
optional applause, replay and a return button. No colour-matching score is used.

## Content scope

This is **2,000 original, procedurally generated vector design variations**,
not 2,000 separately hand-drawn illustrations or downloaded stock images.
Each of the following original design families has 200 geometry variations:

| Family | Variations |
| --- | ---: |
| Flowers | 200 |
| Butterflies | 200 |
| Mandalas | 200 |
| Ocean | 200 |
| Birds | 200 |
| Little homes | 200 |
| Balloons | 200 |
| Turtles | 200 |
| Sweet treats | 200 |
| Cats | 200 |
| Total | 2,000 |

The app draws these vector pages and matching coloured samples on demand; it
does not bundle 4,000 large bitmap files. Every colouring project/export uses
2048×2048 pixels. Black-and-white and sample views share the same closed paths,
so region boundaries always correspond. User colours do not modify the sample.

The catalogue owns a deterministic PRNG rather than relying on SDK Random.
**Catalogue v1 geometry, region ordering and IDs must remain stable** to protect
saved paintings. Add a new ID/version for changed artwork instead of editing an
existing template. Future curated illustration packs can use the same flow after
adding persistent region geometry and a matching reference image.

All 2,000 geometries are tested for uniqueness, closed paths, unique region IDs
and page bounds. Geometry uniqueness does not imply 2,000 different subjects.
Automated QA is not a full human editorial review of all 2,000 variations.

The applause is an original synthesized handclap cue, generated reproducibly by
`tool/generate_applause.dart`; no third-party audio recording is included.

## Acceptance checks

1. Browse all categories, search a title, load additional pages and start a design.
2. Confirm that its outline is uncoloured, 2K and matches the coloured reference.
3. Fill different areas, undo/redo, zoom/pan, paint and erase brush marks.
4. Open/minimise the sample; verify that current fills and zoom are retained.
5. Return to gallery, force-stop/reopen after Saved, and resume the same colours.
6. Duplicate a colouring project: artwork ID, fills and completion must survive.
7. Reset and undo. The original line art must remain.
8. Fill all areas or choose Finish. Check celebration, mute, replay and dismiss.
9. Export and inspect a full-resolution PNG with the outlines and chosen colours.
10. Update from 0.1.0 without uninstalling; legacy free sketches must still open.

Physical-device audio, responsiveness, interruptions, low-storage recovery and
iOS/Mac runtime validation remain required before store release.
