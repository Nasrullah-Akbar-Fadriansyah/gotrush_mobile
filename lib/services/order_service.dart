import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fungsi: Layanan Manajemen Operasional Transaksi dan Siklus Hidup Pesanan (Order Service).
/// Cara Kerja:
/// 1. Mengelola seluruh tahapan pesanan penjemputan sampah dari pembuatan awal, klaim order oleh driver, negosiasi & konfirmasi berat, pembayaran, konfirmasi tiba/penjemputan, hingga penyelesaian & pengarsipan.
/// 2. Memanfaatkan fitur **WriteBatch** untuk menuliskan data secara bersamaan ke dua koleksi (`orders` dan `order_history`) agar data riwayat tidak pernah ketinggalan.
/// 3. Memanfaatkan **Firestore Transactions** (`runTransaction`) pada operasi kritis (seperti `acceptOrder` atau `confirmWeightByUser`) untuk mencegah bentrokan data (*race condition*) antar pengguna/driver.
///
/// Operasi CRUD (Create, Read Stream/Single, Update Batch/Transaction, & Archive):
/// - Create (WriteBatch):
///   - Membuat dokumen order baru di koleksi `orders` dan `order_history`:
///     `batch.set(orderRef, data); batch.set(historyRef, {...}); await batch.commit();`
/// - Read (Stream Queries & Get):
///   - Membaca daftar order aktif/penjemputan driver via Stream:
///     `_db.collection('orders').where("status", whereIn: visible).snapshots()`
///   - Membaca data lengkap satu order: `_db.collection("orders").doc(orderId).get()`
/// - Update (Transactions & Batches):
///   - Mengambil orderan secara aman: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true))`
///   - Mengajukan berat, mengonfirmasi penjemputan, dan mengubah status pembayaran.
/// - Delete / Archive (Logical Delete / Status Update):
///   - Menandai dokumen pesanan sebagai terarsip (`archived: true`):
///     `batch.update(orderRef, {"archived": true, "archived_at": FieldValue.serverTimestamp()})`
class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fungsi: Membuat atau menambahkan pesanan (*order*) baru ke dalam database Cloud Firestore secara bersamaan (*atomic batch*).
  /// Cara Kerja:
  /// 1. Menerima data masukan lengkap mengenai detail pesanan sampah dari pengguna (berat, jarak, harga, alamat, koordinat GPS, foto, nama, dan telepon).
  /// 2. Menyusun data ke dalam objek `Map` bernama `data`, serta menambahkan status default `payment_status: "pending"` dan stempel waktu server.
  /// 3. Menggunakan `WriteBatch` (`_db.batch()`) untuk mengelompokkan perintah tulis ke dua koleksi (`orders` dan `order_history`) secara serentak.
  /// Operasi CRUD (Create Batch):
  /// - Sintaks: `batch.set(orderRef, data); batch.set(historyRef, data); await batch.commit();`
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

  /// Fungsi: Mengubah status pesanan ketika driver mengambil atau menerima orderan (`accept order`) secara aman.
  /// Cara Kerja:
  /// 1. Menggunakan **Transaction** (`_db.runTransaction`) untuk membaca kondisi terkini sebelum menulis.
  /// 2. Memastikan status order masih `'pending'`. Jika sudah diambil driver lain, transaksi membatalkan proses dan mengembalikan `false`.
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
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

  /// Fungsi: Memperbarui status tahapan pesanan dan menyinkronkan data ke koleksi riwayat via `WriteBatch`.
  /// Operasi CRUD (Update Batch):
  /// - Sintaks: `batch.update(orderRef, update); batch.set(historyRef, merged, SetOptions(merge: true)); await batch.commit();`
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

  /// Fungsi: Menambahkan URL foto bukti penjemputan selesai dan mengubah status menjadi `completed`.
  /// Operasi CRUD (Update Field Array & Set History):
  /// - Sintaks: `batch.update(orderRef, {'photo_urls': FieldValue.arrayUnion([photoUrl]), ...}); await batch.commit();`
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

  /// Fungsi Internal: Menandai dokumen pesanan sebagai terarsip (`archived: true`).
  /// Operasi CRUD (Update Archive Flag):
  /// - Sintaks: `batch.update(orderRef, {'archived': true, ...}); await batch.commit();`
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

  /// Fungsi: Mengambil aliran (*stream*) daftar pesanan yang dapat dilihat oleh driver berdasarkan kriteria status.
  /// Operasi CRUD (Read Stream Query):
  /// - Sintaks: `_db.collection('orders').where("status", whereIn: visible).snapshots()`
  Stream<QuerySnapshot> driverOrders({List<String>? statuses}) {
    final List<String> visible = statuses ?? ['pending'];
    return _db
        .collection('orders')
        .where("status", whereIn: visible)
        .snapshots();
  }

  /// Fungsi Helper: Membaca dokumen lengkap pesanan satu kali dari koleksi `orders`.
  /// Operasi CRUD (Read Single Document):
  /// - Sintaks: `_db.collection("orders").doc(orderId).get()`
  Future<Map<String, dynamic>> _getFullOrderData(String orderId) async {
    final doc = await _db.collection("orders").doc(orderId).get();
    return Map<String, dynamic>.from(doc.data() ?? {});
  }

  /// Fungsi: Mengajukan estimasi berat sampah baru oleh driver (*propose weight*).
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> proposeWeight({
    required String orderId,
    required String driverId,
    required double weight,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      final update = {
        'driver_weight': weight,
        'weight_status': 'proposed',
        'weight_proposed_at': FieldValue.serverTimestamp(),
        'status': 'awaiting_confirmation',
        'updated_at': FieldValue.serverTimestamp(),
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Mengonfirmasi perubahan berat sampah oleh pengguna dan mengalkulasi ulang total biaya transaksi.
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> confirmWeightByUser({
    required String orderId,
    required String userId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
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
      final update = {
        'final_weight': driverWeight,
        'price': newPrice,
        'price_paid': newPrice,
        'weight_status': 'approved',
        'status': 'waiting_payment',
        'updated_at': FieldValue.serverTimestamp(),
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Mengajukan sanggahan/sengketa (*dispute*) berat sampah oleh pengguna.
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> disputeWeightByUser({
    required String orderId,
    required String userId,
    String? note,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['user_id'] ?? '') != userId) {
        throw Exception('User tidak berhak pada order ini');
      }
      final update = <String, dynamic>{
        'weight_status': 'disputed',
        'status': 'active',
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (note != null && note.isNotEmpty) {
        update['weight_note'] = note;
      }
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Menandai pembayaran sukses dan memperbarui status pesanan menjadi validasi penjemputan (`pickup_validation`).
  /// Operasi CRUD (Update Batch):
  /// - Sintaks: `batch.update(orderRef, update); batch.set(historyRef, update, SetOptions(merge: true)); await batch.commit();`
  Future<void> markPaymentSuccessToPickupValidation({
    required String orderId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);
    final update = {
      'payment_status': 'success',
      'status': 'pickup_validation',
      'updated_at': FieldValue.serverTimestamp(),
    };
    final batch = _db.batch();
    batch.update(orderRef, update);
    batch.set(historyRef, update, SetOptions(merge: true));
    await batch.commit();
  }

  /// Fungsi: Konfirmasi oleh driver bahwa sampah telah diambil dan menunggu validasi dari pengguna.
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> driverConfirmPickup({
    required String orderId,
    required String driverId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      final update = {
        'status': 'waiting_user_validation',
        'pickup_requested_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Mengembalikan (*reset*) status penjemputan driver kembali ke status `arrived`.
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> driverResetPickupConfirmation({
    required String orderId,
    required String driverId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      final update = {
        'status': 'arrived',
        'updated_at': FieldValue.serverTimestamp(),
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Merespons permintaan validasi penjemputan dari pengguna (mengonfirmasi atau menolak).
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> userRespondPickupValidation({
    required String orderId,
    required String userId,
    required bool confirmed,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['user_id'] ?? '') != userId) {
        throw Exception('User tidak berhak pada order ini');
      }
      final update = confirmed
          ? {
              'status': 'picked_up',
              'picked_up_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            }
          : {'status': 'arrived', 'updated_at': FieldValue.serverTimestamp()};
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Menandai bahwa driver telah tiba di lokasi penjemputan pengguna (`arrived`).
  /// Operasi CRUD (Update Transaction):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> driverArrived({
    required String orderId,
    required String driverId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      final update = {
        'status': 'arrived',
        'arrived_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
  }

  /// Fungsi: Menandai transaksi pesanan telah selesai penuh oleh driver (`completed`) lalu mengarsipkannya.
  /// Operasi CRUD (Update Transaction & Auto Archive):
  /// - Sintaks: `tx.update(orderRef, update); tx.set(historyRef, update, SetOptions(merge: true));`
  Future<void> driverCompleteOrder({
    required String orderId,
    required String driverId,
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final historyRef = _db.collection('order_history').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if ((data['driver_id'] ?? '') != driverId) {
        throw Exception('Driver tidak berhak mengubah order ini');
      }
      final update = {
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'timestamp_end': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'hidden_by_user': false,
        'hidden_by_driver': false,
      };
      tx.update(orderRef, update);
      tx.set(historyRef, update, SetOptions(merge: true));
    });
    await _archiveOrder(orderId);
  }

  /// Fungsi: Mengambil aliran (*stream*) daftar pesanan masuk khusus untuk hari ini yang belum memiliki driver.
  /// Operasi CRUD (Read Stream Filtered Query):
  /// - Sintaks:
  ///   ```dart
  ///   _db.collection('orders')
  ///       .where('status', whereIn: visible)
  ///       .where('driver_id', isNull: true)
  ///       .where('pickup_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
  ///       .where('pickup_date', isLessThan: Timestamp.fromDate(endOfDay))
  ///       .snapshots();
  ///   ```
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
