import '../models/dashboard_stats.dart';
import '../models/revenue_chart_model.dart';
import '../models/order_chart_model.dart';
import '../models/admin_latest_order.dart';
import '../models/top_driver_model.dart';
import '../models/top_user_model.dart';

class DashboardData {
  final DashboardStats stats;

  final List<RevenueChartModel> revenueChart;

  final List<OrderChartModel> orderChart;

  final List<AdminLatestOrder> latestOrders;

  final List<TopDriverModel> topDrivers;

  final List<TopUserModel> topUsers;

  const DashboardData({
    required this.stats,
    required this.revenueChart,
    required this.orderChart,
    required this.latestOrders,
    required this.topDrivers,
    required this.topUsers,
  });
}
