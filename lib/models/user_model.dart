// Kelas untuk merepresentasikan data akun Pengguna (User/Driver)
class UserModel {
  String uid; // ID unik pengguna dari Firebase Auth
  String name; // Nama lengkap
  String email; // Alamat email
  String phone; // Nomor telepon
  String role; // Peran akun (misal: 'user', 'driver', 'admin')
  String? fcmToken; // Token Firebase Cloud Messaging untuk kirim Notifikasi
  String? status; // Status keaktifan (misal: 'online', 'offline')

  // Constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.fcmToken,
    this.status,
  });

  // [CREATE / UPDATE PROCESS] Konversi Objek UserModel ke Map untuk disimpan/di-update di Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'fcm_token': fcmToken,
      'status':
          status ??
          'offline', // Jika status belum diset, bawaan-nya adalah 'offline'
    };
  }

  // [READ PROCESS] Pabrik konversi dari Map Firestore ke Objek UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      role: map['role'],
      fcmToken: map['fcm_token'],
      status: map['status'],
    );
  }
}
