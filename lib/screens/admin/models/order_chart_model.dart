/// Fungsi: Model Data Koordinat Grafik Transaksi Pesanan Bulanan.
/// Cara Kerja:
/// 1. Menandai pasangan data antara bulan ke-$N$ ($1..12$) dan jumlah transaksi order (`totalOrders`) pada bulan tersebut.
/// 2. Digunakan oleh pustaka `fl_chart` pada widget `DashboardChartSection` untuk menggambar Grafik Batang (`BarChart`).
///
/// Operasi Data (Pemetaan Waktu Firestore):
/// - Diproses oleh `DashboardService.getOrderChart()` dengan mengekstrak atribut `created_at.toDate().month` dari setiap dokumen `orders`.
/// - Contoh Sintaks Pemetaan:
///   ```dart
///   OrderChartModel(month: i, totalOrders: monthlyOrders[i] ?? 0);
///   ```
class OrderChartModel {
  /// Angka representasi bulan ($1$ untuk Januari hingga $12$ untuk Desember).
  final int month;

  /// Total volume pesanan transaksi yang tercipta pada bulan terkait.
  final int totalOrders;

  OrderChartModel({required this.month, required this.totalOrders});
}
