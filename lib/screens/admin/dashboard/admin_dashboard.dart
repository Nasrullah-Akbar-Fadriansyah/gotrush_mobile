import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../dashboard/dashboard_service.dart';
import '../widgets/dashboard_header.dart';
import '../dashboard/sections/dashboard_stat_section.dart';
import '../widgets/latest_orders.dart';
import '../models/admin_latest_order.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService service = DashboardService();
  late Future<DashboardStats> statsFuture;

  late Future<List<AdminLatestOrder>> latestOrdersFuture;

  @override
  void initState() {
    super.initState();

    statsFuture = service.getDashboardStats();

    latestOrdersFuture = service.getLatestOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DashboardStats>(
          future: statsFuture,

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final stats = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  const DashboardHeader(),

                  const SizedBox(height: 20),

                  DashboardStatSection(stats: stats),

                  const SizedBox(height: 20),

                  FutureBuilder<List<AdminLatestOrder>>(
                    future: latestOrdersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Text("Gagal memuat order terbaru");
                      }

                      return LatestOrders(orders: snapshot.data ?? []);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
