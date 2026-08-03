import 'package:flutter/material.dart';
import 'dashboard_data.dart';
import 'dashboard_service.dart';
import '../widgets/dashboard_header.dart';
import 'sections/dashboard_stat_section.dart';
import 'sections/dashboard_chart_section.dart';
import '../widgets/latest_orders.dart';

/// Fungsi: Halaman Utama Dashboard Admin GoTrash.
/// Cara Kerja:
/// 1. Menginisialisasi `DashboardService` untuk memantau perubahan koleksi pesanan (`orders`) secara real-time.
/// 2. Menggunakan `StreamBuilder` berbasis `DashboardData` untuk memperbarui UI secara otomatis jika terjadi perubahan data pada Firestore.
/// 3. Menyediakan dukungan gesture `RefreshIndicator` (Pull-to-Refresh) untuk memicu pembaruan aliran data secara manual.
/// 4. Merender susunan seksi komponen dashboard: Header, Kartu Statistik, Grafik Analitik (Pendapatan & Order), serta Aktivitas Pesanan Terbaru.
///
/// Operasi CRUD (Read Stream):
/// - Membuka aliran data real-time snapshot dari Firestore koleksi `orders` via `service.streamDashboard()`.
/// - Sintaks: `FirebaseFirestore.instance.collection('orders').snapshots()`
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService service = DashboardService();
  late Stream<DashboardData> dashboardStream;

  @override
  void initState() {
    super.initState();
    dashboardStream = service.streamDashboard();
  }

  /// Fungsi: Memperbarui alur aliran data (Stream) secara manual saat pengguna menarik layar ke bawah (Pull-to-Refresh).
  Future<void> _manualRefresh() async {
    setState(() {
      dashboardStream = service.streamDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _manualRefresh,
          child: StreamBuilder<DashboardData>(
            stream: dashboardStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("Gagal memuat dashboard: ${snapshot.error}"),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("Data tidak tersedia"));
              }

              final data = snapshot.data!;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const DashboardHeader(),
                    const SizedBox(height: 20),
                    DashboardStatSection(stats: data.stats),
                    const SizedBox(height: 20),
                    DashboardChartSection(
                      revenueData: data.revenueChart,
                      orderData: data.orderChart,
                    ),
                    const SizedBox(height: 20),
                    LatestOrders(orders: data.latestOrders),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
