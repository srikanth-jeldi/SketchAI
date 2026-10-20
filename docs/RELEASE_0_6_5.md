# Sketluma 0.6.5 (13): smaller offline app

Replaces bundled artwork PNGs with WebP display images at the original dimensions. All existing designs remain bundled and usable offline. Original PNG masters remain in Git but are excluded from the Flutter asset manifest. Native libraries use compressed packaging; direct testing APKs are split by ABI instead of shipping three CPU architectures to every phone.

Colouring component maps are precomputed from the original PNGs with the original Flutter decoder and algorithm. The runtime loads compressed maps independently of display-image compression, preserving saved region IDs and fill boundaries. This also avoids calculating those maps whenever an artwork opens.

## Rebuild assets

- `python tool/optimize_art_assets.py` (Pillow required).
- Verify original mask bytes: `flutter test tool/generate_art_masks_test.dart`.
- Regenerate intentionally: set `GENERATE_ART_MASKS=1` and run the same command. Retain PNG masters for this check.

## Validation

41 app tests passed, including artwork loading, filling, persistence and export. All 14 generated masks matched the original component runs byte-for-byte. Compared PNG/WebP artwork visually. Final quality-80 artwork passed the illustrated/premium fill, persistence and 2K export tests (4 tests). Display assets were visually checked side-by-side against the masters. APK signatures were verified; package is `com.epitomehub.sketluma`, version 0.6.5. Direct split test APKs have Flutter ABI version codes (arm64: 2013); the Play bundle uses version code 13.

| Local test artifact | Bytes | Decimal MB |
| --- | ---: | ---: |
| ARM64 phone APK | 19,831,576 | 19.83 |
| ARM32 phone APK | 19,351,934 | 19.35 |
| x86-64 emulator APK | 20,023,335 | 20.02 |

Both phone APKs are strictly below 20,000,000 bytes. Compared with the previous 121,647,904-byte universal APK, ARM64 is 83.7% smaller. The all-architecture AAB upload file is larger than a per-device APK; it must not be advertised as a sub-20-MB upload bundle or installed footprint.

The earlier Android startup R8 fix and AdMob consent gate remain. AdMob privacy messages are still a server-side setup requirement; a successful build does not confirm ads are serving. This release is not publicly rolled out.
