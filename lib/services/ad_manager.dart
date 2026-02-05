import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String appId = 'ca-app-pub-7036399347927896~5750385934';
  
  // Rewarded Ad Unit ID
  static const String rewardedAdUnitId = 'ca-app-pub-7036399347927896/8592171696';

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  void loadRewardedAd({required Function() onAdLoaded}) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          print('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required Function() onUserEarnedReward,
    required Function() onAdClosed,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          onAdClosed();
          // Load next ad
          loadRewardedAd(onAdLoaded: () {});
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          onAdClosed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onUserEarnedReward();
        },
      );
    } else {
      // If ad not loaded, just proceed
      onUserEarnedReward();
    }
  }
}
