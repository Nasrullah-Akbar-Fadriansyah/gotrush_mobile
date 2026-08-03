import 'package:flutter/material.dart';
import '../utils/admin_formatter.dart';
import 'revenue_service.dart';

/// Fungsi: Halaman Tampilan Analisis Keuangan & Pemasukan Admin (Admin Revenue Page).
/// Cara Kerja:
/// 1. Memanggil `RevenueService().getRevenueReport(_startDate, _endDate)` untuk mengambil rincian statistik pemasukan.
/// 2. Menampilkan total pendapatan kotor, jumlah transaksi, rata-rata pendapatan per order, serta *breakdown* berdasarkan status/metode pembayaran.
/// 3. Menyediakan kustomisasi rentang tanggal analisis via `showDateRangePicker` serta tombol pembaruan data manual.
///
/// Operasi Data (Read Financial Summary):
/// - Memicu metode pembacaan data keuangan dari `RevenueService`.
class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({super.key});

  @override
  State<AdminRevenuePage> createState() => _AdminRevenuePageState();
}

class _AdminRevenuePageState extends State<AdminRevenuePage> {
  final RevenueService _service = RevenueService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  double _totalRevenue = 0;
  int _orderCount = 0;
  double _averageRevenue = 0;
  Map<String, double> _breakdown = {};

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  /// Fungsi: Memuat ulang laporan data pemasukan dari layanan `RevenueService`.
  Future<void> _fetchRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getRevenueReport(_startDate, _endDate);
      setState(() {
        _totalRevenue = result['totalRevenue'];
        _orderCount = result['transactionCount'];
        _averageRevenue = result['averagePerOrder'];
        _breakdown = Map<String, double>.from(result['breakdown']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data keuangan: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Fungsi: Menampilkan dialog kalender untuk memilih rentang periode analisis pemasukan.
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.green.shade600),
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
      _fetchRevenueData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analisis Pemasukan',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRevenueData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Rerata Tanggal
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range, color: Colors.green),
                    label: Text(
                      'Periode: ${AdminFormatter.date(_startDate)} - ${AdminFormatter.date(_endDate)}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Utama: Total Revenue Card
                  Card(
                    color: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL PENDAPATAN KOTOR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AdminFormatter.rupiah(_totalRevenue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Informasi Sekunder
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStatCard(
                          'Total Transaksi',
                          '$_orderCount Order',
                          Icons.shopping_bag_outlined,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStatCard(
                          'Rata-rata / Order',
                          AdminFormatter.rupiah(_averageRevenue),
                          Icons.analytics_outlined,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Rincian Metode Status Pembayaran
                  const Text(
                    'Metode / Status Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: _breakdown.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text('Tidak ada rincian data transaksi.'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _breakdown.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              String key = _breakdown.keys.elementAt(index);
                              double val = _breakdown.values.elementAt(index);
                              return ListTile(
                                leading: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.green,
                                ),
                                title: Text(key),
                                trailing: Text(
                                  AdminFormatter.rupiah(val),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Helper Builder: Membangun kartu statistik berukuran kecil untuk metrik tambahan.
  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
