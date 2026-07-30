import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Tempat semua urusan notifikasi dikumpulkan.
/// Jadi file lain cukup memanggil service ini tanpa perlu tahu detail FCM.
class NotificationService {
  // Constructor dibuat private supaya object ini tidak bisa dibuat sembarangan.
  NotificationService._private();

  // Kita hanya butuh satu NotificationService selama aplikasi berjalan.
  static final NotificationService _instance = NotificationService._private();

  // Kalau ada yang memanggil NotificationService(),
  // selalu kembalikan object yang sama.
  factory NotificationService() => _instance;

  // Plugin yang dipakai untuk menampilkan notifikasi lokal.
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Menyiapkan semua kebutuhan notifikasi saat aplikasi pertama kali dijalankan.
  Future<void> init({required AuthService authService}) async {
    // Mengambil instance Firebase Messaging.
    final fcm = FirebaseMessaging.instance;

    // Minta izin ke pengguna untuk menampilkan notifikasi.
    final settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Kalau pengguna mengizinkan...
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Ambil FCM Token milik perangkat.
      final token = await fcm.getToken();
      // Token ini nanti dipakai server untuk mengirim notifikasi
      // ke perangkat yang benar.
      if (token != null) {
        await authService.updateFcmToken(token);
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final n = message.notification;
      if (n != null) {
        const androidDetails = AndroidNotificationDetails(
          'sampah_channel',
          'Sampah Notifications',
          channelDescription: 'Notifikasi aplikasi sampah_online',
          importance: Importance.max,
          priority: Priority.high,
        );
        const details = NotificationDetails(android: androidDetails);
        final id = safeId(
          'fcm_${n.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
        );
        await _local.show(
          id,
          n.title,
          n.body,
          details,
          payload: message.data.toString(),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.data}');
    });
  }

  Future<void> showLocal({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sampah_channel',
      'Sampah Notifications',
      channelDescription: 'Notifikasi aplikasi sampah_online',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(id, title, body, details);
  }

  int safeId(Object seed) => (seed.hashCode & 0x7fffffff);

  Future<void> notifyDriverPaymentSuccess({
    required String orderId,
    required String driverId,
  }) async {
    await showLocal(
      id: safeId('driver_payment_$orderId'),
      title: 'Pembayaran Berhasil',
      body: 'Order $orderId telah dibayar. Silakan konfirmasi pengambilan.',
    );
  }

  Future<void> notifyUserPickupRequested({
    required String orderId,
    required String userId,
  }) async {
    await showLocal(
      id: safeId('user_pickup_$orderId'),
      title: 'Konfirmasi Pengambilan',
      body:
          'Driver mengonfirmasi pengambilan untuk order $orderId. Apakah sampah sudah diambil?',
    );
  }

  Future<void> notifyUserDriverArrived({
    required String orderId,
    required String userId,
  }) async {
    await showLocal(
      id: safeId('user_arrived_$orderId'),
      title: 'Driver Tiba di Lokasi',
      body: 'Driver telah tiba untuk order $orderId. Siapkan pengambilan.',
    );
  }

  Future<void> notifyBothCompleted({
    required String orderId,
    required String userId,
    required String driverId,
  }) async {
    await showLocal(
      id: safeId('completed_user_$orderId'),
      title: 'Terima kasih',
      body:
          'Order $orderId selesai. Terima kasih telah menggunakan layanan kami.',
    );
    await showLocal(
      id: safeId('completed_driver_$orderId'),
      title: 'Order Selesai',
      body: 'Order $orderId telah dikonfirmasi selesai oleh user.',
    );
  }
}
