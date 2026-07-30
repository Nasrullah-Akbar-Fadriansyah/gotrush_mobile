import 'package:flutter/material.dart';
import 'package:sampah_online/screens/login_screen.dart';
import 'package:sampah_online/screens/register_screen.dart';

/// Fungsi: Widget halaman selamat datang (Welcome Screen) aplikasi GoTrash.
/// Cara Kerja: Menampilkan logo, nama aplikasi, slogan, serta tombol navigasi menuju
/// halaman Login atau Register. Halaman ini juga bertindak sebagai pelindung (gatekeeper)
/// yang memvalidasi apakah status inisialisasi aplikasi (`isReady` & `initError`) sudah terpenuhi
/// sebelum mengaktifkan tombol interaksi pengguna.
class WelcomeScreen extends StatelessWidget {
  /// Fungsi: Menandakan apakah sistem latar belakang (seperti Firebase) sudah siap digunakan.
  final bool isReady;

  /// Fungsi: Menyimpan pesan error jika proses inisialisasi aplikasi gagal.
  final String? initError;

  const WelcomeScreen({super.key, this.isReady = false, this.initError});

  @override
  Widget build(BuildContext context) {
    /// Fungsi: Logika untuk menentukan status aktif tombol.
    /// Cara Kerja: Tombol hanya akan aktif (`true`) jika aplikasi sudah siap (`isReady` bernilai true)
    /// dan tidak ada error (`initError` bernilai null).
    final bool buttonsEnabled = isReady && initError == null;

    /// Fungsi: Aksi ketika tombol Login ditekan.
    /// Cara Kerja: Jika tombol aktif, fungsi akan melakukan push navigasi ke `LoginScreen`.
    /// Jika tidak aktif, mengembalikan nilai `null` (membuat tombol berstatus disabled).
    final VoidCallback? onLoginPressed = buttonsEnabled
        ? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          )
        : null;

    /// Fungsi: Aksi ketika tombol Register ditekan.
    /// Cara Kerja: Jika tombol aktif, fungsi akan melakukan push navigasi ke `RegisterScreen`.
    /// Jika tidak aktif, mengembalikan nilai `null`.
    final VoidCallback? onRegisterPressed = buttonsEnabled
        ? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          )
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildLogo(context),
                const SizedBox(height: 40),
                _buildButton(context, 'Login', onLoginPressed),
                const SizedBox(height: 20),
                _buildButton(
                  context,
                  'Register',
                  onRegisterPressed,
                  isPrimary: false,
                ),
                const SizedBox(height: 30),
                _buildStatusIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final double logoSize = MediaQuery.of(context).size.width * 1;
    return Column(
      children: [
        Image.asset(
          'assets/images/welcome.png',
          height: logoSize,
          width: logoSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 1),
        const Text(
          'GoTrash',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const Text(
          'Solusi Cerdas untuk Sampah Anda',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    VoidCallback? onPressed, {
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? Colors.green : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (initError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Gagal inisialisasi: $initError',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.yellowAccent),
        ),
      );
    }
    if (!isReady) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2.0,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Mempersiapkan aplikasi...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // fungsi ini mengembalikan widget kosong jika aplikasi siap dan tidak ada error
  }
}
