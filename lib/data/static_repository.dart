import 'dart:typed_data';

import '../core/format.dart';
import '../core/storage.dart';
import 'models.dart';
import 'repository.dart';

/// Demo data used while the store's JapsPos API is not active.
class StaticCustomerRepository implements CustomerRepository {
  StaticCustomerRepository(this._store);

  final LocalStore _store;

  static const _business = Business(name: 'Japs POS');
  static const _customer = Customer(
    id: 1390,
    name: 'Tony',
    contactId: 'CO0001',
    businessName: 'Tony & Prem Service Station',
    email: 'customer@example.com',
    mobile: '13474972046',
    address1: '206-06 Jamaica Ave',
    city: 'Queens Village',
    state: 'NY',
    zip: '11428',
    country: 'USA',
    shippingAddress: '206-06 Jamaica Ave, Queens Village NY 11428',
    balanceDue: 426.46,
  );

  static const _locations = [
    StoreLocation(id: 2, label: 'New Jersey', name: 'Japs POS NJ', city: 'Newark'),
    StoreLocation(id: 1, label: 'New York', name: 'Japs POS', city: 'New York'),
  ];

  static const _categories = [
    Category(id: 84, name: 'Beverages', subs: [Category(id: 110, name: 'Soda'), Category(id: 111, name: 'Water'), Category(id: 112, name: 'Energy Drinks')]),
    Category(id: 85, name: 'Candy & Snacks', subs: [Category(id: 120, name: 'Chocolate'), Category(id: 121, name: 'Chips')]),
    Category(id: 86, name: 'Paper Bags'),
    Category(id: 87, name: 'Grocery'),
    Category(id: 88, name: 'Tobacco Accessories'),
  ];

  // (product, category, sub-category)
  static final List<(Product, int, int)> _catalog = [
    (const Product(productId: 5536, variationId: 5536, name: '#1 BROWN IND-IMPORT PAPER BAGS 500/CS', sku: '878507435386', price: 11.99, stock: 40), 86, 0),
    (const Product(productId: 5537, variationId: 5537, name: '#10 BROWN IND-IMPORT BAGS 500/CS', sku: 'SKU4580', price: 13.99, stock: 25), 86, 0),
    (const Product(productId: 5538, variationId: 5538, name: '#12 BROWN IND-IMPORT BAGS 500/CS', sku: 'SKU4623', price: 23.99, stock: 18), 86, 0),
    (const Product(productId: 5541, variationId: 5541, name: '#16 BROWN BAGS 500/CS', sku: 'SKU4625', price: 20.99, stock: 30), 86, 0),
    (const Product(productId: 5542, variationId: 5542, name: '#20 BROWN BAGS 500/CS', sku: 'SKU4626', price: 24.49, stock: 12), 86, 0),
    (const Product(productId: 5645, variationId: 5645, name: 'POLAND SPRING SPORTS CAP 24PK', sku: '075720710034', price: 14.49, stock: 60), 84, 111),
    (const Product(productId: 5646, variationId: 5646, name: 'POLAND SPRING GALLON 6PK', sku: '075720005048', price: 11.99, stock: 45), 84, 111),
    (const Product(productId: 5650, variationId: 5650, name: 'COCA-COLA 20OZ 24PK', sku: '049000028911', price: 32.99, stock: 50), 84, 110),
    (const Product(productId: 5651, variationId: 5651, name: 'PEPSI 20OZ 24PK', sku: '012000001291', price: 31.49, stock: 36), 84, 110),
    (const Product(productId: 5652, variationId: 5652, name: 'SPRITE 20OZ 24PK', sku: '049000028928', price: 32.99, stock: 28), 84, 110),
    (const Product(productId: 5653, variationId: 5653, name: 'RED BULL 8.4OZ 24PK', sku: '611269991000', price: 44.99, stock: 20), 84, 112),
    (const Product(productId: 5654, variationId: 5654, name: 'MONSTER ENERGY 16OZ 24PK', sku: '070847811169', price: 42.49, stock: 22), 84, 112),
    (const Product(productId: 5660, variationId: 5660, name: 'SNICKERS SINGLES 48CT', sku: '040000424314', price: 54.99, stock: 15), 85, 120),
    (const Product(productId: 5661, variationId: 5661, name: 'M&M PEANUT SINGLES 48CT', sku: '040000424321', price: 54.99, stock: 14), 85, 120),
    (const Product(productId: 5662, variationId: 5662, name: 'KIT KAT SINGLES 36CT', sku: '034000002405', price: 41.99, stock: 16), 85, 120),
    (const Product(productId: 5663, variationId: 5663, name: 'LAYS CLASSIC 1OZ 64CT', sku: '028400090858', price: 29.99, stock: 24), 85, 121),
    (const Product(productId: 5664, variationId: 5664, name: 'DORITOS NACHO 1OZ 64CT', sku: '028400090865', price: 29.99, stock: 24), 85, 121),
    (const Product(productId: 5670, variationId: 5670, name: 'DOMINO SUGAR 4LB', sku: '049200045121', price: 4.29, stock: 80), 87, 0),
    (const Product(productId: 5671, variationId: 5671, name: 'GOYA RICE 5LB', sku: '041331012345', price: 6.99, stock: 64), 87, 0),
    (const Product(productId: 5672, variationId: 5672, name: 'CARNATION EVAPORATED MILK 12OZ', sku: '050000470004', price: 1.79, stock: 120), 87, 0),
    (const Product(productId: 5680, variationId: 5680, name: 'BIC LIGHTERS 50CT TRAY', sku: '070330601219', price: 52.99, stock: 10), 88, 0),
    (const Product(productId: 5681, variationId: 5681, name: 'RAW CLASSIC PAPERS 24CT', sku: '716165177357', price: 27.49, stock: 18), 88, 0),
  ];

