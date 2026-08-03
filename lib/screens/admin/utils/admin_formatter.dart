import 'package:intl/intl.dart';

/// Fungsi: Utilitas Pemformat Teks, Mata Uang, & Tanggal/Waktu Khusus Panel Admin (Admin Formatter Utility).
/// Cara Kerja:
/// 1. Menggunakan pustaka `intl` dengan konfigurasi standar Bahasa Indonesia (`id_ID`).
/// 2. Mengonversi tipe data numerik mentah (`double` / `int`) menjadi format Rupiah, Kilogram, dan Kilometer.
/// 3. Mengonversi objek `DateTime` menjadi representasi tanggal dan waktu yang mudah dibaca oleh manusia.
///
/// Operasi Data:
/// - Fungsi murni (*Pure Helper Utility*) penunjang tampilan UI di seluruh layar modul admin GoTrash.
class AdminFormatter {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _number = NumberFormat("#,##0.##", "id_ID");

  /// Mengonversi nilai numerik menjadi teks format Rupiah (contoh: `15000` -> `Rp 15.000`).
  static String rupiah(double value) {
    return _currency.format(value);
  }

  /// Mengonversi nilai numerik berat menjadi teks bersatuan Kg (contoh: `2.5` -> `2,5 Kg`).
  static String weight(double value) {
    return "${_number.format(value)} Kg";
  }

  /// Mengonversi nilai numerik jarak menjadi teks bersatuan Km (contoh: `1.2` -> `1,2 Km`).
  static String distance(double value) {
    return "${_number.format(value)} Km";
  }

  /// Mengonversi `DateTime` menjadi format tanggal Indonesia (contoh: `03 Agustus 2026`).
  static String date(DateTime date) {
    return DateFormat("dd MMMM yyyy", "id_ID").format(date);
  }

  /// Mengonversi `DateTime` menjadi format jam dan menit (contoh: `14:30`).
  static String time(DateTime date) {
    return DateFormat("HH:mm", "id_ID").format(date);
  }

  /// Mengonversi `DateTime` menjadi gabungan tanggal dan waktu (contoh: `03 Agu 2026 • 14:30`).
  static String dateTime(DateTime date) {
    return DateFormat("dd MMM yyyy • HH:mm", "id_ID").format(date);
  }
}
