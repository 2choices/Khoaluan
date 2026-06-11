import 'package:flutter_test/flutter_test.dart';

import 'package:omnigo_auth/omnigo_auth.dart';

void main() {
  test('exports auth user model', () {
    const user = AuthUser(
      id: 'user-1',
      email: 'user@example.com',
      tenantId: 'tenant-1',
    );
    expect(user.id, 'user-1');
    expect(user.email, 'user@example.com');
  });
}