  final List<OrderRow> _orders = [
    OrderRow(id: 452, invoiceNo: '2026/0008', kind: 'order', date: DateTime(2026, 10, 9, 15, 25), total: 20.99, shippingStatus: 'ordered', shippingMethod: 'Pickup'),
    OrderRow(id: 447, invoiceNo: '0116', kind: 'invoice', type: 'sell', status: 'final', date: DateTime(2026, 9, 29, 14, 51), total: 13.99, paymentStatus: 'paid'),
    OrderRow(id: 440, invoiceNo: '2026/0005', kind: 'order', date: DateTime(2026, 9, 17, 14, 29), total: 51.96, shippingStatus: 'ordered', shippingMethod: 'Delivery'),
    OrderRow(id: 431, invoiceNo: '0107', kind: 'invoice', type: 'sell', status: 'final', date: DateTime(2026, 9, 16, 10, 5), total: 269.50, paymentStatus: 'partial'),
    OrderRow(id: 425, invoiceNo: '0101', kind: 'invoice', type: 'sell', status: 'final', date: DateTime(2026, 9, 2, 12, 40), total: 156.96, paymentStatus: 'due'),
  ];

  final Map<int, OrderDetail> _details = {};

  static final List<Invoice> _invoices = [
    Invoice(id: 447, invoiceNo: '0116', date: DateTime(2026, 9, 29, 14, 51), total: 13.99, paid: 13.99),
    Invoice(id: 446, invoiceNo: '0115', date: DateTime(2026, 9, 29, 9, 12), total: 98.45, tax: 4.12, paid: 98.45),
    Invoice(id: 431, invoiceNo: '0107', date: DateTime(2026, 9, 16, 10, 5), total: 269.50, tax: 8.40, paid: 149.50, balanceDue: 120),
    Invoice(id: 428, invoiceNo: '0104', date: DateTime(2026, 9, 10, 16, 20), total: 312.80, tax: 9.75, paid: 312.80),
    Invoice(id: 425, invoiceNo: '0101', date: DateTime(2026, 9, 2, 12, 40), total: 156.96, tax: 5.20, balanceDue: 156.96),
    Invoice(id: 419, invoiceNo: '0096', date: DateTime(2026, 8, 25, 11, 0), total: 205.10, tax: 6.18, paid: 205.10),
    Invoice(id: 410, invoiceNo: '0090', date: DateTime(2026, 8, 18, 15, 45), total: 149.50, paid: 0, balanceDue: 149.50),
    Invoice(id: 402, invoiceNo: '0084', date: DateTime(2026, 8, 4, 10, 30), total: 422.26, tax: 6.00, paid: 422.26),
  ];

