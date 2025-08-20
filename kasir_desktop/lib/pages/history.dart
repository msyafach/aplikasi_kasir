import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/db.dart';
import 'receipt_preview.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final _fmtDate = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  final _fmtMoney =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  DateTime? _from;
  DateTime? _to;
  final _qC = TextEditingController();

  late Future<bool> _schemaFuture;
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _schemaFuture = DatabaseService.instance.isSchemaReady();
    _reload();
  }

  @override
  void dispose() {
    _qC.dispose();
    super.dispose();
  }

  void _reload() {
    _future = DatabaseService.instance.salesHistory(
      from: _from,
      to: _to,
      query: _qC.text.trim().isEmpty ? null : _qC.text.trim(),
    );
    setState(() {});
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDate: _from ?? now,
    );
    if (d != null) {
      _from = DateTime(d.year, d.month, d.day, 0, 0, 0);
      _reload();
    }
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDate: _to ?? now,
    );
    if (d != null) {
      _to = DateTime(d.year, d.month, d.day, 23, 59, 59);
      _reload();
    }
  }

  Future<void> _preview(Map<String, Object?> sale) async {
    final id = sale['id'] as int;
    final items = await DatabaseService.instance.saleItems(id);

    final lines = items
        .map((e) => {
              'name': (e['name'] ?? '') as String,
              'qty': (e['qty'] ?? 0) as int,
              'price': (e['price'] ?? 0) as num,
            })
        .toList();

    final total = (sale['total'] ?? 0) as num;
    final discount = (sale['discount'] ?? 0) as num;
    final tax = (sale['tax'] ?? 0) as num;
    final cash = (sale['cash'] ?? 0) as num;
    final change = cash > 0 ? (cash - total) : null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewPage(
          storeName: 'Kasir & Inventory',
          dateTime:
              DateTime.parse((sale['created_at'] ?? DateTime.now().toIso8601String()) as String),
          items: lines,
          total: total,
          discount: discount,
          tax: tax,
          cashGiven: cash == 0 ? null : cash,
          change: change,
          footerNote: 'No. Transaksi: $id',
        ),
      ),
    );
  }

  Widget _schemaCallout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFECB3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Database Belum Siap',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF7B5E00),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Klik tombol di bawah untuk membuat tabel yang diperlukan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7B5E00)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await DatabaseService.instance.initSchema();
              setState(() {
                _schemaFuture = DatabaseService.instance.isSchemaReady();
              });
            },
            icon: const Icon(Icons.build),
            label: const Text('Buat Tabel Otomatis'),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () async {
              await DatabaseService.instance.seedSampleProductsIfEmpty();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contoh produk diisi.')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Isi Contoh Produk (opsional)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Transaksi',
                    style:
                        t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Opacity(
                  opacity: .75,
                  child: Text(
                    'Lihat dan cetak ulang nota transaksi sebelumnya',
                    style: t.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 18),

                // Filter bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            controller: _qC,
                            onSubmitted: (_) => _reload(),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Cari no. transaksi…',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFrom,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_from == null
                              ? 'Dari tanggal'
                              : DateFormat('dd MMM yyyy', 'id_ID').format(_from!)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickTo,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_to == null
                              ? 'Sampai tanggal'
                              : DateFormat('dd MMM yyyy', 'id_ID').format(_to!)),
                        ),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Terapkan'),
                        ),
                        if (_from != null || _to != null || _qC.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _from = null;
                              _to = null;
                              _qC.clear();
                              _reload();
                            },
                            child: const Text('Reset'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cek skema DB dulu (tanpa menampilkan pesan error mentah)
                FutureBuilder<bool>(
                  future: _schemaFuture,
                  builder: (context, s) {
                    if (s.connectionState == ConnectionState.waiting) {
                      return const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final ready = s.data == true;
                    if (!ready) {
                      return Expanded(child: _schemaCallout());
                    }

                    // Skema siap -> tampilkan list riwayat
                    return Expanded(
                      child: FutureBuilder<List<Map<String, Object?>>>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final list = snap.data ?? const [];
                          if (list.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Belum ada transaksi.'),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.point_of_sale),
                                    label: const Text('Kembali ke Kasir'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final s = list[i];
                              final id = s['id'] as int;
                              final created =
                                  DateTime.parse((s['created_at'] as String));
                              final itemCount = (s['item_count'] ?? 0) as int;
                              final total = (s['total'] ?? 0) as num;

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    child: Text('$id'),
                                  ),
                                  title: Text('No. Transaksi #$id'),
                                  subtitle: Text(
                                    '${_fmtDate.format(created)} • $itemCount item',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _fmtMoney.format(total),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 18),
                                        label: const Text('Preview'),
                                        onPressed: () => _preview(s),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
