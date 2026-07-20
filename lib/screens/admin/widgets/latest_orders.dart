import 'package:flutter/material.dart';
import '../models/admin_latest_order.dart';
import '../utils/admin_formatter.dart';
import '../orders/order_detail_page.dart';

class LatestOrders extends StatelessWidget {
  final List<AdminLatestOrder> orders;

  const LatestOrders({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Order Terbaru",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: orders.length,

              separatorBuilder: (_, __) => const Divider(),

              itemBuilder: (_, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),

                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.green,
                      ),
                    ),

                    title: Text(
                      order.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),

                        Text("Driver : ${order.driverName}"),

                        Text("Berat : ${order.weight} Kg"),

                        Text(AdminFormatter.rupiah(order.price)),
                      ],
                    ),

                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statusChip(order.status),

                        const SizedBox(height: 6),

                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderId: order.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _statusChip(String status) {
  Color color;

  String label;

  switch (status) {
    case "completed":
      label = "Selesai";
      color = Colors.green;
      break;

    case "active":
      label = "Aktif";
      color = Colors.blue;
      break;

    case "pending":
      label = "Pending";
      color = Colors.orange;
      break;

    case "cancelled":
      label = "Batal";
      color = Colors.red;
      break;

    default:
      label = status;
      color = Colors.grey;
  }

  return Chip(
    label: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
    backgroundColor: color,
    visualDensity: VisualDensity.compact,
  );
}
