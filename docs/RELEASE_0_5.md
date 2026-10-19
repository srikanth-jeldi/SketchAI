# Sketchora 0.5.0+7 — internal testing candidate

## Delivered scope

Eight new AI-generated illustrated colouring pages, each with a separate outline and colour guide, are bundled offline: Woodland picnic, Coral lagoon, Cottage in bloom, Magnolia morning, Dragon's balloon garden, Kitten's bakery, Lily pond serenity, Seaside café. Prompts and provenance are in ILLUSTRATED_ART_PROMPTS.md. Generated via the built-in image_gen tool; no downloaded third-party artwork is presented as our original work.

Gallery offers 34 Kids pages (four new illustrated scenes plus 30 selected older simple pages) and 10 Adults pages (four new scenes plus the six earlier detailed illustrations). Rejected simple adult shapes are hidden but old saves remain resolvable. This is 44 browsable designs, not a completed 2,000+ artwork library. The older procedural catalogue remains only for save compatibility.

New source PNGs are 1254×1254, not native 2048×2048. Export is 2048×2048. The six older detailed sources have about 768×1024 per portrait panel. A true 2,000+ native-2K curated collection is still outstanding and must not appear in store marketing.

## Idle/crash work

Final verification: Flutter analyzer clean; 32 tests passed, including all eight bundled image pairs, fill/save/reopen/2K export/release, request deduplication, mask ID stability after unload/reload, boot without raster-mask decoding, and simulated idle/background/memory-pressure recovery. ADB reported no connected physical devices. These tests do not establish that the reported phone-specific idle exit is resolved.

Startup no longer decodes all detailed art or builds its masks. Gallery cards use small previews; a retryable loading screen prepares only the chosen full artwork. Mask segmentation runs in a background isolate with serialized requests. Concurrent requests deduplicate; active art is pinned and unused masks/images are released after the studio closes. Flutter's image cache is capped at 24MiB and clears on background/memory-pressure notifications. Empty drawing layers avoid unnecessary render surfaces; PNG rendering releases native resources on failures as well as success.

Errors and Android previous-process exit reasons are written only to a bounded device-local diagnostics file. Android exit history requires API 30+. Home > About > Share local diagnostics exports it only after a user chooses to share. No analytics backend or automatic uploading was added. Crash cause on the user's phone remains unconfirmed: no physical Android device was connected. Simulated idle/lifecycle/memory-pressure tests are not a physical soak test.

## Two build types

- dist/Sketchora-0.5.0-illustrated-test.apk: local testing APK using the earlier internal debug certificate so it can update prior testing installs.
- dist/Sketchora-0.5.0-upload.aab: upload-key-signed Play bundle; never upload the debug-signed APK to production.

Production signing reads android/key.properties. Missing upload signing fails release tasks unless SKETCHORA_TEST_SIGNING=1 is explicitly set for local APK testing. AAB tasks reject that test flag. The new upload keystore is .tools/release-signing/sketchora-upload.jks; its alias is upload. Credentials live in ignored android/key.properties and a local Windows-DPAPI backup file. Back up the keystore and credentials to your own secure storage before publishing. They are intentionally excluded from Git and source archives. Do not paste credentials in chat.

This new upload key is for a first Sketchora listing. If an existing Sketchora Play listing/key exists, verify its expected certificate before uploading. Other apps in the developer account need not use this key.

## Remaining production steps

Publish docs/privacy.html at a stable public HTTPS URL, verify it and enter that URL in Play Console. Supply your support contact in the listing. Complete target audience/Families, content rating and Data safety declarations based on the actual mixed Kids/Adults app and SDKs. Run Play internal testing/pre-launch report and a real-device idle/background/reopen/export soak, then inspect Android vitals. Existing developer account eligibility and review timing are controlled by Play Console; today's production approval is not guaranteed. The app has not been uploaded or published by this task.

Official references checked 2026-10-19:
- https://developer.android.com/studio/publish/app-signing
- https://support.google.com/googleplay/android-developer/answer/9859152
- https://support.google.com/googleplay/android-developer/answer/9867159
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://developer.android.com/google/play/vitals
