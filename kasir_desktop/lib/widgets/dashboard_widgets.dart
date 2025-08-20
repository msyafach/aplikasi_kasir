import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trend;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trend!.startsWith('+') ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trend!.startsWith('+') ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LowStockAlert extends StatelessWidget {
  final List<Map<String, Object?>> products;

  const LowStockAlert({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Stock Menipis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (products.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Semua produk memiliki stock yang cukup',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final name = product['name'] as String;
                    final stock = product['stock'] as int;
                    final price = product['price'] as num;
                    final category = product['category'] as String?;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: stock == 0 ? Colors.red : Colors.orange,
                        foregroundColor: Colors.white,
                        child: Text('$stock'),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(category ?? 'Tanpa Kategori'),
                      trailing: Text(
                        fmtMoney.format(price),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TopProductsList extends StatelessWidget {
  final List<Map<String, Object?>> products;

  const TopProductsList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Produk Terlaris Bulan Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (products.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada data penjualan bulan ini',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final name = product['name'] as String;
                    final totalSold = product['total_sold'] as int;
                    final revenue = product['revenue'] as num;
                    final category = product['category'] as String?;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${category ?? 'Tanpa Kategori'} • $totalSold terjual'),
                      trailing: Text(
                        fmtMoney.format(revenue),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DailySalesChart extends StatelessWidget {
  final List<Map<String, Object?>> dailySales;

  const DailySalesChart({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final fmtDate = DateFormat('dd MMM', 'id_ID');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Penjualan 7 Hari Terakhir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (dailySales.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Belum ada data penjualan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 200,
                child: _buildSimpleBarChart(dailySales, fmtMoney, fmtDate),
              ),
              const SizedBox(height: 16),
              // Summary
              _buildSalesSummary(dailySales, fmtMoney),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(List<Map<String, Object?>> data, NumberFormat fmtMoney, DateFormat fmtDate) {
    if (data.isEmpty) return const SizedBox();
    
    final maxRevenue = data.map((e) => (e['revenue'] as num)).reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((sale) {
        final revenue = (sale['revenue'] as num).toDouble();
        final date = DateTime.parse(sale['date'] as String);
        final height = maxRevenue > 0 ? (revenue / maxRevenue * 150) : 0.0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: '${fmtDate.format(date)}\n${fmtMoney.format(revenue)}',
                  child: Container(
                    height: height.clamp(5.0, 150.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fmtDate.format(date),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSalesSummary(List<Map<String, Object?>> data, NumberFormat fmtMoney) {
    final totalRevenue = data.fold<num>(0, (sum, sale) => sum + (sale['revenue'] as num));
    final totalTransactions = data.fold<int>(0, (sum, sale) => sum + (sale['transaction_count'] as int));
    final avgPerDay = data.isNotEmpty ? totalRevenue / data.length : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fmtMoney.format(totalRevenue),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Transaksi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalTransactions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rata-rata/Hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fmtMoney.format(avgPerDay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TodayScorecard extends StatelessWidget {
  final Map<String, dynamic> todayStats;

  const TodayScorecard({super.key, required this.todayStats});

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final revenue = todayStats['revenue'] ?? 0;
    final transactions = todayStats['transactions'] ?? 0;
    final avgPerTransaction = transactions > 0 ? revenue / transactions : 0;
    final itemsSold = todayStats['itemsSold'] ?? 0;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Scorecard Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'Penjualan',
                    fmtMoney.format(revenue),
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildScoreItem(
                    'Transaksi',
                    '$transactions',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'Rata-rata/Transaksi',
                    fmtMoney.format(avgPerTransaction),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildScoreItem(
                    'Item Terjual',
                    '$itemsSold',
                    Icons.shopping_cart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}