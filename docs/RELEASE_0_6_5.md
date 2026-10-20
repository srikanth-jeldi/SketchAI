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


## Final delivery verification

- Signed AAB: 66,186,907 bytes (all architectures), SHA256 `01137F3E79A1166FA0522D3874FE1EF25A3B7538E1EB7AEB1F19AC49C15940E8`.
- Google bundletool 1.18.1 ARM64/API36/en/420dpi estimate: **19,088,108 download bytes (19.09 MB)**. Generated APK files together occupy 21,743,340 bytes; installed size is larger. Other devices/locales can differ.
- ARM64 local demo APK SHA256: `2B971811B69B6D789F1EBBE8EB29A9EEE76E484307AC145EE0A0A7E1C4A5B254`.
- Emulator installation succeeded. The release displayed its main activity, `libflutter.so` loaded successfully, and the process remained alive through the subsequent idle check. No `FATAL EXCEPTION`, `UnsatisfiedLinkError`, or `dlopen failed` in the captured log. Emulator launch was slow under host memory pressure; this is not a physical-phone performance measurement.
- Log: ignored `output/final-startup-0.6.5.txt`. The task emulator was stopped afterward.


## Play Console submission — 20 October 2026

- Version code 13 (0.6.5) was accepted by Google Play. The old version-10 crash bundle was removed from the release selection.
- Production release `0.6.5 (13) - Sketluma launch` passed release validation (Ready to release). Play Console estimated 19.3 MB for new installs.
- At the owner's explicit request, all 178 available country/region selections were targeted (177 named countries/regions plus rest of world).
- Submitted the production release, listing, country availability and app-content declarations: 11 changes. Console verified **Changes in review**; preliminary quick checks were running. Managed publishing is off, so approved changes publish automatically. This does not mean the app is already publicly available.
- No source code or binary changed after the verified AAB build.
- Separate monetization follow-up: the AdMob privacy-message manager still renders a blank embedded page. Privacy-message configuration and ad serving are not confirmed; the app's consent gate remains fail-closed.
- Local UI proofs: `output/sketluma-production-ready-065.png`, `output/sketluma-production-in-review-065.png`, and `output/sketluma-worldwide-countries.png` (ignored).
