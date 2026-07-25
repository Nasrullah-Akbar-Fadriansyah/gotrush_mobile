import 'package:cloud_firestore/cloud_firestore.dart';

// Kelas untuk merepresentasikan data satu item pesan chat
class ChatMessage {
  final String id; // ID unik pesan
  final String orderId; // ID order yang terkait dengan chat ini
  final String senderId; // ID pengguna/driver yang mengirim pesan
  final String senderRole; // Peran pengirim (misal: 'user' atau 'driver')
  final String message; // Teks isi pesan

  final Timestamp createdAt; // Waktu pesan dikirim
  final Timestamp? readAt; // Waktu pesan dibaca (bisa null jika belum dibaca)

  final String type; // Tipe pesan ('text', 'location', atau 'image')
  final double? latitude; // Koordinat Latitude (jika pesan berupa kirim lokasi)
  final double?
  longitude; // Koordinat Longitude (jika pesan berupa kirim lokasi)

  // Constructor utama untuk membuat objek ChatMessage di Dart
  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.type = 'text', // Nilai bawaan (default) adalah 'text'
    this.latitude,
    this.longitude,
  });

  // [READ PROCESS] Pabrik konversi dari Map (JSON Firestore) menjadi Objek ChatMessage
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      orderId: map['orderId'],
      senderId: map['senderId'],
      senderRole: map['senderRole'],
      message: map['message'],
      createdAt: map['createdAt'],
      readAt: map['readAt'],
      type: map['type'] ?? 'text', // Kalau tipe kosong, otomatis isi 'text'
      latitude: map['latitude']?.toDouble(), // Konversi aman angka ke double
      longitude: map['longitude']?.toDouble(),
    );
  }

  // [CREATE / UPDATE PROCESS] Mengubah Objek ChatMessage menjadi Map agar bisa disimpan ke Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'senderId': senderId,
    'senderRole': senderRole,
    'message': message,
    'createdAt': createdAt,
    'readAt': readAt,
    'type': type,
    'latitude': latitude,
    'longitude': longitude,
  };
}
