import 'package:flutter/material.dart';

import '../../models/order_detail_model.dart';
import '../../widgets/info_card.dart';

class UserInfoCard extends StatelessWidget {
  final OrderDetailModel order;

  const UserInfoCard({super.key, required this.order});

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          SizedBox(
            width: 110,
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
      title: "Informasi Pengguna",

      icon: Icons.person,

      child: Column(
        children: [
          _item("Nama", order.userName),

          _item("Email", order.userEmail),

          _item("Telepon", order.phoneNumber),
        ],
      ),
    );
  }
}
