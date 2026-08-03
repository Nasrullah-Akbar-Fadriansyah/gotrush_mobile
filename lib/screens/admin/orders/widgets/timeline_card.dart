import 'package:flutter/material.dart';

import '../../models/order_detail_model.dart';
import '../../utils/admin_formatter.dart';
import '../../widgets/info_card.dart';

/// Fungsi: Kartu Tampilan Jejak Waktu Perjalanan Pesanan (Timeline Order Card Widget).
/// Cara Kerja:
/// 1. Menyusun alur peristiwa siklus hidup pesanan secara vertikal (Order Dibuat -> Driver Menerima -> Order Selesai).
/// 2. Memeriksa keberadaan Timestamp `acceptedAt` dan `completedAt`. Jika nilai bernilai `null`, tahapan ditampilkan dengan status non-aktif (Warna Abu-abu & Teks "Belum diterima / Belum selesai").
/// 3. Menggunakan `IntrinsicHeight` untuk menggambar garis penghubung antar-titik event timeline secara presisi.
///
/// Operasi Data & Presentasi:
/// - Membaca dan memformat nilai `order.createdAt`, `order.acceptedAt`, dan `order.completedAt`.
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

  /// Helper Builder: Membangun satu item nodus rantai timeline lengkap dengan garis vertikal konektor.
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
