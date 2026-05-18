import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:netpay_ksa/features/salary_calculator/models/salary_record.dart';

class PdfService {
  static final _currency = NumberFormat.currency(
    locale: 'ar_SA', symbol: 'SAR ', decimalDigits: 2);

  /// يولّد PDF ويفتح نافذة المشاركة/الطباعة.
  static Future<void> exportAndShare(SalaryRecord record) async {
    final pdf = await _buildPdf(record);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'salary_${record.id.substring(0, 8)}.pdf',
    );
  }

  /// يحفظ PDF على الجهاز ويرجع المسار.
  static Future<String> saveToDevice(SalaryRecord record) async {
    final pdf = await _buildPdf(record);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/salary_${record.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<pw.Document> _buildPdf(SalaryRecord record) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final date = DateFormat('dd/MM/yyyy').format(record.savedAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0D7A5F'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'NetPay KSA',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'تقرير الراتب الصافي',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.white70,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Info Row ────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _infoCell('التاريخ', date, font, fontBold),
                _infoCell('الجنسية',
                    record.nationality.name == 'saudi' ? 'سعودي' : 'غير سعودي',
                    font, fontBold),
                _infoCell('النظام',
                    record.regime.name == 'legacy' ? 'قديم 9.75%' : 'جديد 2026',
                    font, fontBold),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Net Salary ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F0FBF7'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#0D7A5F')),
              ),
              child: pw.Column(
                children: [
                  pw.Text('صافي الراتب',
                      style: pw.TextStyle(font: font, fontSize: 13,
                          color: PdfColor.fromHex('#0D7A5F'))),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    _currency.format(record.netSalary),
                    style: pw.TextStyle(font: fontBold, fontSize: 28,
                        color: PdfColor.fromHex('#0D7A5F')),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Salary Breakdown ────────────────────────────────────────
            _sectionTitle('تفاصيل الراتب', fontBold),
            _row('الراتب الأساسي', record.basicSalary, font, fontBold),
            _row('بدل السكن', record.housingAllowance, font, fontBold),
            _row('بدلات أخرى', record.otherAllowances, font, fontBold),
            _row('الإجمالي', record.totalGross, font, fontBold, highlight: true),
            pw.SizedBox(height: 16),

            // ── GOSI ────────────────────────────────────────────────────
            _sectionTitle('تفصيل GOSI', fontBold),
            _row('خصم الموظف', record.employeeGosi, font, fontBold),
            _row('اشتراك صاحب العمل', record.gosi.employerGosi, font, fontBold),
            _row('أجر الاشتراك', record.gosi.contributableWage, font, fontBold),
            pw.SizedBox(height: 24),

            // ── Footer ──────────────────────────────────────────────────
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'تم الإنشاء بواسطة NetPay KSA — $date',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _sectionTitle(String title, pw.Font fontBold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(title,
            style: pw.TextStyle(font: fontBold, fontSize: 14,
                color: PdfColor.fromHex('#0D7A5F'))),
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
            pw.Text(label,
                style: pw.TextStyle(
                    font: highlight ? fontBold : font, fontSize: 12)),
            pw.Text(_currency.format(value),
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: highlight ? PdfColor.fromHex('#0D7A5F') : PdfColors.black)),
          ],
        ),
      );

  static pw.Widget _infoCell(
          String label, String value, pw.Font font, pw.Font fontBold) =>
      pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ],
      );
}