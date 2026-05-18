import 'package:conduit/core/models/server_config.dart';
import 'package:conduit/core/providers/app_providers.dart';
import 'package:conduit/core/services/optimized_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeServerProvider', () {
    test('defaults first-run installs to the Public AI server', () async {
      final storage = _FakeOptimizedStorageService();
      final container = ProviderContainer(
        overrides: [optimizedStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final server = await container.read(activeServerProvider.future);

      expect(server, isNotNull);
      expect(server!.id, 'public-ai-default');
      expect(server.name, 'Public AI');
      expect(server.url, 'https://chat.publicai.co');
      expect(server.isActive, isTrue);
      expect(storage.activeServerIdWrites, isEmpty);
    });

    test('keeps a saved active server instead of replacing it', () async {
      const saved = ServerConfig(
        id: 'saved-server',
        name: 'Saved Server',
        url: 'https://saved.example.com',
        isActive: true,
      );
      final storage = _FakeOptimizedStorageService(
        configs: const [saved],
        activeServerId: 'saved-server',
      );
      final container = ProviderContainer(
        overrides: [optimizedStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final server = await container.read(activeServerProvider.future);

      expect(server, saved);
    });
  });
}

class _FakeOptimizedStorageService extends Fake
    implements OptimizedStorageService {
  _FakeOptimizedStorageService({
    List<ServerConfig> configs = const <ServerConfig>[],
    String? activeServerId,
  }) : _configs = configs,
       _activeServerId = activeServerId;

  final List<ServerConfig> _configs;
  final String? _activeServerId;
  final activeServerIdWrites = <String>[];

  @override
  Future<List<ServerConfig>> getServerConfigs() async => _configs;

  @override
  Future<String?> getActiveServerId() async => _activeServerId;

  @override
  Future<void> setActiveServerId(String? id) async {
    if (id != null) activeServerIdWrites.add(id);
  }
}
