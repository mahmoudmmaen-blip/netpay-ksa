import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/models/salary_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// تصدير تقرير الراتب كـ PDF عربي (RTL) مع خط Cairo.
class PdfService {
  PdfService._();

  static const PdfColor _emerald = PdfColor.fromInt(0xFF0D7A5F);
  static const PdfColor _emeraldLight = PdfColor.fromInt(0xFFF0FBF7);

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'ar_SA',
    symbol: 'ر.س ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'ar_SA');

  /// يولّد PDF ويفتح نافذة المشاركة/الطباعة.
  static Future<void> exportAndShare(SalaryRecord record) async {
    final bytes = await _buildPdfBytes(record);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: _fileName(record),
    );
  }

  /// يحفظ PDF على الجهاز ويرجع المسار الكامل.
  static Future<String> saveToDevice(SalaryRecord record) async {
    final bytes = await _buildPdfBytes(record);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_fileName(record)}');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static String _fileName(SalaryRecord record) =>
      'netgulf_salary_${record.id.substring(0, 8)}.pdf';

  static Future<List<int>> _buildPdfBytes(SalaryRecord record) async {
    final doc = await _buildPdf(record);
    return doc.save();
  }

  static Future<pw.Document> _buildPdf(SalaryRecord record) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final gosi = record.gosi;
    final date = _dateFormat.format(record.savedAt);

    final doc = pw.Document(
      title: 'تقرير الراتب — ${record.label}',
      author: 'NetGulf',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _header(date),
          pw.SizedBox(height: 16),
          _metaRow(record, font, fontBold),
          pw.SizedBox(height: 20),
          _netSalaryCard(record, font, fontBold),
          pw.SizedBox(height: 20),
          _sectionTitle('تفاصيل الراتب', fontBold),
          _row('الراتب الأساسي', record.basicSalary, font, fontBold),
          _row('بدل السكن', record.housingAllowance, font, fontBold),
          _row('بدلات أخرى', record.otherAllowances, font, fontBold),
          if (record.includeOtherInGosiBase)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                '• البدلات الأخرى مدرجة في أجر الاشتراك',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
            ),
          _row('إجمالي الراتب', record.totalGross, font, fontBold, highlight: true),
          pw.SizedBox(height: 16),
          _sectionTitle(
            'تفصيل GOSI — موظف (${gosi.employeeRatePercent}%)',
            fontBold,
          ),
          _row('تقاعد', gosi.employeePension, font, fontBold),
          _row('ساند (SANED)', gosi.employeeSaned, font, fontBold),
          _row('إجمالي خصم الموظف', record.employeeGosi, font, fontBold,
              highlight: true),
          pw.SizedBox(height: 12),
          _sectionTitle(
            'تفصيل GOSI — صاحب العمل (${gosi.employerRatePercent}%)',
            fontBold,
          ),
          _row('تقاعد', gosi.employerPension, font, fontBold),
          _row('أخطار مهنية', gosi.employerHazard, font, fontBold),
          _row('ساند', gosi.employerSaned, font, fontBold),
          _row('إجمالي صاحب العمل', gosi.employerGosi, font, fontBold),
          pw.SizedBox(height: 12),
          _row('أجر الاشتراك', gosi.subscriptionWage, font, fontBold),
          _row(
            'بعد السقف (${GosiModel.wageCeiling} ر.س)',
            gosi.contributableWage,
            font,
            fontBold,
            highlight: true,
          ),
          if (gosi.wageCeilingApplied)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4, bottom: 8),
              child: pw.Text(
                'تم تطبيق سقف 45,000 ر.س على أجر الاشتراك',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.orange800),
              ),
            ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'تم الإنشاء بواسطة NetGulf — $date',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _header(String date) => pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: _emerald,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              'NetGulf',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'تقرير الراتب الصافي',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              date,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey300),
            ),
          ],
        ),
      );

  static pw.Widget _metaRow(
    SalaryRecord record,
    pw.Font font,
    pw.Font fontBold,
  ) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _infoCell('العنوان', record.label, font, fontBold),
          _infoCell(
            'الجنسية',
            record.nationality == NationalityType.saudi ? 'سعودي' : 'غير سعودي',
            font,
            fontBold,
          ),
          _infoCell(
            'النظام',
            record.regime == GosiRegime.legacy ? 'قديم 9.75%' : 'جديد 2026',
            font,
            fontBold,
          ),
        ],
      );

  static pw.Widget _netSalaryCard(
    SalaryRecord record,
    pw.Font font,
    pw.Font fontBold,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: pw.BoxDecoration(
          color: _emeraldLight,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _emerald, width: 1.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              'صافي الراتب',
              style: pw.TextStyle(font: font, fontSize: 13, color: _emerald),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _currency.format(record.netSalary),
              style: pw.TextStyle(font: fontBold, fontSize: 28, color: _emerald),
            ),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String title, pw.Font fontBold) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 14, color: _emerald),
        ),
      );

  static pw.Widget _row(
    String label,
    double value,
    pw.Font font,
    pw.Font fontBold, {
    bool highlight = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: highlight ? fontBold : font,
                fontSize: 12,
              ),
            ),
            pw.Text(
              _currency.format(value),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: highlight ? _emerald : PdfColors.black,
              ),
            ),
          ],
        ),
      );

  static pw.Widget _infoCell(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) =>
      pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ],
      );
}
