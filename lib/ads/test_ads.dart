import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_gate.dart';

/// Demo units remain available for all debug/profile and default builds.
class TestAdIds {
  static String get banner => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitial => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
}

/// Created for Sketluma Android on 2026-10-20. Live serving is opt-in only.
/// Keep disabled until the production consent/audience flow is validated.
class SketlumaAdIds {
  static const liveAdsEnabled = bool.fromEnvironment('SKETLUMA_LIVE_ADS');
  static const androidApp = 'ca-app-pub-9061518700917881~2013058778';
  static const androidBanner = 'ca-app-pub-9061518700917881/8725631776';
  static const androidInterstitial = 'ca-app-pub-9061518700917881/9759511842';

  static bool useLive({
    required bool release,
    required bool android,
    required bool enabled,
  }) => release && android && enabled;

  static bool get _live => useLive(
    release: kReleaseMode,
    android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    enabled: liveAdsEnabled,
  );
  static String get banner => _live ? androidBanner : TestAdIds.banner;
  static String get interstitial =>
      _live ? androidInterstitial : TestAdIds.interstitial;
}

class CompletionAdPolicy {
  final Set<String> _shown = {};
  DateTime? _lastShown;
  bool canShow(String id, DateTime now) =>
      !_shown.contains(id) &&
      (_lastShown == null ||
          now.difference(_lastShown!) >= const Duration(seconds: 60));
  void recordShown(String id, DateTime now) {
    _shown.add(id);
    _lastShown = now;
  }
}

class TestAds with WidgetsBindingObserver {
  TestAds._();
  static final instance = TestAds._();
  final ready = ValueNotifier<bool>(false);
  final privacyOptionsRequired = ValueNotifier<bool>(false);
  final policy = CompletionAdPolicy();
  InterstitialAd? _interstitial;
  DateTime? _loadedAt;
  bool _loading = false, _showing = false;
  bool _sdkInitialized = false;
  Future<void>? _initializing;
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      final permitted = await prepareAdConsent(
        update: () async {
          final updated = Completer<bool>();
          // No verified age screen: use protective child treatment throughout,
          // including when the Adults artwork collection is selected.
          ConsentInformation.instance.requestConsentInfoUpdate(
            ConsentRequestParameters(tagForUnderAgeOfConsent: true),
            () {
              if (!updated.isCompleted) updated.complete(true);
            },
            (_) {
              if (!updated.isCompleted) updated.complete(false);
            },
          );
          return updated.future.timeout(
            const Duration(seconds: 12),
            onTimeout: () => false,
          );
        },
        showIfRequired: () async {
          var succeeded = false;
          await ConsentForm.loadAndShowConsentFormIfRequired(
            (error) => succeeded = error == null,
          );
          return succeeded;
        },
        canRequestAds: () => ConsentInformation.instance.canRequestAds(),
      );
      await _refreshPrivacyOptions();
      if (!permitted) return;
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      WidgetsBinding.instance.addObserver(this);
      ready.value = true;
      unawaited(_preload());
    } catch (_) {
      ready.value = false;
    }
  }

  Future<void> _refreshPrivacyOptions() async {
    privacyOptionsRequired.value =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      final allowed = await ConsentInformation.instance.canRequestAds();
      _interstitial?.dispose();
      _interstitial = null;
      if (allowed && !_sdkInitialized) {
        await MobileAds.instance.initialize();
        _sdkInitialized = true;
        WidgetsBinding.instance.addObserver(this);
      }
      ready.value = allowed;
      await _refreshPrivacyOptions();
      if (allowed) unawaited(_preload());
    } catch (_) {
      // An unavailable privacy form must never interrupt a drawing.
    }
  }

  Future<void> _preload() async {
    if (!ready.value || _loading || _interstitial != null || _showing) return;
    _loading = true;
    try {
      await InterstitialAd.load(
        adUnitId: SketlumaAdIds.interstitial,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (!ready.value ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.paused) {
              ad.dispose();
              return;
            }
            _interstitial = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  /// Called only after a saved completion and an explicit Back to Home tap.
  /// Never wait for a network load. No ready ad means immediate navigation.
  Future<void> afterCompletion(String documentId) async {
    if (!ready.value ||
        _showing ||
        !policy.canShow(documentId, DateTime.now())) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_preload());
      return;
    }
    _interstitial = null;
    if (_loadedAt == null ||
        DateTime.now().difference(_loadedAt!) > const Duration(minutes: 55)) {
      ad.dispose();
      unawaited(_preload());
      return;
    }
    _showing = true;
    final dismissed = Completer<void>();
    void done() {
      ad.dispose();
      _showing = false;
      if (!dismissed.isCompleted) dismissed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (_) => done(),
      onAdFailedToShowFullScreenContent: (_, _) => done(),
      onAdShowedFullScreenContent: (_) =>
          policy.recordShown(documentId, DateTime.now()),
    );
    try {
      await ad.show();
      await dismissed.future;
    } catch (_) {
      done();
    }
    unawaited(_preload());
  }

  @override
  void didHaveMemoryPressure() {
    if (!_showing) {
      _interstitial?.dispose();
      _interstitial = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_showing) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    if (state == AppLifecycleState.resumed) unawaited(_preload());
  }
}

class HomeTestBanner extends StatelessWidget {
  const HomeTestBanner({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: TestAds.instance.ready,
    builder: (context, ready, _) =>
        ready && MediaQuery.sizeOf(context).width >= 320
        ? const _BannerSlot()
        : const SizedBox.shrink(),
  );
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot();
  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _load() {
    if (_ad != null) return;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: SketlumaAdIds.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || ad != _ad) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted && ad == _ad) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    unawaited(
      ad.load().catchError((Object _) {
        if (mounted && _ad == ad) {
          setState(() {
            _ad = null;
            _loaded = false;
          });
        }
        ad.dispose();
      }),
    );
  }

  @override
  void didHaveMemoryPressure() {
    _ad?.dispose();
    _ad = null;
    if (mounted) setState(() => _loaded = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _loaded = false);
    }
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_loaded || _ad == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Advertisement',
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              SizedBox(width: 320, height: 50, child: AdWidget(ad: _ad!)),
            ],
          ),
        );
}
