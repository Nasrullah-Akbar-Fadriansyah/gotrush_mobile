import '../models/dashboard_stats.dart';
import '../models/revenue_chart_model.dart';
import '../models/order_chart_model.dart';
import '../models/admin_latest_order.dart';
import '../models/top_driver_model.dart';
import '../models/top_user_model.dart';

/// Fungsi: Kelas Data Transfer Object (DTO) untuk Penampung Komprehensif Data Dashboard Admin.
/// Cara Kerja:
/// 1. Menggabungkan hasil pemrosesan statistik umum, grafik pendapatan, grafik order bulanan, riwayat order terbaru, serta pemeringkatan pengguna/driver ke dalam satu struktur objek immutabel.
/// 2. Memudahkan distribusi data hasil agregasi layanan `DashboardService` menuju komponen UI dashboard secara terpusat.
///
/// Operasi Data:
/// - Bertindak sebagai wadah tunggal (*wrapper object*) data read-only yang disuapkan ke `StreamBuilder` pada `AdminDashboard`.
class DashboardData {
  /// Statistik umum ringkasan sistem (pendapatan, total order, total pengguna, total driver, dan total berat sampah).
  final DashboardStats stats;

  /// Daftar poin data pendapatan bulanan untuk grafik garis.
  final List<RevenueChartModel> revenueChart;

  /// Daftar poin data frekuensi transaksi order bulanan untuk grafik batang.
  final List<OrderChartModel> orderChart;

  /// Daftar 10 transaksi pesanan paling baru untuk tabel/list aktivitas terkini.
  final List<AdminLatestOrder> latestOrders;

  /// Daftar peringkat 5 mitra driver teraktif.
  final List<TopDriverModel> topDrivers;

  /// Daftar peringkat pengguna/pelanggan teraktif.
  final List<TopUserModel> topUsers;

  const DashboardData({
    required this.stats,
    required this.revenueChart,
    required this.orderChart,
    required this.latestOrders,
    required this.topDrivers,
    required this.topUsers,
  });
}
