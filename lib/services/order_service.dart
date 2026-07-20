import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fungsi: Membuat atau menambahkan pesanan (*order*) baru ke dalam database Cloud Firestore secara bersamaan (*atomic batch*).
  /// Cara Kerja:
  /// 1. Menerima data masukan (parameter) lengkap mengenai detail pesanan sampah dari pengguna (seperti berat, jarak, harga, alamat, koordinat GPS, foto, nama, dan nomor telepon).
  /// 2. Menyusun data tersebut ke dalam struktur objek `Map` (JSON) bernama `data`, serta menambahkan informasi default seperti `payment_status: "pending"`, status arsip, dan stempel waktu server (`FieldValue.serverTimestamp()`).
  /// 3. Menggunakan fitur `WriteBatch` (`_db.batch()`) milik Firestore. Fitur ini mengelompokkan beberapa perintah tulis menjadi satu baris transaksi aman (*All-or-Nothing*).
  /// 4. Menyiapkan dua target dokumen baru dengan ID pesanan yang sama (`orderId`), yaitu pada tabel/koleksi `'orders'` dan koleksi rekam jejak `'order_history'`.
  /// 5. Menuliskan data tersebut ke kedua koleksi secara serentak melalui perintah `batch.commit()`. Jika salah satu gagal (misal koneksi terputus di tengah jalan), maka kedua data tersebut dibatalkan secara otomatis agar database tetap konsisten dan tidak korup
  Future<void> createOrder({
    required String orderId,
    required String userId,
    required double weight,
    required double distance,
    required double price,
    required String address,
    required GeoPoint location,
    required List<String> photoUrls,
    required String status,
    DateTime? pickupDate,
    required String name,
    required String phoneNumber,
  }) async {
    final now = FieldValue.serverTimestamp();

    final data = {
      "order_id": orderId,
      "user_id": userId,
      "driver_id": null,
      "status": status,
      "payment_status": "pending",
      "weight": weight,
      "distance": distance,
      "price": price,
      "price_paid": price,
      "address": address,
      "location": location,
      "photo_urls": photoUrls,
      "pickup_date": pickupDate != null
          ? Timestamp.fromDate(pickupDate)
          : FieldValue.serverTimestamp(),
      "created_at": now,
      "updated_at": now,
      "archived": false,
      "name": name,
      "phone_number": phoneNumber,
      "hidden_by_user": false,
      "hidden_by_driver": false,
    };

    final batch = _db.batch();
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    batch.set(orderRef, data);
    batch.set(historyRef, {...data, "archived_at": null, "completed_at": null});

    await batch.commit();
  }

  /// Fungsi: Mengubah status pesanan ketika driver mengambil atau menerima orderan (`accept order`).
  /// Fungsi ini mengembalikan nilai boolean (`true` jika berhasil diambil oleh driver, atau `false` jika gagal).
  /// Cara Kerja:
  /// 1. Menentukan referensi dokumen pesanan di koleksi `'orders'` dan `'order_history'` berdasarkan `orderId`.
  /// 2. Menggunakan sistem **Transaction** (`_db.runTransaction`). Berbeda dengan batch, transaksi ini membaca data server terlebih dahulu untuk memastikan kondisi terkini sebelum menulis. Ini sangat krusial agar orderan tidak bisa "berebutan" atau diambil oleh dua driver sekaligus (*Race Condition*).
  /// 3. Di dalam transaksi, aplikasi mengambil (*get*) data pesanan terbaru dari server.
  /// 4. Melakukan validasi status: Jika pesanan tidak ada atau statusnya sudah berubah (bukan `'pending'` lagi, misalnya sudah diambil driver lain), transaksi langsung dibatalkan dan mengembalikan nilai `false`.
  /// 5. Jika status lolos validasi (masih `'pending'`), transaksi akan memperbarui data dokumen dengan memasukkan `driver_id` penjemput, mengubah status menjadi `'active'`, serta mencatat waktu `accepted_at`.
  /// 6. Menulis perubahan tersebut ke koleksi `'orders'` dan menggabungkannya (*merge*) ke `'order_history'`, lalu mengembalikan nilai `true`. Jika ada kendala jaringan, proses otomatis dialihkan ke blok `catch` dan mengembalikan nilai `false`.
  Future<bool> acceptOrder(String orderId, String driverId) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    final List<String> allowedAcceptStatuses = ['pending'];

    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(orderRef);
        if (!snap.exists) return false;

        final status = (snap.data()?['status'] ?? "").toString();

        if (!allowedAcceptStatuses.contains(status)) {
          debugPrint(
            "acceptOrder: status '$status' not allowed for acceptance",
          );
          return false;
        }

        final update = {
          "driver_id": driverId,
          "status": "active",
          "accepted_at": FieldValue.serverTimestamp(),
          "updated_at": FieldValue.serverTimestamp(),
        };

        tx.update(orderRef, update);
        tx.set(historyRef, update, SetOptions(merge: true));

        return true;
      });
    } catch (e) {
      debugPrint("🔥 acceptOrder error: $e");
      return false;
    }
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    final now = FieldValue.serverTimestamp();
    final fullData = await _getFullOrderData(orderId);

    final update = {"status": newStatus, "updated_at": now};

    if (newStatus == "completed") {
      update["completed_at"] = now;
      update["timestamp_end"] = now;
    }

    final merged = {...fullData, ...update};

    final batch = _db.batch();
    batch.update(orderRef, update);
    batch.set(historyRef, merged, SetOptions(merge: true));
    await batch.commit();

    if (newStatus == "completed") {
      await _archiveOrder(orderId);
    }
  }

  Future<void> addCompletionPhoto(String orderId, String photoUrl) async {
    final fullData = await _getFullOrderData(orderId);

    final update = {
      "photo_urls": FieldValue.arrayUnion([photoUrl]),
      "status": "completed",
      "completed_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    };

    final merged = {...fullData, ...update};

    final batch = _db.batch();
    batch.update(_db.collection('orders').doc(orderId), update);
    batch.set(
      _db.collection('order_history').doc(orderId),
      merged,
      SetOptions(merge: true),
    );
    await batch.commit();

    await _archiveOrder(orderId);
  }

  Future<void> _archiveOrder(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    final snap = await orderRef.get();
    if (!snap.exists) return;

    final update = {
      "archived": true,
      "archived_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.update(orderRef, update);
    batch.set(historyRef, update, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<QuerySnapshot> driverOrders({List<String>? statuses}) {
    final List<String> visible = statuses ?? ['pending'];
    return _db
        .collection('orders')
        .where("status", whereIn: visible)
        .snapshots();
  }

  Future<Map<String, dynamic>> _getFullOrderData(String orderId) async {
    final doc = await _db.collection("orders").doc(orderId).get();
    return Map<String, dynamic>.from(doc.data() ?? {});
  }

  Future<void> proposeWeight({
    required String orderId,
    required String driverId,
    required double weight,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      tx.update(ref, {
        'driver_weight': weight,
        'weight_status': 'proposed',
        'weight_proposed_at': FieldValue.serverTimestamp(),
        'status': 'awaiting_confirmation',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> confirmWeightByUser({
    required String orderId,
    required String userId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['user_id'] ?? '') != userId) {
        throw Exception('User tidak berhak pada order ini');
      }
      final driverWeight = (data['driver_weight'] ?? 0).toDouble();
      const double pricePerKm = 1000;
      const double pricePerKg = 1000;
      final distance = (data['distance'] ?? 0).toDouble();
      final newPrice = (distance * pricePerKm) + (driverWeight * pricePerKg);
      tx.update(ref, {
        'final_weight': driverWeight,
        'price': newPrice,
        'price_paid': newPrice,
        'weight_status': 'approved',
        'status': 'waiting_payment',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> disputeWeightByUser({
    required String orderId,
    required String userId,
    String? note,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['user_id'] ?? '') != userId) {
        throw Exception('User tidak berhak pada order ini');
      }
      final update = {
        'weight_status': 'disputed',
        'status': 'active',
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (note != null && note.isNotEmpty) {
        update['weight_note'] = note;
      }
      tx.update(ref, update);
    });
  }

  Future<void> markPaymentSuccessToPickupValidation({
    required String orderId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await ref.update({
      'payment_status': 'success',
      'status': 'pickup_validation',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> driverConfirmPickup({
    required String orderId,
    required String driverId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      tx.update(ref, {
        'status': 'waiting_user_validation',
        'pickup_requested_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> driverResetPickupConfirmation({
    required String orderId,
    required String driverId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      tx.update(ref, {
        'status': 'arrived',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> userRespondPickupValidation({
    required String orderId,
    required String userId,
    required bool confirmed,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['user_id'] ?? '') != userId) {
        throw Exception('User tidak berhak pada order ini');
      }
      if (confirmed) {
        tx.update(ref, {
          'status': 'picked_up',
          'picked_up_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, {
          'status': 'arrived',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> driverArrived({
    required String orderId,
    required String driverId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      tx.update(ref, {
        'status': 'arrived',
        'arrived_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> driverCompleteOrder({
    required String orderId,
    required String driverId,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      tx.update(ref, {
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'timestamp_end': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'hidden_by_user': false,
        'hidden_by_driver': false,
      });
    });
    await _archiveOrder(orderId);
  }

  Stream<QuerySnapshot> driverTodayOrders({List<String>? statuses}) {
    final List<String> visible = statuses ?? ['pending'];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('orders')
        .where('status', whereIn: visible)
        .where('driver_id', isNull: true)
        .where(
          'pickup_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('pickup_date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }
}
