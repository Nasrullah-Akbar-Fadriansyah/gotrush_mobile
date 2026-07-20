import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailModel {
  final String id;
  final String orderId;

  final String userId;
  final String userEmail;
  final String userName;
  final String phoneNumber;

  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverStatus;

  final String status;
  final String paymentStatus;

  final double weight;
  final double distance;
  final double price;

  final String address;

  final GeoPoint location;

  final List<String> photoUrls;

  final Timestamp createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? completedAt;

  const OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.phoneNumber,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverStatus,
    required this.status,
    required this.paymentStatus,
    required this.weight,
    required this.distance,
    required this.price,
    required this.address,
    required this.location,
    required this.photoUrls,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });
}
