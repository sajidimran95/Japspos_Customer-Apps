import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  static const _kCompany = 'setup.company_name';
  static const _kBaseUrl = 'setup.base_url';
  static const _kActivated = 'setup.activated';
  static const _kApiLive = 'setup.api_live';
  static const _kToken = 'auth.token';
  static const _kCustomer = 'auth.customer';
  static const _kBusiness = 'auth.business';
  static const _kRemember = 'auth.remember_login';
  static const _kLocation = 'customer.location_id';

  String? get companyName => _prefs.getString(_kCompany);
  String? get baseUrl => _prefs.getString(_kBaseUrl);
  bool get isActivated => _prefs.getBool(_kActivated) ?? false;

  /// True when the base URL answered the JapsPos API ping: screens use live
  /// data. False means the server was not reachable: demo data is shown.
  bool get apiLive => _prefs.getBool(_kApiLive) ?? false;
  Future<void> setApiLive(bool v) => _prefs.setBool(_kApiLive, v);

  Future<void> saveSetup({required String company, required String baseUrl, required bool apiLive}) async {
    await _prefs.setString(_kCompany, company);
    await _prefs.setString(_kBaseUrl, baseUrl);
    await _prefs.setBool(_kActivated, true);
    await _prefs.setBool(_kApiLive, apiLive);
  }

  Future<void> clearSetup() async {
    await _prefs.remove(_kCompany);
    await _prefs.remove(_kBaseUrl);
    await _prefs.remove(_kActivated);
    await _prefs.remove(_kApiLive);
    await clearSession();
  }

  String? get token => _prefs.getString(_kToken);
  Map<String, dynamic>? get customer => _json(_kCustomer);
  Map<String, dynamic>? get business => _json(_kBusiness);

  Map<String, dynamic>? _json(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSession(String token, Map<String, dynamic> customer, Map<String, dynamic> business) async {
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kCustomer, jsonEncode(customer));
    await _prefs.setString(_kBusiness, jsonEncode(business));
  }

  Future<void> saveCustomer(Map<String, dynamic> customer) => _prefs.setString(_kCustomer, jsonEncode(customer));

  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kCustomer);
    await _prefs.remove(_kBusiness);
    await _prefs.remove(_kLocation);
  }

  String? get rememberedLogin => _prefs.getString(_kRemember);
  Future<void> setRememberedLogin(String? v) async {
    if (v == null) {
      await _prefs.remove(_kRemember);
    } else {
      await _prefs.setString(_kRemember, v);
    }
  }

  int? get locationId => _prefs.getInt(_kLocation);
  Future<void> setLocationId(int id) => _prefs.setInt(_kLocation, id);
}
