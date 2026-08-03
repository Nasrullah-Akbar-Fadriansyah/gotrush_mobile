/// Fungsi: Model Data Ringkasan Statistik Utama Dashboard Admin GoTrash.
/// Cara Kerja:
/// 1. Menampung total nilai akumulasi finansial, berat sampah, serta metrik pengguna dari seluruh sistem.
/// 2. Disuapkan langsung ke widget `DashboardStatSection` untuk dirender menjadi kartu-kartu statistik (`StatCard`).
///
/// Operasi Data (Agregasi Data Firestore):
/// - Dihasilkan melalui fungsi `DashboardService.getDashboardStats()` yang melakukan kalkulasi *iteration loop* dari snapshot koleksi `orders` dan `users`.
/// - Contoh Sintaks Agregasi:
///   ```dart
///   DashboardStats(
///     totalRevenue: totalRevenue,
///     totalCompletedOrders: totalOrdersCount,
///     totalWeight: totalWeight,
///     totalUsers: totalUsers,
///     totalDrivers: totalDrivers,
///   );
///   ```
class DashboardStats {
  /// Akumulasi total pendapatan bersih dari seluruh order berstatus 'completed' (dalam Rp).
  final double totalRevenue;

  /// Jumlah keseluruhan pesanan transaksi yang tercatat di dalam sistem.
  final int totalCompletedOrders;

  /// Total akumulasi berat sampah yang berhasil diangkut/didaur ulang (dalam Kg).
  final double totalWeight;

  /// Total jumlah akun terdaftar ber-role 'user' (Pelanggan).
  final int totalUsers;

  /// Total jumlah akun terdaftar ber-role 'driver' (Mitra Driver).
  final int totalDrivers;

  const DashboardStats({
    required this.totalRevenue,
    required this.totalCompletedOrders,
    required this.totalWeight,
    required this.totalUsers,
    required this.totalDrivers,
  });
}
