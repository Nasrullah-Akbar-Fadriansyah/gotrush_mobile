import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fungsi: Widget Header Atas Dashboard Admin GoTrash.
/// Cara Kerja:
/// 1. Mengambil waktu sistem saat ini (`DateTime.now()`).
/// 2. Memformat tanggal menggunakan `DateFormat` sesuai standar lokalisasi Bahasa Indonesia (`id_ID`) dengan format nama hari lengkap.
/// 3. Merender kartu ucapan selamat/judul utama "Dashboard Admin" bersudut tumpul (*rounded banner*) dengan latar hijau khas aplikasi.
///
/// Operasi Data & Presentasi:
/// - Menggunakan `DateFormat("EEEE, dd MMMM yyyy", "id_ID")` untuk mengonversi waktu sistem menjadi teks terformat (contoh: `Senin, 03 Agustus 2026`).
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat(
      "EEEE, dd MMMM yyyy",
      "id_ID",
    ).format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard Admin",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(today, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
