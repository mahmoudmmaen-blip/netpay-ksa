import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// التقاط بطاقة الراتب ومشاركتها كصورة.
class ShareService {
  ShareService({ScreenshotController? controller})
      : _screenshot = controller ?? ScreenshotController();

  final ScreenshotController _screenshot;

  /// يلتقط [SalaryShareCard] ويفتح ورقة المشاركة (واتساب، X، …).
  Future<void> shareSalaryResult({
    required BuildContext context,
    required SalaryShareData data,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final bytes = await captureSalaryCard(data: data);
    if (bytes == null || bytes.isEmpty) {
      throw ShareException('تعذر إنشاء صورة المشاركة.');
    }

    final file = await _writePng(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: '${AppConstants.appNameAr} — صافي الراتب',
      text:
          'حسبت راتبي الصافي عبر ${AppConstants.appNameEn} '
          '(${AppConstants.appTaglineAr})',
      sharePositionOrigin: origin,
    );
  }

  /// يلتقط البطاقة دون فتح ورقة المشاركة (للاختبار).
  Future<Uint8List?> captureSalaryCard({
    required SalaryShareData data,
    double pixelRatio = 3,
  }) async {
    try {
      return await _screenshot.captureFromWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.transparent,
            child: SalaryShareCard(data: data),
          ),
        ),
        delay: const Duration(milliseconds: 40),
        pixelRatio: pixelRatio,
        targetSize: const Size(360, 520),
      );
    } catch (_) {
      return null;
    }
  }

  Future<File> _writePng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/netgulf_salary_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

class ShareException implements Exception {
  ShareException(this.message);
  final String message;

  @override
  String toString() => message;
}
