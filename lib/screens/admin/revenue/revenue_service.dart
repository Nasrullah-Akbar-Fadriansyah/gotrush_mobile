import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mengambil data pendapatan berdasarkan rentang waktu tertentu
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
        .collection('order_history')
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
