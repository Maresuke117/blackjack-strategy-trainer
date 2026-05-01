import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告ユニットIDを管理するクラス。
/// 本番環境では自身のAdMob IDに差し替えてください。
class AdHelper {
  // TODO: リリース時にここを true にして本番IDを設定する
  static const bool isProduction = false;

  static String get bannerAdUnitId {
    if (kIsWeb) return ''; // Webでは空文字を返す
    if (isProduction) {
      if (Platform.isAndroid) return 'YOUR_ANDROID_BANNER_ID';
      if (Platform.isIOS) return 'YOUR_IOS_BANNER_ID';
    }
    // テスト用ID
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return ''; // Webでは空文字を返す
    if (isProduction) {
      if (Platform.isAndroid) return 'YOUR_ANDROID_INTERSTITIAL_ID';
      if (Platform.isIOS) return 'YOUR_IOS_INTERSTITIAL_ID';
    }
    // テスト用ID
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    return 'ca-app-pub-3940256099942544/4411468910';
  }

  /// インタースティシャル広告を読み込んで表示する。
  static void showInterstitialAd(Function onAdDismissed) {
    if (kIsWeb) {
      onAdDismissed();
      return;
    }
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              onAdDismissed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (err) {
          onAdDismissed();
        },
      ),
    );
  }
}
