import 'dart:io';
import 'package:flutter/material.dart';
import '../services/db.dart';
import 'product_add.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _query = '';
  String? _category;
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DatabaseService.instance
        .products(query: _query, category: _category);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Kelola Inventory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );
                if (changed == true) _reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // total
              FutureBuilder<int>(
                future: DatabaseService.instance.countProducts(),
                builder: (context, snap) {
                  final total = snap.data ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 8),
                      Text('Total Produk: $total',
                          style: Theme.of(context).textTheme.titleMedium),
                    ]),
                  );
                },
              ),
              // filter card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter & Pencarian',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Cari nama produk atau deskripsi...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                _query = v.trim();
                                _reload();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          FutureBuilder<List<String>>(
                            future:
                                DatabaseService.instance.getCategories(),
                            builder: (context, snap) {
                              final cats =
                                  ['Semua Kategori', ...?snap.data];
                              final value = _category ?? 'Semua Kategori';
                              return DropdownButton<String>(
                                value: value,
                                items: cats
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  _category =
                                      val == 'Semua Kategori' ? null : val;
                                  _reload();
                                },
                              );
                            },
                          ),
                        ]),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              // list
              Expanded(
                child: FutureBuilder<List<Map<String, Object?>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                            'Belum ada produk. Tambah produk pertama Anda!'),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = items[i];
                        final id = m['id'] as int;
                        final name = (m['name'] ?? '') as String;
                        final cat = (m['category'] ?? '-') as String;
                        final stock = (m['stock'] ?? 0) as int;
                        final price = (m['price'] ?? 0) as num;
                        final active = ((m['active'] ?? 1) as int) == 1;
                        final imgPath = (m['image_path'] ?? '') as String;
                        return Card(
                          child: ListTile(
                            leading: imgPath.isEmpty
                                ? const Icon(Icons.image_not_supported)
                                : Image.file(File(imgPath),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover),
                            title: Text(name),
                            subtitle: Text(
                                'Kategori: $cat • Stok: $stock • Rp ${price.toStringAsFixed(0)}'),
                            trailing: Wrap(spacing: 8, children: [
                              Icon(
                                active
                                    ? Icons.check_circle_outline
                                    : Icons.remove_circle_outline,
                                color: active ? Colors.green : Colors.orange,
                              ),
                              IconButton(
                                tooltip: 'Tambah stok',
                                onPressed: () async {
                                  await DatabaseService.instance
                                      .updateStock(id, stock + 1);
                                  _reload();
                                },
                                icon: const Icon(Icons.add),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                onPressed: () async {
                                  await DatabaseService.instance
                                      .deleteProduct(id);
                                  _reload();
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}