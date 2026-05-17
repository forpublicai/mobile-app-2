import 'package:conduit/features/auth/views/server_connection_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultServerConnectionUrl', () {
    test('points first-run connection at the Public AI Open WebUI backend', () {
      expect(defaultServerConnectionUrl(), 'https://chat.publicai.co');
    });
  });
}
