import 'package:flutter/material.dart';

import '../../models/order_detail_model.dart';
import '../../utils/admin_formatter.dart';
import '../../widgets/info_card.dart';

class OrderInfoCard extends StatelessWidget {
  final OrderDetailModel order;

  const OrderInfoCard({super.key, required this.order});

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: "Detail Order",
      icon: Icons.inventory_2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item("Berat", AdminFormatter.weight(order.weight)),

          _item("Jarak", AdminFormatter.distance(order.distance)),

          _item("Harga", AdminFormatter.rupiah(order.price)),

          _item("Pembayaran", order.paymentStatus),

          _item("Tanggal", AdminFormatter.dateTime(order.createdAt.toDate())),

          const SizedBox(height: 10),

          const Text("Alamat", style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 6),

          Text(order.address),
        ],
      ),
    );
  }
}
