import 'package:cloud_firestore/cloud_firestore.dart';

/// Fungsi: Model Data Rincian Lengkap Dokumen Pesanan (Detail Order Model).
/// Cara Kerja:
/// 1. Menyimpan seluruh metadata transaksi pesanan secara komprehensif untuk disajikan pada halaman Detail Pesanan Admin.
/// 2. Menampung data geolokasi (`GeoPoint`), lampiran foto bukti penjemputan (`photoUrls`), hingga jejak riwayat waktu (*timestamps*).
/// 3. Menggabungkan data relasional antara entitas Pelanggan (User), Mitra Driver, dan Transaksi Order.
///
/// Operasi Data (Read Full Document):
/// - Mengonversi dokumen Firestore berkapasitas lengkap untuk kebutuhan peninjauan, verifikasi, atau pembaruan status transaksi oleh Admin.
/// - Contoh Sintaks Parsing Firestore:
///   ```dart
///   OrderDetailModel(
///     id: doc.id,
///     orderId: data['order_id'] ?? '',
///     userId: data['user_id'] ?? '',
///     userEmail: data['user_email'] ?? '',
///     userName: data['user_name'] ?? '',
///     phoneNumber: data['phone_number'] ?? '',
///     driverId: data['driver_id'] ?? '',
///     driverName: data['driver_name'] ?? '',
///     driverPhone: data['driver_phone'] ?? '',
///     driverStatus: data['driver_status'] ?? '',
///     status: data['status'] ?? '',
///     paymentStatus: data['payment_status'] ?? '',
///     weight: (data['weight'] ?? 0).toDouble(),
///     distance: (data['distance'] ?? 0).toDouble(),
///     price: (data['price'] ?? 0).toDouble(),
///     address: data['address'] ?? '',
///     location: data['location'] as GeoPoint,
///     photoUrls: List<String>.from(data['photo_urls'] ?? []),
///     createdAt: data['created_at'] as Timestamp,
///     acceptedAt: data['accepted_at'] as Timestamp?,
///     completedAt: data['completed_at'] as Timestamp?,
///   );
///   ```
class OrderDetailModel {
  /// ID Dokumen unik Firestore (Doc ID).
  final String id;

  /// Kode unik transaksi order yang ditampilkan ke pengguna.
  final String orderId;

  /// ID Pengguna (User UID) pemesan.
  final String userId;

  /// Alamat Email pemesan.
  final String userEmail;

  /// Nama lengkap pemesan.
  final String userName;

  /// Nomor kontak/telepon pemesan.
  final String phoneNumber;

  /// ID Mitra Driver (Driver UID) penanggung jawab.
  final String driverId;

  /// Nama lengkap driver.
  final String driverName;

  /// Nomor kontak/telepon driver.
  final String driverPhone;

  /// Status keaktifan/kehadiran driver saat bertugas.
  final String driverStatus;

  /// Status siklus hidup pesanan (misal: `pending`, `active`, `arrived`, `completed`, `cancelled`).
  final String status;

  /// Status transaksi pembayaran (misal: `unpaid`, `waiting_payment`, `paid`, `success`).
  final String paymentStatus;

  /// Berat sampah yang diangkut (dalam Kg).
  final double weight;

  /// Jarak tempuh penjemputan dari driver ke lokasi user (dalam Km).
  final double distance;

  /// Nominal total biaya jasa penjemputan sampah (dalam Rp).
  final double price;

  /// Alamat titik lokasi penjemputan.
  final String address;

  /// Koordinat GPS lokasi penjemputan (`GeoPoint` latitude & longitude).
  final GeoPoint location;

  /// Daftar URL foto bukti kondisi/penjemputan sampah di lapangan.
  final List<String> photoUrls;

  /// Waktu pembuatan pesanan.
  final Timestamp createdAt;

  /// Waktu ketika pesanan diterima oleh driver (Opsional).
  final Timestamp? acceptedAt;

  /// Waktu ketika pesanan diselesaikan (Opsional).
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