  static Future<T> _delay<T>(T v) => Future.delayed(const Duration(milliseconds: 250), () => v);

  int get _locationId => _store.locationId ?? _locations.last.id;

  @override
  Future<({String token, Customer customer, Business business})> login(String login, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (login.trim().isEmpty || password.isEmpty) throw RepoException('Invalid email/mobile or password.');
    return (token: 'demo-token', customer: _customer, business: _business);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<HomeData> home() => _delay(HomeData(
        balanceDue: _customer.balanceDue,
        location: _locations.firstWhere((l) => l.id == _locationId, orElse: () => _locations.last),
        newArrivals: _catalog.reversed.take(8).map((e) => e.$1).toList(),
        topProducts: ([..._catalog.map((e) => e.$1)]..sort((a, b) => a.name.compareTo(b.name))).take(8).toList(),
      ));

  @override
  Future<({int? currentId, List<StoreLocation> locations})> locations() => _delay((currentId: _locationId, locations: _locations));

  @override
  Future<String> setLocation(int id) async {
    await _store.setLocationId(id);
    return 'Location updated: ${_locations.firstWhere((l) => l.id == id).label}';
  }

  @override
  Future<List<Category>> categories() => _delay(_categories);

  @override
  Future<List<Product>> products({int? locationId, String q = '', int categoryId = 0, int subCategoryId = 0, int? variationId, int limit = 20}) {
    final s = q.trim().toLowerCase();
    final rows = _catalog
        .where((e) {
          if (variationId != null) return e.$1.variationId == variationId;
          if (subCategoryId != 0 && e.$3 != subCategoryId) return false;
          if (subCategoryId == 0 && categoryId != 0 && e.$2 != categoryId) return false;
          return s.isEmpty || e.$1.name.toLowerCase().contains(s) || e.$1.sku.toLowerCase().contains(s);
        })
        .map((e) => e.$1)
        .take(limit)
        .toList();
    return _delay(rows);
  }

  @override
  Future<List<OrderRow>> orders() => _delay(List.of(_orders));

  @override
  Future<OrderDetail> order(int id) {
    final known = _details[id];
    if (known != null) return _delay(known);
    final row = _orders.firstWhere((o) => o.id == id, orElse: () => throw RepoException('Order not found.'));
    final picks = _catalog.map((e) => e.$1).where((p) => p.price <= row.total).take(3).toList();
    final lines = <OrderLineView>[];
    var left = row.total;
    for (var k = 0; k < picks.length && left > 0.009; k++) {
      final p = picks[k];
      final last = k == picks.length - 1 || left - p.price < p.price;
      final qty = last ? (left / p.price).floor().clamp(1, 99) : 1;
      final total = last ? left : p.price * qty;
      final unit = total / qty;
      lines.add(OrderLineView(
        name: p.name,
        sku: p.sku,
        upc: p.sku,
        qty: qty.toDouble(),
        unitBefore: p.price > unit ? p.price : unit,
        unitFinal: unit,
        lineTotal: total,
        hasDiscount: p.price > unit + 0.009,
      ));
      left -= total;
      if (last) break;
    }
    final detail = OrderDetail(
      order: row,
      fulfillment: row.shippingMethod.isEmpty ? 'delivery' : row.shippingMethod.toLowerCase(),
      shippingAddress: _customer.shippingAddress,
      lines: lines,
      itemsTotal: lines.fold(0, (t, l) => t + l.lineTotal),
    );
    _details[id] = detail;
    return _delay(detail);
  }

  @override
  Future<OrderCreateData> orderCreateData() => _delay(OrderCreateData(
        defaultLocationId: _locationId,
        locations: _locations,
        shippingAddress: _customer.shippingAddress,
      ));

  @override
  Future<({String message, OrderRow order})> placeOrder(OrderInput input) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = _orders.map((o) => o.id).fold(0, (a, b) => a > b ? a : b) + 1;
    final seq = _orders.where((o) => o.kind == 'order').length + 4;
    final row = OrderRow(
      id: id,
      invoiceNo: '2026/${seq.toString().padLeft(4, '0')}',
      kind: 'order',
      date: DateTime.now(),
      total: input.total,
      shippingStatus: 'ordered',
      shippingMethod: input.shippingMethod,
    );
    _orders.insert(0, row);
    _details[id] = OrderDetail(
      order: row,
      fulfillment: input.shippingMethod.toLowerCase(),
      shippingAddress: input.shippingAddress,
      note: input.note,
      lines: input.lines
          .map((l) => OrderLineView(
                name: l.product.name,
                image: l.product.image,
                sku: l.product.sku,
                upc: l.product.sku,
                qty: l.qty.toDouble(),
                unitBefore: l.product.price,
                unitFinal: l.product.price,
                lineTotal: l.total,
              ))
          .toList(),
      itemsTotal: input.total,
    );
    return (message: 'Order placed: ${row.invoiceNo}', order: row);
  }

