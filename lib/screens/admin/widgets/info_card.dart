import 'package:flutter/material.dart';

/// Fungsi: Widget Wadah Kartu Informasi Generik (Reusable Information Container Card).
/// Cara Kerja:
/// 1. Menerima judul header (`title`), ikon identitas (`icon`), serta konten widget anak (`child`).
/// 2. Membungkus konten anak ke dalam struktur `Card` bersudut tumpul yang konsisten di seluruh panel admin.
/// 3. Menyediakan header terstandarisasi yang dipisahkan oleh garis pembatas vertikal/horisontal (`Divider`).
///
/// Operasi Data & Presentasi:
/// - Menyediakan abstraksi UI terpusat untuk widget rincian seperti `UserInfoCard`, `DriverInfoCard`, `OrderInfoCard`, dan `TimelineCard`.
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),

                const SizedBox(width: 8),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            child,
          ],
        ),
      ),
    );
  }
}
