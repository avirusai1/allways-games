import 'package:flutter/foundation.dart';

/// Ad unit identifiers.
///
/// The values below are Google's public *test* units. They must be
/// replaced with the real ones from the AdMob console before release, and
/// the AdMob app id in AndroidManifest.xml has to be replaced too.
/// Shipping test units to production earns no revenue; shipping *real*
/// units while developing gets the account suspended for invalid traffic,
/// which is why the two are split on [kDebugMode] rather than chosen by
/// hand.
class AdConfig {
  AdConfig._();

  // TODO(release): replace with the real AdMob unit ids before publishing.
  static const String _prodBanner = 'ca-app-pub-0000000000000000/0000000000';
  static const String _prodInterstitial =
      'ca-app-pub-0000000000000000/1111111111';

  // Google's documented test units — safe to click, never billed.
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  /// True until the real unit ids above are filled in.
  static bool get usingTestUnits =>
      kDebugMode || _prodBanner.contains('0000000000000000');

  static String get bannerUnitId =>
      usingTestUnits ? _testBanner : _prodBanner;

  static String get interstitialUnitId =>
      usingTestUnits ? _testInterstitial : _prodInterstitial;

  /// Puzzles a player finishes between interstitials.
  ///
  /// Interstitials only ever appear *after* a puzzle is done, never
  /// mid-solve: interrupting someone three guesses into a word game is the
  /// fastest way to lose them.
  static const int puzzlesPerInterstitial = 3;
}
