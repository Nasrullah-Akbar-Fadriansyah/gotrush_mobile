/// Fungsi: Model Data Peringkat Pengguna/Pelanggan Teraktif (Leaderboard User).
/// Cara Kerja:
/// 1. Menampung data kontribusi pengguna berdasarkan kuantitas transaksi pembuatan order dan berat sampah yang disetorkan.
/// 2. Disuapkan ke widget `TopUserSection` untuk merender susunan daftar peringkat pelanggan teraktif.
///
/// Operasi Data (Agregasi Data Per Pelanggan):
/// - Diproses oleh `DashboardService.getTopUsers()` melalui penghitungan agregat aktivitas transaksi berbasis `user_id`.
/// - Contoh Sintaks Pembentukan Model:
///   ```dart
///   TopUserModel(
///     uid: userId,
///     name: userData["name"] ?? "-",
///     phone: userData["phone"] ?? "-",
///     totalOrders: count,
///     totalWeight: weight,
///     totalRevenue: revenue,
///   );
///   ```
class TopUserModel {
  /// ID Unik Akun Pengguna (User UID).
  final String uid;

  /// Nama lengkap pelanggan.
  final String name;

  /// Nomor telepon pelanggan.
  final String phone;

  /// Total pesanan penjemputan yang pernah dibuat oleh pelanggan.
  final int totalOrders;

  /// Total berat sampah yang pernah disetorkan oleh pelanggan (dalam Kg).
  final double totalWeight;

  /// Total nominal pengeluaran/pembayaran yang dilakukan pelanggan (dalam Rp).
  final double totalRevenue;

  const TopUserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalWeight,
    required this.totalRevenue,
  });
}
