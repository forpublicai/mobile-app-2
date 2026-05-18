import 'package:conduit/core/config/public_ai_server.dart';
import 'package:conduit/core/models/server_config.dart';
import 'package:conduit/core/router/app_router.dart';
import 'package:conduit/core/services/navigation_service.dart';
import 'package:conduit/features/auth/providers/unified_auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('serverConnectionRedirect', () {
    test(
      'routes Public AI default users to SSO instead of server selection',
      () {
        expect(
          serverConnectionRedirect(
            publicAiDefaultServerConfig,
            AuthNavigationState.needsLogin,
          ),
          Routes.ssoAuth,
        );
      },
    );

    test(
      'treats saved chat.publicai.co configs as the Public AI app server',
      () {
        const savedPublicAiServer = ServerConfig(
          id: 'saved-public-ai',
          name: 'Saved Public AI',
          url: 'https://chat.publicai.co',
          isActive: true,
        );

        expect(isPublicAiServer(savedPublicAiServer), isTrue);
        expect(
          serverConnectionRedirect(
            savedPublicAiServer,
            AuthNavigationState.needsLogin,
          ),
          Routes.ssoAuth,
        );
      },
    );

    test('routes authenticated Public AI users to chat', () {
      expect(
        serverConnectionRedirect(
          publicAiDefaultServerConfig,
          AuthNavigationState.authenticated,
        ),
        Routes.chat,
      );
    });

    test('preserves manual server connection fallback for custom servers', () {
      const customServer = ServerConfig(
        id: 'custom',
        name: 'Custom',
        url: 'https://custom.example.com',
        isActive: true,
      );

      expect(
        serverConnectionRedirect(customServer, AuthNavigationState.needsLogin),
        isNull,
      );
    });
  });
}
