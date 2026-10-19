# Phases and testing checklist

The 0.2.0 colouring expansion is implemented. See [colouring library and
acceptance checks](COLOURING_LIBRARY.md) for the 2,000-variation catalogue,
matching reference, fill, progress, reset and completion flow.

## Phase 1A — canvas/UI

- Open Home/Gallery and new portrait/square/landscape canvases.
- Make dots, slow curves, fast loops and long strokes with every brush.
- Change width, opacity and colour. Existing strokes must remain unchanged.
- Undo/redo at least 30 strokes; undo then draw to discard previous redo.
- Put a second finger down mid-stroke: partial stroke cancels; pan/zoom leaves
  no stray marks. Lift fingers in both orders and repeat.
- Pan off-screen and recover with Fit. Use Move to pan with one finger.
- Test stylus pressure on supported hardware. Palm rejection is not promised.
- Check 320 px phone, larger phone, landscape, tablet, notches and keyboard.
- Measure drawing after 500 and 2,000 strokes on target devices using a
  profile/release build. Debug builds do not establish drawing performance.

## Phase 1B — layers/save

- Add/reorder/hide layers, adjust opacity, draw different colours on each.
- Erasing the top layer must reveal lower layers without damaging them.
- Delete a layer, undo, redo. Last remaining layer must survive deletion.
- Clear and undo. Other layers must remain unchanged.
- Wait for “Saved on device”, background/resume, force-stop and reopen.
- Rename, duplicate, confirm deletion, reopen from gallery.
- Test full storage: save failure shown, drawing retained, retry works after
  freeing storage. Back must not silently discard unsaved changes.
- Corrupt primary file: previous valid save recovers. Unreadable files are
  reported and preserved. Recovery does not guarantee the latest changes.
- Autosave debounces 650 ms and runs on lifecycle changes. Abrupt process kills
  before completion can lose unsaved changes. Undo history is session-only.

## Phase 1C — export/install

- Export white/transparent PNG and open in another app. Verify dimensions,
  transparency, layer order/opacity and exclusion of hidden layers.
- View pan/zoom must not change export; share cancellation must keep artwork.
- Android: select a receiver/save target in the system sheet.
- iPhone/iPad: test share/save options and popover. Mac/device checks required.
- Install updated APK without uninstalling; confirm existing sketches remain.
- PNG is implemented; JPEG, PSD, project-file export and cloud sync are not.

## Phase 2

Image import, selection/transforms, rotation, eyedropper, textured
watercolour/pastel, brush presets, project backups and broader device tuning.
Learn/Settings navigation will appear when useful working screens exist.

## Phase 3

Optional sketch-to-illustration, line cleanup and colouring. Define provider,
backend, privacy controls, budget and failure handling before connecting AI.

## Report feedback

`Build | device/OS | canvas size | steps | expected | actual | screenshot/video`

Export important work before uninstalling or changing signing/application ID.
Automated tests and screenshots do not establish physical-device latency or iOS
compatibility. See VERIFICATION.md for completed checks and outstanding checks.
