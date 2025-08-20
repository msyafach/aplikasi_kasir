import 'package:flutter/material.dart';

import '../services/db.dart';
import '../services/auth_service.dart';
import 'inventory.dart';
import 'pos.dart';
import 'history.dart';
import 'dashboard.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              AuthService.instance.logout();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = AuthService.instance;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kasir & Inventory',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              '${authService.userFullName} (${authService.userRole.toUpperCase()})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          if (authService.hasPermission('dashboard')) ...[
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
                child: const Text('Quick Stats'),
              ),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _showLogoutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
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
                  final features = <Widget>[
                    // Kasir - tersedia untuk semua role
                    if (authService.hasPermission('pos'))
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
                    
                    // Inventory - tersedia untuk semua role
                    if (authService.hasPermission('inventory_view'))
                      _FeatureCard(
                        icon: Icons.all_inbox_outlined,
                        title: 'Inventory',
                        description:
                            'Kelola data produk dan stok barang',
                        actionLabel: authService.hasPermission('inventory_full') 
                            ? 'Kelola Inventory' 
                            : 'Lihat Inventory',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryPage()),
                        ),
                      ),
                    
                    // Dashboard - hanya admin
                    if (authService.hasPermission('dashboard'))
                      _FeatureCard(
                        icon: Icons.bar_chart,
                        title: 'Dashboard',
                        description:
                            'Lihat dashboard dan analisis bisnis',
                        actionLabel: 'Lihat Dashboard',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DashboardPage()),
                        ),
                      ),
                    
                    // History - hanya admin
                    if (authService.hasPermission('history'))
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
                  ];

                  // Center cards if less than 4 features
                  if (features.length < 4 && !narrow) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: features.length * 300.0 + (features.length - 1) * 20,
                        ),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          crossAxisCount: features.length,
                          childAspectRatio: 1.0,
                          children: features,
                        ),
                      ),
                    );
                  }
                  
                  // Default grid for 4+ features or narrow screens
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    crossAxisCount: narrow ? 1 : 4,
                    children: features,
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
