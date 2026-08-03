import 'package:flutter/material.dart';

/// Fungsi: Halaman Layar Penuh Pratinjau Foto Sampah (Full Image Viewer Page).
/// Cara Kerja:
/// 1. Menerima alamat `imageUrl` dari thumbnail foto yang dipilih pada `PhotoCard`.
/// 2. Menggunakan animasi `Hero` agar transisi perpindahan gambar dari thumbnail ke layar penuh terasa halus.
/// 3. Membungkus gambar dengan widget `InteractiveViewer` untuk mendukung gestur *pinch-to-zoom* (perbesaran skala 1x hingga 5x) serta pergeseran posisi gambar (*panning*).
///
/// Operasi Data & Presentasi:
/// - Mengakses URL foto jaringan via `Image.network(imageUrl)` pada latar belakang hitam (*dark backdrop*).
class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
