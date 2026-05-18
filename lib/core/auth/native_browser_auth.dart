import 'package:flutter/services.dart';

final class NativeBrowserAuth {
  const NativeBrowserAuth();

  static const MethodChannel _channel = MethodChannel(
    'com.publicai.app/native_browser_auth',
  );

  Future<Uri> authenticate({
    required Uri startUri,
    required String callbackScheme,
    String? state,
  }) async {
    try {
      final args = <String, String>{
        'url': startUri.toString(),
        'callbackScheme': callbackScheme,
      };
      if (state != null) {
        args['state'] = state;
      }
      final callback = await _channel.invokeMethod<String>(
        'authenticate',
        args,
      );
      if (callback == null || callback.isEmpty) {
        throw const NativeBrowserAuthException(
          'Native auth returned no callback',
        );
      }
      final uri = Uri.tryParse(callback);
      if (uri == null) {
        throw const NativeBrowserAuthException(
          'Native auth returned invalid callback',
        );
      }
      return uri;
    } on NativeBrowserAuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw NativeBrowserAuthException(e.message ?? e.code);
    }
  }

  Future<NativeBrowserAuthPendingCallback?> consumePendingCallback() async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        'consumePendingCallback',
      );
      if (result == null) return null;
      if (result is String) {
        final uri = Uri.tryParse(result);
        return uri == null ? null : NativeBrowserAuthPendingCallback(uri: uri);
      }
      if (result is Map) {
        final callback = result['callback'];
        if (callback is! String || callback.isEmpty) return null;
        final uri = Uri.tryParse(callback);
        if (uri == null) return null;
        final state = result['state'];
        return NativeBrowserAuthPendingCallback(
          uri: uri,
          state: state is String ? state : null,
        );
      }
      return null;
    } on PlatformException catch (e) {
      throw NativeBrowserAuthException(e.message ?? e.code);
    }
  }
}

final class NativeBrowserAuthPendingCallback {
  const NativeBrowserAuthPendingCallback({required this.uri, this.state});

  final Uri uri;
  final String? state;
}

final class NativeBrowserAuthException implements Exception {
  const NativeBrowserAuthException(this.message);

  final String message;

  @override
  String toString() => 'NativeBrowserAuthException: $message';
}
