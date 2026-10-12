import 'package:flutter/foundation.dart';

import '../core/storage.dart';
import '../data/api_client.dart';
import '../data/api_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/static_repository.dart';

enum AppStage { setup, login, home }

/// Bottom-nav tabs, in portal order.
enum CaTab { home, order, docs, price, orders }

class AppState extends ChangeNotifier {
  AppState(this.store) {
    _rebuildRepo();
    final c = store.customer;
    if (c != null) customer = Customer.fromJson(c);
    final b = store.business;
    if (b != null) business = Business.fromJson(b);
    _recheckDemoServer();
  }

  final LocalStore store;
  late CustomerRepository repo;
  Customer? customer;
  Business? business;
  CaTab tab = CaTab.home;

  /// Selected store location label ("📍 New York" in the portal header).
  String locationLabel = '';

  String get companyName => store.companyName ?? '';
  String get baseUrl => store.baseUrl ?? '';
  String get businessName => (business?.name.isNotEmpty ?? false) ? business!.name : companyName;

  /// True when the base URL has no active JapsPos API and demo data is shown.
  bool get isStatic => !store.apiLive;

  AppStage get stage {
    if (!store.isActivated || baseUrl.isEmpty) return AppStage.setup;
    if (store.token == null || customer == null) return AppStage.login;
    return AppStage.home;
  }

  void goTab(CaTab t) {
    tab = t;
    notifyListeners();
  }

  void _rebuildRepo() {
    if (!store.apiLive || baseUrl.isEmpty) {
      repo = StaticCustomerRepository(store);
    } else {
      repo = ApiCustomerRepository(ApiClient(baseUrl: baseUrl, token: store.token, onAuthExpired: _onAuthExpired), store);
    }
  }

  void _clearUser() {
    customer = null;
    business = null;
    locationLabel = '';
    tab = CaTab.home;
  }

  /// The store revoked the token or disabled Customer App access.
  void _onAuthExpired() {
    if (store.token == null) return;
    store.clearSession().then((_) {
      _clearUser();
      _rebuildRepo();
      notifyListeners();
    });
  }

  /// Running on demo data: if the saved server's API is active now, switch to
  /// live data and drop the demo session so the customer signs in for real.
  Future<void> _recheckDemoServer() async {
    if (store.apiLive || !store.isActivated || baseUrl.isEmpty) return;
    if (await ApiClient.ping(baseUrl) != null) return;
    await store.setApiLive(true);
    await store.clearSession();
    _clearUser();
    _rebuildRepo();
    notifyListeners();
  }

  static const invalidUrlMessage = 'Enter a valid base URL';

  /// Pings the server; returns null when its JapsPos API is active.
  Future<String?> checkServer(String rawUrl) async {
    final url = ApiClient.normalizeBaseUrl(rawUrl);
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return invalidUrlMessage;
    return ApiClient.ping(url);
  }

  Future<void> completeSetup(String company, String rawUrl, {required bool apiLive}) async {
    await store.clearSession();
    _clearUser();
    await store.saveSetup(company: company.trim(), baseUrl: ApiClient.normalizeBaseUrl(rawUrl), apiLive: apiLive);
    _rebuildRepo();
    notifyListeners();
  }

  Future<void> resetSetup() async {
    if (store.token != null) await repo.logout();
    await store.clearSetup();
    _clearUser();
    _rebuildRepo();
    notifyListeners();
  }

  Future<void> login(String login, String password, {required bool remember}) async {
    final res = await repo.login(login.trim(), password);
    customer = res.customer;
    business = res.business;
    await store.saveSession(res.token, res.customer.toJson(), res.business.toJson());
    await store.setRememberedLogin(remember ? login.trim() : null);
    _rebuildRepo();
    tab = CaTab.home;
    notifyListeners();
    refreshLocation();
  }

  Future<void> logout() async {
    await repo.logout();
    await store.clearSession();
    _clearUser();
    _rebuildRepo();
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    try {
      final r = await repo.locations();
      final id = r.currentId ?? store.locationId ?? (r.locations.isEmpty ? null : r.locations.first.id);
      final loc = r.locations.where((l) => l.id == id).firstOrNull;
      locationLabel = loc?.label ?? 'No location';
      notifyListeners();
    } on RepoException {
      // Header keeps the previous label.
    }
  }

  Future<String> setLocation(int id) async {
    final msg = await repo.setLocation(id);
    await refreshLocation();
    return msg;
  }

  void updateCustomer(Customer c) {
    customer = c;
    store.saveCustomer(c.toJson());
    notifyListeners();
  }
}
