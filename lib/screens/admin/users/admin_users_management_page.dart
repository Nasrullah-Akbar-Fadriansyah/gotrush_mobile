import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersManagementPage extends StatefulWidget {
  final String roleFilter; // 'user' atau 'driver'

  const AdminUsersManagementPage({super.key, required this.roleFilter});

  @override
  State<AdminUsersManagementPage> createState() =>
      _AdminUsersManagementPageState();
}

class _AdminUsersManagementPageState extends State<AdminUsersManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menampilkan Dialog Form untuk Tambah atau Edit Pengguna
  void _showFormDialog({
    String? docId,
    String? currentName,
    String? currentPhone,
    String? currentEmail,
  }) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final emailController = TextEditingController(text: currentEmail);
    final isEdit = docId != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            isEdit
                ? 'Edit Data ${widget.roleFilter}'
                : 'Tambah Data ${widget.roleFilter}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled:
                      !isEdit, // Email tidak boleh diedit jika memperbarui data
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi!')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  if (isEdit) {
                    await _firestore.collection('users').doc(docId).update({
                      'name': name,
                      'phone': phone,
                    });
                    _showSnackBar('Data berhasil diperbarui');
                  } else {
                    await _firestore.collection('users').add({
                      'name': name,
                      'phone': phone,
                      'email': email,
                      'role': widget.roleFilter,
                      'status': widget.roleFilter == 'driver'
                          ? 'offline'
                          : 'active',
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    _showSnackBar('Data berhasil ditambahkan');
                  }
                } catch (e) {
                  _showSnackBar('Terjadi kesalahan: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );
  }

  // Menampilkan Dialog Konfirmasi Hapus Akun
  void _showDeleteConfirmation(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Pengguna',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus data "$name"? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _firestore.collection('users').doc(docId).delete();
                  _showSnackBar('Data berhasil dihapus');
                } catch (e) {
                  _showSnackBar('Gagal menghapus data: $e');
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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String labelTitle = widget.roleFilter == 'user'
        ? 'Pelanggan / User'
        : 'Driver / Pengemudi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola $labelTitle',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: widget.roleFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.supervised_user_circle,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada data $labelTitle terdaftar.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? '-';
              final phone = data['phone'] ?? '-';
              final email = data['email'] ?? '-';
              final status = data['status'] ?? 'active';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: widget.roleFilter == 'user'
                        ? Colors.purple.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      widget.roleFilter == 'user'
                          ? Icons.person
                          : Icons.delivery_dining,
                      color: widget.roleFilter == 'user'
                          ? Colors.purple.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 Telp: $phone'),
                        Text('✉️ Email: $email'),
                        if (widget.roleFilter == 'driver')
                          Text('🟢 Status Drive: $status'),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormDialog(
                          docId: doc.id,
                          currentName: name,
                          currentPhone: phone,
                          currentEmail: email,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(doc.id, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
