import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/revenue_chart_model.dart';
import '../../models/order_chart_model.dart';
import '../../utils/admin_formatter.dart';

class DashboardChartSection extends StatefulWidget {
  final List<RevenueChartModel> revenueData;
  final List<OrderChartModel> orderData;

  const DashboardChartSection({
    super.key,
    required this.revenueData,
    required this.orderData,
  });

  @override
  State<DashboardChartSection> createState() => _DashboardChartSectionState();
}

class _DashboardChartSectionState extends State<DashboardChartSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Grafik",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // PERBAIKAN 1: TabBar dibuat simetris & tidak overflow
                Container(
                  height: 35,
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false, // Membagi area rata (50:50)
                    padding: EdgeInsets.zero,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    indicator: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: "Pendapatan"),
                      Tab(text: "Total Order"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230, // Ditambah sedikit dari 220 ke 230
              child: TabBarView(
                controller: _tabController,
                children: [_buildRevenueChart(), _buildOrderChart()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (widget.revenueData.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    List<FlSpot> spots = widget.revenueData.map((data) {
      return FlSpot(data.month.toDouble() - 1, data.revenue);
    }).toList();

    double maxRevenue = 0;
    for (var spot in spots) {
      if (spot.y > maxRevenue) maxRevenue = spot.y;
    }

    // PERBAIKAN 2: Menaikkan batas atas Y sebesar 40% (1.4) agar tooltip punya ruang cukup
    double maxY = maxRevenue > 0 ? maxRevenue * 1.4 : 10000;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _months[index],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value >= 1000000) {
                  return Text(
                    '${(value / 1000000).toStringAsFixed(1)}M',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                } else if (value >= 1000) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade600.withValues(alpha: 0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // PERBAIKAN 3: Memaksa tooltip agar muat di dalam layar (tidak terpotong ke luar)
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (touchedSpot) => Colors.green.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  AdminFormatter.rupiah(spot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderChart() {
    if (widget.orderData.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    List<BarChartGroupData> barGroups = widget.orderData.map((data) {
      return BarChartGroupData(
        x: data.month - 1,
        barRods: [
          BarChartRodData(
            toY: data.totalOrders.toDouble(),
            color: Colors.orange.shade600,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _months[index],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (group) => Colors.orange.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} Order',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
