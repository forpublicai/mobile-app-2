import 'dart:convert';
import 'dart:math';

final class MobileOAuthBridge {
  static const callbackScheme = 'publicai';
  static final callbackUri = Uri(
    scheme: callbackScheme,
    host: 'auth',
    path: '/callback',
  );

  static String createState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Uri buildStartUri({
    required Uri serverUri,
    required String provider,
    required String state,
  }) {
    final normalizedServer = serverUri.replace(
      path: '',
      query: '',
      fragment: '',
    );
    return normalizedServer.replace(
      path: '/api/mobile/oauth/start',
      queryParameters: <String, String>{
        'provider': provider,
        'redirect_uri': callbackUri.toString(),
        'state': state,
      },
    );
  }

  static MobileOAuthCallback parseCallback(
    Uri callback, {
    required String expectedState,
    bool allowTokenCallback = false,
  }) {
    if (callback.scheme != callbackScheme ||
        callback.host != callbackUri.host ||
        callback.path != callbackUri.path) {
      throw const MobileOAuthCallbackException('Invalid OAuth callback target');
    }

    final state = callback.queryParameters['state'];
    if (state == null || state.isEmpty || state != expectedState) {
      throw const MobileOAuthCallbackException('Invalid OAuth callback state');
    }

    final error = callback.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      return MobileOAuthCallback.error(
        error,
        callback.queryParameters['error_description'],
      );
    }

    final code = callback.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      return MobileOAuthCallback.code(code);
    }

    final token = callback.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      if (!allowTokenCallback) {
        throw const MobileOAuthCallbackException(
          'Token callbacks are disabled for this OAuth flow',
        );
      }
      if (!_isJwtLike(token)) {
        throw const MobileOAuthCallbackException('Invalid OAuth token format');
      }
      return MobileOAuthCallback.token(token);
    }

    throw const MobileOAuthCallbackException(
      'OAuth callback did not include a code or error',
    );
  }

  static bool _isJwtLike(String token) {
    final parts = token.split('.');
    return parts.length == 3 && token.length >= 50;
  }
}

final class MobileOAuthCallback {
  const MobileOAuthCallback._({
    this.code,
    this.token,
    this.error,
    this.errorDescription,
  });

  factory MobileOAuthCallback.code(String code) =>
      MobileOAuthCallback._(code: code);

  factory MobileOAuthCallback.token(String token) =>
      MobileOAuthCallback._(token: token);

  factory MobileOAuthCallback.error(String error, String? description) =>
      MobileOAuthCallback._(error: error, errorDescription: description);

  final String? code;
  final String? token;
  final String? error;
  final String? errorDescription;

  bool get isError => error != null;
}

final class MobileOAuthCallbackException implements Exception {
  const MobileOAuthCallbackException(this.message);

  final String message;

  @override
  String toString() => 'MobileOAuthCallbackException: $message';
}
