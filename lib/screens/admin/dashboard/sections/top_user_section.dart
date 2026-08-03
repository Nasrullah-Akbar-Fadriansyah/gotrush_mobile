import 'package:flutter/material.dart';
import '../../models/top_user_model.dart';

/// Fungsi: Bagian Komponen Peringkat Pelanggan/User Teraktif (Leaderboard).
/// Cara Kerja:
/// 1. Menerima daftar pengguna paling aktif (`users`) berdasarkan jumlah transaksi order dan total berat sampah yang disetorkan.
/// 2. Menampilkan susunan daftar bernomor (`ListView.separated`) lengkap dengan Avatar peringkat ($1..N$).
/// 3. Menampilkan rincian statistik tiap pelanggan berupa jumlah total order serta total berat (Kg) sampah yang berhasil didaur ulang.
///
/// Operasi Data & Presentasi:
/// - Menerima masukan berupa `List<TopUserModel>` yang terikat pada data pengguna aktif di database.
class TopUserSection extends StatelessWidget {
  final List<TopUserModel> users;

  const TopUserSection({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🏆 Pengguna Teraktif",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Text(
                        "Belum ada pelanggan teraktif.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: Colors.purple.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.phone),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${user.totalOrders} Order",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${user.totalWeight.toStringAsFixed(1)} Kg",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
