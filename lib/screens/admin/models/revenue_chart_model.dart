/// Fungsi: Model Data Koordinat Grafik Pendapatan Finansial Bulanan.
/// Cara Kerja:
/// 1. Memetakan nilai finansial pendapatan (`revenue`) terhadap angka urutan bulan (`month`).
/// 2. Digunakan oleh pustaka `fl_chart` pada widget `DashboardChartSection` untuk merepresentasikan Grafik Garis Tren (`LineChart`).
///
/// Operasi Data (Kalkulasi Pendapatan Firestore):
/// - Dihasilkan oleh `DashboardService.getRevenueChart()` yang menjumlahkan nilai `price_paid` atau `price` dari dokumen order berstatus selesai per bulan.
/// - Contoh Sintaks Pemetaan:
///   ```dart
///   RevenueChartModel(month: i, revenue: monthlyRevenue[i] ?? 0);
///   ```
class RevenueChartModel {
  /// Angka representasi bulan ($1..12$).
  final int month;

  /// Akumulasi total nominal pendapatan yang diperoleh pada bulan tersebut (dalam Rp).
  final double revenue;

  RevenueChartModel({required this.month, required this.revenue});
}
