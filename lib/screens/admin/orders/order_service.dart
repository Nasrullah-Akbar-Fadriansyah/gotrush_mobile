import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_detail_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OrderDetailModel> getOrderDetail(String documentId) async {
    final orderDoc = await _firestore
        .collection("order_history")
        .doc(documentId)
        .get();

    if (!orderDoc.exists) {
      throw Exception("Order tidak ditemukan");
    }

    final order = orderDoc.data()!;
    final results = await Future.wait([
      _firestore.collection("users").doc(order["user_id"]).get(),
      _firestore.collection("users").doc(order["driver_id"]).get(),
    ]);
    final user = results[0].data() as Map<String, dynamic>;

    final driver = results[1].data() as Map<String, dynamic>;
    return OrderDetailModel(
      id: orderDoc.id,
      orderId: order["order_id"] ?? "",
      userId: order["user_id"] ?? "",
      userEmail: user["email"] ?? "-",
      userName: user["name"] ?? "-",
      phoneNumber: user["phone"] ?? "-",
      driverId: order["driver_id"] ?? "",
      driverName: driver["name"] ?? "-",
      driverPhone: driver["phone"] ?? "-",
      driverStatus: driver["status"] ?? "offline",
      status: order["status"] ?? "",
      paymentStatus: order["payment_status"] ?? "",
      weight: (order["weight"] ?? 0).toDouble(),
      distance: (order["distance"] ?? 0).toDouble(),
      price: ((order["price_paid"] ?? order["price"] ?? 0) as num).toDouble(),
      address: order["address"] ?? "",
      location: order["location"],
      photoUrls: List<String>.from(order["photo_urls"] ?? []),
      createdAt: order["created_at"],
      acceptedAt: order["accepted_at"],
      completedAt: order["completed_at"],
    );
  }
}
