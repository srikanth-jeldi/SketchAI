# Sketluma 0.6.4+12 — startup crash fix and AdMob release

Package: `com.epitomehub.sketluma`.

The reported immediate crash was reproduced with the optimized 0.6.2 APK on
the Android 36.1 emulator: `InitializationProvider` failed while WorkManager
created `WorkDatabase`. The R8 usage report showed that the reflected
`WorkDatabase_Impl` no-argument constructor had been removed. A narrow keep
rule now retains that constructor. The fixed optimized 0.6.3 APK survived
repeated cold launches and idle checks; the final 0.6.3 artifact also survived
a separate cold launch/idle log capture with no new fatal exception. These
checks do not establish crash-free operation on every physical phone.

0.6.4 keeps this fix, adds an in-app hosted privacy-policy link and UMP privacy
gating, and integrates the three verified Sketluma AdMob Android IDs documented
in ADS_AND_COMPLETION.md. The upload AAB enables real units with the explicit
SKETLUMA_LIVE_ADS build flag. The test APK uses demo units and the existing
internal testing certificate. AABs use the existing private upload key.

All users receive child-restricted, G-rated, non-personalized ad settings and
under-age UMP treatment, because the app does not verify age. Consent updates,
required forms and SDK permission must succeed before ad initialization or
loads. Drawing is available independently of advertising. About offers Ad
privacy choices when required by UMP. No runtime AI service was added.

Validation: clean Flutter analysis; 41 existing/new regression tests pass,
including consent-update failure, form failure, denied permission, native
errors, success ordering and Android-release-only real-unit selection.

Play Console: the owner explicitly approved permanent deletion of the old
unpublished `com.srikanth.sketchora` draft (app 4974662142680739969). Deletion
was verified while the new app 4972803420874038186 remained. Store assets,
privacy URL, unrestricted sign-in access, ads declaration, Everyone/PEGI 3
ratings, target ages 6–8 through adults, non-government/no-finance/no-health
declarations, Art & design category and contactus@epitomehub.com were saved.
The owner approved IARC terms and the children-law certification. Expert
Approved was not requested or claimed. AD_ID and Privacy Sandbox advertising
permissions remain removed; the separate App Set SDK can still process other
identifiers.

Data safety answers cover SDK IP-derived general location, app interactions,
diagnostics, other performance data and device/other IDs. Google's official
SDK data disclosure and the bundled dependency report were checked; artwork
and local logs are not automatically uploaded. At the last dashboard check,
10/11 setup tasks were complete and Data safety required its final submission
after the target-audience save. Subsequent completion/build/upload evidence
will be appended below. No public rollout has been performed by this release
work yet. AdMob approval remains Requires review.

Hosted policy: https://srikanth-jeldi.github.io/SketchAI/privacy.html

Sources for the SDK data mapping:
- https://developers.google.com/admob/android/privacy/play-data-disclosure?hl=en
- https://developers.google.com/admob/android/targeting

The catalogue is unchanged: this release does not claim 2,000 bespoke native
2K illustrations. iOS source identifiers/privacy UI are prepared, but no iOS
binary is built or validated on Windows.
