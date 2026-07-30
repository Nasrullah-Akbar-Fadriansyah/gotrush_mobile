import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/alerts.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  String _role = 'user';
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final ValueNotifier<bool> _showPassword = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showConfirmPassword = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _showPassword.dispose();
    _showConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAutoFill() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isGoogleLoading = true);
    final auth = context.read<AuthService>();

    try {
      final googleUser = await auth.getGoogleAccountData();

      if (googleUser != null) {
        if (googleUser.displayName != null &&
            googleUser.displayName!.isNotEmpty) {
          _nameCtrl.text = googleUser.displayName!;
        }
        _emailCtrl.text = googleUser.email;

        if (mounted) {
          showAppSnackBar(
            context,
            'Nama & Email berhasil terisi otomatis!',
            type: AlertType.success,
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(
            context,
            'Pengisian otomatis dibatalkan atau gagal terhubung ke Google.',
            type: AlertType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Gagal mengambil data akun Google: $e',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    // 1. Unfocus keyboard secara penuh & beri jeda agar animasi IME selesai
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();

    try {
      // 2. Tambahkan timeout 12 detik agar tidak terkunci selamanya jika jaringan lambat
      await auth
          .register(
            email: _emailCtrl.text.trim().toLowerCase(),
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: _role,
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException(
              'Koneksi server lambat. Pastikan jaringan internet Anda stabil.',
            ),
          );

      if (!mounted) return;

      showAppSnackBar(
        context,
        'Registrasi berhasil! Silakan login.',
        type: AlertType.success,
      );

      // 3. Pindah ke halaman Login secara mulus menggunakan PageRouteBuilder
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 150),
        ),
      );
    } on TimeoutException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e.message ?? 'Proses registrasi memakan waktu terlalu lama.',
          type: AlertType.error,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message =
              'Email sudah terdaftar. Gunakan email lain atau silakan Login.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah. Buat password yang lebih kuat.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
          break;
        default:
          message = e.message ?? 'Terjadi kesalahan registrasi (${e.code}).';
      }

      if (mounted) {
        showAppSnackBar(context, message, type: AlertType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Gagal registrasi: ${e.toString()}',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2E4C6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.person_add_alt_1,
                          size: 42,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9D58),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Button Google Auto-Fill
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _handleGoogleAutoFill,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: Colors.redAccent,
                                ),
                          label: Text(
                            _isGoogleLoading
                                ? 'Mengambil Data...'
                                : 'Isi Otomatis via Google',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'atau isi manual',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor telepon wajib diisi';
                          }
                          if (v.length < 10) {
                            return 'Nomor telepon minimal 10 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          final val = v.trim().toLowerCase();
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password
                      ValueListenableBuilder<bool>(
                        valueListenable: _showPassword,
                        builder: (_, show, __) {
                          return TextFormField(
                            controller: _passwordCtrl,
                            textInputAction: TextInputAction.next,
                            obscureText: !show,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  show
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    _showPassword.value = !_showPassword.value,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.green[50],
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (v.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Confirm Password
                      ValueListenableBuilder<bool>(
                        valueListenable: _showConfirmPassword,
                        builder: (_, show, __) {
                          return TextFormField(
                            controller: _confirmPasswordCtrl,
                            textInputAction: TextInputAction.done,
                            obscureText: !show,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  show
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => _showConfirmPassword.value =
                                    !_showConfirmPassword.value,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.green[50],
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Role Selection
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: InputDecoration(
                          labelText: 'Daftar sebagai',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(
                            value: 'driver',
                            child: Text('Driver'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _role = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sudah punya akun?'),
                          TextButton(
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              await Future.delayed(
                                const Duration(milliseconds: 200),
                              );

                              if (!context.mounted) return;

                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const LoginScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                  transitionDuration: const Duration(
                                    milliseconds: 150,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Login',
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
      ),
    );
  }
}
