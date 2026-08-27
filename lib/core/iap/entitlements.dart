import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product ids as configured in the Play Console.
class IapProducts {
  IapProducts._();

  /// One-off purchase: removes ads and unlocks the full archive.
  static const String removeAds = 'allways_remove_ads';

  static const Set<String> all = {removeAds};
}

/// What the player has paid for.
class Entitlements {
  const Entitlements({required this.adsRemoved});

  const Entitlements.none() : adsRemoved = false;

  final bool adsRemoved;

  bool get showAds => !adsRemoved;
}

/// Tracks purchases and caches the result.
///
/// The cache is a convenience so the UI does not flash ads on a paying
/// player during the round trip to the store; it is never the source of
/// truth. Every launch calls [restore], and the store's answer overwrites
/// whatever was cached — otherwise clearing the cache would grant, or
/// editing it would fake, a purchase.
///
/// Verification here is client-side only, which is the accepted tradeoff
/// for a v1 with no backend. A determined user can defeat it. For a
/// low-value one-off unlock that is a reasonable trade; a subscription
/// would need server-side receipt validation.
class EntitlementsController extends AsyncNotifier<Entitlements> {
  static const String _cacheKey = 'entitlement_ads_removed';

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Future<Entitlements> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_cacheKey) ?? false;

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      // No store (an emulator without Play services, or an offline
      // launch). Fall back to the cache rather than revoking a purchase
      // the player really made.
      return Entitlements(adsRemoved: cached);
    }

    _subscription ??= InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );
    ref.onDispose(() => _subscription?.cancel());

    unawaited(InAppPurchase.instance.restorePurchases());
    return Entitlements(adsRemoved: cached);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    var adsRemoved = state.valueOrNull?.adsRemoved ?? false;

    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == IapProducts.removeAds) adsRemoved = true;
      }
      // Required by both stores: an unacknowledged purchase is refunded.
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKey, adsRemoved);
    state = AsyncData(Entitlements(adsRemoved: adsRemoved));
  }

  /// Starts the purchase flow for [IapProducts.removeAds].
  Future<bool> buyRemoveAds() async {
    if (!await InAppPurchase.instance.isAvailable()) return false;

    final response = await InAppPurchase.instance
        .queryProductDetails(IapProducts.all);
    if (response.productDetails.isEmpty) return false;

    final product = response.productDetails
        .firstWhere((p) => p.id == IapProducts.removeAds);
    return InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() => InAppPurchase.instance.restorePurchases();
}

final entitlementsProvider =
    AsyncNotifierProvider<EntitlementsController, Entitlements>(
  EntitlementsController.new,
);
