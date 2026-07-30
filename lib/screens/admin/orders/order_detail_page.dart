import 'package:flutter/material.dart';
import 'widgets/status_card.dart';
import '../models/order_detail_model.dart';
import 'order_service.dart';
import 'widgets/user_info_card.dart';
import 'widgets/driver_info_card.dart';
import 'widgets/order_info_card.dart';
import 'widgets/photo_card.dart';
import 'widgets/timeline_card.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService service = OrderService();

  late Future<OrderDetailModel> orderFuture;

  @override
  void initState() {
    super.initState();

    orderFuture = service.getOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Order")),

      body: FutureBuilder<OrderDetailModel>(
        future: orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final order = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusCard(order: order),

                const SizedBox(height: 16),

                UserInfoCard(order: order),

                const SizedBox(height: 16),

                DriverInfoCard(order: order),

                const SizedBox(height: 16),

                OrderInfoCard(order: order),

                const SizedBox(height: 16),

                PhotoCard(order: order),

                const SizedBox(height: 16),

                TimelineCard(order: order),
              ],
            ),
          );
        },
      ),
    );
  }
}
