import 'package:flutter_test/flutter_test.dart';
import 'package:japspos_customer_app/core/format.dart';
import 'package:japspos_customer_app/data/api_client.dart';

void main() {
  test('money and initials match the portal', () {
    expect(money(1234.5), '\$1,234.50');
    expect(initialsOf('Tony & Prem Service Station'), 'TP');
  });

  test('base URL is any domain, not a fixed host', () {
    expect(ApiClient.normalizeBaseUrl('www.xyz.com'), 'https://www.xyz.com');
    expect(ApiClient.normalizeBaseUrl('shop.example.net'), 'https://shop.example.net');
    expect(ApiClient.normalizeBaseUrl('store.example.co.uk'), 'https://store.example.co.uk');
    expect(ApiClient.normalizeBaseUrl('https://Shop.Example.com/customer'), 'https://shop.example.com');
    expect(ApiClient.normalizeBaseUrl('http://10.0.2.2:8000/api/v1/customer'), 'http://10.0.2.2:8000');
  });
}
