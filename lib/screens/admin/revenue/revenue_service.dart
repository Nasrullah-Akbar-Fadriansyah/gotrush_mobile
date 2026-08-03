import 'package:cloud_firestore/cloud_firestore.dart';

/// Fungsi: Layanan Agregasi Data Pemasukan Keuangan (Revenue Service).
/// Cara Kerja:
/// 1. Mengambil seluruh dokumen pesanan dari koleksi `orders` yang berstatus `completed` dalam rentang waktu yang ditentukan.
/// 2. Menghitung total nilai pendapatan (`totalRevenue`) dan total transaksi (`transactionCount`).
/// 3. Mengelompokkan pendapatan berdasarkan metode/status pembayaran (`paymentMethodBreakdown`).
/// 4. Menghitung nilai rata-rata transaksi per order (`averagePerOrder`).
///
/// Operasi CRUD (Read Query & Agregasi):
/// - Membaca pesanan selesai dalam periode tertentu.
/// - Sintaks:
///   ```dart
///   _firestore
///       .collection('orders')
///       .where('status', isEqualTo: 'completed')
///       .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
///       .where('created_at', isLessThanOrEqualTo: endTimestamp)
///       .get();
///   ```
class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fungsi: Mengambil dan mengagregasi data laporan pendapatan berdasarkan rentang waktu tertentu.
  /// Operasi CRUD (Read Operations):
  /// - Sintaks: `_firestore.collection('orders').where('status', isEqualTo: 'completed').where('created_at', isGreaterThanOrEqualTo: startTimestamp).where('created_at', isLessThanOrEqualTo: endTimestamp).get()`
  Future<Map<String, dynamic>> getRevenueReport(
    DateTime start,
    DateTime end,
  ) async {
    final startTimestamp = Timestamp.fromDate(
      DateTime(start.year, start.month, start.day, 0, 0, 0),
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(end.year, end.month, end.day, 23, 59, 59),
    );

    final snap = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
        .where('created_at', isLessThanOrEqualTo: endTimestamp)
        .get();

    double totalRevenue = 0;
    int transactionCount = 0;
    Map<String, double> paymentMethodBreakdown = {};

    for (var doc in snap.docs) {
      final data = doc.data();
      final p = data['price_paid'] ?? data['price'] ?? 0;
      final double price = (p is num)
          ? p.toDouble()
          : double.tryParse(p.toString()) ?? 0;

      totalRevenue += price;
      transactionCount++;

      // Breakdown berdasarkan tipe pembayaran (misal: Tunai, E-Wallet, dll.)
      final String method = data['payment_status'] ?? 'Belum Diketahui';
      paymentMethodBreakdown.update(
        method,
        (val) => val + price,
        ifAbsent: () => price,
      );
    }

    return {
      'totalRevenue': totalRevenue,
      'transactionCount': transactionCount,
      'averagePerOrder': transactionCount > 0
          ? totalRevenue / transactionCount
          : 0.0,
      'breakdown': paymentMethodBreakdown,
    };
  }
}
