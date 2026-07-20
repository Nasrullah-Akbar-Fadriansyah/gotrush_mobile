import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_formatter.dart';
import 'order_detail_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _documentLimit = 10;

  // Filter default untuk menampilkan semua jenis orderan
  String _selectedFilter = 'all';

  // Map untuk menampilkan nama filter yang ramah pengguna di UI Dropdown
  final Map<String, String> _filterLabels = {
    'all': 'Semua Order',
    'pending': 'Pending',
    'active': 'Aktif',
    'completed': 'Selesai',
    'cancelled': 'Batal',
  };

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    // Listener untuk sistem Paginasi / Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk membersihkan state lama dan memuat ulang data saat filter diubah atau di-refresh
  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _orders.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _fetchOrders();
  }

  // Mengambil data dari Firestore menggunakan batasan limit pagination
  Future<void> _fetchOrders() async {
    if (_isLoading || !_hasMore) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      Query query = _firestore
          .collection('order_history')
          .orderBy('created_at', descending: true);

      // Jika filter bukan 'all', terapkan filter status ke Firestore query
      if (_selectedFilter != 'all') {
        query = query.where('status', isEqualTo: _selectedFilter);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_documentLimit);
      final querySnapshot = await query.get();

      if (!mounted) return;

      if (querySnapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        setState(() {
          for (var doc in querySnapshot.docs) {
            // Mencegah duplikasi item data lokal di dalam list
            if (!_orders.any((existingDoc) => existingDoc.id == doc.id)) {
              _orders.add(doc);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data pagination order: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditOrderDialog(String docId, Map<String, dynamic> data) {
    final addressController = TextEditingController(
      text: data['address'] ?? '',
    );
    final weightController = TextEditingController(
      text: (data['weight'] ?? 0).toString(),
    );
    final priceController = TextEditingController(
      text: (data['price_paid'] ?? data['price'] ?? 0).toString(),
    );
    String selectedStatus = data['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Edit Informasi Order',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status Order'),
                  items: ['pending', 'active', 'completed', 'cancelled'].map((
                    status,
                  ) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'completed'
                            ? 'Selesai (Completed)'
                            : status.toUpperCase(),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedStatus = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Pengiriman',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Berat (Kg)',
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Total Harga (Rp)',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final weight =
                    double.tryParse(weightController.text.trim()) ?? 0.0;
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;

                Navigator.pop(dialogContext);

                try {
                  Map<String, dynamic> updateData = {
                    'status': selectedStatus,
                    'address': addressController.text.trim(),
                    'weight': weight,
                    'price': price,
                    'price_paid': price,
                  };

                  if (selectedStatus == 'completed') {
                    updateData['completed_at'] = FieldValue.serverTimestamp();
                  }

                  await _firestore
                      .collection('order_history')
                      .doc(docId)
                      .update(updateData);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order berhasil diperbarui!')),
                  );

                  // Langsung memicu refresh otomatis pada halaman list yang sama
                  _refreshData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteOrderConfirmation(String docId, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus data transaksi "$orderId"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _firestore
                      .collection('order_history')
                      .doc(docId)
                      .delete();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order sukses dihapus')),
                  );

                  _refreshData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    String label = status;
    switch (status.toLowerCase()) {
      case 'completed':
        label = 'Selesai';
        break;
      case 'active':
        label = 'Aktif';
        break;
      case 'pending':
        label = 'Pending';
        break;
      case 'cancelled':
        label = 'Batal';
        break;
    }
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty && _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manajemen Order',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filter kecil (Dropdown) di bagian kanan AppBar
          Theme(
            data: Theme.of(
              context,
            ).copyWith(canvasColor: Colors.green.shade700),
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              underline: const SizedBox(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: _filterLabels.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(_filterLabels[key]!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedFilter) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                  _refreshData(); // Jalankan ulang query saat filter dipilih
                }
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _orders.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada order dengan status ini.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _orders.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _orders.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final doc = _orders[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final double weight = (data['weight'] ?? 0).toDouble();
                  final double price =
                      ((data['price_paid'] ?? data['price'] ?? 0) as num)
                          .toDouble();
                  final String orderStatus = data['status'] ?? '';
                  final String orderIdStr = data['order_id'] ?? 'No Order ID';
                  final Timestamp createdAt =
                      data['created_at'] ?? Timestamp.now();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              orderStatus,
                            ).withOpacity(0.15),
                            child: Icon(
                              Icons.shopping_bag,
                              color: _getStatusColor(orderStatus),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  orderIdStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(orderStatus),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alamat: ${data['address'] ?? '-'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Berat: ${AdminFormatter.weight(weight)}',
                                    ),
                                    Text(
                                      AdminFormatter.rupiah(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AdminFormatter.dateTime(createdAt.toDate()),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailPage(orderId: doc.id),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  'Ubah / Selesai',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () =>
                                    _showEditOrderDialog(doc.id, data),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () => _showDeleteOrderConfirmation(
                                  doc.id,
                                  orderIdStr,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
