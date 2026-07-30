import 'package:intl/intl.dart';

class AdminFormatter {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _number = NumberFormat("#,##0.##", "id_ID");

  static String rupiah(double value) {
    return _currency.format(value);
  }

  static String weight(double value) {
    return "${_number.format(value)} Kg";
  }

  static String distance(double value) {
    return "${_number.format(value)} Km";
  }

  static String date(DateTime date) {
    return DateFormat("dd MMMM yyyy", "id_ID").format(date);
  }

  static String time(DateTime date) {
    return DateFormat("HH:mm", "id_ID").format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat("dd MMM yyyy • HH:mm", "id_ID").format(date);
  }
}
