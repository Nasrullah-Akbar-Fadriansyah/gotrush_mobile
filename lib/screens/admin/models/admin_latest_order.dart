import 'package:cloud_firestore/cloud_firestore.dart';

/// Fungsi: Model Data (DTO) untuk Menampung Ringkasan Pesanan Terbaru pada Dashboard Admin.
/// Cara Kerja:
/// 1. Mengelompokkan atribut penting dari dokumen pesanan Firestore untuk kebutuhan widget `LatestOrders`.
/// 2. Menyimpan identitas pemesan (User) dan mitra pengambil (Driver) beserta nama teresolusi untuk ditampilkan langsung tanpa query ulang di sisi UI.
/// 3. Menampung status transaksi, rincian biaya, berat sampah, dan waktu pembuatan pesanan (`createdAt`).
///
/// Operasi Data (Read / Parsing Data Firestore):
/// - Digunakan oleh `DashboardService.getLatestOrders()` saat mengonversi Map data dokumen Firestore dari koleksi `orders` menjadi objek terstruktur.
/// - Contoh Sintaks Pembentukan Model:
///   ```dart
///   AdminLatestOrder(
///     id: doc.id,
///     orderId: data['order_id'] ?? '',
///     userId: data['user_id'] ?? '',
///     driverId: data['driver_id'] ?? '',
///     userName: userNames[userId] ?? '-',
///     driverName: userNames[driverId] ?? '-',
///     address: data['address'] ?? '',
///     weight: (data['weight'] ?? 0).toDouble(),
///     price: ((data['price_paid'] ?? data['price'] ?? 0) as num).toDouble(),
///     status: data['status'] ?? '',
///     createdAt: data['created_at'] ?? Timestamp.now(),
///   );
///   ```
class AdminLatestOrder {
  /// ID Dokumen unik Firestore (Auto-generated Doc ID).
  final String id;

  /// Kode referensi transaksi pesanan yang disajikan ke pengguna (contoh: `ORD-12345`).
  final String orderId;

  /// ID unik pengguna (User UID) pemilik pesanan.
  final String userId;

  /// ID unik driver (Driver UID) yang menangani pesanan.
  final String driverId;

  /// Nama lengkap pelanggan pemesan.
  final String userName;

  /// Nama lengkap mitra driver pengambil.
  final String driverName;

  /// Alamat lengkap lokasi penjemputan sampah.
  final String address;

  /// Berat sampah dalam satuan Kilogram (Kg).
  final double weight;

  /// Total nominal biaya/pembayaran pesanan dalam Rupiah (Rp).
  final double price;

  /// Status perjalanan pesanan saat ini (misal: `pending`, `active`, `completed`, `cancelled`).
  final String status;

  /// Waktu dokumen pesanan pertama kali dibuat di database.
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
