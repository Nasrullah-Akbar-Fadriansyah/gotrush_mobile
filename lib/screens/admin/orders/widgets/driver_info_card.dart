import 'package:flutter/material.dart';
import '../../models/order_detail_model.dart';
import '../../widgets/info_card.dart';

/// Fungsi: Kartu Tampilan Informasi Mitra Driver (Driver Info Card Widget).
/// Cara Kerja:
/// 1. Menerima objek `OrderDetailModel` yang berisi metadata driver penanggung jawab pesanan.
/// 2. Menampilkan rincian identitas driver (Nama dan Nomor Telepon).
/// 3. Mengubah warna indikator badge status keaktifan driver secara dinamis berdasarkan nilai status (`online`, `offline`, dll).
///
/// Operasi Data & Presentasi:
/// - Mengakses properti `order.driverName`, `order.driverPhone`, dan `order.driverStatus`.
/// - Menyesuaikan warna badge menggunakan fungsi pembantu `_statusColor`.
class DriverInfoCard extends StatelessWidget {
  final OrderDetailModel order;

  const DriverInfoCard({super.key, required this.order});

  /// Helper Builder: Membangun baris teks terstruktur dengan label judul dan nilai data.
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

  /// Fungsi Helper: Menentukan warna badge visual berdasarkan status kerja mitra driver.
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "online":
        return Colors.green;
      case "offline":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: "Informasi Driver",
      icon: Icons.local_shipping,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item("Nama", order.driverName),
          _item("Telepon", order.driverPhone),
          Row(
            children: [
              const SizedBox(
                width: 110,
                child: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.driverStatus),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.driverStatus,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
