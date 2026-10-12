import 'package:flutter_test/flutter_test.dart';
import 'package:japspos_customer_app/core/format.dart';

void main() {
  test('money and initials match the portal', () {
    expect(money(1234.5), '\$1,234.50');
    expect(initialsOf('Tony & Prem Service Station'), 'TP');
  });
}
