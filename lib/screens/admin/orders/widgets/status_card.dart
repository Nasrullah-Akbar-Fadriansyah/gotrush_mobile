import 'package:flutter/material.dart';
import '../../models/order_detail_model.dart';

class StatusCard extends StatelessWidget {
  final OrderDetailModel order;

  const StatusCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (order.status) {
      case 'completed':
        color = Colors.green;
        break;

      case 'active':
        color = Colors.blue;
        break;

      case 'pending':
        color = Colors.orange;
        break;

      case 'cancelled':
        color = Colors.red;
        break;

      default:
        color = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Row(
          children: [
            Icon(Icons.assignment_turned_in, color: color, size: 40),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    order.orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Status : ${order.status}",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),

                  Text("Pembayaran : ${order.paymentStatus}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
