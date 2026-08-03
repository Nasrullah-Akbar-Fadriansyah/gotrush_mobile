import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Fungsi: Layanan Pelacakan & Pengiriman Lokasi Driver secara Latar Belakang / Berkelanjutan (Driver Location Tracker).
/// Cara Kerja:
/// 1. Memeriksa ketersediaan dan izin akses GPS (*Location Permission*) pada perangkat hardware.
/// 2. Mendengarkan aliran lokasi bergerak (`Geolocator.getPositionStream`) dengan tingkat akurasi tinggi dan filter jarak minimal 10 meter.
/// 3. Setiap terjadi perubahan posisi, koordinat (`GeoPoint`), arah pergerakan (`heading`), dan kecepatan (`speed`) otomatis diunggah ke Firestore.
/// 4. Menyediakan metode pembatalan penyiaran lokasi (`stop`) saat driver selesai beroperasi/offline.
///
/// Operasi CRUD (Create/Update Continuous Data):
/// - Menulis atau memperbarui koordinat lokasi driver di koleksi `'drivers'`:
/// - Sintaks: `FirebaseFirestore.instance.collection('drivers').doc(driverId).set(data, SetOptions(merge: true))`
class DriverLocationService {
  final String driverId;
  StreamSubscription<Position>? _sub;

  DriverLocationService(this.driverId);

  /// Fungsi: Memulai penyiaran posisi GPS driver secara berkala ke server Firestore.
  /// Operasi CRUD (Update / Set Merge Continuous):
  /// - Sintaks: `FirebaseFirestore.instance.collection('drivers').doc(driverId).set(data, SetOptions(merge: true))`
  Future<void> start() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location services disabled');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
          ),
        ).listen((pos) async {
          final data = {
            'location': GeoPoint(pos.latitude, pos.longitude),
            'heading': pos.heading,
            'speed': pos.speed,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverId)
              .set(data, SetOptions(merge: true));
        });
  }

  /// Fungsi: Memhentikan langganan aliran data posisi GPS driver (*Stream Subscription*).
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
