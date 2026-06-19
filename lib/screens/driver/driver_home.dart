import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampah_online/screens/driver/driver_profile.dart';
import 'package:sampah_online/screens/driver/new_orders_screen.dart';
import 'package:sampah_online/welcome_screen.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../order_history_widget.dart';
import '../order_room_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  StreamSubscription<QuerySnapshot>? _orderSub;
  Timer? _locationUpdateTimer;
  bool _showingDialog = false;
  bool _notificationShown = false;
  Map<String, dynamic>? _activeOrderData;
  String? _activeOrderId;
  final Map<String, String> _previousStatusPerOrder = {};
  String? _lastNavigatedOrderId;
  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningAndTracking();
    });
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Widget _buildTodayOrderBadge() {
    final startToday = Timestamp.fromDate(_startOfToday());
    final endToday = Timestamp.fromDate(_endOfToday());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['pending'])
          .where('driver_id', isNull: true)
          .where('pickup_date', isGreaterThanOrEqualTo: startToday)
          .where('pickup_date', isLessThan: endToday)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final orderCount = snapshot.data!.docs.length;
        if (orderCount == 0) return const SizedBox.shrink();

        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            child: Text(
              orderCount.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startListeningAndTracking() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final driverUid = auth.currentUser?.uid;
    if (driverUid == null) return;

    _orderSub?.cancel();
    final startToday = Timestamp.fromDate(_startOfToday());
    final endToday = Timestamp.fromDate(_endOfToday());

    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .where('driver_id', isNull: true)
        .where('pickup_date', isGreaterThanOrEqualTo: startToday)
        .where('pickup_date', isLessThan: endToday)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final hasOrders = snapshot.docs.isNotEmpty;

          if (hasOrders && !_notificationShown) {
            _notificationShown = true;
            _showNewOrdersNotification();
          }

          if (!hasOrders) {
            _notificationShown = false;
          }
        });

    FirebaseFirestore.instance
        .collection('orders')
        .where('driver_id', isEqualTo: driverUid)
        .where('archived', isEqualTo: false)
        .where(
          'status',
          whereIn: [
            'active',
            'awaiting_confirmation',
            'waiting_payment',
            'pickup_validation',
            'arrived',
            'waiting_user_validation',
            'picked_up',
            'completed',
          ],
        )
        .snapshots()
        .listen((activeSnapshot) {
          if (!mounted) return;

          if (activeSnapshot.docs.isNotEmpty) {
            final doc = activeSnapshot.docs.first;
            final data = doc.data();
            final status = data['status'] as String;
            final orderId = doc.id;
            final paymentStatus = data['payment_status'];
            setState(() {
              _activeOrderId = orderId;
              _activeOrderData = data;
            });
            if (status == 'active' && _lastNavigatedOrderId != orderId) {
              _lastNavigatedOrderId = orderId; // Tandai sudah navigasi
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderRoomScreen(orderId: orderId, role: 'driver'),
                    ),
                  )
                  .then((_) {
                    _lastNavigatedOrderId = null;
                  });
            }
            if (_previousStatusPerOrder[orderId] != '$status|$paymentStatus') {
              _previousStatusPerOrder[orderId] = '$status|$paymentStatus';
              if (paymentStatus == 'success') {
                NotificationService().showLocal(
                  id: orderId.hashCode & 0x7fffffff,
                  title: 'Pesanan Dibayar',
                  body: 'User Telah Melakukan Pembayaran.',
                );
              }

              switch (status) {
                case 'pickup_validation':
                  NotificationService().showLocal(
                    id: orderId.hashCode & 0x7fffffff,
                    title: 'Validasi Pengambilan',
                    body: 'Silakan konfirmasi ambil sampah di order.',
                  );
                  break;
                case 'waiting_user_validation':
                  NotificationService().showLocal(
                    id: orderId.hashCode & 0x7fffffff,
                    title: 'Menunggu Validasi User',
                    body: 'User akan memvalidasi pengambilan Anda.',
                  );
                  break;
                case 'completed':
                  NotificationService().showLocal(
                    id: orderId.hashCode & 0x7fffffff,
                    title: 'Order Selesai',
                    body: 'Order telah selesai',
                  );
                  break;
              }
            }
          } else if (_activeOrderId != null) {
            setState(() {
              _activeOrderId = null;
              _activeOrderData = null;
            });
          }
        });

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final status = _activeOrderData?['status'];
      if (status == 'active') {
        _updateDriverLocation(driverUid);
      }
    });
  }

  Future<void> _updateDriverLocation(String driverUid) async {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final driverLocation = {
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('drivers_location')
          .doc(driverUid)
          .set(driverLocation, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Gagal update lokasi driver: $e');
    }
  }

  Future<void> _showNewOrdersNotification() async {
    if (_showingDialog) return;
    _showingDialog = true;
    try {
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24), // Spacer for center alignment
                      IconButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (mounted) {
                            setState(() => _notificationShown = false);
                          }
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Ada orderan baru hari ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (mounted) {
                        setState(() => _notificationShown = false);
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NewOrdersScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Lihat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      // 🔄 RESET setelah dialog ditutup
      if (mounted) {
        setState(() {
          _showingDialog = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String driverName = "Driver";
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUserId = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        title: const Text(
          "Dashboard Driver",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withAlpha((0.3 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.local_shipping,
                      size: 36,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Hai, $driverName 👋\nSiap menjalankan tugas hari ini?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Menu Utama",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),

            // Grid Menu
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMenuCard(
                      context,
                      title: "Pesanan Baru",
                      subtitle: "Order hari ini",
                      icon: FontAwesomeIcons.clipboardList,
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildTodayOrderBadge(),
                  ],
                ),

                _buildMenuCard(
                  context,
                  title: "Riwayat",
                  subtitle: "Lihat daftar riwayat",
                  icon: FontAwesomeIcons.clockRotateLeft,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            backgroundColor: Colors.green[800],
                            title: const Text(
                              'Riwayat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          body: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OrderHistoryWidget(
                              currentUserId: currentUserId,
                              role: 'driver',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: "Status Online",
                  subtitle: "Ubah status kerja",
                  icon: FontAwesomeIcons.wifi,
                  color: Colors.orange,
                  onTap: () {},
                ),
                _buildMenuCard(
                  context,
                  title: "Profil",
                  subtitle: "Edit profil ",
                  icon: FontAwesomeIcons.userGear,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DriverProfile()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            Builder(
              builder: (ctx) {
                final auth = Provider.of<AuthService>(context, listen: false);
                final driverUid = auth.currentUser?.uid;
                if (driverUid == null) return const SizedBox.shrink();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('driver_id', isEqualTo: driverUid)
                      .where('archived', isEqualTo: false)
                      .where(
                        'status',
                        whereIn: [
                          'active',
                          'awaiting_confirmation',
                          'waiting_payment',
                          'pickup_validation',
                          'arrived',
                          'waiting_user_validation',
                          'picked_up',
                        ],
                      )
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final orderId = snapshot.data!.docs.first.id;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.assignment),
                        label: const Text('Buka Order Aktif'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderRoomScreen(
                                orderId: orderId,
                                role: 'driver',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
            // Footer
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Keluar Akun",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: color.withAlpha((0.2 * 255).round()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.15 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withAlpha((0.15 * 255).round()),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
