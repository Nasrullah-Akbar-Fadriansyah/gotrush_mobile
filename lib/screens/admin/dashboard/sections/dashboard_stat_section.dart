import 'package:flutter/material.dart';
import '../../models/dashboard_stats.dart';
import '../../utils/admin_formatter.dart';
import '../../widgets/stat_card.dart';
import '../../users/admin_users_management_page.dart';
import '../../orders/admin_orders_page.dart';

class DashboardStatSection extends StatelessWidget {
  final DashboardStats stats;

  const DashboardStatSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          title: "Pendapatan",
          value: AdminFormatter.rupiah(stats.totalRevenue),
          icon: Icons.payments,
          color: Colors.green,
          onTap: () {
            // Aksi jika ingin melihat detail ringkasan pemasukan
          },
        ),

        StatCard(
          title: "Order",
          value: stats.totalCompletedOrders.toString(),
          icon: Icons.shopping_bag,
          color: Colors.orange,
          onTap: () {
            // Pindah ke halaman daftar orderan secara keseluruhan saat diklik
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
            );
          },
        ),

        StatCard(
          title: "Berat Sampah",
          value: "${stats.totalWeight.toStringAsFixed(1)} Kg",
          icon: Icons.delete,
          color: Colors.blue,
        ),

        StatCard(
          title: "User",
          value: stats.totalUsers.toString(),
          icon: Icons.people,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AdminUsersManagementPage(roleFilter: 'user'),
              ),
            );
          },
        ),

        StatCard(
          title: "Driver",
          value: stats.totalDrivers.toString(),
          icon: Icons.delivery_dining,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AdminUsersManagementPage(roleFilter: 'driver'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PlaceholderCRUDPage extends StatelessWidget {
  final String title;
  final String roleFilter;

  const PlaceholderCRUDPage({
    super.key,
    required this.title,
    required this.roleFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              roleFilter == 'user'
                  ? Icons.supervised_user_circle
                  : Icons.local_shipping,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Halaman $title sedang disiapkan.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Ganti target Navigator.push di file dashboard_stat_section.dart dengan widget CRUD utama Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
