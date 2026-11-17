import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/unlock/reward_ad_gateway.dart';

/// Ethical AdMob: voluntary rewarded video ONLY, shown solely after the user
/// taps "Watch Video to Unlock". No interstitials, no app-open ads, nothing on
/// launch or tab switches.
///
/// Ad unit ids default to Google's public test units. Release builds pass the
/// real ids with `--dart-define=ADMOB_REWARDED_ANDROID=...` /
/// `--dart-define=ADMOB_REWARDED_IOS=...`.
class AdMobRewardGateway implements RewardAdGateway {
  AdMobRewardGateway._();
  static final instance = AdMobRewardGateway._();

  static const _androidUnit = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const _iosUnit = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  String get _unitId => Platform.isIOS ? _iosUnit : _androidUnit;

  bool _initialized = false;
  RewardedAd? _ad;
  Completer<RewardedAd?>? _loading;

  /// Initialise the SDK and quietly preload one rewarded ad (nothing is shown).
  Future<void> init() async {
    if (_initialized || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(_load());
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  Future<RewardedAd?> _load() {
    if (_ad != null) return Future.value(_ad);
    final pending = _loading;
    if (pending != null) return pending.future;
    final c = _loading = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(nonPersonalizedAds: false),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = null;
          c.complete(ad);
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded ad failed to load: ${err.code} ${err.message}');
          _loading = null;
          c.complete(null);
        },
      ),
    );
    return c.future;
  }

  @override
  Future<bool> showRewarded() async {
    await init();
    if (!_initialized) return false;
    final ad = await _load().timeout(const Duration(seconds: 10), onTimeout: () => null);
    if (ad == null) return false;
    _ad = null;

    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete(earned);
        unawaited(_load()); // preload the next one for later
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('Rewarded ad failed to show: $err');
        a.dispose();
        if (!done.isCompleted) done.complete(false);
        unawaited(_load());
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }
}
