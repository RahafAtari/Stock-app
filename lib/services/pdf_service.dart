import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import 'supabase_service.dart';

class PdfService {
  static pw.Font? _arabicFont;

  static Future<pw.Font> _loadFont() async {
    _arabicFont ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    return _arabicFont!;
  }

  static Future<pw.Page> _buildReceiptPage(
    pw.Font font,
    Sale sale,
    List<Map<String, dynamic>> lines,
  ) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a5,
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('فاتورة بيع',
                  style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('العميل: ${sale.customerName}', style: pw.TextStyle(font: font)),
              pw.Text('التاريخ: ${sale.saleDate.toIso8601String().split('T').first}',
                  style: pw.TextStyle(font: font)),
              pw.Text('طريقة الدفع: ${sale.paymentMethod ?? ''}', style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(children: [
                    _cell('الصنف', font, bold: true),
                    _cell('الكمية', font, bold: true),
                    _cell('سعر الوحدة', font, bold: true),
                    _cell('الإجمالي', font, bold: true),
                  ]),
                  ...lines.map((l) {
                    final item = l['items'] as Map<String, dynamic>?;
                    return pw.TableRow(children: [
                      _cell('${item?['item_name'] ?? ''}', font),
                      _cell('${l['quantity']}', font),
                      _cell('${l['unit_price']}', font),
                      _cell('${l['total_price']}', font),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('الإجمالي الكلي: ${sale.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('المدفوع: ${sale.amountPaid.toStringAsFixed(2)}', style: pw.TextStyle(font: font)),
              if (sale.amountOwed > 0)
                pw.Text('المتبقي: ${sale.amountOwed.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font, color: PdfColors.red)),
            ],
          ),
        );
      },
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(font: font, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  /// Prints or shows a print-preview for a single sale.
  static Future<void> printSingleSale(Sale sale) async {
    final font = await _loadFont();
    final lines = await SupabaseService.instance.fetchSaleLines(sale.saleId);
    final doc = pw.Document();
    doc.addPage(await _buildReceiptPage(font, sale, lines));
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  /// Prints several sales as one PDF — one receipt per page.
  static Future<void> printMultipleSales(List<Sale> sales) async {
    final font = await _loadFont();
    final doc = pw.Document();
    for (final sale in sales) {
      final lines = await SupabaseService.instance.fetchSaleLines(sale.saleId);
      doc.addPage(await _buildReceiptPage(font, sale, lines));
    }
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}