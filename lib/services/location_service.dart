import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Fungsi: Layanan Pembantu Pembaruan & Pemantauan Lokasi Driver Spesifik Order (Location Service).
/// Cara Kerja:
/// 1. Memperbarui dokumen posisi driver pada koleksi terpisah `'drivers_location'` beserta referensi `order_id` aktif.
/// 2. Menyediakan *Stream* dokumen posisi driver agar pengguna dapat memantau pergerakan driver pada peta *real-time*.
///
/// Operasi CRUD (Update / Set Merge & Read Stream):
/// - Update Location Doc:
///   - Sintaks: `_firestore.collection('drivers_location').doc(driverId).set({...}, SetOptions(merge: true))`
/// - Read Location Stream:
///   - Sintaks: `_firestore.collection('drivers_location').doc(driverId).snapshots()`
class LocationService {
  final _firestore = FirebaseFirestore.instance;

  /// Fungsi: Memperbarui koordinat garis lintang (`lat`) dan garis bujur (`lng`) driver pada dokumen `drivers_location`.
  /// Operasi CRUD (Update / Set Merge):
  /// - Sintaks: `_firestore.collection('drivers_location').doc(driverId).set({'lat': ..., 'lng': ...}, SetOptions(merge: true))`
  Future<void> updateDriverLocation(
    String driverId,
    Position position, {
    String? orderId,
  }) async {
    await _firestore.collection('drivers_location').doc(driverId).set({
      'lat': position.latitude,
      'lng': position.longitude,
      'last_update': FieldValue.serverTimestamp(),
      if (orderId != null) 'order_id': orderId,
    }, SetOptions(merge: true));
  }

  /// Fungsi: Mendengarkan aliran data lokasi driver secara *real-time* berdasarkan ID Driver.
  /// Operasi CRUD (Read Stream):
  /// - Sintaks: `_firestore.collection('drivers_location').doc(driverId).snapshots()`
  Stream<DocumentSnapshot> getDriverLocationStream(String driverId) {
    return _firestore.collection('drivers_location').doc(driverId).snapshots();
  }
}