  @override
  Future<DocumentsData> documents({DateTime? start, DateTime? end, String q = ''}) {
    final s = q.trim().toLowerCase();
    final rows = _invoices.where((i) {
      final day = DateTime(i.date.year, i.date.month, i.date.day);
      if (start != null && day.isBefore(start)) return false;
      if (end != null && day.isAfter(end)) return false;
      return s.isEmpty || i.invoiceNo.toLowerCase().contains(s);
    }).toList();
    return _delay(DocumentsData.fromInvoices(rows));
  }

  @override
  Future<String> invoiceHtml(int invoiceId) async {
    final inv = _invoices.firstWhere((i) => i.id == invoiceId, orElse: () => throw RepoException('Invoice not found.'));
    final c = _customer;
    final sub = inv.total - inv.tax;
    return '''
<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:Helvetica,Arial,sans-serif;color:#0f172a;margin:0;padding:18px;font-size:13px}
.top{display:flex;justify-content:space-between;align-items:flex-start;border-bottom:3px solid #e11d48;padding-bottom:12px}
h1{margin:0;font-size:22px} .muted{color:#64748b} .tag{font-size:26px;font-weight:800;color:#e11d48;text-align:right}
table{width:100%;border-collapse:collapse;margin-top:16px} th{background:#f1f5f9;text-align:left;padding:8px;font-size:12px}
td{padding:8px;border-bottom:1px solid #e2e8f0} .r{text-align:right} .tot td{border:0;padding:4px 8px} .grand td{font-weight:800;font-size:15px}
.box{display:flex;gap:16px;margin-top:14px} .box div{flex:1;background:#f8fafc;border-radius:10px;padding:10px}
</style></head><body>
<div class="top"><div><h1>${_business.name}</h1><div class="muted">New York, NY</div></div>
<div><div class="tag">INVOICE</div><div class="r">#${inv.invoiceNo}<br>${fmtMdY(inv.date)}</div></div></div>
<div class="box"><div><b>Bill To</b><br>${c.displayName}<br>${c.address1}<br>${c.city} ${c.state} ${c.zip}<br>Acct #: ${c.contactId}</div>
<div><b>Ship To</b><br>${c.shippingAddress}</div></div>
<table><tr><th>Item</th><th class="r">Qty</th><th class="r">Price</th><th class="r">Total</th></tr>
<tr><td>Assorted merchandise</td><td class="r">1</td><td class="r">${money(sub)}</td><td class="r">${money(sub)}</td></tr></table>
<table class="tot"><tr><td class="r muted">Subtotal</td><td class="r" style="width:110px">${money(sub)}</td></tr>
<tr><td class="r muted">Tax</td><td class="r">${money(inv.tax)}</td></tr>
<tr class="grand"><td class="r">Total</td><td class="r">${money(inv.total)}</td></tr>
<tr><td class="r muted">Paid</td><td class="r">${money(inv.paid)}</td></tr>
<tr><td class="r muted">Balance Due</td><td class="r">${money(inv.total - inv.paid)}</td></tr></table>
<p class="muted" style="margin-top:24px;text-align:center">Thank you for your business!</p>
</body></html>''';
  }

  @override
  Future<Uint8List?> invoicePdf(int invoiceId) async => null;

  @override
  Future<ProfileData> profile() => _delay(ProfileData(customer: _customer, currentLocationId: _locationId, locations: _locations));

  @override
  Future<String> changePassword(String current, String password, String confirm) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (password.length < 4) throw RepoException('The password must be at least 4 characters.');
    if (password != confirm) throw RepoException('The password confirmation does not match.');
    return 'Password updated successfully.';
  }
}
