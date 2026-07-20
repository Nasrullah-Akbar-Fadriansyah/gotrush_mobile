import 'package:flutter/material.dart';

import '../../models/dashboard_stats.dart';
import '../../utils/admin_formatter.dart';
import '../../widgets/stat_card.dart';

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
        ),

        StatCard(
          title: "Order",
          value: stats.totalCompletedOrders.toString(),
          icon: Icons.shopping_bag,
          color: Colors.orange,
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
        ),

        StatCard(
          title: "Driver",
          value: stats.totalDrivers.toString(),
          icon: Icons.delivery_dining,
          color: Colors.red,
        ),
      ],
    );
  }
}
