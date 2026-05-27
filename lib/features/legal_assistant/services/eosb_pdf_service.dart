import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// تصدير تقرير نهاية الخدمة PDF — عربي RTL.
class EosbPdfService {
  EosbPdfService._();

  static const PdfColor _emerald = PdfColor.fromInt(0xFF0D7A5F);

  static Future<void> exportAndShare(EosbModel model) async {
    final bytes = await _buildBytes(model);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename:
          'netgulf_eosb_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}.pdf',
    );
  }

  static Future<List<int>> _buildBytes(EosbModel model) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: '${model.country.currencySymbol} ',
      decimalDigits: 2,
    );
    final date = DateFormat('dd/MM/yyyy', 'ar').format(DateTime.now());

    final doc = pw.Document(
      title: 'تقرير نهاية الخدمة — NetGulf',
      author: AppConstants.appNameEn,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          pw.Text(
            'حاسبة نهاية الخدمة الشاملة',
            style: pw.TextStyle(font: fontBold, fontSize: 20, color: _emerald),
          ),
          pw.SizedBox(height: 4),
          pw.Text('NetGulf · $date', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Text(
            '${model.country.flag} ${model.country.nameAr}',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          _row('سبب الإنهاء', model.terminationSummary, font, fontBold),
          _row(
            'مدة الخدمة',
            '${model.yearsOfService} سنة · ${model.monthsOfService} شهر · ${model.daysOfService} يوم',
            font,
            fontBold,
          ),
          _row(
            'نوع العقد',
            EosbModel.contractTypeLabel(model.contractType),
            font,
            fontBold,
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF0FBF7),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الإجمالي المستحق',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
                pw.Text(
                  currency.format(model.totalEntitlements),
                  style: pw.TextStyle(font: fontBold, fontSize: 16, color: _emerald),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('جدول التفصيل', style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          ...model.breakdownRows.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      r.label,
                      style: pw.TextStyle(
                        font: r.highlight ? fontBold : font,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  pw.Text(
                    currency.format(r.amount),
                    style: pw.TextStyle(
                      font: r.highlight ? fontBold : font,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('مراجع قانونية', style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 6),
          ...model.legalReferences.map(
            (ref) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ref.article, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  pw.Text(ref.summary, style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'تنبيه: هذه الحاسبة للتوجيه العام فقط وليست استشارة قانونية ملزمة. '
            'راجع محامياً أو الجهة المختصة للحالات المعقدة.',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.left,
              style: pw.TextStyle(font: fontBold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
