# Test ads and completion — 0.6.0+8

User authorized Google test ads because Sketchora's live AdMob IDs are not available. This build supports Google's published demo units only and produces no ad revenue. It must not be presented as a monetized production build.

## Finish flow

Done is available for colouring and free drawing. Empty canvases cannot finish. The editable document is marked completed and saved before celebration. A 640px snapshot is generated once and saved as the Home thumbnail. The completion card shows a brief photo flash/settle animation, confetti/applause and a clear Artwork complete message. Reduced-motion users receive a static snapshot. Keep painting returns to the canvas; Back to Home exits through the completion-ad opportunity and returns to the Home saved-sketch list. Manual Done does not pretend to detect whether every brush-painted pixel is covered; fully filled region sets still trigger completion automatically.

Completion persists for free drawing as well as colouring. A new stroke/fill removes completed status. Reopening an already-completed painting and tapping Done again does not trigger an ad. Thumbnail generation failure cannot erase the editable save.

## Ad placement and failure behavior

- Fixed 320×50 banner on Home/Gallery, labelled Advertisement and separated from bottom navigation. No banner over the canvas or palette.
- Preloaded interstitial only after a newly saved completion, when the user taps Back to Home. None during painting, opening the app, background resume, ordinary Back navigation or celebration replay.
- At most once per document in the current process; at least 60 seconds between shown completion ads. If no ad is ready, the app returns Home immediately instead of waiting for network. Failed/dismissed ads are disposed. Cached ads clear on background/memory pressure; unavailable banners disappear.

Google Mobile Ads Flutter 9.1.0 is configured before initialization with AgeRestrictedTreatment.child, maximum content rating G and nonPersonalizedAds:true on every request. All users receive these conservative settings; selecting Adults is not used as proof of age. Android removes AD_ID and Privacy Sandbox advertising permissions. Child settings are not a substitute for production Families/privacy review.

Android demo app ID: ca-app-pub-3940256099942544~3347511713. iOS demo app ID: ca-app-pub-3940256099942544~1458002511. Banner units: Android /6300978111, iOS /2934735716. Interstitial: Android /1033173712, iOS /4411468910, all under ca-app-pub-3940256099942544. No live ad IDs or mediation networks are configured. SDK initialization is asynchronous and must not block opening local artwork.

## Release status

Validation on Windows: `flutter analyze --no-pub` reports no issues; all 36 Flutter tests pass, including completion save/thumbnail/Home navigation, offline-ad fallback, frequency policy and artwork load/fill/export regression checks. The Android APK has version 0.6.0 (8), min SDK 24 and target SDK 36; its merged manifest contains the Google demo App ID and excludes Advertising ID/Privacy Sandbox permissions. The update APK retains the previous internal-test signing certificate.

The APK updates earlier test installs; the upload-key-signed AAB is for internal testing. Google test creatives require network and may be unavailable because of connectivity or serving conditions. No physical-device ad rendering/dismissal verification is claimed from Windows widget tests. iOS source is configured but requires a Mac build and review of the current SDK's iOS integration requirements.

Before live advertising: supply real per-platform app/unit IDs, implement and test the required UMP consent/privacy-options flow for the actual audience/regions, update and host the privacy policy, review Play Data safety/target audience/Families declarations, configure AdMob/app-ads.txt, and test actual placements and ad lifecycle on devices. No live consent flow is represented as finished in this demo-only build.

Official references checked 2026-10-19:
- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/targeting
- https://developers.google.com/admob/flutter/privacy
- https://support.google.com/admob/answer/6201362
