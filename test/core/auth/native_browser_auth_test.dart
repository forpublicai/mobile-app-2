import 'package:conduit/core/auth/mobile_oauth_bridge.dart';
import 'package:conduit/core/auth/native_browser_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBrowserAuth', () {
    const channel = MethodChannel('com.publicai.app/native_browser_auth');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'authenticate sends url and callback scheme to native channel',
      () async {
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              return 'publicai://auth/callback?code=abc123&state=state-123';
            });

        final result = await const NativeBrowserAuth().authenticate(
          startUri: Uri.parse(
            'https://chat.publicai.co/api/mobile/oauth/start',
          ),
          callbackScheme: MobileOAuthBridge.callbackScheme,
        );

        expect(
          result.toString(),
          'publicai://auth/callback?code=abc123&state=state-123',
        );
        expect(calls, hasLength(1));
        expect(calls.single.method, 'authenticate');
        expect(calls.single.arguments, {
          'url': 'https://chat.publicai.co/api/mobile/oauth/start',
          'callbackScheme': 'publicai',
        });
      },
    );

    test('consumePendingCallback returns null when native has none', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'consumePendingCallback');
            return null;
          });

      final result = await const NativeBrowserAuth().consumePendingCallback();

      expect(result, isNull);
    });

    test('consumePendingCallback parses orphan callback with state', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'consumePendingCallback');
            return {
              'callback':
                  'publicai://auth/callback?code=abc123&state=state-123',
              'state': 'state-123',
            };
          });

      final result = await const NativeBrowserAuth().consumePendingCallback();

      expect(
        result!.uri.toString(),
        'publicai://auth/callback?code=abc123&state=state-123',
      );
      expect(result.state, 'state-123');
    });

    test('authenticate wraps native failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'CANCELED', message: 'User canceled');
          });

      expect(
        () => const NativeBrowserAuth().authenticate(
          startUri: Uri.parse(
            'https://chat.publicai.co/api/mobile/oauth/start',
          ),
          callbackScheme: MobileOAuthBridge.callbackScheme,
        ),
        throwsA(isA<NativeBrowserAuthException>()),
      );
    });
  });
}
