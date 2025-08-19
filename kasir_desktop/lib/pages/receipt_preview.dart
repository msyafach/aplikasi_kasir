import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/receipt.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final String storeName;
  final DateTime dateTime;
  final List<Map<String, dynamic>> items;
  final num total;
  final num discount;
  final num tax;          // <— tambah
  final num? cashGiven;
  final num? change;
  final String? footerNote;

  const ReceiptPreviewPage({
    super.key,
    required this.storeName,
    required this.dateTime,
    required this.items,
    required this.total,
    this.discount = 0,
    this.tax = 0,         // <— default
    this.cashGiven,
    this.change,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Nota')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        build: (format) => buildReceiptPdfBytes(
          storeName: storeName,
          dateTime: dateTime,
          items: items,
          total: total,
          discount: discount,
          tax: tax,                 // <— kirim ke builder
          cashGiven: cashGiven,
          change: change,
          footerNote: footerNote,
        ),
      ),
    );
  }
}
