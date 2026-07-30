import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../utils/alerts.dart';
import '../order_room_screen.dart';
import '../user/edukasi_screen.dart';
import '../user/pickup_schedule_screen.dart';
import '../user/user_profile.dart';
import '../order_history_widget.dart';
import '../map_selection_screen.dart';
import 'package:flutter/services.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  DateTime? _lastNotifyAt;
  String? _lastNotifiedOrderId;
  bool _dialogOpen = false;

  final Set<String> _orderStatuses = <String>{};

  late final OrderService _orderService;

  final double _pricePerKm = 1000;
  final double _pricePerKg = 1000;

  // Default base location (Monas, Jakarta) for distance calculation.
  // If your project already has another util, we can swap later.
  final LatLng _monasLocation = const LatLng(-6.1754, 106.8272);

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
  }

  double _calculateDistance(LatLng a, LatLng b) {
    // Haversine formula
    const earthRadiusKm = 6371.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLon = (b.longitude - a.longitude) * (math.pi / 180.0);
    final lat1 = a.latitude * (math.pi / 180.0);
    final lat2 = b.latitude * (math.pi / 180.0);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  Future<void> handleStatusChange(
    String orderId,
    String status,
    Map<String, dynamic> data,
  ) async {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastNotifyAt != null && _lastNotifiedOrderId == orderId) {
      final diff = now.difference(_lastNotifyAt!);
      if (diff < const Duration(seconds: 3)) return;
    }
    _lastNotifyAt = now;
    _lastNotifiedOrderId = orderId;

    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    switch (status) {
      case 'active':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderRoomScreen(orderId: orderId, role: 'user'),
          ),
        );
        break;

      case 'pickup_validation':
        await notificationService.showLocal(
          id: orderId.hashCode + 4,
          title: 'Validasi Pengambilan',
          body: 'Silakan lakukan validasi akhir setelah driver konfirmasi.',
        );
        break;

      case 'waiting_user_validation':
        await notificationService.showLocal(
          id: orderId.hashCode + 7,
          title: 'Konfirmasi Pengambilan',
          body:
              'Driver mengonfirmasi pengambilan. Apakah sampah sudah diambil?',
        );
        break;

      case 'arrived':
        await notificationService.showLocal(
          id: orderId.hashCode + 8,
          title: 'Driver Tiba di Lokasi',
          body: 'Driver telah tiba. Siapkan sampah anda.',
        );
        break;

      case 'completed':
        _orderStatuses.remove(orderId);
        await notificationService.showLocal(
          id: orderId.hashCode + 6,
          title: 'Pesanan Selesai',
          body: 'Terima kasih! Sampah telah diambil.',
        );

        if (_dialogOpen) return;
        _dialogOpen = true;
        if (!mounted) return;

        await showAppDialog(
          context,
          title: 'Selesai',
          message: 'Terima kasih! Sampah telah diambil.',
          type: AlertType.success,
        );

        if (mounted) {
          setState(() => _dialogOpen = false);
        } else {
          _dialogOpen = false;
        }
        break;

      default:
        break;
    }
  }

  Future<void> _startCreateOrderFlow() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const MapSelectionScreen()),
    );

    if (result == null) return;

    final GeoPoint selectedLocation = result['location'] as GeoPoint;
    final String selectedAddress = result['address'] as String;

    final selected = LatLng(
      selectedLocation.latitude,
      selectedLocation.longitude,
    );
    final distanceKm = _calculateDistance(_monasLocation, selected);

    final addressCtl = TextEditingController(text: selectedAddress);
    final distanceCtl = TextEditingController(
      text: distanceKm.toStringAsFixed(2),
    );
    final weightCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    DateTime? selectedDate;

    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      nameCtl.text = currentUser.displayName ?? '';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          void updatePrice() {
            final distance = double.tryParse(distanceCtl.text) ?? 0;
            final weight = double.tryParse(weightCtl.text) ?? 0;
            final price = (distance * _pricePerKm) + (weight * _pricePerKg);
            priceCtl.text = price.toStringAsFixed(0);
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_location_alt, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Buat Order Penjemputan')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: addressCtl,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                  ),
                  TextField(
                    controller: distanceCtl,
                    readOnly: true,
                    enabled: true,
                    decoration: const InputDecoration(
                      labelText: 'Jarak (km x Rp.1000)',
                    ),
                  ),
                  TextField(
                    controller: weightCtl,
                    decoration: const InputDecoration(
                      labelText: 'Berat (kg x Rp.1000)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => updatePrice(),
                  ),
                  TextField(
                    controller: priceCtl,
                    decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  TextField(
                    controller: phoneCtl,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedDate = picked);
                      }
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Pilih Tanggal Penjemputan'
                          : 'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final address = addressCtl.text.trim();
                  final distance = double.tryParse(distanceCtl.text) ?? 0;
                  final weight = double.tryParse(weightCtl.text) ?? 0;
                  final price = double.tryParse(priceCtl.text) ?? 0;
                  final name = nameCtl.text.trim();
                  final phoneNumber = phoneCtl.text.trim();

                  if (address.isEmpty || name.isEmpty || phoneNumber.isEmpty) {
                    showAppSnackBar(
                      context,
                      'Alamat, nama, dan nomor telepon harus diisi',
                      type: AlertType.error,
                    );
                    return;
                  }

                  final uid = auth.currentUser?.uid ?? '';
                  final orderId =
                      'ORDER_${DateTime.now().millisecondsSinceEpoch}_$uid';

                  try {
                    await _orderService.createOrder(
                      orderId: orderId,
                      userId: uid,
                      weight: weight,
                      distance: distance,
                      price: price,
                      address: address,
                      location: selectedLocation,
                      photoUrls: [],
                      status: 'pending',
                      pickupDate: selectedDate,
                      name: name,
                      phoneNumber: phoneNumber,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    showAppSnackBar(
                      context,
                      'Gagal menyimpan order: $e',
                      type: AlertType.error,
                    );
                    return;
                  }

                  if (!ctx2.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;

                  showAppSnackBar(
                    context,
                    'Pesanan disimpan. Menunggu driver menerima.',
                    type: AlertType.success,
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  final List<Map<String, Object>> menuItems = [
    {
      'title': 'Jadwal Penjemputan',
      'subtitle': 'Lihat jadwal penjemputan sampah Anda',
      'icon': Icons.recycling,
      'color1': const Color(0xFFD9F2D9),
      'color2': const Color(0xFFC1EAC1),
    },
    {
      'title': 'Poin & Reward',
      'subtitle': 'Lihat jumlah poin yang telah kamu kumpulkan',
      'icon': Icons.star_rate,
      'color1': const Color(0xFFFFE3B3),
      'color2': const Color(0xFFFFD580),
    },
    {
      'title': 'Edukasi Daur Ulang',
      'subtitle': 'Pelajari cara mengelola sampah dengan benar',
      'icon': Icons.book_rounded,
      'color1': const Color(0xFFCCE1FF),
      'color2': const Color(0xFFB3D4FF),
    },
  ];

  int _selectedIndex = 0;
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [_buildBeranda(), _buildRiwayat(), const UserProfile()];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? 'Beranda Pengguna'
              : _selectedIndex == 1
              ? 'Riwayat Penjemputan'
              : 'Profil Saya',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? _buildDynamicFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    final List<Widget> children = [
      Text(
        'Hai, Selamat Datang! 👋',
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Kelola aktivitas penjemputan sampahmu dengan mudah.',
        style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
      ),
      const SizedBox(height: 24),
    ];

    for (final item in menuItems) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _MenuCard(
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            icon: item['icon'] as IconData,
            color1: item['color1'] as Color,
            color2: item['color2'] as Color,
            onTap: () {
              if (item['title'] == 'Jadwal Penjemputan') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PickupScheduleScreen(),
                  ),
                );
              } else if (item['title'] == 'Edukasi Daur Ulang') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EdukasiScreen()),
                );
              } else {
                showAppSnackBar(
                  context,
                  'Navigasi ke ${item['title']}',
                  type: AlertType.info,
                );
              }
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: ListView(children: children))],
      ),
    );
  }

  Widget _buildDynamicFab() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;

    final createBtn = Expanded(
      child: ElevatedButton.icon(
        onPressed: _startCreateOrderFlow,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text(
          'Buat Order',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 13, 214, 23),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    if (uid == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(children: [createBtn]),
      );
    }

    const activeStatuses = [
      'active',
      'awaiting_confirmation',
      'waiting_payment',
      'pickup_validation',
      'arrived',
      'waiting_user_validation',
      'picked_up',
    ];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: uid)
          .where('archived', isEqualTo: false)
          .where('status', whereIn: activeStatuses)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final hasActive = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        Widget? activeBtn;

        if (hasActive) {
          final orderId = snapshot.data!.docs.first.id;
          activeBtn = Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderRoomScreen(orderId: orderId, role: 'user'),
                  ),
                );
              },
              icon: const Icon(Icons.assignment, color: Colors.white),
              label: const Text(
                'Orderan Aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              createBtn,
              if (activeBtn != null) const SizedBox(width: 12),
              if (activeBtn != null) activeBtn,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiwayat() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUserId = auth.currentUser?.uid ?? '';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: OrderHistoryWidget(currentUserId: currentUserId, role: 'user'),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.25 * 255).round()),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 28, color: Colors.green[800]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  final VoidCallback onChatPressed;
  final VoidCallback? onPayPressed;
  final VoidCallback? onConfirmPressed;

  const ActiveOrderCard({
    required this.orderData,
    required this.orderId,
    required this.onChatPressed,
    this.onPayPressed,
    this.onConfirmPressed,
  });

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Driver';
      case 'active':
        return 'Driver Ditemukan';
      case 'awaiting_confirmation':
        return 'Menunggu Konfirmasi Berat';
      case 'waiting_payment':
        return 'Menunggu Pembayaran';
      case 'pickup_validation':
        return 'Validasi Penjemputan';
      case 'completed':
        return 'Selesai';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] as String? ?? '';
    final weight = (orderData['weight'] ?? 0).toDouble();
    final price = (orderData['price'] ?? 0).toDouble();
    final address = orderData['address'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Pesanan Aktif',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${_getStatusText(status)}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Berat: ${weight.toStringAsFixed(1)} kg',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Harga: Rp ${price.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Alamat: $address',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onChatPressed,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Chat dengan Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (onPayPressed != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPayPressed,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'pickup_validation' &&
                  (orderData['pickup_confirmed'] ?? false) == true &&
                  onConfirmPressed != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirmPressed,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Konfirmasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
