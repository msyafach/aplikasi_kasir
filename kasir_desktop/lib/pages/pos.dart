import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/db.dart';
import 'receipt_preview.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});
  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  String _query = '';
  String? _category;
  late Future<List<Map<String, Object?>>> _future;

  final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final Map<int, _CartItem> _cart = {}; // productId -> item

  // Diskon
  final TextEditingController _discC = TextEditingController(text: '0');
  String _discMode = 'Rp'; // 'Rp' atau '%'

  // PPN
  final TextEditingController _taxC = TextEditingController(text: '11'); // default 11%
  String _taxMode = '%'; // 'Rp' atau '%'

  // Pembayaran
  final TextEditingController _payC = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _discC.dispose();
    _taxC.dispose();
    _payC.dispose();
    super.dispose();
  }

  void _reload() {
    _future = DatabaseService.instance.productsForSale(query: _query, category: _category);
    setState(() {});
  }

  double _parseNum(String s) {
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  num get subtotal => _cart.values.fold<num>(0, (a, b) => a + b.price * b.qty);

  num get discountNominal {
    final raw = _parseNum(_discC.text);
    if (_discMode == '%') {
      final p = raw.clamp(0, 100);
      return (subtotal * p) / 100.0;
    }
    return max(0, raw);
  }

  num get dpp => max<num>(0, subtotal - min<num>(discountNominal, subtotal)); // dasar pengenaan pajak

  num get taxNominal {
    final raw = _parseNum(_taxC.text);
    if (_taxMode == '%') {
      final p = raw.clamp(0, 100);
      return (dpp * p) / 100.0;
    }
    return max(0, raw);
  }

  num get totalNet => dpp + taxNominal;

  num get cashGiven => max<num>(0, _parseNum(_payC.text));
  num get change => max<num>(0, cashGiven - totalNet);
  int get cartCount => _cart.values.fold<int>(0, (a, b) => a + b.qty);

  void _addToCart(Map<String, Object?> p) {
    final id = p['id'] as int;
    final name = (p['name'] ?? '') as String;
    final price = (p['price'] ?? 0) as num;
    final stock = (p['stock'] ?? 0) as int;
    final imgPath = (p['image_path'] ?? '') as String?;
    final exist = _cart[id];
    if (exist == null) {
      if (stock <= 0) return;
      _cart[id] = _CartItem(id, name, price, 1, stock, imgPath);
    } else {
      if (exist.qty < exist.stock) exist.qty++;
    }
    setState(() {});
  }

  void _minus(int id) {
    final it = _cart[id];
    if (it == null) return;
    if (it.qty > 1) it.qty--; else _cart.remove(id);
    setState(() {});
  }

  void _plus(int id) {
    final it = _cart[id];
    if (it == null) return;
    if (it.qty < it.stock) { it.qty++; setState(() {}); }
  }

  Future<void> _payAndPreview() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong')));
      return;
    }
    if (cashGiven < totalNet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang bayar kurang')));
      return;
    }

    final itemsForDb = _cart.values
        .map((e) => {'product_id': e.id, 'qty': e.qty, 'price': e.price})
        .toList();
    final itemsForReceipt = _cart.values
        .map((e) => {'name': e.name, 'qty': e.qty, 'price': e.price})
        .toList();

    final saleId = await DatabaseService.instance
        .processSale(items: itemsForDb, total: totalNet);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewPage(
          storeName: 'Kasir & Inventory',
          dateTime: DateTime.now(),
          items: itemsForReceipt,
          total: totalNet,
          discount: discountNominal,
          tax: taxNominal,           // <— kirim PPN ke preview
          cashGiven: cashGiven,
          change: change,
          footerNote: 'No. Transaksi: $saleId',
        ),
      ),
    );

    setState(() {
      _cart.clear();
      _discC.text = '0';
      _discMode = 'Rp';
      _taxC.text = '11';
      _taxMode = '%';
      _payC.text = '0';
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: const Text('Kasir & Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sistem Kasir', style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Opacity(opacity: .75, child: Text('Pilih produk dan proses transaksi penjualan', style: t.textTheme.titleMedium)),
                const SizedBox(height: 18),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: produk
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 260, maxWidth: 520),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(Icons.search),
                                            hintText: 'Cari produk...',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) { _query = v.trim(); _reload(); },
                                        ),
                                      ),
                                    ),
                                    FutureBuilder<List<String>>(
                                      future: DatabaseService.instance.getCategories(),
                                      builder: (context, snap) {
                                        final cats = ['Semua Kategori', ...?snap.data];
                                        final val = _category ?? 'Semua Kategori';
                                        return DropdownButton<String>(
                                          value: val,
                                          items: cats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                          onChanged: (v) { if (v==null) return; _category = v=='Semua Kategori'? null : v; _reload(); },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Expanded(
                              child: FutureBuilder<List<Map<String, Object?>>>(
                                future: _future,
                                builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final items = snap.data ?? [];
                                  if (items.isEmpty) {
                                    return const Center(child: Text('Tidak ada produk tersedia'));
                                  }

                                  return LayoutBuilder(
                                    builder: (context, c) {
                                      final w = c.maxWidth;
                                      final cols = w < 520 ? 1 : (w < 900 ? 2 : 3);

                                      return GridView.builder(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 3.2,
                                        ),
                                        itemCount: items.length,
                                        itemBuilder: (_, i) {
                                          final p = items[i];
                                          final name  = (p['name'] ?? '') as String;
                                          final price = (p['price'] ?? 0) as num;
                                          final stock = (p['stock'] ?? 0) as int;
                                          final img   = (p['image_path'] ?? '') as String;

                                          return Card(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: img.isEmpty
                                                      ? const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported))
                                                      : Image.file(File(img), width: 56, height: 56, fit: BoxFit.cover),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium),
                                                        const SizedBox(height: 4),
                                                        Opacity(opacity: .8, child: Text('${money.format(price)} • Stok: $stock')),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  FilledButton(
                                                    onPressed: stock > 0 ? () => _addToCart(p) : null,
                                                    child: const Text('Tambah'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // RIGHT: keranjang
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.shopping_cart_outlined),
                                  const SizedBox(width: 8),
                                  Text('Keranjang ($cartCount)', style: t.textTheme.titleMedium),
                                ]),
                                const SizedBox(height: 12),

                                if (_cart.isEmpty)
                                  const Expanded(child: Center(child: Opacity(opacity: .7, child: Text('Keranjang kosong'))))
                                else
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: _cart.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (_, i) {
                                        final item = _cart.values.elementAt(i);
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(item.name),
                                          subtitle: Text('${money.format(item.price)} • Stok: ${item.stock}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(onPressed: () => _minus(item.id), icon: const Icon(Icons.remove)),
                                              Text('${item.qty}'),
                                              IconButton(onPressed: () => _plus(item.id), icon: const Icon(Icons.add)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                const Divider(),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Subtotal'),
                                  Text(money.format(subtotal)),
                                ]),
                                const SizedBox(height: 6),

                                // Diskon
                                Row(children: [
                                  const Text('Diskon'),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: _discC,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: '0'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: _discMode,
                                    items: const [
                                      DropdownMenuItem(value: 'Rp', child: Text('Rp')),
                                      DropdownMenuItem(value: '%', child: Text('%')),
                                    ],
                                    onChanged: (v) { if (v==null) return; setState(() => _discMode = v); },
                                  ),
                                  const Spacer(),
                                  Text('- ${money.format(discountNominal)}'),
                                ]),

                                const SizedBox(height: 6),

                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('DPP'),
                                  Text(money.format(dpp)),
                                ]),

                                const SizedBox(height: 6),

                                // PPN
                                Row(children: [
                                  const Text('PPN'),
                                  const SizedBox(width: 28),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: _taxC,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: '11'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: _taxMode,
                                    items: const [
                                      DropdownMenuItem(value: '%', child: Text('%')),
                                      DropdownMenuItem(value: 'Rp', child: Text('Rp')),
                                    ],
                                    onChanged: (v) { if (v==null) return; setState(() => _taxMode = v); },
                                  ),
                                  const Spacer(),
                                  Text('+ ${money.format(taxNominal)}'),
                                ]),

                                const SizedBox(height: 6),

                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(money.format(totalNet), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 6),

                                // Pembayaran
                                Row(children: [
                                  const Text('Bayar'),
                                  const SizedBox(width: 28),
                                  SizedBox(
                                    width: 160,
                                    child: TextField(
                                      controller: _payC,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: '0'),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(money.format(cashGiven)),
                                ]),
                                const SizedBox(height: 6),

                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Kembalian'),
                                  Text(money.format(change)),
                                ]),
                                const SizedBox(height: 8),

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _cart.isEmpty ? null : _payAndPreview,
                                    icon: const Icon(Icons.picture_as_pdf_outlined),
                                    label: const Text('Bayar & Preview Nota'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItem {
  final int id;
  final String name;
  final num price;
  int qty;
  final int stock;
  final String? imagePath;
  _CartItem(this.id, this.name, this.price, this.qty, this.stock, this.imagePath);
}
