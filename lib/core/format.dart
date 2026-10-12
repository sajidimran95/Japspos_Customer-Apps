import 'package:intl/intl.dart';

final NumberFormat _money2 = NumberFormat('#,##0.00', 'en_US');

String money(num? v) => '\$${_money2.format(v ?? 0)}';

String qtyText(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String fmtMdY(DateTime d) => DateFormat('MM/dd/y').format(d);
String fmtMonDY(DateTime d) => DateFormat('MMM dd, y').format(d);
String fmtMonDYNoComma(DateTime d) => DateFormat('MMM dd y').format(d);
String fmtDayGroup(DateTime d) => DateFormat('EEE, MMM dd y').format(d);
String fmtYmd(DateTime d) => DateFormat('y-MM-dd').format(d);

String initialsOf(String text) {
  final clean = text.replaceAll(RegExp(r'[^A-Za-z0-9\s]'), '').trim();
  if (clean.isEmpty) return 'C';
  final parts = clean.split(RegExp(r'\s+'));
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}
