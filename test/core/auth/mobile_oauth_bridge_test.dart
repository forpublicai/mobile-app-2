import 'package:conduit/core/auth/mobile_oauth_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MobileOAuthBridge', () {
    test('buildStartUri targets the mobile OAuth bridge endpoint', () {
      final uri = MobileOAuthBridge.buildStartUri(
        serverUri: Uri.parse('https://chat.publicai.co'),
        provider: 'google',
        state: 'state-123',
      );

      expect(
        uri.toString(),
        startsWith('https://chat.publicai.co/api/mobile/oauth/start?'),
      );
      expect(uri.queryParameters['provider'], 'google');
      expect(uri.queryParameters['redirect_uri'], 'publicai://auth/callback');
      expect(uri.queryParameters['state'], 'state-123');
    });

    test('createState returns url-safe random values', () {
      final first = MobileOAuthBridge.createState();
      final second = MobileOAuthBridge.createState();

      expect(first, hasLength(greaterThanOrEqualTo(32)));
      expect(first, isNot(second));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(first), isTrue);
    });

    test('parseCallback returns single-use code for valid callback', () {
      final callback = MobileOAuthBridge.parseCallback(
        Uri.parse('publicai://auth/callback?code=abc123&state=state-123'),
        expectedState: 'state-123',
      );

      expect(callback.code, 'abc123');
      expect(callback.token, isNull);
      expect(callback.isError, isFalse);
    });

    test('parseCallback rejects callbacks for a different scheme', () {
      expect(
        () => MobileOAuthBridge.parseCallback(
          Uri.parse('evil://auth/callback?code=abc123&state=state-123'),
          expectedState: 'state-123',
        ),
        throwsA(isA<MobileOAuthCallbackException>()),
      );
    });

    test('parseCallback rejects callbacks for a different host or path', () {
      expect(
        () => MobileOAuthBridge.parseCallback(
          Uri.parse('publicai://other/callback?code=abc123&state=state-123'),
          expectedState: 'state-123',
        ),
        throwsA(isA<MobileOAuthCallbackException>()),
      );
      expect(
        () => MobileOAuthBridge.parseCallback(
          Uri.parse('publicai://auth/other?code=abc123&state=state-123'),
          expectedState: 'state-123',
        ),
        throwsA(isA<MobileOAuthCallbackException>()),
      );
    });

    test('parseCallback rejects callbacks for a different state', () {
      expect(
        () => MobileOAuthBridge.parseCallback(
          Uri.parse('publicai://auth/callback?code=abc123&state=other'),
          expectedState: 'state-123',
        ),
        throwsA(isA<MobileOAuthCallbackException>()),
      );
    });

    test('parseCallback returns structured OAuth errors', () {
      final callback = MobileOAuthBridge.parseCallback(
        Uri.parse(
          'publicai://auth/callback?error=access_denied&error_description=Denied&state=state-123',
        ),
        expectedState: 'state-123',
      );

      expect(callback.isError, isTrue);
      expect(callback.error, 'access_denied');
      expect(callback.errorDescription, 'Denied');
    });

    test('parseCallback rejects token callbacks unless explicitly allowed', () {
      final token = _jwtLikeToken();

      expect(
        () => MobileOAuthBridge.parseCallback(
          Uri.parse('publicai://auth/callback?token=$token&state=state-123'),
          expectedState: 'state-123',
        ),
        throwsA(isA<MobileOAuthCallbackException>()),
      );
    });

    test(
      'parseCallback rejects malformed legacy token callbacks when enabled',
      () {
        expect(
          () => MobileOAuthBridge.parseCallback(
            Uri.parse(
              'publicai://auth/callback?token=not-a-jwt&state=state-123',
            ),
            expectedState: 'state-123',
            allowTokenCallback: true,
          ),
          throwsA(isA<MobileOAuthCallbackException>()),
        );
      },
    );

    test('parseCallback accepts legacy token callbacks when enabled', () {
      final token = _jwtLikeToken();
      final callback = MobileOAuthBridge.parseCallback(
        Uri.parse('publicai://auth/callback?token=$token&state=state-123'),
        expectedState: 'state-123',
        allowTokenCallback: true,
      );

      expect(callback.token, token);
      expect(callback.code, isNull);
    });
  });
}

String _jwtLikeToken() {
  final part = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return '$part.$part.$part';
}
