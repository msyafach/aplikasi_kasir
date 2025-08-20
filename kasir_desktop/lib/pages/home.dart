import 'package:flutter/material.dart';

import '../services/db.dart';
import 'inventory.dart';
import 'pos.dart';
import 'history.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Kasir & Inventory',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white24),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                final c = await DatabaseService.instance.countProducts();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Total produk: $c')));
              },
              child: const Text('Dashboard'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white24),
                shape: const StadiumBorder(),
              ),
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Beranda'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const SizedBox(height: 24),
              const _Heading(
                title: 'Sistem Kasir & Inventory',
                subtitle: 'Kelola penjualan dan stok barang dengan mudah',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 900;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    crossAxisCount: narrow ? 1 : 4,
                    children: [
                      _FeatureCard(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Kasir',
                        description:
                            'Proses transaksi penjualan dan cetak nota',
                        actionLabel: 'Buka Kasir',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PosPage()),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.all_inbox_outlined,
                        title: 'Inventory',
                        description:
                            'Kelola data produk dan stok barang',
                        actionLabel: 'Kelola Inventory',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryPage()),
                        ),
                      ),
                      _FeatureCard(
                        icon: Icons.bar_chart,
                        title: 'Dashboard',
                        description:
                            'Lihat dashboard dan analisis bisnis',
                        actionLabel: 'Lihat Dashboard',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon 🙂')),
                          );
                        },
                      ),
                      _FeatureCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Riwayat',
                        description:
                            'Riwayat transaksi dan cetak ulang nota',
                        actionLabel: 'Lihat Riwayat',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SalesHistoryPage()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Opacity(
                opacity: .75,
                child: Text(
                  'Sistem Kasir & Inventory Management',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Heading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: .75,
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, description, actionLabel;
  final VoidCallback? onTap;

  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 44, color: Colors.black87),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: t.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: .75,
                  child: Text(description, style: t.textTheme.bodyMedium),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
