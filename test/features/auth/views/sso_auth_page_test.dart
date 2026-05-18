import 'package:conduit/features/auth/views/sso_auth_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isGooglePasskeyChallengeErrorUrl', () {
    test('detects Google passkey challenge failures', () {
      const url =
          'https://accounts.google.com/v3/signin/challenge/pk/error?tag=tid%3DI131372680658103%2Cpasskey_first_auth_factor_error';

      expect(isGooglePasskeyChallengeErrorUrl(url), isTrue);
    });

    test('ignores non-passkey Google auth URLs', () {
      const url = 'https://accounts.google.com/v3/signin/identifier';

      expect(isGooglePasskeyChallengeErrorUrl(url), isFalse);
    });
  });
}
