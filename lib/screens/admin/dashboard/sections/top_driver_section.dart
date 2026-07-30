import 'package:flutter/material.dart';
import '../../models/top_driver_model.dart';
import '../../widgets/top_driver_card.dart';

class TopDriverSection extends StatelessWidget {
  final List<TopDriverModel> drivers;

  const TopDriverSection({super.key, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drivers.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Belum ada data driver teraktif.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          // Menggunakan komponen presentasi global yang sudah Anda definisikan
          TopDriverCard(drivers: drivers),
      ],
    );
  }
}
