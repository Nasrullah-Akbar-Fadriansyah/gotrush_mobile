import 'package:flutter/material.dart';

/// Fungsi: Widget Kartu Placeholder Status Memuat Data (Loading State Card Widget).
/// Cara Kerja:
/// 1. Merender wadah `Card` bersudut tumpul dengan tinggi tetap ($120$ piksel) sebagai *skeleton/placeholder* sementara saat proses pengambilan data Firestore berlangsung.
///
/// Operasi Data & Presentasi:
/// - Digunakan sebagai komponen pembantu tata letak (*layout placeholder*) selama status pemuatan data.
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(child: Container(height: 120));
  }
}
