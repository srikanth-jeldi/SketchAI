# Sketluma 0.8.0+15 — Creative Studio and complete gallery

One combined update adds offline creative tools and fixes the confusing gallery filters. Android and iOS share the Flutter implementation; the iOS photo-library usage description is included. iOS compilation and physical-device acceptance remain unverified on this Windows host.

## Creative tools

- 24 original vector stickers with editable colour, size, rotation, opacity and horizontal flip.
- Editable text, including bold, serif and italic styles. Text stays editable after reopening.
- Native system photo picker, private resized photo copies, full-photo/circle/rounded crops, crop zoom and position, optional coloured frames. This is geometric cropping, not AI background removal.
- Photos can sit behind brush strokes so users can paint on them. Objects can also sit above drawings, move by dragging, duplicate, move front/back or be deleted. Gestures commit one undo step; two fingers still pan/zoom the canvas.
- My stickers stores reusable selected objects or a transparent export of the user's own drawing. Saved projects embed their photo data, so deleting a shelf sticker does not break existing projects.
- Limits: 100 objects, six imported photos and 8 million encoded photo characters per canvas; 40 saved shelf stickers. Photos decode at a maximum long edge of 1,024 pixels with bounded caching. Large PNG imports are automatically reduced further rather than rejected; source files larger than 20 MB are refused. Selection handles are excluded from exported PNGs.
- Document version 3 supports these objects; existing version 1/2 projects and artwork IDs remain readable. Object editing participates in undo/redo, autosave, completion and PNG export. Android picker recovery is associated with the original sketch and handled when it is reopened.

## Gallery

The initial screen is **All designs — 3,094 unique entries**, with automatic incremental loading when scrolling and a visible loaded/total count. Rendering all thousands of thumbnails simultaneously would waste memory; every design remains reachable through scrolling, category filters and search.

Original collection keeps all 2,000 legacy procedural pages. Studio contains 1,080 procedural vector editions and 14 raster illustrations: 1,094 unique entries. Kids has 364 entries; Intermediate now offers both easy and medium adult-friendly editions (724 entries); Advanced has 366. The easy editions intentionally appear in both Kids and Intermediate. The All screen deduplicates by permanent ID and never counts these shared entries twice.

Botanical, Wildlife, Gardens, Travel and Still life each have actual new vector editions in Easy, Medium and Detailed, verified in tests. Category labels include matching counts. Difficulty and category controls are based on available matching content; switching collections or searching clears stale filters. An explicit Clear filters action handles searches with no matches. Original difficulty metadata is precomputed to avoid generating thousands of paths during filtering.

The 3,094 entries include procedural geometry variations, not 3,094 independently illustrated subjects. Vector designs support 2K export; raster source resolutions are unchanged. Imported photos are resized for memory safety.

## Release configuration

Package remains `com.epitomehub.sketluma`. Version code 15 supersedes 14. Store bundles use the existing upload key and live Android ad-unit flag; separate local test APKs use demo ad units. Consent gating, child-protective settings and the WorkManager/Room startup keep rule are preserved. Server-side AdMob verification/forms are not asserted to be resolved by this update. The privacy policy explains local photo and sticker storage.

Validation: 54 app tests passed, including multiline text spacing, object persistence and ordering, transparent photo crops, painting above photos, automatic resizing of large PNG imports, gesture undo, custom-sticker storage, actual empty-category coverage, full original catalogue access, automatic pagination and existing drawing/export regressions. Static analysis has no issues. Visual QA sheets are in ignored `output/creative-qa/`.

## Signed delivery artifacts

- AAB: **67,111,008 bytes**; SHA256 `040F58BFB4971E0AAA7A61507DA6493379C51F91FE9AB9FCCFD3886C11FA9AB2`. Bundletool validation and JAR signature verification passed; package and version code are correct. Upload certificate matches the previous release.
- ARM64/API36/en/420dpi bundletool download estimate: **19,244,283 bytes (19.24 MB)**. Other configurations can vary; this is not installed size or the all-architecture upload-file size.
- ARM64 demo-ad APK: **19,988,857 bytes (19.99 MB)**; SHA256 `5FABEAD8C723A290735BA07479C232FA4692E93918F8D9CED3849CAA23E3BB32`. APK signature verification passed.
- x64 emulator APK: 20,183,104 bytes; SHA256 `1470731356D3C58707939F8A6B07A87EFA838957A6566E6BCBD55E9FB2C7D1F6`.
- Split test APKs use ABI-prefixed version codes (ARM64 2015, x64 4015) and the existing debug test certificate. The signed Play upload AAB uses version code 15 and the upload certificate. Existing Play installs should be updated through Play signing, not assumed to accept a separately signed local test APK.

## Native Android checks and limits

The exact final x64 APK installed successfully. Native Android Photo Picker opened, selected the app-owned 3 MB PNG fixture, and imported it as an editable object. A circular crop and coloured frame applied correctly. Added text, moved it, added/recoloured/dragged a heart sticker, saved the project and reopened it from Home; all three objects and the photo crop/frame remained intact. Proofs: ignored `output/native080-imported.png`, `native080-crop.png`, `native080-composition.png` and `native080-reopened.png`.

The low-memory emulator initially had Android media-storage/System UI failures. After releasing the idle build JVM and restarting with more guest RAM, the native photo workflow above completed. During the final manual gallery pass the Windows host emulator executable exited; Windows Error Reporting recorded `qemu-system-x86_64-headless.exe` APPCRASH, exception `c0000005`. Consequently this release does not claim a completed final native gallery acceptance test or physical-phone stability certification. Automated gallery/category/pagination checks passed. The emulator process is no longer running.

This task prepared local APK/AAB files; it did not upload a new production release to Play Console.
