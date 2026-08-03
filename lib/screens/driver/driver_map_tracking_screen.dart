import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';

/// Fungsi: Halaman Peta Pelacakan Rute Driver ke Lokasi Pengguna (Driver Map Tracking Screen).
/// Cara Kerja:
/// 1. Menerima posisi `userLocation` dan `orderId` dari halaman sebelumnya.
/// 2. Mendengarkan pembaruan koordinat GPS driver secara real-time dari Firestore koleksi `drivers_location`.
/// 3. Meminta rute jalan raya dari OSRM API (Open Source Routing Machine) dan merendernya sebagai garis Polyline di atas peta.
/// 4. Menyediakan tombol Floating Action Button yang interaktif sesuai dengan tahapan status pesanan (`arrived`, `pickup_confirmed`).
///
/// Operasi CRUD (Read & Update/Call):
/// - Read (Stream Realtime Document):
///   - Mendengarkan perubahan dokumen lokasi driver.
///     - Sintaks: `firestore.FirebaseFirestore.instance.collection('drivers_location').doc(driverId).snapshots()`
///   - Mendengarkan status dokumen pesanan aktif.
///     - Sintaks: `firestore.FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots()`
/// - Update (via OrderService):
///   - Mengubah status pesanan menjadi 'arrived' (Driver Tiba) atau 'pickup_validation' (Konfirmasi Ambil).
///     - Sintaks: `OrderService().driverArrived(...)` & `OrderService().driverConfirmPickup(...)`
class DriverMapTrackingScreen extends StatefulWidget {
  final String orderId;
  final firestore.GeoPoint userLocation;
  final String? watchDriverId;

  const DriverMapTrackingScreen({
    super.key,
    required this.orderId,
    required this.userLocation,
    this.watchDriverId,
  });

  @override
  State<DriverMapTrackingScreen> createState() =>
      _DriverMapTrackingScreenState();
}

