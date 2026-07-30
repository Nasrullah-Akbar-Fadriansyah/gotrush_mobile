import 'package:flutter/material.dart';

import '../../models/order_detail_model.dart';
import '../../utils/admin_formatter.dart';
import '../../widgets/info_card.dart';

class TimelineCard extends StatelessWidget {
  final OrderDetailModel order;

  const TimelineCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: "Timeline Order",
      icon: Icons.timeline,
      child: Column(
        children: [
          _timelineItem(
            icon: Icons.add_circle,
            color: Colors.green,
            title: "Order Dibuat",
            time: AdminFormatter.dateTime(order.createdAt.toDate()),
            isLast: false,
          ),

          _timelineItem(
            icon: Icons.local_shipping,
            color: order.acceptedAt != null ? Colors.blue : Colors.grey,
            title: "Driver Menerima",
            time: order.acceptedAt != null
                ? AdminFormatter.dateTime(order.acceptedAt!.toDate())
                : "Belum diterima",
            isLast: false,
          ),

          _timelineItem(
            icon: Icons.check_circle,
            color: order.completedAt != null ? Colors.green : Colors.grey,
            title: "Order Selesai",
            time: order.completedAt != null
                ? AdminFormatter.dateTime(order.completedAt!.toDate())
                : "Belum selesai",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 18),
              ),

              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
