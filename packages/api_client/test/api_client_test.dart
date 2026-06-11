import 'package:flutter_test/flutter_test.dart';

import 'package:api_client/api_client.dart';

void main() {
  test('exports NestJS client', () {
    final client = NestJSClient(baseUrl: 'http://localhost:3000');
    expect(client, isA<NestJSClient>());
  });
}
