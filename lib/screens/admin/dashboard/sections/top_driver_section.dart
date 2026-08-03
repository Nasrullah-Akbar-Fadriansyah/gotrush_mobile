import 'package:flutter/material.dart';
import '../../models/top_driver_model.dart';
import '../../widgets/top_driver_card.dart';

/// Fungsi: Bagian Komponen Daftar Driver Teraktif pada Dashboard Admin.
/// Cara Kerja:
/// 1. Menerima data jajaran driver paling aktif (`drivers`) berdasarkan frekuensi penyelesaian pesanan.
/// 2. Memeriksa ketersediaan data driver teratas: Menampilkan pesan fallback jika data belum tersedia, atau merender komponen `TopDriverCard`.
///
/// Operasi Data & Presentasi:
/// - Menerima masukan berupa `List<TopDriverModel>` yang telah diurutkan berdasarkan performa penjemputan terbanyak.
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
          TopDriverCard(drivers: drivers),
      ],
    );
  }
}
