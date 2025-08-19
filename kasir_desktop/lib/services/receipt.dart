import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// items: [{'name': String, 'qty': int, 'price': num}]
Future<Uint8List> buildReceiptPdfBytes({
  required String storeName,
  required DateTime dateTime,
  required List<Map<String, dynamic>> items,
  required num total,            // total NET = DPP + pajak
  num discount = 0,              // nominal diskon
  num tax = 0,                   // nominal PPN
  num? cashGiven,
  num? change,
  String? footerNote,
}) async {
  const locale = 'id_ID';
  try { await initializeDateFormatting(locale, null); } catch (_) {}
  Intl.defaultLocale = locale;

  final doc = pw.Document();
  final money   = NumberFormat.currency(locale: locale, symbol: 'Rp ', decimalDigits: 0);
  final dateTxt = DateFormat('dd MMM yyyy HH:mm', locale).format(dateTime);

  final subtotal = items.fold<num>(0, (a, e) => a + (e['price'] as num) * (e['qty'] as int));
  final dpp = (subtotal - discount).clamp(0, double.infinity); // dasar pengenaan pajak

  pw.Widget kv(String k, String v, {bool bold = false}) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          pw.Text(v, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        ],
      );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Nota Penjualan • $dateTxt'),
          pw.SizedBox(height: 12),
          pw.Divider(),

          // Items
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(children: [
                pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Qty x Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ]),
              ...items.map((it) {
                final name  = (it['name'] ?? '') as String;
                final qty   = (it['qty'] ?? 0) as int;
                final price = (it['price'] ?? 0) as num;
                final st = price * qty;
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(name, maxLines: 2)),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('$qty x ${money.format(price)}')),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(money.format(st))),
                  ),
                ]);
              }),
            ],
          ),

          pw.Divider(),
          kv('Subtotal', money.format(subtotal)),
          if (discount > 0) kv('Diskon', '- ${money.format(discount)}'),
          kv('DPP', money.format(dpp)),                 // <— DPP ditampilkan
          if (tax > 0) kv('PPN', '+ ${money.format(tax)}'),
          pw.SizedBox(height: 4),
          kv('TOTAL', money.format(total), bold: true),

          if (cashGiven != null) ...[
            pw.SizedBox(height: 4),
            kv('Bayar', money.format(cashGiven)),
          ],
          if (change != null) kv('Kembalian', money.format(change)),

          pw.SizedBox(height: 24),
          if (footerNote != null) pw.Center(child: pw.Text(footerNote)),
          pw.Spacer(),
          pw.Center(child: pw.Text('Terima kasih!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
        ],
      ),
    ),
  );

  return doc.save();
}
