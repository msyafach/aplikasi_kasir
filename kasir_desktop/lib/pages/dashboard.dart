import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _fmtMoney = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, Object?>>> _lowStockFuture;
  late Future<List<Map<String, Object?>>> _topProductsFuture;
  late Future<List<Map<String, Object?>>> _dailySalesFuture;
  late Future<Map<String, dynamic>> _todayStatsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = DatabaseService.instance.getDashboardStats();
      _lowStockFuture = DatabaseService.instance.getLowStockProducts();
      _topProductsFuture = DatabaseService.instance.getTopSellingProducts();
      _dailySalesFuture = DatabaseService.instance.getDailySales();
      _todayStatsFuture = DatabaseService.instance.getTodayDetailedStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard Penjualan',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau performa bisnis dan status inventory Anda',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final stats = snapshot.data ?? {};
                  return _buildStatsSection(stats);
                },
              ),
              
              const SizedBox(height: 24),

              // Today's Scorecard
              FutureBuilder<Map<String, dynamic>>(
                future: _todayStatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final todayStats = snapshot.data ?? {};
                  return TodayScorecard(todayStats: todayStats);
                },
              ),
              
              const SizedBox(height: 32),

              // Charts and Lists Section
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLeftColumn()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildRightColumn()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildLeftColumn(),
                        const SizedBox(height: 24),
                        _buildRightColumn(),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final columns = isWide ? 3 : 2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isWide ? 2.5 : 2.0,
          children: [
            DashboardCard(
              title: 'Penjualan Hari Ini',
              value: _fmtMoney.format(stats['todayRevenue'] ?? 0),
              subtitle: '${stats['todayTransactions'] ?? 0} transaksi',
              icon: Icons.today,
              color: Colors.green,
            ),
            DashboardCard(
              title: 'Penjualan Bulan Ini',
              value: _fmtMoney.format(stats['monthRevenue'] ?? 0),
              subtitle: '${stats['monthTransactions'] ?? 0} transaksi',
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
            DashboardCard(
              title: 'Total Produk',
              value: '${stats['totalProducts'] ?? 0}',
              subtitle: 'item dalam inventory',
              icon: Icons.inventory,
              color: Colors.orange,
            ),
            if (isWide) ...[
              DashboardCard(
                title: 'Nilai Inventory',
                value: _fmtMoney.format(stats['inventoryValue'] ?? 0),
                subtitle: 'total aset produk',
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Sales Chart
        FutureBuilder<List<Map<String, Object?>>>(
          future: _dailySalesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final dailySales = snapshot.data ?? [];
            return DailySalesChart(dailySales: dailySales);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Top Selling Products
        FutureBuilder<List<Map<String, Object?>>>(
          future: _topProductsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final topProducts = snapshot.data ?? [];
            return TopProductsList(products: topProducts);
          },
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        // Low Stock Alert
        FutureBuilder<List<Map<String, Object?>>>(
          future: _lowStockFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final lowStockProducts = snapshot.data ?? [];
            return LowStockAlert(products: lowStockProducts);
          },
        ),
      ],
    );
  }
}