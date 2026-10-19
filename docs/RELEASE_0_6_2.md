# Sketluma 0.6.2+10 — EpitomeHub package

At the owner's explicit request, Android applicationId/namespace and iOS bundle identifiers are now `com.epitomehub.sketluma`. The Kotlin MainActivity has moved to the matching package directory; RunnerTests use the new bundle prefix. Display branding remains Sketluma: Sketch & Paint, Powered by EpitomeHub®. The existing local upload key is reused; no signing credentials are tracked in Git.

This is a new Android app identity and a separate install, not an update to `com.srikanth.sketchora`. Private sketches cannot be automatically read from the older sandbox. Export important artwork from the old app before removing it. The old unpublished Play draft cannot have its package changed in place, so the new package requires a new Console entry. Earlier release documentation is historical.

Artifacts: `dist/Sketluma-0.6.2-epitomehub-test.apk`, `dist/Sketluma-0.6.2-epitomehub-upload.aab`. Google demo ad IDs remain in use; production advertising and public-launch prerequisites are unchanged. No iOS binary is built on Windows.

Validation: Flutter analysis is clean. Both Android release builds succeed. APK manifest inspection confirms `com.epitomehub.sketluma`, MainActivity `com.epitomehub.sketluma.MainActivity`, version 0.6.2 (10), label Sketluma. APK and upload AAB signatures verify. The previous 36-test drawing regression suite was unchanged and passed in 0.6.1; this package-only change is verified by native builds and manifest/signature checks.

The owner approved the new app creation declarations. Correct-package Console app ID: `4972803420874038186`. Dashboard: https://play.google.com/console/u/1/developers/7303820685500548033/app/4972803420874038186/app-dashboard . The previous personal-package app ID `4974662142680739969` remains a separate unpublished draft; it is not the current upload destination.

Correct-package listing verified as Ready to send for review, with the same description, icon, feature graphic and six phone images. AI asset declarations are saved. The new signed AAB 10 (0.6.2) was accepted and saved as internal-testing release draft 1, track 4701620690798032187. No public or tester rollout was started. Public-launch setup remains outstanding as documented in the previous release notes.
