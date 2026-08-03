import 'package:flutter/material.dart';

/// Fungsi: Widget Kartu Ringkasan Metrik Statistik Utama (Dashboard Metric Stat Card).
/// Cara Kerja:
/// 1. Menerima data ikon (`icon`), judul metrik (`title`), nilai angka/teks (`value`), warna tema (`color`), serta penanganan gesture ketukan (`onTap`).
/// 2. Menggunakan `FittedBox` agar ukuran teks nilai otomatis menyesuaikan skala agar tidak menyebabkan luapan (*overflow*) pada layar berukuran kecil.
/// 3. Mendukung responsivitas klik via `InkWell` dengan batas sudut ikuti bentuk `Card`.
///
/// Operasi Data & Presentasi:
/// - Digunakan oleh `DashboardStatSection` untuk merender kartu statistik seperti Total Pemasukan, Total Order, Berat Sampah, Jumlah User, dan Jumlah Driver.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14), // Mengikuti sudut Card
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
