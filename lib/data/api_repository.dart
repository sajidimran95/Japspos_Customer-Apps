import 'dart:typed_data';

import '../core/format.dart';
import '../core/storage.dart';
import 'api_client.dart';
import 'models.dart';
import 'repository.dart';

/// Live data source: the JapsPos Customer API (`{BASE_URL}/api/v1/customer/*`).
class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  static Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<Map<String, dynamic>> _rows(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
  static int? _id(dynamic v) {
    final n = v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    return n == null || n <= 0 ? null : n;
  }

  List<StoreLocation> _locations(dynamic v) => _rows(v).map(StoreLocation.fromJson).toList();

  @override
  Future<({String token, Customer customer, Business business})> login(String login, String password) async {
    final d = (await _api.send('POST', '/auth/login', body: {'login': login, 'password': password, 'device_name': 'Customer Apps (Flutter)'}, authCall: true)).map;
    final token = '${d['token'] ?? ''}';
    _api.token = token;
    return (token: token, customer: Customer.fromJson(_m(d['customer'])), business: Business.fromJson(_m(d['business'])));
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
  }

  @override
  Future<HomeData> home() async {
    final d = (await _api.get('/home')).map;
    final loc = _m(d['current_location']);
    return HomeData(
      balanceDue: _d(d['balance_due']),
      location: loc.isEmpty ? null : StoreLocation.fromJson(loc),
      newArrivals: _rows(d['new_arrivals']).map(Product.fromJson).toList(),
      topProducts: _rows(d['top_products']).map(Product.fromJson).toList(),
    );
  }

  @override
  Future<({int? currentId, List<StoreLocation> locations})> locations() async {
    final d = (await _api.get('/locations')).map;
    final id = _id(d['current_location_id']);
    if (id != null) await _store.setLocationId(id);
    return (currentId: id, locations: _locations(d['locations']));
  }

  @override
  Future<String> setLocation(int id) async {
    final res = await _api.post('/locations/current', {'location_id': id});
    await _store.setLocationId(id);
    return res.message ?? 'Location updated';
  }

  @override
  Future<List<Category>> categories() async => _rows((await _api.get('/categories')).data).map(Category.fromJson).toList();

  @override
  Future<List<Product>> products({int? locationId, String q = '', int categoryId = 0, int subCategoryId = 0, int? variationId, int limit = 20}) async =>
      _rows((await _api.get('/products', {
        'q': q,
        'location_id': locationId,
        'category_id': categoryId == 0 ? null : categoryId,
        'sub_category_id': subCategoryId == 0 ? null : subCategoryId,
        'variation_id': variationId,
        'limit': limit.clamp(1, 80),
      }))
              .data)
          .map(Product.fromJson)
          .toList();

  @override
  Future<List<OrderRow>> orders() async => _rows((await _api.get('/orders')).map['orders']).map(OrderRow.fromJson).toList();

  @override
  Future<OrderDetail> order(int id) async {
    final d = (await _api.get('/orders/$id')).map;
    final o = _m(d['order']);
    final lines = _rows(d['lines']).map(OrderLineView.fromJson).toList();
    return OrderDetail(
      order: OrderRow.fromJson(o),
      fulfillment: '${o['fulfillment'] ?? 'delivery'}'.toLowerCase(),
      shippingAddress: '${o['shipping_address'] ?? ''}',
      note: '${o['sale_note'] ?? ''}',
      lines: lines,
      itemsTotal: d['items_total'] == null ? lines.fold(0, (t, l) => t + l.lineTotal) : _d(d['items_total']),
    );
  }

  @override
  Future<OrderCreateData> orderCreateData() async {
    final d = (await _api.get('/orders/create')).map;
    return OrderCreateData(
      defaultLocationId: _id(d['default_location_id']),
      locations: _locations(d['locations']),
      shippingAddress: '${d['shipping_address'] ?? ''}',
      defaultFulfillment: '${d['default_fulfillment'] ?? 'Delivery'}',
    );
  }

  @override
  Future<({String message, OrderRow order})> placeOrder(OrderInput input) async {
    final res = await _api.post('/orders', input.toJson());
    return (message: res.message ?? 'Order placed', order: OrderRow.fromJson(_m(res.map['order'])));
  }

  @override
  Future<DocumentsData> documents({DateTime? start, DateTime? end, String q = ''}) async {
    final d = (await _api.get('/documents', {
      'start_date': start == null ? null : fmtYmd(start),
      'end_date': end == null ? null : fmtYmd(end),
      'q': q,
    }))
        .map;
    final s = _m(d['summary']);
    return DocumentsData(
      invoices: _rows(d['invoices']).map(Invoice.fromJson).toList(),
      invoiceCount: (s['invoice_count'] as num?)?.toInt() ?? 0,
      salesTotal: _d(s['sales_total']),
      taxTotal: _d(s['tax_total']),
      paidTotal: _d(s['paid_total']),
    );
  }

  @override
  Future<String> invoiceHtml(int invoiceId) async => '${(await _api.get('/documents/$invoiceId/invoice', {'format': 'json'})).map['html'] ?? ''}';

  @override
  Future<Uint8List?> invoicePdf(int invoiceId) => _api.bytes('/documents/$invoiceId/invoice', {'format': 'pdf'});

  @override
  Future<ProfileData> profile() async {
    final d = (await _api.get('/profile')).map;
    return ProfileData(customer: Customer.fromJson(_m(d['customer'])), currentLocationId: _id(d['current_location_id']), locations: _locations(d['locations']));
  }

  @override
  Future<String> changePassword(String current, String password, String confirm) async =>
      (await _api.post('/profile/password', {'current_password': current, 'password': password, 'password_confirmation': confirm})).message ??
      'Password updated successfully.';
}
