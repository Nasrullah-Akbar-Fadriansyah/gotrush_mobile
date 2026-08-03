import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Fungsi: Layanan Utama Manajemen Autentikasi dan Profil Pengguna (Auth Service).
/// Cara Kerja:
/// 1. Mengelola sesi login, pendaftaran akun baru, dan logout menggunakan `FirebaseAuth`.
/// 2. Menyediakan mekanisme pendaftaran data akun ke koleksi Firestore `'users'`.
/// 3. Mendukung alur *Google Sign-In* untuk memperoleh data akun kredensial Google pengguna.
/// 4. Menyediakan metode pembaruan token FCM (*Firebase Cloud Messaging*) serta status aktif/nonaktif driver.
///
/// Operasi CRUD (Create, Read, & Update):
/// - Create User Profile (Firestore):
///   - Menulis dokumen profil pengguna baru saat pendaftaran akun.
///   - Sintaks: `_firestore.collection('users').doc(uid).set({...})`
/// - Read User Data & Role (Firestore):
///   - Membaca data satu kali untuk memeriksa *role* pengguna (`user`/`driver`).
///   - Sintaks: `_firestore.collection('users').doc(uid).get()`
///   - Mendengarkan perubahan dokumen secara *real-time* via Stream.
///   - Sintaks: `_firestore.collection('users').doc(uid).snapshots()`
/// - Update Profile Fields (Firestore):
///   - Memperbarui token FCM dengan gabungan dokumen (*merge*):
///     Sintaks: `_firestore.collection('users').doc(uid).set({'fcm_token': token}, SetOptions(merge: true))`
///   - Memperbarui status ketersediaan driver (`active`/`offline`):
///     Sintaks: `_firestore.collection('users').doc(uid).update({'status': status})`
///   - Memperbarui stempel waktu login terakhir (`last_login_at`):
///     Sintaks: `_firestore.collection('users').doc(uid).update({'last_login_at': FieldValue.serverTimestamp()})`
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Pengambil (*getter*) instance pengguna Firebase Auth yang sedang aktif login.
  User? get currentUser => _auth.currentUser;

  /// Stream untuk memantau perubahan status autentikasi pengguna secara *real-time*.
  Stream<User?> get userChanges => _auth.userChanges();

  /// Fungsi: Mengambil data akun Google pengguna melalui alur interaktif *Google Sign-In*.
  Future<GoogleSignInAccount?> getGoogleAccountData() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      final googleUser = await _googleSignIn.signIn();
      return googleUser;
    } catch (e) {
      debugPrint("🔥 Error Get Google Account: $e");
      return null;
    }
  }

  /// Fungsi: Mendaftarkan akun baru menggunakan Email & Password serta menyimpan profil awal pengguna di Firestore.
  /// Operasi CRUD (Create):
  /// - Membuat kredensial Auth: `_auth.createUserWithEmailAndPassword(email: email, password: password)`
  /// - Menyimpan dokumen profil awal di Firestore: `_firestore.collection('users').doc(uid).set({...})`
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'fcm_token': null,
        'status': role == 'driver' ? 'offline' : null,
        'createdAt': FieldValue.serverTimestamp(),
        'last_login_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint("🔥 Register error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("🔥 Unexpected error during register: $e");
      rethrow;
    }
  }

  /// Fungsi: Autentikasi masuk pengguna yang sudah terdaftar dengan Email dan Password.
  Future<UserCredential?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint("🔥 Login error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("🔥 Unexpected error during login: $e");
      rethrow;
    }
  }

  /// Fungsi: Mengeluarkan (*sign out*) pengguna dari sesi Firebase Auth aktif.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint("🔥 Logout error: $e");
      rethrow;
    }
  }

  /// Fungsi: Membaca hak akses (*role*) pengguna yang sedang login dari dokumen Firestore sebanyak satu kali.
  /// Operasi CRUD (Read Single Doc):
  /// - Sintaks: `_firestore.collection('users').doc(uid).get()`
  Future<String?> getUserRoleOnce() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!doc.exists) return null;

      final role = doc.data()?['role'] as String?;
      if (role == 'user' || role == 'driver') return role;

      return null;
    } catch (e) {
      debugPrint("🔥 getUserRoleOnce error: $e");
      return null;
    }
  }

  /// Fungsi: Memperbarui atau menyimpan token notifikasi FCM perangkat pengguna di Firestore.
  /// Operasi CRUD (Update / Set Merge):
  /// - Sintaks: `_firestore.collection('users').doc(uid).set({'fcm_token': token}, SetOptions(merge: true))`
  Future<void> updateFcmToken(String token) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'fcm_token': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("🔥 updateFcmToken error: $e");
    }
  }

  /// Fungsi: Memperbarui status aktif/nonaktif (*online/offline*) khusus pengguna bertipe driver di Firestore.
  /// Operasi CRUD (Update):
  /// - Sintaks: `_firestore.collection('users').doc(uid).update({'status': status})`
  Future<void> setDriverStatus(String status) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'status': status,
      });
    } catch (e) {
      debugPrint("🔥 setDriverStatus error: $e");
    }
  }

  /// Fungsi: Mendengarkan perubahan data profil pengguna dari Firestore secara *real-time*.
  /// Operasi CRUD (Read Stream):
  /// - Sintaks: `_firestore.collection('users').doc(uid).snapshots()`
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Fungsi: Memperbarui stempel waktu login terakhir pengguna (*last login timestamp*).
  /// Operasi CRUD (Update Field):
  /// - Sintaks: `_firestore.collection('users').doc(uid).update({'last_login_at': FieldValue.serverTimestamp()})`
  Future<void> updateLastLogin() async {
    if (_auth.currentUser == null) return;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'last_login_at': FieldValue.serverTimestamp(),
    });
  }
}
