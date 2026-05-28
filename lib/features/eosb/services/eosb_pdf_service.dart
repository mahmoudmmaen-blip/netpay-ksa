import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// تصدير تقرير نهاية الخدمة PDF — عربي RTL احترافي.
class EosbPdfService {
  EosbPdfService._();

  static const PdfColor _emerald = PdfColor.fromInt(0xFF0D7A5F);
  static const PdfColor _emeraldDark = PdfColor.fromInt(0xFF064E3B);
  static const PdfColor _gold = PdfColor.fromInt(0xFFD4AF37);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF0FBF7);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

  static Future<void> exportAndShare(EosbCalculationResult result) async {
    final bytes = await _buildBytes(result);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename:
          'netgulf_eosb_${DateTime.now().millisecondsSinceEpoch.remainder(100000)}.pdf',
    );
  }

  static Future<List<int>> _buildBytes(EosbCalculationResult result) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final model = result.input;
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: '${model.country.currencySymbol} ',
      decimalDigits: 2,
    );
    final date = DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());
    final logo = await _loadLogo();

    final doc = pw.Document(
      title: 'تقرير نهاية الخدمة — ${AppConstants.appNameEn}',
      author: AppConstants.appNameEn,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            '${AppConstants.appNameAr} · ${AppConstants.appNameEn} — صفحة ${context.pageNumber}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _header(logo, font, fontBold, date),
          pw.SizedBox(height: 20),
          _metaSection(result, font, fontBold),
          pw.SizedBox(height: 16),
          _totalBanner(result, currency, fontBold),
          pw.SizedBox(height: 20),
          pw.Text(
            'تفصيل المستحقات',
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: _emeraldDark),
          ),
          pw.SizedBox(height: 10),
          _breakdownTable(result, currency, font, fontBold),
          pw.SizedBox(height: 20),
          pw.Text(
            'المراجع القانونية',
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: _emeraldDark),
          ),
          pw.SizedBox(height: 8),
          ...result.legalReferences.map(
            (ref) => _legalCard(ref, font, fontBold),
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'هذه الحسابة تقريبية - يُفضل استشارة متخصص قانوني',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 24),
          _signatureSection(font, fontBold, date),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.amber200),
            ),
            child: pw.Text(
              'تنبيه: هذا التقرير تقديري للتوجيه العام فقط وليس رأياً قانونياً ملزماً. '
              'راجع العقد ومحامياً أو الجهة المختصة.',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey800),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(
    pw.MemoryImage? logo,
    pw.Font font,
    pw.Font fontBold,
    String date,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_emeraldDark, _emerald],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 48,
              height: 48,
              margin: const pw.EdgeInsets.only(left: 12),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppConstants.appNameAr,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 22,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  AppConstants.appNameEn,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: PdfColors.grey300,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'تقرير حاسبة نهاية الخدمة الشاملة',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'التاريخ',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey300),
              ),
              pw.Text(
                date,
                style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaSection(
    EosbCalculationResult result,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final m = result.input;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _metaRow('الدولة', result.countryLabel, font, fontBold),
          _metaRow('الإطار القانوني', m.country.eosLawChipAr, font, fontBold),
          _metaRow('سبب الإنهاء', m.terminationSummary, font, fontBold),
          _metaRow(
            'مدة الخدمة',
            '${m.yearsOfService} سنة · ${m.monthsOfService} شهر · ${m.daysOfService} يوم',
            font,
            fontBold,
          ),
          _metaRow(
            'نوع العقد',
            EosbModel.contractTypeLabel(m.contractType),
            font,
            fontBold,
          ),
          _metaRow(
            'الأجر الشهري',
            '${m.monthlyWage.toStringAsFixed(2)} ${m.country.currencySymbol}',
            font,
            fontBold,
          ),
          _metaRow(
            'إشعار الإنهاء',
            m.noticeProvided ? 'تم تقديمه' : 'لم يُقدَّم',
            font,
            fontBold,
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalBanner(
    EosbCalculationResult result,
    NumberFormat currency,
    pw.Font fontBold,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _emerald, width: 1.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'إجمالي المستحقات',
            style: pw.TextStyle(font: fontBold, fontSize: 13, color: _emeraldDark),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            currency.format(result.totalEntitlements),
            style: pw.TextStyle(font: fontBold, fontSize: 26, color: _emerald),
          ),
        ],
      ),
    );
  }

  static pw.Widget _breakdownTable(
    EosbCalculationResult result,
    NumberFormat currency,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _surface),
          children: [
            _cell('البند', fontBold, bold: true),
            _cell('المبلغ', fontBold, bold: true, alignEnd: true),
          ],
        ),
        ...result.components.map(
          (c) => pw.TableRow(
            children: [
              _cell(
                c.subtitleAr != null ? '${c.titleAr}\n${c.subtitleAr}' : c.titleAr,
                c.isPrimary ? fontBold : font,
                bold: c.isPrimary,
              ),
              _cell(
                currency.format(c.amount),
                c.isPrimary ? fontBold : font,
                bold: c.isPrimary,
                alignEnd: true,
              ),
            ],
          ),
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _emerald),
          children: [
            _cell('الإجمالي', fontBold, bold: true, light: true),
            _cell(
              currency.format(result.totalEntitlements),
              fontBold,
              bold: true,
              alignEnd: true,
              light: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font, {
    bool bold = false,
    bool alignEnd = false,
    bool light = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: alignEnd ? pw.TextAlign.left : pw.TextAlign.right,
        style: pw.TextStyle(
          font: font,
          fontSize: bold ? 11 : 10,
          color: light ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _legalCard(
    EosbLegalReference ref,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            ref.article,
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: _emerald),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            ref.summary,
            style: pw.TextStyle(font: font, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureSection(
    pw.Font font,
    pw.Font fontBold,
    String date,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'توقيع الموظف',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 28),
              pw.Container(
                width: 180,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500)),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('الاسم: _______________', style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'توقيع صاحب العمل / الموارد البشرية',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 28),
              pw.Container(
                width: 180,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500)),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('التاريخ: $date', style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontBold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
