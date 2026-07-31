import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '', password = '';
  bool isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleLogin(AuthService auth) async {
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final targetEmail = email.trim().toLowerCase();
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException(
              'Gagal memeriksa email di database (Timeout).',
            ),
          );

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        await _showUnregisteredEmailDialog();
        return;
      }

      final userCredential = await auth
          .login(targetEmail, password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
              'Koneksi ke server Firebase Auth lambat atau terputus.',
            ),
          );

      final uid = userCredential?.user?.uid;

      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException(
                'Gagal mengambil data profil dari database (Firestore Timeout).',
              ),
            );

        if (!doc.exists) {
          await _showErrorDialog(
            title: 'Data Tidak Ditemukan',
            message: 'Dokumen profil pengguna tidak ditemukan di database.',
          );
          return;
        }

        final role = doc.data()?['role'] as String?;

        if (!mounted) return;

        if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver');
        } else if (role == 'user') {
          Navigator.pushReplacementNamed(context, '/user');
        } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          await _showErrorDialog(
            title: 'Akses Ditolak',
            message: 'Akun ini tidak memiliki role yang valid.',
          );
        }
      }
    } on TimeoutException catch (e) {
      await _showErrorDialog(
        title: 'Koneksi Terhambat',
        message:
            '${e.message}\n\nPastikan koneksi internet aktif dan layanan Firebase diizinkan di perangkat Anda.',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Password yang Anda masukkan salah, coba masukkan ulang.';
          break;
        case 'user-not-found':
          await _showUnregisteredEmailDialog();
          return;
        case 'user-disabled':
          message = 'Akun Anda telah dinonaktifkan oleh admin.';
          break;
        case 'too-many-requests':
          message =
              'Terlalu banyak percobaan login gagal. Coba beberapa saat lagi.';
          break;
        case 'invalid-email':
          message = 'Format penulisan email tidak valid.';
          break;
        case 'network-request-failed':
          message = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
          break;
        default:
          message = 'Terjadi kesalahan Auth: ${e.message ?? e.code}';
      }
      await _showErrorDialog(title: 'Login Gagal', message: message);
    } catch (e) {
      await _showErrorDialog(
        title: 'Login Gagal',
        message: 'Terjadi kesalahan tidak terduga: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showUnregisteredEmailDialog() async {
    if (mounted) setState(() => isLoading = false);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search_rounded,
                  color: Colors.orange[800],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Tidak Terdaftar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Email Anda salah / belum terdaftar. Apakah Anda ingin mendaftar akun baru?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showErrorDialog({
    required String title,
    required String message,
  }) async {
    if (mounted) setState(() => isLoading = false);

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFB2E4C6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.green[200],
                      child: Icon(
                        Icons.recycling,
                        size: 48,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk melanjutkan',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green[50],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onChanged: (v) => password = v,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  await _handleLogin(auth);
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun?'),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
