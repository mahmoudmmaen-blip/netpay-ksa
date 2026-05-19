import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/share/share_service.dart';

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());