class _DriverMapTrackingScreenState extends State<DriverMapTrackingScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<firestore.DocumentSnapshot<Map<String, dynamic>>>?
  _locationSub;

  LatLng? _driverLocation;
  late final LatLng _userDestination;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _initialBoundsFitted = false; // Flag agar fitBounds hanya sekali di awal

  @override
  void initState() {
    super.initState();
    _userDestination = LatLng(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
    );
    _listenToDriverLocation();
    _fetchCurrentDriverPositionAndRoute();
  }

  /// Fungsi: Mendengarkan update lokasi driver secara real-time dari koleksi Firestore `drivers_location`.
  /// Operasi CRUD (Read Stream):
  /// - Sintaks: `firestore.FirebaseFirestore.instance.collection('drivers_location').doc(driverId).snapshots()`
  void _listenToDriverLocation() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final driverId = widget.watchDriverId ?? auth.currentUser?.uid;
    if (driverId == null) return;

    _locationSub = firestore.FirebaseFirestore.instance
        .collection('drivers_location')
        .doc(driverId)
        .snapshots()
        .listen((snap) {
          if (!mounted || !snap.exists || snap.data() == null) return;

          final data = snap.data()!;
          final loc = data['location'] as firestore.GeoPoint?;

          final rawLat = loc?.latitude ?? data['lat'] ?? data['latitude'];
          final rawLng = loc?.longitude ?? data['lng'] ?? data['longitude'];

          if (rawLat != null && rawLng != null) {
            final double lat = (rawLat is num)
                ? rawLat.toDouble()
                : double.tryParse(rawLat.toString()) ?? 0;
            final double lng = (rawLng is num)
                ? rawLng.toDouble()
                : double.tryParse(rawLng.toString()) ?? 0;

            if (lat == 0 || lng == 0) return;

            final newDriverLoc = LatLng(lat, lng);

            setState(() {
              _driverLocation = newDriverLoc;
            });

            _loadRoute(newDriverLoc, _userDestination);

            // Hanya otomatis jalankan _fitMapBounds jika belum pernah sekali pun dijalankan
            if (!_initialBoundsFitted) {
              _fitMapBounds();
              _initialBoundsFitted = true;
            }
          }
        });
  }

  /// Fungsi: Mengambil posisi lokasi perangkat GPS driver saat ini secara lokal via paket Geolocator.
  Future<void> _fetchCurrentDriverPositionAndRoute() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLoc = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (mounted) {
        setState(() {
          _driverLocation = currentLoc;
        });
        _loadRoute(currentLoc, _userDestination);

        if (!_initialBoundsFitted) {
          _fitMapBounds();
          _initialBoundsFitted = true;
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil posisi GPS driver: $e");
    }
  }

  /// Fungsi: Memanggil OSRM Routing Service HTTP Endpoint untuk mendapatkan deretan koordinat rute jalan raya.
  Future<void> _loadRoute(LatLng origin, LatLng destination) async {
    if (_isLoadingRoute) return;
    _isLoadingRoute = true;

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${origin.longitude},${origin.latitude};"
        "${destination.longitude},${destination.latitude}"
        "?overview=full&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordinates =
            data["routes"][0]["geometry"]["coordinates"] as List;

        final points = coordinates
            .map(
              (e) => LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()),
            )
            .toList();

        if (mounted) {
          setState(() {
            _routePoints = points;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error menggambar rute OSRM: $e");
    } finally {
      _isLoadingRoute = false;
    }
  }

  /// Fungsi: Menyesuaikan batas viewport kamera peta secara dinamis agar mencakup posisi driver dan tujuan.
  void _fitMapBounds() {
    if (!mounted || _driverLocation == null) return;

    Distance distance = const Distance();
    final double meterDistance = distance.as(
      LengthUnit.Meter,
      _driverLocation!,
      _userDestination,
    );

    // Jika jarak driver dan user kurang dari 10 meter (sangat dekat/sama),
    // jangan gunakan fitCamera(bounds) karena pemicu kalkulasi NaN / Infinity
    if (meterDistance < 10) {
      _mapController.move(_userDestination, 17.0);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints([
        _driverLocation!,
        _userDestination,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(70),
          maxZoom: 18.0, // Batasi zoom maksimal agar tidak berlebih
        ),
      );
    } catch (e) {
      debugPrint("Error saat fitCamera: $e");
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rute ke Lokasi User'),
        backgroundColor: Colors.green[800],
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            style: const ButtonStyle(
              iconColor: WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: _fitMapBounds,
            tooltip: 'Fokuskan Peta',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _userDestination, initialZoom: 15),
        children: [
          // 1. Layer Peta OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sampah_online',
          ),

          // 2. Layer Garis Rute (Polyline)
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5.0,
                  color: Colors.green,
                ),
              ],
            ),

          // 3. Layer Marker
          MarkerLayer(
            markers: [
              // Marker Lokasi User / Tujuan
              Marker(
                point: _userDestination,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.red,
                  size: 48,
                ),
              ),

              // Marker Driver (Motor)
              if (_driverLocation != null)
                Marker(
                  point: _driverLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.two_wheeler,
                    color: Colors.blue,
                    size: 44,
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<firestore.DocumentSnapshot<Map<String, dynamic>>>(
        /// Operasi CRUD (Read Stream):
        /// Memantau perubahan status pesanan untuk menyesuaikan tombol tindakan driver.
        /// - Sintaks: `firestore.FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots()`
        stream: firestore.FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final order = snapshot.data!.data();
          if (order == null) return const SizedBox.shrink();
          final status = order['status'] as String? ?? '';
          final paymentStatus = order['payment_status'] as String?;
          final auth = Provider.of<AuthService>(context, listen: false);
          final currentUid = auth.currentUser?.uid;
          final isViewerDriver =
              (widget.watchDriverId == null) ||
              (widget.watchDriverId != null &&
                  widget.watchDriverId == currentUid);

          if (isViewerDriver &&
              (status == 'active' || status == 'awaiting_confirmation')) {
            return FloatingActionButton.extended(
              onPressed: () async {
                try {
                  final driverId = auth.currentUser?.uid ?? '';

                  /// Operasi CRUD (Update Status via Service):
                  /// Mengubah status pesanan menjadi 'arrived'.
                  await OrderService().driverArrived(
                    orderId: widget.orderId,
                    driverId: driverId,
                  );
                  try {
                    final doc = await firestore.FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .get();
                    final data = doc.data();
                    final userId = data?['user_id'] as String?;
                    if (userId != null && userId.isNotEmpty) {
                      await NotificationService().notifyUserDriverArrived(
                        orderId: widget.orderId,
                        userId: userId,
                      );
                    }
                  } catch (_) {}
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ditandai: Tiba di lokasi')),
                  );
                } catch (e) {
                  debugPrint('Gagal tandai tiba: $e');
                }
              },
              label: const Text('Tiba di Lokasi'),
              icon: const Icon(Icons.place),
              backgroundColor: Colors.blue[700],
            );
          }

          if (isViewerDriver &&
              (status == 'arrived') &&
              (paymentStatus == 'success' || paymentStatus == 'paid')) {
            return FloatingActionButton.extended(
              onPressed: () async {
                try {
                  final driverId = auth.currentUser?.uid ?? '';

                  /// Operasi CRUD (Update Status via Service):
                  /// Mengubah status pesanan untuk tahap validasi pengambilan sampah.
                  await OrderService().driverConfirmPickup(
                    orderId: widget.orderId,
                    driverId: driverId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Konfirmasi ambil dikirim')),
                    );
                  }
                } catch (e) {
                  debugPrint('Gagal konfirmasi ambil: $e');
                }
              },
              label: const Text('Konfirmasi Ambil'),
              icon: const Icon(Icons.shopping_bag),
              backgroundColor: Colors.orange[700],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
