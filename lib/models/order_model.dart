import 'package:cloud_firestore/cloud_firestore.dart';

// Kelas untuk merepresentasikan transaksi/pesanan
class OrderModel {
  final String id; // ID unik dokumen transaksi
  final String userId; // ID pemesan (user)
  final String?
  driverId; // ID driver yang mengambil pesanan (bisa null kalau belum ada driver)
  final String
  status; // Status pesanan (misal: 'pending', 'picked_up', 'completed')
  final double weight; // Berat barang/sampah
  final double distance; // Jarak penjemputan
  final double price; // Total harga
  final String address; // Alamat lengkap penjemputan
  final GeoPoint
  location; // Titik kordinat GPS (Latitude & Longitude) dari Firestore
  final List<String> photoUrls; // Daftar link foto pendukung
  final Timestamp createdAt; // Tanggal pesanan dibuat
  final DateTime? pickupDate; // Tanggal jadwal penjemputan
  final String name; // Nama pemesan
  final String phoneNumber; // Nomor telepon pemesan
  final String? paymentStatus; // Status pembayaran (misal: 'paid', 'unpaid')

  // Constructor utama
  OrderModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.status,
    required this.weight,
    required this.distance,
    required this.price,
    required this.address,
    required this.location,
    required this.photoUrls,
    required this.createdAt,
    this.pickupDate,
    required this.name,
    required this.phoneNumber,
    this.paymentStatus,
  });

  // [READ PROCESS] Pabrik konversi langsung dari DocumentSnapshot Firestore ke Objek OrderModel
  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    // Ambil data mentah map dari dokumen Firestore
    final d = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id, // ID diambil langsung dari ID dokumen Firestore
      userId: d['user_id'],
      driverId: d['driver_id'],
      status: d['status'],
      // Mengamankan konversi tipe angka num/int ke double jika nilai awal null diberi 0
      weight: (d['weight'] ?? 0).toDouble(),
      distance: (d['distance'] ?? 0).toDouble(),
      price: (d['price'] ?? 0).toDouble(),
      address: d['address'] ?? '',
      location: d['location'],
      // Mengubah List dinamis dari Firestore ke List<String>
      photoUrls: List<String>.from(d['photo_urls'] ?? []),
      createdAt: d['created_at'] ?? Timestamp.now(),
      // Mengubah Timestamp dari Firestore menjadi DateTime bawaan Dart jika ada
      pickupDate: d['pickup_date'] != null
          ? (d['pickup_date'] as Timestamp).toDate()
          : null,
      name: d['name'] ?? '',
      phoneNumber: d['phone_number'] ?? '',
      paymentStatus: d['payment_status'] as String?,
    );
  }

  // [CREATE / UPDATE PROCESS] Mengubah Objek OrderModel menjadi Map untuk dikirim balik ke Firestore
  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'driver_id': driverId,
    'status': status,
    'weight': weight,
    'distance': distance,
    'price': price,
    'address': address,
    'location': location,
    'photo_urls': photoUrls,
    'created_at': createdAt,
    // Jika pickupDate ada, ubah kembali DateTime ke format Timestamp Firestore
    'pickup_date': pickupDate != null ? Timestamp.fromDate(pickupDate!) : null,
    'name': name,
    'phone_number': phoneNumber,
    'payment_status': paymentStatus,
  };
}
