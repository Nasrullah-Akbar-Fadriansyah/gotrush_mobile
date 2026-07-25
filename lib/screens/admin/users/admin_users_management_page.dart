import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersManagementPage extends StatefulWidget {
  final String roleFilter; // 'user' atau 'driver'

  const AdminUsersManagementPage({super.key, required this.roleFilter});

  @override
  State<AdminUsersManagementPage> createState() =>
      _AdminUsersManagementPageState();
}

class _AdminUsersManagementPageState extends State<AdminUsersManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // [CREATE & UPDATE PROCESS] Dialog Form Gabungan
  void _showFormDialog({
    String? docId,
    String? currentName,
    String? currentPhone,
    String? currentEmail,
  }) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final emailController = TextEditingController(text: currentEmail);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final isEdit = docId != null;
    bool showPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      enabled: !isEdit, // Email hanya diisi saat tambah baru
                    ),

                    // Field Password Hanya Tampak Saat Tambah User Baru
                    if (!isEdit) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text;
                    final confirmPassword = confirmPasswordController.text;

                    // Validasi Dasar
                    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                      _showSnackBar('Nama, Telepon, dan Email wajib diisi!');
                      return;
                    }

                    if (!isEdit) {
                      if (password.isEmpty || confirmPassword.isEmpty) {
                        _showSnackBar('Password wajib diisi!');
                        return;
                      }

                      if (password != confirmPassword) {
                        _showSnackBar('Konfirmasi password tidak cocok!');
                        return;
                      }

                      final passwordRegExp = RegExp(
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{6,}$',
                      );
                      if (!passwordRegExp.hasMatch(password)) {
                        _showSnackBar(
                          'Password min. 6 karakter, kombinasi huruf besar, kecil, & angka.',
                        );
                        return;
                      }
                    }

                    Navigator.pop(context);

                    try {
                      if (isEdit) {
                        // UPDATE DATA FIRESTORE
                        await _firestore.collection('users').doc(docId).update({
                          'name': name,
                          'phone': phone,
                        });
                        _showSnackBar('Data berhasil diperbarui');
                      } else {
                        // CREATE USER DENGAN FIREBASE AUTH (Tanpa Mengeluarkan Admin)
                        FirebaseApp tempApp = await Firebase.initializeApp(
                          name: 'tempRegisterApp',
                          options: Firebase.app().options,
                        );

                        UserCredential cred =
                            await FirebaseAuth.instanceFor(
                              app: tempApp,
                            ).createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                        // Simpan Detail Pengguna ke Firestore dengan ID dari Auth
                        await _firestore
                            .collection('users')
                            .doc(cred.user!.uid)
                            .set({
                              'name': name,
                              'phone': phone,
                              'email': email,
                              'role':
                                  widget.roleFilter, // Otomatis sesuai halaman
                              'status': widget.roleFilter == 'driver'
                                  ? 'offline'
                                  : 'active',
                              'created_at': FieldValue.serverTimestamp(),
                            });

                        // Hapus App Sementara
                        await tempApp.delete();

                        _showSnackBar('Data $name berhasil ditambahkan!');
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
      },
    );
  }

  // fungsi hapus data user/driver
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
    final String labelTitle = widget.roleFilter == 'user' ? 'User' : 'Driver';

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
                          Text('🟢 Status Driver: $status'),
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
