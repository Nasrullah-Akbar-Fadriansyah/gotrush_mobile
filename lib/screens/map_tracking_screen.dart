import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '/utils/alerts.dart';
import 'package:http/http.dart' as http;

/// Fungsi: Antarmuka pelacakan lokasi posisi Driver dan Pengguna secara langsung (Live Tracking) serta pembuatan rute jalan.
/// Cara Kerja:
/// 1. Mendengarkan perubahan koordinat Driver dan Pengguna secara paralel via Firestore Stream Listener (`_listenToLocations`).
/// 2. Menghitung jarak fisik langsung antar kedua titik dan menampilkan pemberitahuan jika Driver berjarak <= 200 meter.
/// 3. Mengambil titik-titik rute perjalanan dari API OSRM (`_loadRoute`) dan menggambarkannya menggunakan `PolylineLayer`.
/// 4. Otomatis menyesuaikan batas fokus peta (`fitCamera`) agar koordinat Driver dan Pengguna selalu terlihat secara bersamaan.
///
/// Operasi CRUD (Read - Realtime Stream):
/// - Read 1: Berlangganan koordinat Driver dari koleksi `drivers_location`.
///   - Sintaks: `FirebaseFirestore.instance.collection('drivers_location').doc(driverId).snapshots()`
/// - Read 2: Berlangganan koordinat Pengguna dari koleksi `users_location`.
///   - Sintaks: `FirebaseFirestore.instance.collection('users_location').doc(userId).snapshots()`
class MapTrackingScreen extends StatefulWidget {
  final String orderId;
  final String driverId;
  final String userId;

  const MapTrackingScreen({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.userId,
  });

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();

  LatLng? _driverLocation;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  /// Debounce request routing
  Timer? _routeDebounce;

  /// Cache route terakhir
  LatLng? _lastRouteOrigin;
  LatLng? _lastRouteDestination;

  /// Waktu request terakhir
  DateTime? _lastRouteRequest;

  /// Agar route tidak diambil bersamaan
  bool _isLoadingRoute = false;

