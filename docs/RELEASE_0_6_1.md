# Sketluma 0.6.1+9 — branding and store draft

Sketchora is now branded Sketluma. Android/iOS display names, boot logo, Home, About, accessibility descriptions, export fallback name, privacy policy and current README use the new name. Home/About include Powered by EpitomeHub® at the owner's request; no registered-trademark symbol is applied to Sketluma.

The existing S icon and violet/coral theme remain. New named branding files are bundled; old original assets and historical release records remain for provenance. The Android application ID and iOS bundle ID `com.srikanth.sketchora`, Dart package/internal identifiers, diagnostics channel, storage locations and signing key remain compatible with previous testing installs. Those internal identifiers are not public display branding.

The existing drawing/colouring features and Google test ads remain unchanged. This is an internal test candidate, not the completed 2,000 bespoke native-2K-artwork release. Actual content/resolution limitations remain documented in RELEASE_0_5.md. Live AdMob IDs and production consent/privacy review remain outstanding.

Validation: static analysis clean; all 36 regression tests pass. Android APK version 0.6.1 (9), label Sketluma, API 24 minimum/36 target; APK and AAB signatures verified. iOS source branding is updated; no iOS binary was built on Windows.

Artifacts: `dist/Sketluma-0.6.1-test.apk` updates previous internal debug-signed installs; `dist/Sketluma-0.6.1-upload.aab` is signed with the existing upload key. Do not treat the APK's debug certificate as the Play upload key.

Play Console app created with the owner's explicit approval of Developer Programme Policies and US export declarations: app ID 4974662142680739969, title Sketluma: Sketch & Paint, Free, default en-GB. Store listing draft: https://play.google.com/console/u/1/developers/7303820685500548033/app/4974662142680739969/store-listings/default/edit . Creation and saving a draft do not publish an app or start a production rollout.

Confirmed Console results: default listing is Ready to send for review, with description, icon, feature graphic, four actual Flutter UI captures and two supplementary promotional posters saved. AI asset labels are enabled for visual assets containing generated artwork. The signed AAB 9 (0.6.1) has been accepted and saved in internal-testing release draft 1; release notes are saved. No public rollout or tester rollout was started. Remaining production setup includes hosted privacy policy, app-content/target-audience/content-rating/Data safety declarations, store category/contact setup and production advertising configuration. Tester selection is also required before a useful internal rollout.

The screenshot capture utility passed its explicit check; final static analysis is clean. Screenshots use the real Flutter UI with editable demonstration fills sampled from bundled reference art, not fabricated controls. Original PNG and smaller upload JPEG exports are available in docs/play-store/sketluma-v1, with generation prompts. Image ZIP: output/Sketluma-Play-Store-Images-v1.zip.
