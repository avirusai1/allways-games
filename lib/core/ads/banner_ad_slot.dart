import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../iap/entitlements.dart';
import 'ad_config.dart';

/// A banner that occupies no space at all for paying players, and none
/// until the ad actually loads.
///
/// Reserving the slot before load would leave a grey gap under every
/// board on a bad connection; collapsing to zero keeps the layout honest.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  void _load() {
    if (_ad != null) return;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = ref.watch(entitlementsProvider).valueOrNull;
    if (entitlements == null || !entitlements.showAds) {
      return const SizedBox.shrink();
    }

    _load();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