  double _distanceToUser = 0.0;
  bool _isNearNotified = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _listenToLocations();
  }

  /// Fungsi: Mengaktifkan pemantauan lokasi real-time dari koleksi Firestore untuk Driver dan User.
  /// Cara Kerja:
  /// 1. Mengaitkan stream `.snapshots()` pada dokumen `drivers_location` dan `users_location`.
  /// 2. Memparsing atribut `latitude` dan `longitude` secara aman dari Firestore.
  /// 3. Memperbarui UI, menguji jarak tempuh, menggerakkan kamera peta, dan mendaftarkan pembaruan rute OSRM.
  ///
  /// Operasi CRUD (Read - Stream):
  /// - Sintaks Stream: `.collection('drivers_location').doc(id).snapshots().listen(...)`
  void _listenToLocations() {
    _driverSub = FirebaseFirestore.instance
        .collection('drivers_location')
        .doc(widget.driverId)
        .snapshots()
        .listen(
          (snap) async {
            if (!mounted) return;
            if (!snap.exists || snap.data() == null) return;

            final data = snap.data()!;

            final rawLat = data['lat'] ?? data['latitude'] ?? 0;
            final rawLng = data['lng'] ?? data['longitude'] ?? 0;

            final lat = rawLat is num
                ? rawLat.toDouble()
                : double.tryParse(rawLat.toString()) ?? 0.0;

            final lng = rawLng is num
                ? rawLng.toDouble()
                : double.tryParse(rawLng.toString()) ?? 0.0;

            if (lat == 0 || lng == 0) return;

            setState(() {
              _driverLocation = LatLng(lat, lng);
            });

            _checkDistanceAndNotify();
            _moveCamera();
            _scheduleRouteUpdate();
          },
          onError: (e) {
            debugPrint("Driver Stream Error : $e");
          },
        );

    _userSub = FirebaseFirestore.instance
        .collection('users_location')
        .doc(widget.userId)
        .snapshots()
        .listen(
          (snap) async {
            if (!mounted) return;
            if (!snap.exists || snap.data() == null) return;

            final data = snap.data()!;

            final rawLat = data['lat'] ?? data['latitude'] ?? 0;
            final rawLng = data['lng'] ?? data['longitude'] ?? 0;

            final lat = rawLat is num
                ? rawLat.toDouble()
                : double.tryParse(rawLat.toString()) ?? 0.0;

            final lng = rawLng is num
                ? rawLng.toDouble()
                : double.tryParse(rawLng.toString()) ?? 0.0;

            if (lat == 0 || lng == 0) return;

            setState(() {
              _userLocation = LatLng(lat, lng);
            });

            _checkDistanceAndNotify();
            _moveCamera();
            _scheduleRouteUpdate();
          },
          onError: (e) {
            debugPrint("User Stream Error : $e");
          },
        );
  }

  /// Fungsi: Menghitung jarak linier antara lokasi driver dan pengguna serta memberikan notifikasi saat mendekat.
  /// Cara Kerja: Menggunakan `Geolocator.distanceBetween`. Jika jarak <= 200m dan notifikasi belum terkirim, menampilkan `SnackBar` peringatan.
  void _checkDistanceAndNotify() {
    if (_driverLocation == null || _userLocation == null) return;

    final distance = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      _userLocation!.latitude,
      _userLocation!.longitude,
    );

    setState(() {
      _distanceToUser = distance;
    });

    const threshold = 200.0;

    if (distance <= threshold && !_isNearNotified) {
      showAppSnackBar(
        context,
        "Driver hampir sampai! Jarak ${distance.toStringAsFixed(0)} meter.",
        type: AlertType.warning,
      );

      _isNearNotified = true;
    }

    if (distance > threshold * 2) {
      _isNearNotified = false;
    }
  }

  /// Fungsi Helper: Menghitung jarak antar dua objek `LatLng` dalam satuan meter.
  double _distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  /// Fungsi: Memetakan penjadwalan pembaruan rute jalan dengan metode pembatasan frekuensi (Debounce & Cache Threshold).
  /// Cara Kerja: Hanya mengeksekusi pengambilan rute jika posisi driver/user bergeser > 30 meter atau selisih waktu permintaan > 10 detik.
  void _scheduleRouteUpdate() {
    if (_driverLocation == null || _userLocation == null) return;
    _routeDebounce = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      bool needUpdate = false;

      if (_lastRouteOrigin == null || _lastRouteDestination == null) {
        needUpdate = true;
      }

      if (!needUpdate &&
          _distanceBetween(_driverLocation!, _lastRouteOrigin!) > 30) {
        needUpdate = true;
      }

      if (!needUpdate &&
          _distanceBetween(_userLocation!, _lastRouteDestination!) > 30) {
        needUpdate = true;
      }

      if (!needUpdate &&
          _lastRouteRequest != null &&
          DateTime.now().difference(_lastRouteRequest!) >
              const Duration(seconds: 10)) {
        needUpdate = true;
      }

      if (!needUpdate) return;

      _lastRouteOrigin = _driverLocation;
      _lastRouteDestination = _userLocation;
      _lastRouteRequest = DateTime.now();

      await _loadRoute();
    });
  }

  /// Fungsi: Menyesuaikan posisi zoom dan titik pusat kamera peta agar mencakup kedua penanda (Driver & User).
  /// Cara Kerja: Menggunakan `LatLngBounds.fromPoints` dan dipasangkan ke `_mapController.fitCamera` dengan *padding* 80 piksel.
  void _moveCamera() {
    if (!mounted) return;

    if (_driverLocation != null && _userLocation != null) {
      final distance = _distanceBetween(_driverLocation!, _userLocation!);

      if (distance < 20) return;

      final bounds = LatLngBounds.fromPoints([
        _driverLocation!,
        _userLocation!,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    } else if (_driverLocation != null) {
      _mapController.move(_driverLocation!, 16);
    } else if (_userLocation != null) {
      _mapController.move(_userLocation!, 16);
    }
  }

  /// Fungsi: Mengambil data GeoJSON rute navigasi dari server OSRM (Open Source Routing Machine) via HTTP GET.
  /// Cara Kerja: Memanggil REST API OSRM, menguraikan koordinat array GeoJSON, dan memasukkannya ke dalam list `_routePoints` untuk dirender oleh `PolylineLayer`.
  Future<void> _loadRoute() async {
    if (_driverLocation == null || _userLocation == null) return;
    if (_isLoadingRoute) return;

    _isLoadingRoute = true;

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${_driverLocation!.longitude},${_driverLocation!.latitude};"
        "${_userLocation!.longitude},${_userLocation!.latitude}"
        "?overview=full&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final coordinates = data["routes"][0]["geometry"]["coordinates"] as List;

      final points = coordinates
          .map(
            (e) => LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _routePoints = points;
      });
    } catch (e) {
      debugPrint("Route Error : $e");
    } finally {
      _isLoadingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking - Jarak: ${_distanceToUser.toStringAsFixed(0)} m',
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(-6.200000, 106.816666),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sampah_online',
          ),

          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: Colors.green,
                ),
              ],
            ),

          MarkerLayer(
            markers: [
              if (_driverLocation != null)
                Marker(
                  point: _driverLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.red,
                    size: 40,
                  ),
                ),

              if (_userLocation != null)
                Marker(
                  point: _userLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 42,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _userSub?.cancel();
    _routeDebounce?.cancel(); // Pastikan timer dibatalkan di sini
    super.dispose();
  }
}
