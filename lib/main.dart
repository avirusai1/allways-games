import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Not awaited: the first banner simply will not fill until this
  // finishes, which is better than holding the splash screen on it.
  unawaited(MobileAds.instance.initialize());
  runApp(const ProviderScope(child: AllwaysGamesApp()));
}
