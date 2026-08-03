/// Fungsi: Model Data Peringkat Mitra Driver Teraktif (Leaderboard Driver).
/// Cara Kerja:
/// 1. Menampung profil performa driver mencakup total transaksi order yang diselesaikan, akumulasi berat sampah, serta nilai perputaran pendapatan.
/// 2. Disuapkan ke widget `TopDriverCard` dan `TopDriverSection` untuk menampilkan 5 jajaran driver terbaik di dashboard admin.
///
/// Operasi Data (Agregasi Data Per Driver):
/// - Diproses oleh `DashboardService.getTopDrivers()` dengan menghitung frekuensi `driver_id` terbanyak pada dokumen `orders` dan mencocokkannya ke koleksi `users`.
/// - Contoh Sintaks Pembentukan Model:
///   ```dart
///   TopDriverModel(
///     uid: item.key,
///     name: user["name"] ?? "-",
///     phone: user["phone"] ?? "-",
///     totalOrders: item.value,
///     totalWeight: 0,
///     totalRevenue: 0,
///   );
///   ```
class TopDriverModel {
  /// ID Unik Akun Driver (User UID).
  final String uid;

  /// Nama lengkap mitra driver.
  final String name;

  /// Nomor telepon driver.
  final String phone;

  /// Total jumlah pesanan yang berhasil ditangani/diselesaikan oleh driver.
  final int totalOrders;

  /// Total berat sampah yang telah diangkut oleh driver (dalam Kg).
  final double totalWeight;

  /// Total estimasi pendapatan yang dihasilkan driver (dalam Rp).
  final double totalRevenue;

  const TopDriverModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalWeight,
    required this.totalRevenue,
  });
}
