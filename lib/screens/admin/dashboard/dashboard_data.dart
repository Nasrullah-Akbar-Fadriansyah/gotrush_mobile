import '../models/admin_latest_order.dart';
import '../models/dashboard_stats.dart';
import '../models/order_chart_model.dart';
import '../models/revenue_chart_model.dart';

class DashboardData {
  final DashboardStats stats;

  final List<RevenueChartModel> revenueChart;

  final List<OrderChartModel> orderChart;

  final List<AdminLatestOrder> latestOrders;

  final List<Map<String, dynamic>> topDrivers;

  final List<Map<String, dynamic>> topUsers;

  const DashboardData({
    required this.stats,

    required this.revenueChart,

    required this.orderChart,

    required this.latestOrders,

    required this.topDrivers,

    required this.topUsers,
  });
}
