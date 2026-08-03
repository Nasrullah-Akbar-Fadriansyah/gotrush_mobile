import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

/// Fungsi: Antarmuka percakapan (Chat Room) real-time antara Pengguna dan Driver terkait pesanan tertentu.
/// Cara Kerja:
/// 1. Saat inisialisasi (`initState`), memanggil `_resetUnreadCounter` untuk mereset jumlah pesan belum dibaca.
/// 2. Merender daftar pesan secara *real-time* dari Firestore sub-koleksi pesan menggunakan `StreamBuilder`.
/// 3. Otomatis menandai pesan dari lawan bicara sebagai "dibaca" (`markAsRead`) saat pesan muncul di layar.
/// 4. Memfasilitasi pengiriman pesan teks biasa maupun koordinat lokasi GPS fisik (berupa alamat lengkap dan tombol Google Maps).
///
/// Operasi CRUD (Read, Create, Update):
/// - Read (Stream): Mengambil daftar pesan real-time berdasarkan `orderId` via `_chatService.getMessages(orderId)`.
///   - Sintaks: `FirebaseFirestore.instance.collection('orders').doc(orderId).collection('messages').orderBy('timestamp', descending: true).snapshots()`
/// - Create (Insert): Mengirim pesan teks via `_sendMessage()` atau kirim lokasi via `_sendLocation()`.
///   - Sintaks: `collection('messages').add(...)`
/// - Update: Memperbarui status baca pesan (`readAt`) dan memperbarui metadata unread counter via `_chatService.markAsRead()`.
///   - Sintaks: `collection('messages').doc(messageId).update({'readAt': FieldValue.serverTimestamp()})`
class ChatScreen extends StatefulWidget {
  final String orderId;
  final String otherUserName;
  final String currentUserRole;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.otherUserName,
    required this.currentUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetUnreadCounter();
    });
  }

  /// Fungsi: Mereset jumlah pesan yang belum dibaca (unread count) untuk pengguna saat ini.
  /// Cara Kerja: Memanggil method `resetUnreadCounter` pada layanan `_chatService` dengan menyertakan `orderId` dan peran pengguna.
  /// Operasi CRUD (Update):
  /// - Memperbarui field counter `unread_user` atau `unread_driver` menjadi 0 pada dokumen metadata percakapan.
  ///   - Sintaks: `doc(orderId).collection('chat_meta').doc('meta').update({'unread_user': 0})`
  void _resetUnreadCounter() async {
    await _chatService.resetUnreadCounter(
      widget.orderId,
      widget.currentUserRole,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fungsi: Mengirimkan pesan teks baru dari input pengguna ke server Firebase.
  /// Cara Kerja:
  /// 1. Mengambil teks dari `_messageController`, memvalidasi agar tidak kosong.
  /// 2. Mengambil ID pengguna aktif dari `AuthService`.
  /// 3. Mengosongkan field input, lalu memanggil `_chatService.sendMessage`.
  /// 4. Memicu animasi *scroll* ke bagian bawah layar chat (`_scrollToBottom`).
  /// Operasi CRUD (Create & Update):
  /// - Create: Menambahkan dokumen baru ke sub-koleksi `messages`.
  ///   - Sintaks: `collection('orders').doc(orderId).collection('messages').add(messageData)`
  /// - Update: Mengatur atribut pesan terakhir (`lastMessage`) dan menambah counter `unread` lawan bicara di dokumen induk/meta.
  ///   - Sintaks: `doc(orderId).update({'last_message': text, 'chat_meta.unread_driver': FieldValue.increment(1)})`
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    _messageController.clear();

    await _chatService.sendMessage(
      orderId: widget.orderId,
      senderId: user.uid,
      senderRole: widget.currentUserRole,
      message: text,
    );

    _scrollToBottom();
  }

  /// Fungsi: Mengonversi koordinat latitude & longitude menjadi nama jalan/alamat manusiawi (Reverse Geocoding).
  /// Cara Kerja: Memanggil fungsi `placemarkFromCoordinates` dari paket `geocoding`, lalu menyusun string alamat berdasarkan nama jalan, kelurahan, dan kecamatan.
  Future<String> _getAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        return "${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}";
      }

      return "Alamat tidak ditemukan";
    } catch (e) {
      return "Alamat tidak tersedia";
    }
  }

  /// Fungsi: Mengambil posisi lokasi GPS saat ini dan mengirimkannya sebagai pesan tipe lokasi.
  /// Cara Kerja:
  /// 1. Menguji dan meminta izin akses lokasi ke perangkat (`Geolocator.requestPermission`).
  /// 2. Mengambil posisi koordinat terkini (`Geolocator.getCurrentPosition`).
  /// 3. Mengirimkan latitude dan longitude melalui `_chatService.sendLocation`.
  /// Operasi CRUD (Create):
  /// - Menambahkan dokumen pesan tipe lokasi ke Firestore.
  ///   - Sintaks: `collection('messages').add({'type': 'location', 'latitude': lat, 'longitude': lng, ...})`
  Future<void> _sendLocation() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await _chatService.sendLocation(
      orderId: widget.orderId,
      senderId: user.uid,
      senderRole: widget.currentUserRole,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    _scrollToBottom();
  }

  /// Fungsi: Membuka aplikasi eksternal Google Maps berdasarkan koordinat latitude & longitude.
  /// Cara Kerja: Mengonversi URL query Google Maps, mengecek kemampuan perangkat (`canLaunchUrl`), lalu membukanya di aplikasi peta luar via `launchUrl`.
  Future<void> _openMap(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Fungsi: Menggulirkan daftar pesan ke posisi paling bawah (pesan terbaru).
  /// Cara Kerja: Menggunakan `_scrollController.animateTo` menuju `minScrollExtent` karena `ListView` diset dengan `reverse: true`.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat dengan ${widget.otherUserName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada pesan'));
                }

                final messages = snapshot.data!.docs
                    .map(
                      (doc) => ChatMessage.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                // Memeriksa dan memperbarui status read pesan dari lawan bicara
                for (var msg in messages) {
                  if (msg.senderRole != widget.currentUserRole &&
                      msg.readAt == null) {
                    _chatService.markAsRead(widget.orderId, msg.id);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg.senderRole == widget.currentUserRole;
                    return _messageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  /// Widget Builder: Memilih tampilan balok pesan (gelembung chat) berdasarkan jenis pesan (teks biasa / lokasi).
  Widget _messageBubble(ChatMessage msg, bool isMe) {
    if (msg.type == 'location') {
      return _locationMessageBubble(msg, isMe);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            _messageFooter(msg, isMe),
          ],
        ),
      ),
    );
  }

  /// Widget Builder: Menampilkan timestamp pengiriman dan status terbaca (ikon centang 1 atau centang 2 biru).
  Widget _messageFooter(ChatMessage msg, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(msg.createdAt),
          style: TextStyle(
            fontSize: 11,
            color: isMe ? Colors.white70 : Colors.black54,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            msg.readAt != null ? Icons.done_all : Icons.check,
            size: 14,
            color: msg.readAt != null ? Colors.lightBlueAccent : Colors.white70,
          ),
        ],
      ],
    );
  }

  /// Widget Builder: Tampilan gelembung pesan khusus lokasi penjemputan dengan integrasi FutureBuilder untuk reverse-geocoding alamat.
  Widget _locationMessageBubble(ChatMessage msg, bool isMe) {
    final lat = msg.latitude!;
    final lng = msg.longitude!;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onTap: () => _openMap(lat, lng),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 290,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 75, 75, 75),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ClipRRect(
              //   borderRadius: const BorderRadius.vertical(
              //     top: Radius.circular(18),
              //   ),
              //   child: Stack(
              //     alignment: Alignment.center,
              //     children: [
              //       Image.network(
              //         _buildMapPreviewUrl(lat, lng),
              //         height: 150,
              //         width: double.infinity,
              //         fit: BoxFit.cover,
              //         loadingBuilder: (context, child, progress) {
              //           if (progress == null) return child;

              //           return Container(
              //             height: 150,
              //             color: Colors.grey[300],
              //             child: const Center(
              //               child: CircularProgressIndicator(),
              //             ),
              //           );
              //         },
              //         errorBuilder: (context, error, stackTrace) {
              //           return Container(
              //             height: 150,
              //             color: Colors.grey[300],
              //             child: const Center(
              //               child: Icon(
              //                 Icons.map,
              //                 size: 50,
              //                 color: Colors.grey,
              //               ),
              //             ),
              //           );
              //         },
              //       ),
              //       Container(
              //         width: 44,
              //         height: 44,
              //         decoration: BoxDecoration(
              //           color: Colors.white.withOpacity(0.9),
              //           shape: BoxShape.circle,
              //         ),
              //         child: const Icon(
              //           Icons.location_on,
              //           color: Colors.red,
              //           size: 28,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 50),
                    SizedBox(height: 8),
                    Text(
                      "Pickup Trash",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: FutureBuilder<String>(
                  future: _getAddress(lat, lng),
                  builder: (context, snapshot) {
                    final address = snapshot.data ?? "Memuat alamat...";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Lokasi Penjemputan",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          address,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Buka Maps",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: _messageFooter(msg, isMe),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget Builder: Membangun baris input pesan bagian bawah yang dilengkapi tombol kirim lokasi GPS dan tombol kirim teks.
  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.green),
            onPressed: _sendLocation,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  /// Fungsi: Mengubah format `Timestamp` Firebase menjadi string waktu jam dan menit (`HH:mm`).
  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
