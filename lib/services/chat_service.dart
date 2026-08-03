import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

/// Fungsi: Layanan Komunikasi dan Olah Pesan Percakapan *Real-Time* (Chat Service).
/// Cara Kerja:
/// 1. Mengirim pesan teks atau pesan lokasi geografis antar pengguna dan driver pada sub-koleksi `messages` di dalam dokumen order tertentu.
/// 2. Menggunakan **Firestore Transactions** (`runTransaction`) untuk memastikan penulisan pesan, pembaruan metadata `last_message`, dan penambahan penghitung pesan belum dibaca (`unread_count`) berjalan secara *atomic*.
/// 3. Memantau aliran pesan masuk secara berurutan berdasarkan waktu kirim (`createdAt`).
/// 4. Menyediakan metode untuk menandai pesan sudah dibaca (`readAt`) dan mereset jumlah pesan belum dibaca.
///
/// Operasi CRUD (Create Transaction, Read Stream, & Update):
/// - Create & Update Transaction (Pesan Teks / Lokasi):
///   - Menulis dokumen pesan ke sub-koleksi: `tx.set(messageRef, chatMessage.toMap())`
///   - Memperbarui pratinjau pesan terakhir di dokumen order: `tx.set(orderRef, {'last_message': ...}, SetOptions(merge: true))`
///   - Menambahkan penghitung pesan belum dibaca (*unread counter*): `tx.set(metaRef, {'unread_driver': FieldValue.increment(1)}, SetOptions(merge: true))`
/// - Read Stream (Daftar Pesan):
///   - Mengambil aliran pesan *real-time* yang diurutkan dari terbaru: `_firestore.collection('orders').doc(orderId).collection('messages').orderBy('createdAt', descending: true).snapshots()`
/// - Update (Tanda Dibaca & Reset Counter):
///   - Memperbarui waktu baca pesan: `messageRef.update({'readAt': Timestamp.now()})`
///   - Mengosongkan penghitung pesan belum dibaca: `metaRef.set({'unread_user': 0}, SetOptions(merge: true))`
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fungsi: Mengirim pesan berupa teks biasa ke dalam percakapan pesanan secara *atomic transaction*.
  /// Operasi CRUD (Create & Update Transaction):
  /// - Sintaks: `_firestore.runTransaction((tx) async {...})`
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderRole,
    required String message,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final messageRef = orderRef.collection('messages').doc();

    final now = Timestamp.now();

    final chatMessage = ChatMessage(
      id: messageRef.id,
      orderId: orderId,
      senderId: senderId,
      senderRole: senderRole,
      message: message,
      createdAt: now,
      readAt: null,
    );

    await _firestore.runTransaction((tx) async {
      tx.set(messageRef, chatMessage.toMap());

      tx.set(orderRef, {
        'last_message': {
          'text': message,
          'sender_role': senderRole,
          'created_at': now,
          'type': 'text',
        },
      }, SetOptions(merge: true));

      final metaRef = orderRef.collection('chat_meta').doc('meta');

      if (senderRole == 'user') {
        tx.set(metaRef, {
          'unread_driver': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else {
        tx.set(metaRef, {
          'unread_user': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Fungsi: Mengirimkan koordinat lokasi terkini dalam bentuk pesan khusus (*type: location*) secara *atomic transaction*.
  /// Operasi CRUD (Create & Update Transaction):
  /// - Sintaks: `_firestore.runTransaction((tx) async {...})`
  Future<void> sendLocation({
    required String orderId,
    required String senderId,
    required String senderRole,
    required double latitude,
    required double longitude,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final messageRef = orderRef.collection('messages').doc();

    final now = Timestamp.now();

    final chatMessage = ChatMessage(
      id: messageRef.id,
      orderId: orderId,
      senderId: senderId,
      senderRole: senderRole,
      message: 'Lokasi Saya',
      createdAt: now,
      readAt: null,
      type: 'location',
      latitude: latitude,
      longitude: longitude,
    );

    await _firestore.runTransaction((tx) async {
      tx.set(messageRef, chatMessage.toMap());

      tx.set(orderRef, {
        'last_message': {
          'text': '📍 Lokasi Dibagikan',
          'sender_role': senderRole,
          'created_at': now,
          'type': 'location',
        },
      }, SetOptions(merge: true));

      final metaRef = orderRef.collection('chat_meta').doc('meta');

      if (senderRole == 'user') {
        tx.set(metaRef, {
          'unread_driver': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else {
        tx.set(metaRef, {
          'unread_user': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Fungsi: Mendengarkan aliran (*stream*) seluruh pesan percakapan untuk order tertentu secara *real-time*.
  /// Operasi CRUD (Read Stream):
  /// - Sintaks: `_firestore.collection('orders').doc(orderId).collection('messages').orderBy('createdAt', descending: true).snapshots()`
  Stream<QuerySnapshot> getMessages(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fungsi: Menandai dokumen pesan tertentu telah dibaca dengan mencatat stempel waktu `readAt`.
  /// Operasi CRUD (Update Field):
  /// - Sintaks: `messageRef.update({'readAt': Timestamp.now()})`
  Future<void> markAsRead(String orderId, String messageId) async {
    final messageRef = _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .doc(messageId);
    await messageRef.update({'readAt': Timestamp.now()});
  }

  /// Fungsi: Mengosongkan (*reset*) jumlah akumulasi pesan belum dibaca sesuai dengan *role* pengguna.
  /// Operasi CRUD (Update / Set Merge):
  /// - Sintaks: `metaRef.set({'unread_user': 0}, SetOptions(merge: true))`
  Future<void> resetUnreadCounter(String orderId, String role) async {
    final metaRef = _firestore
        .collection('orders')
        .doc(orderId)
        .collection('chat_meta')
        .doc('meta');

    if (role == 'user') {
      await metaRef.set({'unread_user': 0}, SetOptions(merge: true));
    } else {
      await metaRef.set({'unread_driver': 0}, SetOptions(merge: true));
    }
  }
}
