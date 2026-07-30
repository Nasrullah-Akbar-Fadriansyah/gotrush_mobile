# Sampah Online

**Aplikasi Flutter untuk penjemputan sampah, pelacakan driver, pembayaran Midtrans, chat realtime, dan dashboard admin berbasis Firebase.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-Placeholder-lightgrey)

## Cover

### Nama Aplikasi

Gotrash

### Deskripsi Singkat

Aplikasi mobile cross-platform berbasis Flutter untuk mengelola layanan penjemputan sampah. Sistem ini mencakup alur pengguna, driver, dan admin; autentikasi Firebase; penyimpanan data di Firestore; pembayaran Midtrans melalui WebView; chat realtime; notifikasi FCM dan notifikasi lokal; pelacakan lokasi; serta dashboard analitik admin.

## Daftar Isi

1. [Tentang Project](#tentang-project)
2. [Fitur Aplikasi](#fitur-aplikasi)
3. [Teknologi](#teknologi)
4. [Semua Dependency](#semua-dependency)
5. [Struktur Folder](#struktur-folder)
6. [Arsitektur Sistem](#arsitektur-sistem)
7. [Arsitektur State Management](#arsitektur-state-management)
8. [Firestore Database](#firestore-database)
9. [Penjelasan Semua Model](#penjelasan-semua-model)
10. [Authentication Flow](#authentication-flow)
11. [Order Flow](#order-flow)
12. [Payment Flow](#payment-flow)
13. [Chat Flow](#chat-flow)
14. [Notification Flow](#notification-flow)
15. [Dashboard Admin](#dashboard-admin)
16. [Status Order](#status-order)
17. [Cara Clone Project](#cara-clone-project)
18. [Cara Setup Flutter](#cara-setup-flutter)
19. [Setup Firebase](#setup-firebase)
20. [Menjalankan Project](#menjalankan-project)
21. [Build](#build)
22. [Struktur Coding](#struktur-coding)
23. [Security](#security)
24. [Troubleshooting](#troubleshooting)
25. [FAQ](#faq)
26. [Roadmap](#roadmap)
27. [Kontribusi](#kontribusi)
28. [Kontributor](#kontributor)
29. [Lisensi](#lisensi)

## Tentang Project

Sampah Online adalah aplikasi layanan penjemputan sampah yang dibangun dengan Flutter dan Firebase. Aplikasi ini dirancang untuk mempertemukan tiga peran utama dalam satu alur kerja yang konsisten:

- Pengguna yang membuat permintaan penjemputan sampah.
- Driver yang menerima, memproses, dan menyelesaikan order.
- Admin yang memantau operasional, pengguna, order, pendapatan, dan laporan.

Tujuan utama proyek ini adalah membuat proses penjemputan sampah menjadi lebih terstruktur, lebih mudah dipantau, dan lebih transparan. Di dalam kode, alur ini diwujudkan melalui Firebase Auth untuk autentikasi, Firestore untuk data transaksi, Firebase Messaging dan local notification untuk notifikasi, WebView untuk pembayaran Midtrans, serta modul dashboard admin untuk analisis data operasional.

Masalah yang diselesaikan oleh aplikasi ini terlihat jelas dari struktur kodenya:

- Permintaan penjemputan tidak lagi dikelola secara manual.
- Status order dapat diikuti dari pembuatan hingga penyelesaian.
- Driver dapat menerima order dan memperbarui status secara bertahap.
- Pembayaran dapat dilakukan dari dalam aplikasi tanpa keluar ke browser eksternal.
- Chat realtime tersedia untuk komunikasi antara pihak terkait.
- Admin memiliki visibilitas terhadap order, pengguna, driver, dan performa pendapatan.

Siapa pengguna aplikasi ini:

- User atau pelanggan yang ingin menjadwalkan penjemputan sampah.
- Driver yang bertugas menjemput, memvalidasi, dan menyelesaikan order.
- Admin yang bertugas memantau dan mengelola operasional sistem.

Manfaat aplikasi:

- Mempermudah pencatatan permintaan penjemputan.
- Mengurangi proses manual dalam koordinasi pickup.
- Memberikan alur pembayaran yang terintegrasi.
- Memberikan notifikasi status secara langsung.
- Membantu admin membaca performa sistem melalui grafik dan laporan.

## Fitur Aplikasi

Bagian ini hanya menjelaskan fitur yang benar-benar muncul di source code yang ada di repository.

### User

#### Registrasi Akun

User dapat membuat akun melalui `RegisterScreen`. Form registrasi mencakup nama, nomor telepon, email, password, konfirmasi password, dan pilihan role. Dari kode, role yang tersedia adalah `user` dan `driver`. Registrasi dilakukan melalui `AuthService.register`, lalu data profil disimpan ke koleksi Firestore `users`.

#### Login

User dapat masuk melalui `LoginScreen` dengan email dan password. Proses login memakai Firebase Auth, lalu setelah autentikasi berhasil aplikasi membaca koleksi `users` untuk menentukan role. Berdasarkan role, user diarahkan ke `'/user'`, driver ke `'/driver'`, dan admin ke `'/admin'`.

#### Logout

Di `WelcomeScreen` dan halaman profil, user dapat keluar dari sesi aplikasi dengan mekanisme navigasi yang disediakan. Di sisi service, logout ditangani oleh `AuthService.logout()`.

#### Beranda User

`UserHome` adalah halaman utama user. Di dalamnya ada menu kartu bergaya visual, navigasi ke riwayat, edukasi, dan tombol aksi untuk membuat order atau membuka order aktif.

#### Membuat Order Penjemputan

User dapat memulai alur pembuatan order dari halaman beranda. Flow-nya dimulai dari `MapSelectionScreen`, lalu user memilih alamat, jarak dihitung terhadap titik dasar, dan form order diisi dengan alamat, berat, nama, nomor telepon, serta tanggal penjemputan.

#### Menentukan Lokasi

Lokasi penjemputan dipilih melalui peta `flutter_osm_plugin`. `MapSelectionScreen` membaca titik yang dipilih user dan mengubahnya menjadi `GeoPoint` Firestore. Alamat dibantu dengan geocoding melalui `placemarkFromCoordinates`.

#### Melihat Jadwal Penjemputan

`PickupScheduleScreen` menampilkan order milik user yang masih relevan untuk jadwal penjemputan. Data diambil dari koleksi `orders`, difilter berdasarkan `user_id`, `status`, dan `pickup_date`.

#### Melakukan Pembayaran

Saat status order berada pada `waiting_payment`, user dapat memulai pembayaran melalui Midtrans Snap. URL pembayaran didapat dari backend endpoint yang dipanggil oleh `getMidtransSnapUrl` pada `payment.dart`, lalu dibuka dalam `MidtransPaymentWebView`.

#### Melihat Status Order

User dapat mengikuti perubahan status order melalui `OrderRoomScreen`, `OrderDetailScreen`, dan stream Firestore pada halaman terkait. Status seperti `pending`, `active`, `awaiting_confirmation`, `waiting_payment`, `pickup_validation`, `arrived`, `waiting_user_validation`, `picked_up`, dan `completed` ditangani di alur ini.

#### Chat Realtime

User dapat mengirim pesan teks dan lokasi di `ChatScreen`. Chat disimpan sebagai subkoleksi pada `orders/{orderId}/messages`, sehingga komunikasi berada langsung dalam konteks order yang sedang diproses.

#### Tracking Driver

User dapat melihat pelacakan lokasi driver melalui halaman tracking yang memanfaatkan `flutter_osm_plugin`, `geolocator`, dan data `drivers_location` atau `drivers`. Sistem ini digunakan untuk menampilkan rute, marker, dan posisi terkini.

#### Riwayat Order

User dapat melihat riwayat order selesai melalui `OrderHistoryWidget`. Data dibaca dari `orders` dengan filter `status = completed` dan field `hidden_by_user = false`.

#### Profil User

`UserProfile` menyediakan tampilan profil user. Data profil diambil dari koleksi `users` dan dapat diperbarui melalui Firebase Auth dan Firestore.

#### Edit Profil

User dapat memperbarui nama dan nomor telepon. Kode di `UserProfile` juga memperbarui `displayName` pada Firebase Auth dan field `name` serta `phone` di Firestore.

#### Ubah Password

Jika user bukan akun Google, halaman profil menampilkan fitur perubahan password. Flow ini memerlukan password saat ini, password baru, dan konfirmasi password baru.

#### Edukasi Daur Ulang

`EdukasiScreen` menyediakan konten edukasi tentang sampah, jenis sampah, kelebihan dan kekurangan daur ulang, serta tips harian 3R.

#### Notifikasi

User menerima notifikasi lokal dan FCM yang dipasang di `NotificationService`. Notifikasi digunakan untuk status order, pesan baru, driver tiba, dan penyelesaian order.

#### Order History Detail

`OrderDetailScreen` menampilkan detail order secara visual, termasuk status, data driver, data pembayaran, waktu, dan akses chat.

### Driver

#### Login

Driver menggunakan alur login yang sama dengan user. Role ditentukan dari data Firestore setelah Firebase Auth berhasil.

#### Dashboard Driver

`DriverHomeScreen` menjadi halaman utama driver. Di sini ada menu untuk melihat pesanan baru, riwayat, status online, dan profil.

#### Melihat Pesanan Baru

`NewOrdersScreen` menampilkan order baru berdasarkan koleksi `orders` dengan filter `status = pending`, `driver_id = null`, dan jadwal pickup hari ini.

#### Accept Order

Driver dapat menerima order melalui `OrderService.acceptOrder`. Saat berhasil, status berubah menjadi `active` dan `driver_id` diisi.

#### Update Status Order

Driver dapat memperbarui status order dari halaman order aktif dan tracking. Service yang tersedia mencakup `driverArrived`, `driverConfirmPickup`, `driverCompleteOrder`, dan alur perubahan status lain yang terkait dengan validasi berat atau validasi pengambilan.

#### Melihat Order Aktif

Di `DriverHomeScreen` dan `OrderRoomScreen`, driver dapat membuka order aktif yang sedang ditugaskan padanya.

#### Propose Berat

Driver dapat mengajukan berat hasil timbangan melalui `OrderRoomScreen` yang memanggil `OrderService.proposeWeight`. Status berubah menjadi `awaiting_confirmation` dengan `weight_status = proposed`.

#### Tracking dan Rute

`DriverMapTrackingScreen` menampilkan peta OSM dengan marker user dan driver. Halaman ini digunakan untuk mengikuti lokasi dan membantu proses pengantaran atau penjemputan.

#### Chat dengan User

Driver dapat membuka chat order yang sama dan berkomunikasi langsung dengan user melalui `ChatScreen`.

#### Riwayat Driver

Driver dapat membuka riwayat melalui `OrderHistoryWidget` dari `DriverHomeScreen`. Filter di history membedakan data user dan driver melalui field tersembunyi `hidden_by_driver`.

#### Profil Driver

`DriverProfile` menyediakan update profil, update nomor telepon, dan perubahan password untuk akun email/password.

#### Status Online

Di `DriverHomeScreen` terdapat menu status online sebagai bagian UI operasional. Service `AuthService.setDriverStatus()` juga tersedia untuk memperbarui status driver pada Firestore.

#### Notifikasi Driver

Driver menerima notifikasi lokal mengenai order baru, pembayaran berhasil, validasi pickup, dan status selesai.

### Admin

#### Dashboard Admin

`AdminDashboard` menampilkan ringkasan utama melalui `DashboardService`, `DashboardStatSection`, `DashboardChartSection`, dan `LatestOrders`.

#### Statistik Operasional

Statistik yang dihitung meliputi total revenue, total order, total berat, total user, dan total driver. Data ini dibentuk dari koleksi `order_history` dan `users`.

#### Grafik Revenue

Grafik revenue bulanan ditampilkan dengan `fl_chart` melalui `RevenueChartModel` dan `DashboardChartSection`.

#### Grafik Total Order

Grafik jumlah order per bulan juga ditampilkan pada komponen grafik admin.

#### Order Terbaru

`LatestOrders` menampilkan order terbaru dan membuka halaman detail order ketika item dipilih.

#### CRUD User dan Driver

`AdminUsersManagementPage` menyediakan pembuatan, pengubahan, dan penghapusan user/driver berdasarkan filter role.

#### CRUD Order

`AdminOrdersPage` menyediakan tampilan order dengan pagination, filter status, edit order, detail order, dan hapus order.

#### Detail Order Admin

`OrderDetailPage` dan `OrderService` admin menampilkan detail order, data user, data driver, foto, status, dan timeline.

#### Laporan Analitik

`ReportsPage` menyediakan analitik berbasis rentang tanggal, total order, completed order, cancelled order, total revenue, dan total weight.

#### Analisis Pendapatan

`AdminRevenuePage` dan `RevenueService` menghitung pendapatan berdasarkan periode tertentu, termasuk rata-rata per order dan breakdown metode/status pembayaran.

#### Monitoring Driver Teraktif

Model dan komponen `TopDriverModel`, `TopDriverCard`, dan `TopDriverSection` disediakan untuk menampilkan driver paling aktif.

#### Monitoring User Teraktif

Model dan komponen `TopUserModel` dan `TopUserSection` juga tersedia. Pada service saat ini, `getTopUsers()` masih mengembalikan list kosong.

#### Filter dan Pagination

Halaman order admin menggunakan query Firestore dengan filter status dan pagination berbasis `startAfterDocument`.

## Teknologi

| Teknologi                          | Versi               | Kegunaan                             |
| ---------------------------------- | ------------------- | ------------------------------------ |
| Flutter                            | SDK Flutter project | Framework UI utama lintas platform   |
| Dart                               | `^3.9.2`            | Bahasa pemrograman utama             |
| Firebase Core                      | `^3.15.2`           | Inisialisasi Firebase                |
| Firebase Auth                      | `^5.1.1`            | Autentikasi pengguna                 |
| Cloud Firestore                    | `^5.1.1`            | Database dokumen realtime            |
| Firebase Storage                   | `^12.4.10`          | Penyimpanan file/foto                |
| Firebase App Check                 | `^0.3.2+10`         | Proteksi akses ke backend Firebase   |
| Firebase Messaging                 | `^15.2.10`          | Push notification                    |
| WebView Flutter                    | `^4.13.0`           | Menampilkan pembayaran Midtrans      |
| geolocator                         | `^13.0.1`           | GPS dan perhitungan jarak            |
| geocoding                          | `^4.0.0`            | Konversi koordinat ke alamat         |
| flutter_osm_plugin                 | `1.4.3`             | Peta dan marker                      |
| provider                           | `^6.0.5`            | State management global              |
| intl                               | `^0.19.0`           | Format tanggal, waktu, angka, rupiah |
| fl_chart                           | `^0.69.0`           | Grafik dashboard                     |
| http                               | any                 | Request HTTP ke backend pembayaran   |
| google_sign_in                     | `^6.2.1`            | Autofill data dari akun Google       |
| font_awesome_flutter               | `^10.7.0`           | Ikon tambahan                        |
| google_fonts                       | `^6.2.1`            | Tipografi                            |
| flutter_local_notifications        | `^19.5.0`           | Notifikasi lokal                     |
| image_picker                       | `^0.8.7+4`          | Pemilihan gambar                     |
| uuid                               | `^4.5.1`            | Generator ID unik                    |
| shared_preferences                 | `^2.2.3`            | Penyimpanan lokal ringan             |
| path_provider                      | `^2.1.5`            | Akses direktori lokal                |
| path                               | `^1.9.0`            | Utilitas path file                   |
| cupertino_icons                    | `^1.0.8`            | Ikon iOS                             |
| latlong2                           | `^0.9.1`            | Tipe koordinat geospasial            |
| geoflutterfire_plus                | `^0.0.32`           | Dukungan query geospasial            |
| cloud_firestore_platform_interface | `^6.0.4`            | Interface platform Firestore         |
| webview_flutter_android            | `4.10.9`            | Implementasi Android untuk WebView   |
| flutter_launcher_icons             | `^0.14.4`           | Generasi ikon aplikasi               |
| flutter_lints                      | `^3.0.0`            | Aturan linting                       |

## Semua Dependency

Bagian ini menjelaskan fungsi setiap package yang tercantum di `pubspec.yaml`. Beberapa package dipakai langsung di source code, sementara yang lain sudah tersedia sebagai dependensi proyek untuk fitur lanjutan atau dukungan platform.

### 1. `flutter`

Framework utama untuk membangun UI aplikasi lintas platform.

### 2. `flutter_lints`

Kumpulan aturan linting untuk menjaga kualitas dan konsistensi kode Dart/Flutter.

### 3. `flutter_osm_plugin`

Dipakai untuk peta interaktif, marker lokasi, pemilihan titik, dan tracking driver.

### 4. `firebase_core`

Menyediakan inisialisasi Firebase sebelum layanan lain dipakai.

### 5. `firebase_auth`

Dipakai untuk registrasi, login, logout, pembaruan password, dan identitas user aktif.

### 6. `cloud_firestore`

Database utama aplikasi untuk menyimpan user, order, riwayat, chat, statistik, dan metadata.

### 7. `firebase_storage`

Tersedia untuk penyimpanan file atau foto. Paket ini cocok untuk fitur upload foto yang terlihat disiapkan pada model dan flow order.

### 8. `path_provider`

Menyediakan akses ke direktori aplikasi di perangkat untuk kebutuhan file lokal.

### 9. `path`

Membantu manipulasi path file dan folder secara aman dan lintas platform.

### 10. `shared_preferences`

Digunakan untuk menyimpan preferensi lokal ringan seperti setting atau state sederhana.

### 11. `cloud_firestore_platform_interface`

Menyediakan interface platform untuk Firestore di level implementasi plugin.

### 12. `firebase_app_check`

Dipakai pada `main.dart` untuk mengaktifkan App Check dalam mode debug pada Android dan Apple.

### 13. `geoflutterfire_plus`

Dependensi pendukung untuk query atau logika geospasial berbasis Firestore.

### 14. `geolocator`

Dipakai untuk lokasi perangkat, posisi GPS, request permission, dan penghitungan jarak antar koordinat.

### 15. `url_launcher`

Dipakai untuk membuka Google Maps dari chat lokasi dan tautan eksternal lain yang relevan.

### 16. `google_sign_in`

Dipakai pada halaman registrasi untuk mengambil data akun Google secara otomatis.

### 17. `latlong2`

Menyediakan tipe koordinat lintang dan bujur untuk kebutuhan geospasial.

### 18. `webview_flutter`

Dipakai untuk menampilkan halaman pembayaran Midtrans di dalam aplikasi.

### 19. `webview_flutter_android`

Implementasi platform Android untuk WebView Flutter.

### 20. `image_picker`

Tersedia untuk pemilihan gambar dari perangkat.

### 21. `uuid`

Tersedia untuk membentuk ID unik ketika dibutuhkan.

### 22. `http`

Dipakai untuk request ke backend Midtrans pada `payment.dart`.

### 23. `provider`

Dipakai sebagai state management utama, khususnya untuk `AuthService`.

### 24. `intl`

Dipakai untuk format tanggal, waktu, number, dan rupiah dengan locale `id_ID`.

### 25. `firebase_messaging`

Dipakai untuk menerima FCM token dan menangani push notification.

### 26. `font_awesome_flutter`

Dipakai untuk ikon yang lebih variatif pada dashboard driver.

### 27. `google_fonts`

Dipakai untuk font yang lebih konsisten dan menarik, terutama Poppins.

### 28. `flutter_local_notifications`

Dipakai untuk menampilkan notifikasi lokal di perangkat ketika app aktif atau menerima event tertentu.

### 29. `flutter_launcher_icons`

Dipakai untuk menghasilkan icon aplikasi dari `assets/logo/icon.png`.

### 30. `cupertino_icons`

Menyediakan ikon gaya iOS.

### 31. `geocoding`

Dipakai untuk mengubah koordinat menjadi alamat yang lebih mudah dibaca.

### 32. `fl_chart`

Dipakai untuk grafik revenue dan jumlah order pada dashboard admin.

## Struktur Folder

Tree berikut adalah ringkasan struktur penting repository ini berdasarkan source yang tersedia.

```text
sampah_online/
├─ android/
├─ assets/
│  ├─ images/
│  └─ logo/
├─ docs/
│  └─ diagrams/
├─ functions/
│  ├─ index.js
│  └─ package.json
├─ ios/
├─ lib/
│  ├─ firebase_options.dart
│  ├─ main.dart
│  ├─ midtrans_payment_webview.dart
│  ├─ payment.dart
│  ├─ welcome_screen.dart
│  ├─ models/
│  ├─ screens/
│  ├─ services/
│  └─ utils/
├─ linux/
├─ macos/
├─ test/
│  └─ widget_test.dart
├─ web/
└─ windows/
```

### Fungsi Setiap Folder

- `lib/` berisi seluruh source Dart utama aplikasi.
- `lib/models/` menyimpan model data utama yang dipakai lintas layar dan service.
- `lib/screens/` menyimpan semua halaman UI, termasuk user, driver, admin, auth, chat, tracking, dan order room.
- `lib/services/` menyimpan logika bisnis dan integrasi Firebase atau backend.
- `lib/utils/` menyimpan helper umum seperti formatter dan alert.
- `assets/` menyimpan gambar dan ikon aplikasi.
- `functions/` adalah fondasi backend Node.js yang disiapkan melalui Firebase Functions.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, dan `macos/` menyimpan konfigurasi platform Flutter.
- `docs/` menyediakan ruang untuk diagram dan dokumentasi tambahan.
- `test/` menyimpan pengujian widget dasar.

### File Penting

#### `lib/main.dart`

Titik masuk aplikasi. File ini menginisialisasi Firebase, mempersiapkan locale tanggal Indonesia, mengaktifkan App Check, menginisialisasi NotificationService, dan memasang `MultiProvider` untuk `AuthService`.

#### `lib/firebase_options.dart`

Konfigurasi Firebase lintas platform hasil FlutterFire CLI. File ini menyediakan `FirebaseOptions` untuk web, Android, iOS, macOS, dan Windows.

#### `lib/payment.dart`

Helper untuk meminta Snap URL Midtrans dari backend API `https://api-midtrans-teal.vercel.app/api`.

#### `lib/midtrans_payment_webview.dart`

Halaman WebView untuk proses pembayaran dan deteksi navigasi sukses, error, atau cancel.

#### `lib/services/auth_service.dart`

Service autentikasi dan sinkronisasi data user ke Firestore.

#### `lib/services/order_service.dart`

Service utama untuk pembuatan order, accept order, update status, pengajuan berat, validasi pembayaran, pickup, dan penyelesaian order.

#### `lib/services/chat_service.dart`

Service pengelolaan pesan realtime pada subkoleksi `messages` dan metadata chat.

#### `lib/services/notification_service.dart`

Service FCM dan local notification.

#### `lib/services/location_service.dart`

Service pembaruan lokasi driver ke koleksi `drivers_location`.

#### `lib/services/driver_location_service.dart`

Service streaming posisi GPS ke koleksi `drivers`.

#### `lib/screens/user/user_home.dart`

Dashboard utama user dengan menu, order flow, dan navigasi ke riwayat dan edukasi.

#### `lib/screens/driver/driver_home.dart`

Dashboard utama driver dengan menu pesanan baru, riwayat, dan tracking status.

#### `lib/screens/admin/dashboard/admin_dashboard.dart`

Halaman dashboard admin.

#### `lib/screens/admin/orders/admin_orders_page.dart`

Manajemen order untuk admin dengan filter dan pagination.

#### `lib/utils/alerts.dart`

Helper terpusat untuk SnackBar dan Dialog.

## Arsitektur Sistem

Arsitektur aplikasi ini dapat diringkas seperti berikut:

```text
Flutter App
   |
   v
Firebase Core
   |
   +--> Firebase Auth ---------> Identitas user / driver / admin
   |
   +--> Cloud Firestore -------> users, orders, order_history, chat, location
   |
   +--> Firebase Messaging -----> Push notification
   |
   +--> Firebase App Check -----> Proteksi akses API
   |
   +--> WebView Midtrans -------> Pembayaran Snap
   |
   +--> Local Notification -----> Notifikasi saat aplikasi aktif
   |
   +--> OSM + Geolocator -------> Peta, lokasi, dan tracking
```

### Alur Antar Komponen

1. Flutter menampilkan UI untuk user, driver, dan admin.
2. Firebase Auth mengelola sesi login.
3. Firestore menyimpan data operasional.
4. NotificationService menghubungkan FCM dan notifikasi lokal.
5. Midtrans dipanggil melalui backend API dan ditampilkan di WebView.
6. Peta OSM dan geolocator dipakai untuk pemilihan lokasi dan tracking.
7. Admin membaca data agregat dari Firestore untuk grafik dan laporan.

## Arsitektur State Management

Project ini memakai `Provider` sebagai state management utama.

### Komponen Utama

- `AuthService` adalah `ChangeNotifier` yang disuntikkan melalui `MultiProvider` di `main.dart`.
- Screen login, register, profile, order, dan halaman lain membaca `AuthService` melalui `Provider.of<AuthService>` atau `context.read<AuthService>()`.
- Perubahan sesi autentikasi dapat memicu refresh state secara terpusat.

### Aliran State

```text
Firebase Auth
   |
   v
AuthService (ChangeNotifier)
   |
   v
MultiProvider di main.dart
   |
   +--> LoginScreen
   +--> RegisterScreen
   +--> UserHome
   +--> DriverHomeScreen
   +--> UserProfile
   +--> DriverProfile
   +--> Admin pages
```

### Catatan Implementasi

- `AuthService.currentUser` dipakai untuk membaca user aktif.
- `AuthService.userChanges` tersedia untuk stream perubahan sesi.
- Service lain, seperti `NotificationService`, menerima `AuthService` sebagai dependency agar token FCM dapat disimpan ke Firestore.

## Firestore Database

Bagian ini diambil dari pola baca/tulis yang tampak pada service, screen, dan model yang ada.

### Collection: `users`

Koleksi ini menyimpan profil akun.

| Field           | Tipe        | Keterangan                                      |
| --------------- | ----------- | ----------------------------------------------- |
| `uid`           | string      | ID pengguna dari Firebase Auth                  |
| `name`          | string      | Nama lengkap                                    |
| `email`         | string      | Email pengguna                                  |
| `phone`         | string      | Nomor telepon                                   |
| `role`          | string      | `user`, `driver`, atau `admin`                  |
| `fcm_token`     | string/null | Token FCM perangkat                             |
| `status`        | string/null | Status akun, misalnya `offline` atau `active`   |
| `createdAt`     | timestamp   | Waktu registrasi pada `AuthService.register`    |
| `created_at`    | timestamp   | Waktu pembuatan data pada admin user management |
| `last_login_at` | timestamp   | Waktu login terakhir                            |

### Collection: `orders`

Koleksi ini adalah pusat alur operasional order aktif.

| Field                 | Tipe           | Keterangan                                                |
| --------------------- | -------------- | --------------------------------------------------------- |
| `order_id`            | string         | Nomor order internal                                      |
| `user_id`             | string         | ID user pemesan                                           |
| `driver_id`           | string/null    | ID driver yang ditugaskan                                 |
| `status`              | string         | Status proses order                                       |
| `payment_status`      | string         | Status pembayaran                                         |
| `weight`              | number         | Berat awal / estimasi                                     |
| `driver_weight`       | number         | Berat hasil timbangan driver                              |
| `final_weight`        | number         | Berat final setelah disetujui user                        |
| `distance`            | number         | Jarak penjemputan                                         |
| `price`               | number         | Harga order                                               |
| `price_paid`          | number         | Harga yang dibayar / dipakai sebagai referensi pembayaran |
| `address`             | string         | Alamat penjemputan                                        |
| `location`            | GeoPoint       | Titik koordinat penjemputan                               |
| `photo_urls`          | list<string>   | URL foto pendukung                                        |
| `pickup_date`         | timestamp/date | Jadwal penjemputan                                        |
| `created_at`          | timestamp      | Waktu order dibuat                                        |
| `updated_at`          | timestamp      | Waktu update terakhir                                     |
| `accepted_at`         | timestamp      | Waktu driver menerima order                               |
| `arrived_at`          | timestamp      | Waktu driver tiba                                         |
| `pickup_requested_at` | timestamp      | Waktu driver meminta validasi pickup                      |
| `weight_proposed_at`  | timestamp      | Waktu berat diajukan                                      |
| `picked_up_at`        | timestamp      | Waktu pickup dikonfirmasi user                            |
| `completed_at`        | timestamp      | Waktu order selesai                                       |
| `timestamp_end`       | timestamp      | Penanda akhir transaksi                                   |
| `archived`            | bool           | Penanda order selesai dan diarsipkan                      |
| `archived_at`         | timestamp      | Waktu arsip                                               |
| `hidden_by_user`      | bool           | Penanda order disembunyikan user di riwayat               |
| `hidden_by_driver`    | bool           | Penanda order disembunyikan driver di riwayat             |
| `weight_status`       | string         | `proposed`, `approved`, atau `disputed`                   |
| `last_message`        | map            | Ringkasan pesan terakhir untuk chat                       |

### Collection: `order_history`

Koleksi ini dipakai untuk riwayat dan laporan admin. `order_service.dart` menulis snapshot ke sini setiap order dibuat dan setiap perubahan penting terjadi.

| Field                 | Tipe           | Keterangan                           |
| --------------------- | -------------- | ------------------------------------ |
| `order_id`            | string         | ID order                             |
| `user_id`             | string         | ID user                              |
| `driver_id`           | string/null    | ID driver                            |
| `status`              | string         | Status terakhir                      |
| `payment_status`      | string         | Status pembayaran                    |
| `weight`              | number         | Berat awal                           |
| `driver_weight`       | number         | Berat proposal driver                |
| `final_weight`        | number         | Berat final                          |
| `distance`            | number         | Jarak                                |
| `price`               | number         | Harga                                |
| `price_paid`          | number         | Harga dibayar                        |
| `address`             | string         | Alamat                               |
| `location`            | GeoPoint       | Lokasi                               |
| `photo_urls`          | list<string>   | Foto terkait                         |
| `pickup_date`         | timestamp/date | Jadwal pickup                        |
| `created_at`          | timestamp      | Waktu pembuatan                      |
| `updated_at`          | timestamp      | Waktu update                         |
| `accepted_at`         | timestamp      | Waktu driver menerima                |
| `arrived_at`          | timestamp      | Waktu driver tiba                    |
| `pickup_requested_at` | timestamp      | Waktu driver meminta validasi pickup |
| `weight_proposed_at`  | timestamp      | Waktu proposal berat                 |
| `picked_up_at`        | timestamp      | Waktu pickup dikonfirmasi            |
| `completed_at`        | timestamp      | Waktu selesai                        |
| `timestamp_end`       | timestamp      | Waktu akhir transaksi                |
| `archived`            | bool           | Status arsip                         |
| `archived_at`         | timestamp      | Waktu arsip                          |
| `name`                | string         | Nama user                            |
| `phone_number`        | string         | Nomor telepon user                   |
| `hidden_by_user`      | bool           | Status sembunyi di riwayat user      |
| `hidden_by_driver`    | bool           | Status sembunyi di riwayat driver    |

### Subcollection: `orders/{orderId}/messages`

Dipakai oleh chat realtime.

| Field        | Tipe           | Keterangan                         |
| ------------ | -------------- | ---------------------------------- |
| `id`         | string         | ID pesan                           |
| `orderId`    | string         | ID order                           |
| `senderId`   | string         | ID pengirim                        |
| `senderRole` | string         | `user` atau `driver`               |
| `message`    | string         | Isi pesan                          |
| `createdAt`  | timestamp      | Waktu kirim                        |
| `readAt`     | timestamp/null | Waktu dibaca                       |
| `type`       | string         | `text`, `location`, atau tipe lain |
| `latitude`   | number/null    | Latitude lokasi                    |
| `longitude`  | number/null    | Longitude lokasi                   |

### Subcollection: `orders/{orderId}/chat_meta/meta`

Dipakai untuk penghitung unread.

| Field           | Tipe   | Keterangan                       |
| --------------- | ------ | -------------------------------- |
| `unread_user`   | number | Jumlah pesan belum dibaca user   |
| `unread_driver` | number | Jumlah pesan belum dibaca driver |

### Collection: `drivers_location`

Dipakai untuk tracking driver berbasis `LocationService`.

| Field         | Tipe        | Keterangan                            |
| ------------- | ----------- | ------------------------------------- |
| `lat`         | number      | Latitude                              |
| `lng`         | number      | Longitude                             |
| `last_update` | timestamp   | Waktu update terakhir                 |
| `order_id`    | string/null | Order yang sedang aktif bila tersedia |

### Collection: `drivers`

Dipakai oleh `DriverLocationService`.

| Field       | Tipe      | Keterangan    |
| ----------- | --------- | ------------- |
| `location`  | GeoPoint  | Lokasi driver |
| `heading`   | number    | Arah gerak    |
| `speed`     | number    | Kecepatan     |
| `updatedAt` | timestamp | Waktu update  |

### Collection: `users_location`

Dipakai dalam layar tracking tertentu untuk membaca lokasi user.

| Field       | Tipe        | Keterangan                 |
| ----------- | ----------- | -------------------------- |
| `lat`       | number      | Latitude                   |
| `lng`       | number      | Longitude                  |
| `latitude`  | number/null | Alternatif field latitude  |
| `longitude` | number/null | Alternatif field longitude |

### Catatan Model Firestore

- Project memakai campuran field snake_case dan camelCase karena evolusi implementasi di berbagai screen dan service.
- Dokumen baru ditulis terutama lewat `OrderService.createOrder`, `AuthService.register`, `AuthService.updateFcmToken`, dan berbagai method update status pada `OrderService`.
- Dashboard admin membaca agregasi terutama dari `order_history`.

## Penjelasan Semua Model

### `OrderModel`

File: `lib/models/order_model.dart`

Model untuk merepresentasikan order aktif atau order yang diambil dari Firestore.

Field utama:

- `id`
- `userId`
- `driverId`
- `status`
- `weight`
- `distance`
- `price`
- `address`
- `location`
- `photoUrls`
- `createdAt`
- `pickupDate`
- `name`
- `phoneNumber`
- `paymentStatus`

Model ini memiliki `fromDoc` untuk membaca `DocumentSnapshot` Firestore dan `toMap` untuk menulis kembali data ke Firestore.

### `UserModel`

File: `lib/models/user_model.dart`

Model profil akun user atau driver.

Field utama:

- `uid`
- `name`
- `email`
- `phone`
- `role`
- `fcmToken`
- `status`

Model ini memiliki `fromMap` dan `toMap`.

### `ChatMessage`

File: `lib/models/chat_message_model.dart`

Model pesan chat realtime.

Field utama:

- `id`
- `orderId`
- `senderId`
- `senderRole`
- `message`
- `createdAt`
- `readAt`
- `type`
- `latitude`
- `longitude`

### `DashboardStats`

File: `lib/screens/admin/models/dashboard_stats.dart`

Menyimpan ringkasan statistik admin.

Field:

- `totalRevenue`
- `totalCompletedOrders`
- `totalWeight`
- `totalUsers`
- `totalDrivers`

### `RevenueChartModel`

File: `lib/screens/admin/models/revenue_chart_model.dart`

Menyimpan revenue per bulan untuk grafik.

Field:

- `month`
- `revenue`

### `OrderChartModel`

File: `lib/screens/admin/models/order_chart_model.dart`

Menyimpan total order per bulan untuk grafik.

Field:

- `month`
- `totalOrders`

### `AdminLatestOrder`

File: `lib/screens/admin/models/admin_latest_order.dart`

Dipakai pada daftar order terbaru di dashboard admin.

Field:

- `id`
- `orderId`
- `userId`
- `driverId`
- `userName`
- `driverName`
- `address`
- `weight`
- `price`
- `status`
- `createdAt`

### `OrderDetailModel`

File: `lib/screens/admin/models/order_detail_model.dart`

Digunakan pada halaman detail order admin.

Field:

- `id`
- `orderId`
- `userId`
- `userEmail`
- `userName`
- `phoneNumber`
- `driverId`
- `driverName`
- `driverPhone`
- `driverStatus`
- `status`
- `paymentStatus`
- `weight`
- `distance`
- `price`
- `address`
- `location`
- `photoUrls`
- `createdAt`
- `acceptedAt`
- `completedAt`

### `TopDriverModel`

File: `lib/screens/admin/models/top_driver_model.dart`

Dipakai untuk daftar driver teraktif.

Field:

- `uid`
- `name`
- `phone`
- `totalOrders`
- `totalWeight`
- `totalRevenue`

### `TopUserModel`

File: `lib/screens/admin/models/top_user_model.dart`

Dipakai untuk daftar user teraktif.

Field:

- `uid`
- `name`
- `phone`
- `totalOrders`
- `totalWeight`
- `totalRevenue`

### `DashboardData`

File: `lib/screens/admin/dashboard/dashboard_data.dart`

Menggabungkan seluruh data dashboard admin.

Field:

- `stats`
- `revenueChart`
- `orderChart`
- `latestOrders`
- `topDrivers`
- `topUsers`

## Authentication Flow

Flow autentikasi pada project ini dibangun di atas Firebase Auth dan Firestore.

```text
Registrasi / Login
   |
   v
Firebase Authentication
   |
   v
Firestore: collection `users`
   |
   v
Ambil field `role`
   |
   +--> user  -> `UserHome`
   +--> driver -> `DriverHomeScreen`
   +--> admin  -> `AdminDashboard`
```

### Registrasi

`RegisterScreen` memanggil `AuthService.register()`. Service ini membuat akun baru di Firebase Auth, lalu menyimpan profil ke `users` dengan field `uid`, `name`, `phone`, `email`, `role`, `fcm_token`, `status`, `createdAt`, dan `last_login_at`.

### Login

`LoginScreen` memanggil `AuthService.login()`. Setelah login berhasil, aplikasi membaca dokumen `users/{uid}` untuk menentukan role akun.

### Redirect Berdasarkan Role

- `user` diarahkan ke `/user`.
- `driver` diarahkan ke `/driver`.
- `admin` diarahkan ke `/admin`.

### Logout

Logout ditangani oleh `AuthService.logout()` yang memanggil `FirebaseAuth.signOut()`.

### Google Autofill

Pada registrasi, user dapat mengambil nama dan email dari akun Google melalui `AuthService.getGoogleAccountData()`.

## Order Flow

Flow order pada kode saat ini berlangsung seperti berikut:

```text
User memilih lokasi
   |
   v
MapSelectionScreen
   |
   v
User mengisi alamat, berat, nama, telepon, tanggal
   |
   v
OrderService.createOrder()
   |
   v
Firestore: `orders` + `order_history`
   |
   v
Driver melihat order pending
   |
   v
Driver accept order
   |
   v
Order aktif -> chat / tracking / update status
   |
   v
Timbangan driver -> konfirmasi user
   |
   v
Pembayaran
   |
   v
Pickup validation -> arrived -> picked_up -> completed
   |
   v
Arsip dan riwayat
```

### Langkah Detail

1. User membuka peta dan menentukan titik lokasi penjemputan.
2. Aplikasi mengonversi titik tersebut menjadi `GeoPoint` dan alamat.
3. User memasukkan detail order.
4. `OrderService.createOrder()` menulis data ke `orders` dan `order_history`.
5. Driver melihat order baru pada `NewOrdersScreen`.
6. Driver menerima order dengan `acceptOrder()`.
7. Order berpindah menjadi `active`.
8. Chat dan tracking aktif untuk order yang sama.
9. Driver mengajukan berat melalui `proposeWeight()`.
10. User menyetujui atau menyanggah berat.
11. Saat status `waiting_payment`, user melakukan pembayaran Midtrans.
12. Setelah pembayaran berhasil, status berpindah ke `pickup_validation`.
13. Driver menandai tiba dan memproses pickup.
14. User mengonfirmasi pengambilan.
15. Driver menyelesaikan order.
16. Order diarsipkan untuk riwayat dan laporan.

### Data yang Disimpan Saat Order Dibuat

`createOrder()` menulis data berikut:

- `order_id`
- `user_id`
- `driver_id: null`
- `status`
- `payment_status: pending`
- `weight`
- `distance`
- `price`
- `price_paid`
- `address`
- `location`
- `photo_urls`
- `pickup_date`
- `created_at`
- `updated_at`
- `archived: false`
- `name`
- `phone_number`
- `hidden_by_user`
- `hidden_by_driver`

## Payment Flow

### Komponen yang Terlibat

- `payment.dart`
- `midtrans_payment_webview.dart`
- `OrderRoomScreen`
- `PickupScheduleScreen`
- `OrderService.markPaymentSuccessToPickupValidation()`

### Alur Pembayaran

```text
User pilih bayar
   |
   v
getMidtransSnapUrl()
   |
   v
HTTP POST ke backend Midtrans
   |
   v
Terima `redirect_url`
   |
   v
MidtransPaymentWebView
   |
   v
Deteksi finish / error / cancel
   |
   v
Firestore update payment_status
   |
   v
Status order lanjut ke pickup_validation
```

### `payment.dart`

File ini mengirim payload JSON ke backend API `https://api-midtrans-teal.vercel.app/api` dengan field:

- `order_id`
- `gross_amount`
- `name`
- `email`

Jika respon sukses mengandung `redirect_url`, URL itu dikembalikan ke caller.

### `midtrans_payment_webview.dart`

Halaman ini memuat halaman pembayaran pada WebView. File ini:

- mengaktifkan JavaScript unrestricted,
- memantau `onNavigationRequest`,
- mendeteksi URL `payment-finish`, `payment-error`, dan `payment-unfinish`,
- memperbarui dokumen order di Firestore jika pembayaran sukses,
- menutup halaman dengan payload status.

### Integrasi Setelah Pembayaran

- Saat pembayaran sukses, `payment_status` di-set menjadi `success`.
- Status order dipindahkan ke `pickup_validation`.
- Field `payment_time` dicatat.
- Notifikasi dapat dikirim ke driver melalui `NotificationService.notifyDriverPaymentSuccess()`.

### Catatan Implementasi

- Backend pembayaran berada di luar Flutter app dan dipanggil via HTTP.
- WebView dipilih agar pengguna tetap berada dalam konteks aplikasi.
- Midtrans finish callback dipakai untuk sinkronisasi status ke Firestore.

## Chat Flow

### Komponen Chat

- `ChatMessage`
- `ChatService`
- `ChatScreen`
- subcollection `orders/{orderId}/messages`
- subcollection `orders/{orderId}/chat_meta/meta`

### Alur Kerja Chat

```text
User/driver membuka chat order
   |
   v
Stream `messages` dari Firestore
   |
   v
Pesan dipetakan ke `ChatMessage`
   |
   v
Pesan teks / lokasi dikirim melalui ChatService
   |
   v
Unread counter di `chat_meta/meta` diperbarui
   |
   v
Pesan dibaca -> `readAt` diisi
```

### Fungsi `ChatService`

- `sendMessage()` menyimpan pesan teks.
- `sendLocation()` menyimpan pesan lokasi.
- `getMessages()` membaca stream pesan dengan urutan terbaru di atas.
- `markAsRead()` mengisi field `readAt`.
- `resetUnreadCounter()` mereset counter unread berdasarkan role.

### Fitur Chat yang Terlihat di UI

- Bubble pesan teks.
- Bubble pesan lokasi.
- Footer waktu pesan.
- Penanda status baca pada pesan yang dikirim oleh user sendiri.
- Integrasi ke Google Maps ketika bubble lokasi diketuk.

### Perilaku Realtime

- Saat message stream berubah, UI diperbarui otomatis.
- Pesan dari lawan bicara yang belum dibaca akan diproses ke `markAsRead()`.
- `last_message` pada order disimpan agar ringkasan percakapan mudah dibaca.

## Notification Flow

### Komponen

- `NotificationService`
- Firebase Messaging
- Flutter Local Notifications
- AuthService untuk update token

### Alur Notifikasi

```text
App start
   |
   v
NotificationService.init()
   |
   v
Request permission FCM
   |
   v
Ambil FCM token
   |
   v
Simpan token ke `users.fcm_token`
   |
   v
Listen `FirebaseMessaging.onMessage`
   |
   v
Tampilkan local notification
```

### Jenis Notifikasi yang Ada di Kode

- `notifyDriverPaymentSuccess()`
- `notifyUserPickupRequested()`
- `notifyUserDriverArrived()`
- `notifyBothCompleted()`

### Notifikasi Lokal

`NotificationService.showLocal()` dipakai untuk menampilkan notifikasi berbasis perangkat ketika aplikasi aktif atau saat event tertentu terjadi.

### Penggunaan Token

Token FCM disimpan lewat `AuthService.updateFcmToken()`, sehingga backend atau service lain dapat menargetkan perangkat yang benar.

### App Check

`FirebaseAppCheck.instance.activate()` dipanggil di `MyApp.initState()` dengan provider debug untuk Android dan Apple.

## Dashboard Admin

### Komponen Dashboard

- `AdminDashboard`
- `DashboardService`
- `DashboardData`
- `DashboardStatSection`
- `DashboardChartSection`
- `LatestOrders`
- `DashboardHeader`

### Statistik yang Ditampilkan

- Total revenue.
- Total order.
- Total berat sampah.
- Total user.
- Total driver.

### Grafik

- Grafik revenue per bulan dengan `LineChart`.
- Grafik total order per bulan dengan `BarChart`.

### Sumber Data

- `order_history` untuk agregasi utama.
- `users` untuk menghitung total user dan driver.

### Order Terbaru

`getLatestOrders()` mengambil 10 order terbaru dari `order_history`, lalu menghubungkan nama user dan driver lewat cache `users`.

### CRUD dan Monitoring

Halaman admin yang tersedia mendukung:

- filter status,
- pagination,
- edit order,
- hapus order,
- manajemen user/driver,
- laporan analitik,
- analisis pendapatan,
- detail order,
- monitoring driver teraktif,
- monitoring user teraktif.

### Catatan Implementasi Top User

Komponen top user sudah disiapkan, tetapi service `getTopUsers()` saat ini masih mengembalikan list kosong.

## Status Order

Status yang terlihat di source code adalah sebagai berikut.

| Status                    | Makna pada kode                                      |
| ------------------------- | ---------------------------------------------------- |
| `pending`                 | Order baru dibuat dan menunggu driver                |
| `active`                  | Driver sudah menerima order                          |
| `awaiting_confirmation`   | Driver mengajukan berat dan menunggu konfirmasi user |
| `waiting_payment`         | Berat sudah disetujui dan menunggu pembayaran        |
| `pickup_validation`       | Pembayaran sukses dan masuk tahap validasi pickup    |
| `arrived`                 | Driver telah tiba                                    |
| `waiting_user_validation` | Driver menunggu validasi pengambilan dari user       |
| `picked_up`               | User mengonfirmasi bahwa barang sudah diambil        |
| `completed`               | Order selesai                                        |
| `cancelled`               | Dipakai pada halaman admin untuk status batal        |

### Field Status Tambahan

Selain `status`, project juga memakai beberapa field status lain:

- `payment_status` dengan nilai seperti `pending`, `success`, dan `paid`.
- `weight_status` dengan nilai seperti `proposed`, `approved`, dan `disputed`.
- `archived` sebagai penanda arsip.
- `hidden_by_user` dan `hidden_by_driver` sebagai penanda riwayat tersembunyi.

### Catatan Penting

Project ini tidak menggunakan semua contoh status generik seperti `accepted` atau `on_the_way` sebagai nama utama di code yang dianalisis. Alur yang nyata memakai status yang tercantum pada tabel di atas.

## Cara Clone Project

### Clone HTTPS

```bash
git clone https://github.com/<username>/<repository>.git
cd <repository>
```

### Clone SSH

```bash
git clone git@github.com:<username>/<repository>.git
cd <repository>
```

### Masuk Folder Proyek

```bash
cd sampah_online
```

### Install Dependency

```bash
flutter pub get
```

## Cara Setup Flutter

### Flutter SDK

Gunakan Flutter yang kompatibel dengan Dart `^3.9.2` sesuai environment pada `pubspec.yaml`.

### Android Studio

Gunakan Android Studio untuk emulator, Android SDK, dan toolchain build Android.

### VS Code

VS Code dipakai sebagai editor utama sesuai konteks workspace repository ini.

### Android SDK

Pastikan Android SDK, platform tools, dan build tools terpasang.

### JDK

Gunakan JDK yang kompatibel dengan build Flutter Android Anda.

### Environment Variable

Pastikan `PATH` sudah mengenali `flutter`, `dart`, `java`, dan tool Android bila diperlukan.

## Setup Firebase

### 1. Buat Project Firebase

Buat project di Firebase Console dengan nama yang sesuai.

### 2. Jalankan FlutterFire Configure

```bash
flutterfire configure
```

### 3. Pastikan `firebase_options.dart`

File `lib/firebase_options.dart` sudah tersedia dan berisi konfigurasi untuk platform yang didukung.

### 4. Android

Pastikan `android/app/google-services.json` ada dan sesuai dengan project Firebase yang dipakai.

### 5. iOS

Pastikan konfigurasi iOS tersedia pada workspace jika target iPhone/iPad digunakan.

### 6. Web

Konfigurasi web menggunakan `FirebaseOptions.web` dari `firebase_options.dart`.

### 7. App Check

Aktifkan App Check sesuai kebutuhan lingkungan development dan production.

## Menjalankan Project

### Install Dependency

```bash
flutter pub get
```

### Jalankan Aplikasi

```bash
flutter run
```

### Bersihkan Build Cache

```bash
flutter clean
```

### Analisis Kode

```bash
flutter analyze
```

### Test Widget

```bash
flutter test
```

## Build

### APK Android

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web
```

### Windows

```bash
flutter build windows
```

## Struktur Coding

Project ini menunjukkan pola coding sebagai berikut:

- Pemisahan tanggung jawab antara `screens`, `services`, `models`, dan `utils`.
- `services` memegang logika bisnis dan integrasi Firebase.
- `models` memegang bentuk data.
- `screens` memegang presentasi dan interaksi pengguna.
- `utils` memegang helper yang dipakai lintas layar.
- Stateful widget dipakai pada layar yang memerlukan stream, timer, controller, atau dynamic UI.
- Banyak layar memanfaatkan `Provider` untuk membaca `AuthService`.
- Format tanggal dan angka dipusatkan lewat `AdminFormatter`.
- Alert dan dialog dipusatkan melalui `alerts.dart`.

### Konvensi Data

- Field Firestore memakai kombinasi snake_case dan camelCase sesuai kebutuhan evolusi implementasi.
- Timestamp Firestore dan `DateTime` Dart dikonversi secara eksplisit di model dan service.
- StreamBuilder dipakai untuk data realtime.
- `FutureBuilder` dipakai untuk data detail yang perlu satu kali fetch.

### Konvensi UI

- Material Design dipakai sebagai basis utama.
- `google_fonts` digunakan pada beberapa halaman untuk tampilan yang lebih konsisten.
- Komponen kartu, chip, dan section header dipakai berulang pada admin dan user flow.

## Security

### Firebase Rules

Firestore Rules harus dikunci sesuai role karena aplikasi ini memuat data user, driver, chat, dan order.

### App Check

App Check diaktifkan dari `main.dart` agar akses backend Firebase lebih terlindungi.

### Authentication

Firebase Auth dipakai sebagai pintu masuk utama. Semua role ditentukan setelah login berhasil.

### Authorization

Authorization didasarkan pada field `role` di Firestore dan pada validasi `user_id` atau `driver_id` di service order.

### Risiko yang Terkait Kode

- Status order diubah lewat service lokal sehingga aturan server-side tetap perlu diperketat.
- Chat dan lokasi berada di Firestore sehingga rules harus sangat spesifik.
- Token FCM perlu dijaga agar tidak disalahgunakan.

## Troubleshooting

1. Jika aplikasi gagal start karena Firebase, pastikan `Firebase.initializeApp()` menerima opsi dari `firebase_options.dart`.
2. Jika login gagal, cek apakah dokumen `users/{uid}` benar-benar ada setelah registrasi.
3. Jika role tidak sesuai, periksa field `role` di koleksi `users`.
4. Jika notifikasi tidak muncul, cek permission Firebase Messaging dan inisialisasi `NotificationService.init()`.
5. Jika WebView Midtrans tidak tampil, cek URL `snapUrl` yang diterima dari backend.
6. Jika pembayaran gagal diarahkan, cek apakah backend mengembalikan `redirect_url`.
7. Jika lokasi tidak terbaca, cek permission GPS dan status layanan lokasi perangkat.
8. Jika peta tidak muncul, cek konfigurasi `flutter_osm_plugin` dan koneksi internet.
9. Jika chat tidak update realtime, cek struktur subkoleksi `messages` pada order yang sama.
10. Jika unread counter salah, cek subkoleksi `chat_meta/meta`.
11. Jika driver tidak melihat order baru, pastikan `status = pending`, `driver_id = null`, dan `pickup_date` berada pada hari yang benar.
12. Jika admin dashboard kosong, cek data di `order_history` dan `users`.
13. Jika grafik tidak tampil, pastikan data bulanan memiliki field `created_at`.
14. Jika order tidak muncul di history, pastikan field `hidden_by_user` atau `hidden_by_driver` bernilai false.
15. Jika order detail admin gagal memuat driver, cek dokumen `users/{driver_id}`.
16. Jika analisis pendapatan kosong, cek order dengan `status = completed`.
17. Jika App Check menghalangi akses saat development, gunakan mode debug provider sesuai implementasi `main.dart`.
18. Jika aplikasi gagal build Android, periksa `google-services.json` dan konfigurasi Gradle.
19. Jika kode analyis gagal karena lint, jalankan `flutter analyze` untuk melihat file yang terdampak.
20. Jika icon aplikasi belum berubah, pastikan `flutter_launcher_icons` dikonfigurasi dan asset `assets/logo/icon.png` tersedia.

## FAQ

1. Apakah aplikasi ini berbasis Flutter? Ya, seluruh UI utama dibangun dengan Flutter.
2. Apakah backend memakai Firebase? Ya, project menggunakan Firebase Auth, Firestore, App Check, dan Messaging.
3. Apakah ada login khusus user, driver, dan admin? Ya, role dipisahkan dari field `role`.
4. Apakah user dapat membuat order? Ya, melalui flow pemilihan lokasi dan pengisian form order.
5. Apakah driver dapat menerima order? Ya, melalui service `acceptOrder()`.
6. Apakah ada fitur chat realtime? Ya, chat disimpan di subkoleksi `messages`.
7. Apakah ada pembayaran di dalam aplikasi? Ya, menggunakan Midtrans Snap melalui WebView.
8. Apakah ada notifikasi push? Ya, memakai Firebase Messaging dan local notifications.
9. Apakah ada tracking lokasi? Ya, dengan OSM, Geolocator, dan data driver location.
10. Apakah admin punya dashboard? Ya, dengan statistik, grafik, order terbaru, dan laporan.
11. Apakah ada riwayat order? Ya, dari `order_history` dan widget history.
12. Apakah ada edit profil? Ya, untuk user dan driver.
13. Apakah ada ubah password? Ya, untuk akun non-Google.
14. Apakah aplikasi sudah punya logo? Asset logo disiapkan pada `assets/logo/`, tetapi README ini masih memakai placeholder dokumentasi.
15. Apakah ada screenshot? Belum dicantumkan di README ini dan masih memakai placeholder.
16. Apakah ada lisensi MIT? Belum ada file license di repository, sehingga masih placeholder.
17. Apakah ada top user di dashboard? Model dan section-nya ada, tetapi service pengisiannya masih kosong.
18. Apakah ada top driver di dashboard? Ya, data driver teraktif sudah dihitung di service.
19. Apakah ada pengujian? Ada folder `test/`, tetapi isi pengujian yang terlihat sangat minimal.
20. Apakah aplikasi mendukung web dan desktop? Struktur Flutter untuk web, Windows, Linux, macOS, dan iOS tersedia.

## Roadmap

Roadmap berikut disusun dari struktur kode yang sudah ada dan dari area yang masih terlihat bisa diperluas.

- Menambahkan screenshot resmi untuk seluruh role.
- Menambahkan file lisensi yang jelas.
- Mengisi `getTopUsers()` dengan data agregasi nyata.
- Menyatukan pola field Firestore agar lebih konsisten.
- Memindahkan beberapa logika kritis ke server-side function.
- Menambah test unit untuk service utama.
- Menambah test widget untuk layar penting.
- Menambah dokumentasi Firestore Rules.
- Menambah dokumentasi skema backend Midtrans.
- Menambah monitoring error runtime yang lebih terstruktur.
- Menambah dukungan upload foto order yang eksplisit pada UI jika dibutuhkan.
- Menambah halaman manajemen lokasi driver yang lebih detail.

## Kontribusi

### Langkah Kontribusi

1. Fork repository ini.
2. Buat branch baru untuk fitur atau perbaikan.
3. Kerjakan perubahan secara fokus.
4. Jalankan `flutter analyze` dan `flutter test`.
5. Push branch ke remote repository Anda.
6. Ajukan Pull Request dengan deskripsi yang jelas.

### Rekomendasi Praktik

- Pertahankan pemisahan `screens`, `services`, `models`, dan `utils`.
- Hindari mencampur logika Firestore langsung di UI jika sudah ada service yang sesuai.
- Jaga konsistensi penamaan field Firestore.
- Jangan menambahkan data yang tidak dibutuhkan oleh flow yang ada.

## Kontributor

Nama kontributor yang tercantum pada repository sebelumnya:

- [`Nasrullah Akbar Fadriansyah`](https://github.com/Nasrullah-Akbar-Fadriansyah)
- [`Yudi Alfarizi`](https://github.com/Yudi-Alfarizi)
- [`Achmad Syahrudin`](https://github.com/achmadsyahrdn)
- [`Aditya April Riandi`](https://github.com/aditya100402)

## Lisensi

Lisensi repository ini belum ditetapkan dalam workspace yang tersedia.

Jika Anda ingin memakai lisensi open source tertentu, tambahkan file `LICENSE` ke repository dan perbarui badge lisensi di bagian cover.
