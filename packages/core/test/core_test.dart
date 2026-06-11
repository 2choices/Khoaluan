import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

void main() {
  test('formats Vietnamese currency', () {
    expect(CurrencyFormatter.formatVND(1500000), contains('1.500.000'));
  });
}
