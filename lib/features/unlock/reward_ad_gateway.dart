import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Voluntary rewarded-video hook for the Unlock Pass.
///
/// Implementations must only show an ad in direct response to a user tap and
/// return `true` only when the reward was earned (video watched to the end).
/// Return `false` when offline, no ad is loaded, or the user dismissed early.
abstract class RewardAdGateway {
  Future<bool> showRewarded();
}

/// Placeholder until the google_mobile_ads implementation lands (Phase 4).
class _NoopGateway implements RewardAdGateway {
  @override
  Future<bool> showRewarded() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return false;
  }
}

/// Override with the real AdMob gateway in Phase 4.
final rewardAdGatewayProvider = Provider<RewardAdGateway>((ref) => _NoopGateway());
