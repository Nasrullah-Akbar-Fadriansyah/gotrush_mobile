import 'package:flutter/material.dart';
import '../../models/admin_latest_order.dart';
import '../../widgets/latest_orders.dart';
import '../../orders/admin_orders_page.dart';

class LatestOrderSection extends StatelessWidget {
  final List<AdminLatestOrder> orders;

  const LatestOrderSection({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Aktivitas Transaksi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
                );
              },
              icon: const Icon(
                Icons.open_in_new,
                size: 16,
                color: Colors.green,
              ),
              label: Text(
                "Lihat Semua",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_late_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Belum ada order masuk hari ini.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Menggunakan widget global presentasi yang sudah Anda buat sebelumnya
          LatestOrders(orders: orders),
      ],
    );
  }
}
