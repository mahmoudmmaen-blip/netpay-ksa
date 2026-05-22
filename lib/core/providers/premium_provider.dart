import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/premium/providers/premium_provider.dart';

export 'package:netgulf/features/premium/providers/premium_provider.dart';

/// هل يُعرض إعلان AdMob؟ — false لمشتركي Premium فقط.
final showAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(premiumNotifierProvider).isPremium;
  return !isPremium;
});
