import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';
import '../models/revenue_chart_model.dart';
import '../models/order_chart_model.dart';
import '../models/admin_latest_order.dart';
import 'dashboard_data.dart';
import '../models/top_driver_model.dart';
import '../models/top_user_model.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DashboardStats> getDashboardStats() async {
    final historyFuture = _firestore.collection('order_history').get();
    final usersFuture = _firestore.collection('users').get();

    final historySnapshot = await historyFuture;
    final usersSnapshot = await usersFuture;

    double totalRevenue = 0;
    double totalWeight = 0;
    int completedOrders = 0;
    int totalUsers = 0;
    int totalDrivers = 0;

    // ORDER HISTORY
    for (final doc in historySnapshot.docs) {
      final data = doc.data();

      totalRevenue += ((data['price_paid'] ?? data['price'] ?? 0) as num)
          .toDouble();

      totalWeight += ((data['weight'] ?? 0) as num).toDouble();

      completedOrders++;
    }

    // USERS
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
      totalCompletedOrders: completedOrders,
      totalWeight: totalWeight,
      totalUsers: totalUsers,
      totalDrivers: totalDrivers,
    );
  }

  Future<List<RevenueChartModel>> getRevenueChart() async {
    final snapshot = await _firestore.collection("order_history").get();

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

  Future<List<OrderChartModel>> getOrderChart() async {
    final snapshot = await _firestore.collection("order_history").get();

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

  Future<List<AdminLatestOrder>> getLatestOrders() async {
    final usersFuture = _firestore.collection('users').get();

    final ordersFuture = _firestore
        .collection('order_history')
        .orderBy('created_at', descending: true)
        .limit(10)
        .get();

    final results = await Future.wait([usersFuture, ordersFuture]);

    final userSnapshot = results[0];

    final orderSnapshot = results[1];

    // Cache user
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
      topDrivers: [],
      topUsers: [],
    );
  }

  Future<List<TopDriverModel>> getTopDrivers() async {
    final historySnapshot = await _firestore.collection("order_history").get();

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
          totalWeight: 0, // Placeholder, you can calculate this if needed
          totalRevenue: 0, // Placeholder, you can calculate this if needed
        ),
      );
    }

    return drivers;
  }

  Future<List<TopUserModel>> getTopUsers() async {
    return [];
  }
}
