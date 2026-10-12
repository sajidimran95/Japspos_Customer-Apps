import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// The Create Order cart: one line per variation, quantity in pieces.
class CartState extends ChangeNotifier {
  final List<CartLine> lines = [];
  String fulfillment = 'Delivery';
  int? locationId;

  bool get isEmpty => lines.isEmpty;
  double get total => lines.fold(0, (t, l) => t + l.total);
  int qtyOf(int variationId) => lines.where((l) => l.product.variationId == variationId).firstOrNull?.qty ?? 0;

  void add(Product p) {
    final ex = lines.where((l) => l.product.variationId == p.variationId).firstOrNull;
    if (ex != null) {
      ex.qty += 1;
    } else {
      lines.add(CartLine(product: p));
    }
    notifyListeners();
  }

  void change(CartLine line, int delta) {
    line.qty += delta;
    if (line.qty <= 0) lines.remove(line);
    notifyListeners();
  }

  void setFulfillment(String v) {
    fulfillment = v;
    notifyListeners();
  }

  void setLocation(int? id) {
    locationId = id;
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}
