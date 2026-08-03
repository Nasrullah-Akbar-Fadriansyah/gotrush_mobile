import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';
import '../models/revenue_chart_model.dart';
import '../models/order_chart_model.dart';
import '../models/admin_latest_order.dart';
import 'dashboard_data.dart';
import '../models/top_driver_model.dart';
import '../models/top_user_model.dart';

/// Fungsi: Layanan Utama Pengolah & Agregasi Data Dashboard Admin (Dashboard Service).
/// Cara Kerja:
/// 1. Berhubungan langsung dengan database Cloud Firestore untuk mengambil koleksi `orders` dan `users`.
/// 2. Melakukan pengolahan asinkron untuk kalkulasi agregasi: total finansial, rekapitulator berat sampah, distribusi peran pengguna, dan pembuatan deret waktu bulanan (grafik).
/// 3. Mengombinasikan query paralel menggunakan `Future.wait` guna meningkatkan performa pemuatan data dashboard.
///
/// Operasi CRUD (Read Operations):
/// - Stream Realtime:
///   - Mendengarkan event perubahan pada seluruh dokumen di koleksi `orders`.
///     - Sintaks: `_firestore.collection('orders').snapshots()`
/// - Read Collections (Get Once):
///   - Mengambil seluruh data pesanan: `_firestore.collection('orders').get()`
///   - Mengambil seluruh data pengguna: `_firestore.collection('users').get()`
///   - Filter & Limit Pesanan Terbaru: `_firestore.collection('orders').orderBy('created_at', descending: true).limit(10).get()`
///   - Membaca dokumen spesifik pengguna: `_firestore.collection('users').doc(uid).get()`
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fungsi: Membuka aliran data (Stream) realtime yang terhubung ke koleksi `orders` di Firestore.
  /// Setiap kali ada perubahan transaksi di database, aliran akan memanggil ulang `loadDashboard()`.
  /// Operasi CRUD (Read Stream):
  /// - Sintaks: `_firestore.collection('orders').snapshots()`
  Stream<DashboardData> streamDashboard() {
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      return await loadDashboard();
    });
  }

  /// Fungsi: Menghitung metrik ringkasan umum statistik sistem (Statistik Pemasukan, Berat Sampah, Jumlah Transaksi, serta Sebaran Pengguna/Driver).
  /// Operasi CRUD (Read Documents):
  /// - Sintaks: `_firestore.collection('orders').get()` & `_firestore.collection('users').get()`
  Future<DashboardStats> getDashboardStats() async {
    final historyFuture = _firestore.collection('orders').get();
    final usersFuture = _firestore.collection('users').get();

    final historySnapshot = await historyFuture;
    final usersSnapshot = await usersFuture;

    double totalRevenue = 0;
    double totalWeight = 0;
    int totalOrdersCount = 0;
    int totalUsers = 0;
    int totalDrivers = 0;

    // KETENTUAN AKUMULASI ORDER:
    for (final doc in historySnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';

      // Pendapatan bersih & berat hanya dihitung jika status order selesai/completed
      if (status == 'completed') {
        totalRevenue += ((data['price_paid'] ?? data['price'] ?? 0) as num)
            .toDouble();
        totalWeight += ((data['weight'] ?? 0) as num).toDouble();
      }

      // Setiap dokumen order dihitung ke dalam total transaksi keseluruhan
      totalOrdersCount++;
    }

    // KETENTUAN PERHITUNGAN ROLE USER:
    for (final doc in usersSnapshot.docs) {
      final role = doc.data()['role'];

      switch (role) {
        case 'user':
          totalUsers++;
          break;
        case 'driver':
          totalDrivers++;
          break;
      }
    }

    return DashboardStats(
      totalRevenue: totalRevenue,
      totalCompletedOrders: totalOrdersCount,
      totalWeight: totalWeight,
      totalUsers: totalUsers,
      totalDrivers: totalDrivers,
    );
  }

  /// Fungsi: Memetakan akumulasi total pendapatan berdasarkan bulan (Januari - Desember) untuk grafik pendapatan.
  /// Operasi CRUD (Read Documents):
  /// - Sintaks: `_firestore.collection('orders').get()`
  Future<List<RevenueChartModel>> getRevenueChart() async {
    final snapshot = await _firestore.collection("orders").get();

    final Map<int, double> monthlyRevenue = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final Timestamp? createdAt = data["created_at"];
      if (createdAt == null) continue;

      final month = createdAt.toDate().month;

      final revenue = ((data["price_paid"] ?? data["price"] ?? 0) as num)
          .toDouble();

      monthlyRevenue.update(
        month,
        (value) => value + revenue,
        ifAbsent: () => revenue,
      );
    }

    final List<RevenueChartModel> result = [];

    for (int i = 1; i <= 12; i++) {
      result.add(RevenueChartModel(month: i, revenue: monthlyRevenue[i] ?? 0));
    }

    return result;
  }

  /// Fungsi: Menghitung frekuensi total transaksi order berdasarkan bulan (Januari - Desember) untuk grafik total order.
  /// Operasi CRUD (Read Documents):
  /// - Sintaks: `_firestore.collection('orders').get()`
  Future<List<OrderChartModel>> getOrderChart() async {
    final snapshot = await _firestore.collection("orders").get();

    final Map<int, int> monthlyOrders = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final Timestamp? createdAt = data["created_at"];
      if (createdAt == null) continue;

      final month = createdAt.toDate().month;

      monthlyOrders.update(month, (value) => value + 1, ifAbsent: () => 1);
    }

    final List<OrderChartModel> result = [];

    for (int i = 1; i <= 12; i++) {
      result.add(OrderChartModel(month: i, totalOrders: monthlyOrders[i] ?? 0));
    }

    return result;
  }

  /// Fungsi: Mengambil 10 transaksi pesanan terbaru dan menggabungkannya dengan data identitas pengguna/driver dari koleksi `users`.
  /// Operasi CRUD (Read Parallel & Query):
  /// - Sintaks User Caching: `_firestore.collection('users').get()`
  /// - Sintaks Order Terbatas: `_firestore.collection('orders').orderBy('created_at', descending: true).limit(10).get()`
  Future<List<AdminLatestOrder>> getLatestOrders() async {
    final usersFuture = _firestore.collection('users').get();

    final ordersFuture = _firestore
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(10)
        .get();

    final results = await Future.wait([usersFuture, ordersFuture]);
    final userSnapshot = results[0];
    final orderSnapshot = results[1];

    // Caching nama pengguna berbasis Map ID
    final Map<String, String> userNames = {};

    for (final doc in userSnapshot.docs) {
      final data = doc.data();
      userNames[doc.id] = data['name'] ?? '-';
    }

    final List<AdminLatestOrder> orders = [];

    for (final doc in orderSnapshot.docs) {
      final data = doc.data();
      final userId = data['user_id'] ?? '';
      final driverId = data['driver_id'] ?? '';

      orders.add(
        AdminLatestOrder(
          id: doc.id,
          orderId: data['order_id'] ?? '',
          userId: userId,
          driverId: driverId,
          userName: userNames[userId] ?? '-',
          driverName: userNames[driverId] ?? '-',
          address: data['address'] ?? '',
          weight: (data['weight'] ?? 0).toDouble(),
          price: ((data['price_paid'] ?? data['price'] ?? 0) as num).toDouble(),
          status: data['status'] ?? '',
          createdAt: data['created_at'] ?? Timestamp.now(),
        ),
      );
    }
    return orders;
  }

  /// Fungsi: Menjalankan pemuatan seluruh komponen data dashboard secara eksekusi paralel via `Future.wait`.
  Future<DashboardData> loadDashboard() async {
    final results = await Future.wait([
      getDashboardStats(),
      getRevenueChart(),
      getOrderChart(),
      getLatestOrders(),
      getTopDrivers(),
      getTopUsers(),
    ]);

    return DashboardData(
      stats: results[0] as DashboardStats,
      revenueChart: results[1] as List<RevenueChartModel>,
      orderChart: results[2] as List<OrderChartModel>,
      latestOrders: results[3] as List<AdminLatestOrder>,
      topDrivers: results[4] as List<TopDriverModel>,
      topUsers: results[5] as List<TopUserModel>,
    );
  }

  /// Fungsi: Mengagregasi data driver teraktif berdasarkan akumulasi penyelesaian pesanan dan mengambil 5 peringkat teratas.
  /// Operasi CRUD (Read Documents & Dynamic Lookup):
  /// - Read Order History: `_firestore.collection('orders').get()`
  /// - Read User Detail: `_firestore.collection('users').doc(uid).get()`
  Future<List<TopDriverModel>> getTopDrivers() async {
    final historySnapshot = await _firestore.collection("orders").get();
    final Map<String, int> counter = {};

    for (final doc in historySnapshot.docs) {
      final data = doc.data();
      final driverId = data["driver_id"];
      if (driverId == null || driverId.toString().isEmpty) {
        continue;
      }
      counter.update(driverId, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFive = sorted.take(5).toList();

    List<TopDriverModel> drivers = [];

    for (final item in topFive) {
      final userDoc = await _firestore.collection("users").doc(item.key).get();
      if (!userDoc.exists) continue;
      final user = userDoc.data()!;

      drivers.add(
        TopDriverModel(
          uid: item.key,
          name: user["name"] ?? "-",
          phone: user["phone"] ?? "-",
          totalOrders: item.value,
          totalWeight: 0,
          totalRevenue: 0,
        ),
      );
    }
    return drivers;
  }

  /// Fungsi: Mengagregasi data pengguna/pelanggan teraktif (Placeholder pengembang untuk modul leaderboard pengguna).
  Future<List<TopUserModel>> getTopUsers() async {
    return [];
  }
}
