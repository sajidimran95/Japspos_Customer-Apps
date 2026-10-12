class AppConfig {
  static const String appName = 'Customer Apps';
  static const String brandName = 'JapsPos';
  static const String brandTagline = 'Customer App';

  /// Public health check every JapsPos server exposes.
  static const String pingPath = '/api/v1/ping';
  static const String pingApiId = 'japspos-mobile';

  /// Customer App REST API (`{BASE_URL}/api/v1/customer/...`).
  static const String apiPrefix = '/api/v1/customer';

  static const Duration requestTimeout = Duration(seconds: 25);
  static const Duration activationTimeout = Duration(seconds: 10);
}
