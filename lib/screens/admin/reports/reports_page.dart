import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_formatter.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;

  // Variabel penampung hasil kalkulasi laporan
  int _totalOrders = 0;
  int _completedOrders = 0;
  int _cancelledOrders = 0;
  double _totalRevenue = 0;
  double _totalWeight = 0;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mengatur awal hari untuk startDate (00:00:00) dan akhir hari untuk endDate (23:59:59)
      final startTimestamp = Timestamp.fromDate(
        DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
      );
      final endTimestamp = Timestamp.fromDate(
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      );

      final snapshot = await _firestore
          .collection('order_history')
          .where('created_at', isGreaterThanOrEqualTo: startTimestamp)
          .where('created_at', isLessThanOrEqualTo: endTimestamp)
          .get();

      int total = 0;
      int completed = 0;
      int cancelled = 0;
      double revenue = 0;
      double weight = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        total++;

        final status = data['status'] ?? '';
        if (status == 'completed') {
          completed++;
          // Hanya hitung pendapatan & berat dari order yang sukses
          final p = data['price_paid'] ?? data['price'] ?? 0;
          revenue += (p is num)
              ? p.toDouble()
              : double.tryParse(p.toString()) ?? 0;

          final w = data['weight'] ?? 0;
          weight += (w is num)
              ? w.toDouble()
              : double.tryParse(w.toString()) ?? 0;
        } else if (status == 'cancelled') {
          cancelled++;
        }
      }

      setState(() {
        _totalOrders = total;
        _completedOrders = completed;
        _cancelledOrders = cancelled;
        _totalRevenue = revenue;
        _totalWeight = weight;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat laporan: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Analitik',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Kard Rentang Tanggal
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rentang Tanggal Laporan',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AdminFormatter.date(_startDate)} - ${AdminFormatter.date(_endDate)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: const Text('Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bagian Konten Utama Laporan
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ringkasan Performa",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grid Ringkasan Finansial & Operasional
                      _buildReportItem(
                        title: "Total Pendapatan Bersih",
                        value: AdminFormatter.rupiah(_totalRevenue),
                        icon: Icons.monetization_on,
                        color: Colors.green,
                      ),
                      _buildReportItem(
                        title: "Total Volume Sampah Terangkut",
                        value: AdminFormatter.weight(_totalWeight),
                        icon: Icons.scale,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        "Statistik Status Order",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rincian Operasional Masuk
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.list_alt,
                                  color: Colors.grey,
                                ),
                                title: const Text("Total Order Masuk"),
                                trailing: Text(
                                  "$_totalOrders",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                title: const Text("Order Berhasil (Completed)"),
                                trailing: Text(
                                  "$_completedOrders",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  "Order Dibatalkan (Cancelled)",
                                ),
                                trailing: Text(
                                  "$_cancelledOrders",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Tombol Export Simulasi
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _totalOrders == 0
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fitur integrasi Cetak PDF / CSV berhasil dieksekusi.',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.download),
                          label: const Text('Export Ringkasan Laporan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
