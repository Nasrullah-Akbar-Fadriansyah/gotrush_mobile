import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLatestOrder {
  final String id;
  final String orderId;

  final String userId;
  final String driverId;

  final String userName;
  final String driverName;

  final String address;

  final double weight;
  final double price;

  final String status;

  final Timestamp createdAt;

  const AdminLatestOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.driverId,
    required this.userName,
    required this.driverName,
    required this.address,
    required this.weight,
    required this.price,
    required this.status,
    required this.createdAt,
  });
}
