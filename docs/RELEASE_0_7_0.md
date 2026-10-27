# Sketluma 0.7.0+14 — expanded offline colouring catalogue

The visible library contains **3,094 unique pages**: the Studio collection has Kids 364, Intermediate 364 and Advanced 366; Original collection restores all 2,000 legacy procedural pages. All collections initially show every difficulty, with category, difficulty and search filters and incremental grid loading. Switching sections resets stale filters. Existing saved artwork IDs remain supported.

The new Atelier collection contains **1,080 deterministic procedural vector editions**, built from 36 scene compositions across 12 themes, ten geometry editions and three detail levels. These are variations, not 1,080 independently illustrated or AI-generated subjects. Themes include botanicals, birds, butterflies, cottages, mountains, coastal scenes, koi ponds, ocean life, still life, woodland villages, mandalas and succulents. All 14 existing raster illustrations remain in Studio. The 30 previously selected legacy pages are now available within the complete Original collection, without duplicates in Studio. The six older broad-shape adult masters remain supported for saved documents.

New vector pages have colour references, a coordinated named palette, closed fill paths and progressively more detail. Decorative lines draw with their parent shapes so foreground petals and leaves cover background details. A small precomputed index excludes shapes hidden at 2K resolution from completion counts, without runtime path boolean operations. New region IDs use the existing persisted format. Geometry is generated on demand with a bounded 32-design cache; no network artwork downloads or thousand-image asset bundle are required. Vector output supports 2,048-pixel export. Existing raster master resolutions are unchanged.

Version code 14 exceeds the previous production code 13. The signed bundle keeps `com.epitomehub.sketluma`, the upload certificate, the WorkManager startup fix, consent gating and the Android live-ad flag. A separate test APK uses demo ad units. AdMob verification and consent-message availability remain separate server-side issues; this release does not assert those are resolved.

Validation covers catalogue counts, deterministic geometry, closed regions and bounds across every new page, fill/undo/redo/save/export across every theme and level, rendered contact sheets and existing app regressions. Physical-device acceptance and iOS builds remain unverified. This bundle is prepared locally; it has not automatically been submitted to production.

## Verified artifacts

- Flutter analysis: no issues. Complete app suite: 45 tests passed, including access to the final original page, `Whisker wishes 200`.
- Signed AAB: 66,449,858 bytes; package `com.epitomehub.sketluma`, version code 14, version 0.7.0. Bundletool validation and JAR signature verification passed. Upload certificate matches 0.6.5.
- SHA256: `90C4ECA90C3F1D9C68E3EEA1A8904220EAAABF05042E2BFB1AC8C95835D01DBD`.
- ARM64/API36/en/420dpi bundletool download estimate: **19,127,150 bytes (19.13 MB)**. This is a device-specific download estimate, not installed size or the all-architecture AAB size.
- ARM64 demo-ad test APK: **19,870,168 bytes (19.87 MB)**, SHA256 `B941EA576AD8C423C7B2696AD6F3933622356AAC6E259593D22694CB6260DDFD`.
- x86-64 emulator test APK: 20,063,187 bytes. Split APK version codes include Flutter ABI prefixes (ARM64 2014, x64 4014); the Play AAB uses 14. Test APKs use the existing debug test certificate, not the upload/Play signing certificate.
- The exact final x64 APK installed and cold-launched successfully. Gallery showed 3,094 total and Original collection showed 2,000. The process remained alive while browsing; its captured logs contained zero native fatal/load errors. Android's System UI displayed a temporary wait dialog on the resource-constrained emulator; this is not a physical-device performance or long-idle stability certification. Task emulator stopped afterward.
- After the last layout adjustment, the ten relevant gallery/colouring tests passed again and analysis remained clean. Local proof: ignored `output/sketluma070-final-gallery.png`; app logs: `output/sketluma070-final-startup.txt`.
- UMP still reported no configured consent forms for the app ID in this test session. Drawing stayed available; no claim is made that server-side AdMob setup or ad serving is complete.
