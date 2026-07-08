import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();
  factory AdmobService() => _instance;
  AdmobService._internal();

  BannerAd? bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool isBannerAdReady = false;

  // TODO: Replace with Production IDs when releasing to Play Store
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  void loadBannerAd(VoidCallback onLoaded) {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerAdReady = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: ${err.message}');
          ad.dispose();
          bannerAd = null;
          isBannerAdReady = false;
        },
        onAdClosed: (ad) {
          ad.dispose();
          bannerAd = null;
        },
      ),
    );
    bannerAd?.load();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed: ${err.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // Ads should only be shown once
      loadInterstitialAd(); // Load next ad
    }
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: ${err.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd(Function onUserEarnedReward) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
        },
      );
      _rewardedAd = null;
      loadRewardedAd(); // Load next ad
    } else {
      loadRewardedAd(); // Fallback if it wasn't loaded
    }
  }
  
  void dispose() {
    bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
