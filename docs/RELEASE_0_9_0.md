# Sketluma 0.9.0+16 — Offline sticker library

This combines the 0.8 creative studio and complete 3,094-page gallery with a larger, searchable sticker library. Android and iOS share the Flutter code; iOS is not compiled on this Windows host.

## Actual content

- **1,104 built-in sticker entries**: the original 24 essentials, followed by 60 new original vector motifs in 18 compositions (1,080 editions).
- Twelve new topics, each with 90 entries: Flowers, Botanical, Animals, Ocean, Space, Food, Travel, Celebrations, Weather, Creative, Love and Geometric.
- Compositions include classic, sparkling, botanical wreath, sunburst, scallop seal, polaroid, postage stamp, ribbon badge, heart frame, orbit frame, arch, diamond frame, confetti party, twin charms, trio, bouquet, pendant and night sky.
- These are motif/composition variations, **not 1,104 unrelated hand-drawn illustrations**. All are bundled code-native vector artwork, with no network download, subscription or third-party sticker assets.

## Browsing and editing

The lazy grid has category filters, multiword search, composition filters, visible result counts, six quick preview/insert colours and a clear-filters empty state. Browsing shows different subjects before their subsequent editions, so opening a topic does not start with eighteen versions of the same motif. The selected sticker can still be recoloured with the full existing colour picker after insertion. Size, rotation, opacity, flip, front/back ordering, duplication, undo/redo, autosave and transparent PNG export continue to apply. My stickers remains available in the picker.

Original sticker indices 0–23 are unchanged; new indices 24–1103 are append-only. Saved documents and custom shelf objects remain readable. No existing colouring IDs, geometry, palettes or page counts were removed. Editable text, photo crops/frames and user-created stickers remain included.

## Resource limits

The grid builds visible tiles rather than rasterizing 1,104 thumbnails in memory. Each sticker is painted on demand; no added image files or SDK dependencies. Canvas limits remain 100 objects, six photos and 8 million encoded photo characters. My stickers retains its 40-item safety limit. Built-in sticker selection is available offline without a usage quota. This does not promise unlimited canvas capacity or a month without maintenance.

## Validation

**58 tests passed; static analysis has no issues.** See `output/stickers090-analyze.log`, `output/stickers090-tests.log` and `output/stickers090-focused.log`. New tests round-trip every persisted sticker ID, verify 90 entries per topic, render all 1,080 new editions with nonempty/distinct pixel output inside object bounds, check zero opacity and exercise search through the final catalogue item and colour selection. A preview rendering fix prevents very small thumbnails from violating document object-size validation; the regression test paints a 10-pixel thumbnail.

Visual atlas: `output/creative-qa/sticker-library-090.png`. Physical-device acceptance and iOS builds remain pending; passing automated tests is not a guarantee of crash-free operation. This release is not uploaded to Play Console by the build step.

## Delivery

Package `com.epitomehub.sketluma`, version 0.9.0, AAB version code 16. The signed AAB uses the same upload certificate as the previous release (SHA256 `60:AA:D7:7B:16:D0:D2:DD:12:F2:C2:9A:A1:F5:40:76:C7:3A:71:50:06:1E:8F:2A:38:AF:3E:BE:05:ED:47:54`). Bundletool and signature validation passed. ARM64, ARMv7 and x64 Flutter/app native libraries are present. Existing startup keep rules, consent gating and ad-unit configuration are preserved; server-side AdMob approval is separate.

- `dist/Sketluma-0.9.0-epitomehub-upload.aab`: 67,419,618 bytes. SHA256 `BCF1C5C5C998B8C48B7E90DA0E59086E9640FEAC6977BFEE5912E6BF3375068C`.
- ARM64/API36/en/420dpi bundletool download estimate: **19,291,749 bytes (19.29 MB)**. This is a device-specific download estimate, not installed size or the all-architecture AAB upload size.
- `dist/Sketluma-0.9.0-arm64-test.apk`: 20,035,921 bytes (20.04 MB), ABI-prefixed code 2016. SHA256 `7D9DDECB8E093C86662163CA5822D1272C19A6B5CD7BB35D893D75EBA6CEA25D`.
- `dist/Sketluma-0.9.0-x64-test.apk`: 20,236,036 bytes, ABI-prefixed code 4016. SHA256 `86F5782748532C1FBFC74DAA7EF4E7D6399CACAFC3AA69CB3AEE41E4C86DC6A4`.

Both local APKs have verified debug test signatures and demo ad units. Existing Play installations use Play signing and should be updated through a Play testing/release track; local test APK signing is not interchangeable. Final build logs: `output/stickers090-aab-final.log`, `output/stickers090-apk.log`, `output/stickers090-validation.log`, `output/stickers090-aab-signature.log`. APK/AAB binaries and visual QA output remain ignored local delivery artifacts.
