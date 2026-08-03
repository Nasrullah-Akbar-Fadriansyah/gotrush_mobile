import 'package:flutter/material.dart';

import '../../models/order_detail_model.dart';
import '../../widgets/info_card.dart';

/// Fungsi: Kartu Tampilan Informasi Pelanggan/Pemesan (User Info Card Widget).
/// Cara Kerja:
/// 1. Menerima objek `OrderDetailModel` yang memuat data pelanggan pemesan.
/// 2. Merender informasi identitas pemesan mencakup Nama Lengkap, Alamat Email, dan Nomor Telepon Kontak.
///
/// Operasi Data & Presentasi:
/// - Mengakses properti `order.userName`, `order.userEmail`, dan `order.phoneNumber`.
class UserInfoCard extends StatelessWidget {
  final OrderDetailModel order;

  const UserInfoCard({super.key, required this.order});

  /// Helper Builder: Membangun baris teks terstruktur untuk atribut informasi pengguna.
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
