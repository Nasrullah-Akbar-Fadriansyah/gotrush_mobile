import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_detail_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OrderDetailModel> getOrderDetail(String documentId) async {
    final orderDoc = await _firestore
        .collection("orders")
        .doc(documentId)
        .get();

    if (!orderDoc.exists) {
      throw Exception("Order tidak ditemukan");
    }

    final order = orderDoc.data()!;
    final String userId = order["user_id"] ?? "";
    final String driverId = order["driver_id"] ?? "";

    // Siapkan penampung data snapshot dokumen
    DocumentSnapshot? userSnap;
    DocumentSnapshot? driverSnap;

    // Lakukan fetch data secara paralel hanya jika ID tidak kosong
    List<Future<DocumentSnapshot>> futures = [];

    futures.add(_firestore.collection("users").doc(userId).get());

    if (driverId.isNotEmpty) {
      futures.add(_firestore.collection("users").doc(driverId).get());
    }

    final results = await Future.wait(futures);
    userSnap = results[0];

    // Jika driverId tidak kosong, ambil hasil kedua dari Future.wait
    if (driverId.isNotEmpty) {
      driverSnap = results[1];
    }

    // Pengecekan data user secara aman
    Map<String, dynamic> userData = {};
    if (userSnap.exists && userSnap.data() != null) {
      userData = userSnap.data() as Map<String, dynamic>;
    }

    // Pengecekan data driver secara aman (antisipasi order pending tanpa driver)
    Map<String, dynamic> driverData = {};
    if (driverSnap != null && driverSnap.exists && driverSnap.data() != null) {
      driverData = driverSnap.data() as Map<String, dynamic>;
    }

    return OrderDetailModel(
      id: orderDoc.id,
      orderId: order["order_id"] ?? "",
      userId: userId,
      userEmail: userData["email"] ?? "-",
      userName: userData["name"] ?? "-",
      phoneNumber: userData["phone"] ?? "-",
      driverId: driverId,
      driverName:
          driverData["name"] ??
          "Belum Ada Driver", // Text informatif untuk pending order
      driverPhone: driverData["phone"] ?? "-",
      driverStatus: driverData["status"] ?? "offline",
      status: order["status"] ?? "",
      paymentStatus: order["payment_status"] ?? "",
      weight: (order["weight"] ?? 0).toDouble(),
      distance: (order["distance"] ?? 0).toDouble(),
      price:
          double.tryParse(
            order["price_paid"]?.toString() ??
                order["price"]?.toString() ??
                "0",
          ) ??
          0.0,
      address: order["address"] ?? "",
      location: order["location"],
      photoUrls: List<String>.from(order["photo_urls"] ?? []),
      createdAt: order["created_at"] ?? Timestamp.now(),
      acceptedAt: order["accepted_at"],
      completedAt: order["completed_at"],
    );
  }
}
