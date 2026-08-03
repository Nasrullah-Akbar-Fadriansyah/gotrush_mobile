import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Fungsi: Antarmuka pemeliharaan/pemilihan titik koordinat lokasi penjemputan berbasis peta OpenStreetMap.
/// Cara Kerja:
/// 1. Mengambil lokasi GPS pengguna saat pertama dibuka (`_getCurrentUserLocation`).
/// 2. Merender peta interaktif dengan pin penanda tepat di tengah layar.
/// 3. Setiap kali peta digeser (`onPositionChanged`), mendeteksi koordinat baru dan menjalankan *reverse geocoding* dengan teknik *debounce*.
/// 4. Saat tombol konfirmasi ditekan, mengembalikan koordinat lokasi berupa `firestore.GeoPoint` dan string alamat lengkap ke layar sebelumnya
class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();

  // Lokasi default sementara sebelum GPS berhasil didapat
  LatLng _currentCenter = const LatLng(-6.200000, 106.816666);

  String? _selectedAddress;
  bool _loadingAddress = false;
  bool _loadingLocation = true;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentUserLocation();
  }

  /// Fungsi: Mengambil posisi lokasi nyata pengguna dari perangkat keras GPS.
  /// Cara Kerja:
  /// 1. Menguji status aktif sensor GPS (`Geolocator.isLocationServiceEnabled`).
  /// 2. Menguji dan meminta hak akses izin lokasi ke sistem operasi.
  /// 3. Mendapatkan koordinat `Position`, memindahkan kamera peta via `_mapController.move`, dan menginisialisasi pembacaan alamat.
  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setDefaultLocation("Layanan GPS tidak aktif.");
      return;
    }

    // 2. Cek izin akses lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation("Izin lokasi ditolak.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation("Izin lokasi ditolak secara permanen.");
      return;
    }

    // 3. Ambil posisi GPS pengguna
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentCenter = userLatLng;
        _loadingLocation = false;
      });

      // Pindahkan kamera peta ke titik GPS pengguna
      _mapController.move(userLatLng, 16);

      // Ambil nama alamat berdasarkan posisi baru
      _reverseGeocode(userLatLng);
    } catch (e) {
      _setDefaultLocation("Gagal mengambil posisi GPS.");
    }
  }

  /// Fungsi: Mengatur posisi peta fallback jika GPS gagal didapatkan dan memunculkan pesan peringatan.
  void _setDefaultLocation(String errorMessage) {
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
    });
    _reverseGeocode(_currentCenter);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  /// Fungsi: Melakukan konversi dari titik koordinat peta (LatLng) menjadi nama alamat teks (Reverse Geocoding).
  /// Cara Kerja: Menggunakan `Timer` debounce sebesar 100 ms untuk mencegah panggilan beruntun berlebihan saat peta digeser dengan cepat.
  Future<void> _reverseGeocode(LatLng point) async {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted) return;

      setState(() {
        _loadingAddress = true;
      });

      try {
        final placemarks = await placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );

        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final address = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.country,
          ].where((e) => e != null && e.isNotEmpty).join(", ");

          setState(() {
            _selectedAddress = address.isEmpty
                ? "Alamat tidak ditemukan"
                : address;
          });
        } else {
          setState(() {
            _selectedAddress = "Alamat tidak ditemukan";
          });
        }
      } catch (e) {
        debugPrint(e.toString());

        if (!mounted) return;

        setState(() {
          _selectedAddress = "Gagal mengambil alamat";
        });
      }

      if (mounted) {
        setState(() {
          _loadingAddress = false;
        });
      }
    });
  }

  /// Fungsi: Mengonfirmasi lokasi terpilih dan mengembalikannya ke layar pemanggil (Order Form).
  /// Cara Kerja: Mengubah atribut latitude dan longitude menjadi objek `firestore.GeoPoint`, lalu menutup layar (`Navigator.pop`).
  void _confirm() {
    Navigator.pop(context, {
      "location": firestore.GeoPoint(
        _currentCenter.latitude,
        _currentCenter.longitude,
      ),
      "address": _selectedAddress ?? "",
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Lokasi")),
      body: Stack(
        children: [
          // 1. PETA (FlutterMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16,
              onPositionChanged: (position, hasGesture) {
                _currentCenter = position.center;
                _reverseGeocode(_currentCenter);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.sampah_online",
              ),
            ],
          ),

          // 2. PIN INDIKATOR DI TENGAH
          const IgnorePointer(
            child: Center(
              child: Icon(Icons.location_pin, color: Colors.red, size: 54),
            ),
          ),

          // 3. CARD NAMA JALAN / ALAMAT
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadingAddress
                            ? "Mencari alamat..."
                            : (_selectedAddress ?? "Geser peta"),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. TOMBOL GPS MY LOCATION
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getCurrentUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 5. TOMBOL KONFIRMASI
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_loadingAddress || _loadingLocation)
                    ? null
                    : _confirm,
                icon: const Icon(Icons.check),
                label: const Text("Konfirmasi Lokasi"),
              ),
            ),
          ),

          // 6. OVERLAY LOADING GPS
          if (_loadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
