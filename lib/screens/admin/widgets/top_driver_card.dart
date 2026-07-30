import 'package:flutter/material.dart';

import '../models/top_driver_model.dart';

class TopDriverCard extends StatelessWidget {
  final List<TopDriverModel> drivers;

  const TopDriverCard({super.key, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "🏆 Driver Paling Aktif",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 16),

            ...drivers.asMap().entries.map((entry) {
              final index = entry.key;

              final driver = entry.value;

              return ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),

                title: Text(driver.name),

                subtitle: Text(driver.phone),

                trailing: Text(
                  "${driver.totalOrders} Order",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
