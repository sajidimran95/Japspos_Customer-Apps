import 'dart:typed_data';

import 'models.dart';

class RepoException implements Exception {
  RepoException(this.message, {this.data});
  final String message;
  final dynamic data;
  @override
  String toString() => message;
}

/// Everything the Customer app needs from JapsPos. One method per `/customer/*`
/// screen of the web portal.
abstract class CustomerRepository {
  // Auth
  Future<({String token, Customer customer, Business business})> login(String login, String password);
  Future<void> logout();

  // Home
  Future<HomeData> home();

  // Store locations
  Future<({int? currentId, List<StoreLocation> locations})> locations();
  Future<String> setLocation(int id);

  // Catalog / price check
  Future<List<Category>> categories();
  Future<List<Product>> products({int? locationId, String q = '', int categoryId = 0, int subCategoryId = 0, int? variationId, int limit = 20});

  // Orders
  Future<List<OrderRow>> orders();
  Future<OrderDetail> order(int id);
  Future<OrderCreateData> orderCreateData();
  Future<({String message, OrderRow order})> placeOrder(OrderInput input);

  // Documents
  Future<DocumentsData> documents({DateTime? start, DateTime? end, String q = ''});

  /// Printable invoice as HTML (the store's real invoice layout).
  Future<String> invoiceHtml(int invoiceId);

  /// Invoice PDF for share / save, or null when the data source can't make one.
  Future<Uint8List?> invoicePdf(int invoiceId);

  // Profile
  Future<ProfileData> profile();
  Future<String> changePassword(String current, String password, String confirm);
}
