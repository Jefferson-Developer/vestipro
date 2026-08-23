import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/invites/invites.dart';

void main() {
  group('validateInviteEmail', () {
    test('rejects a blank e-mail', () {
      expect(validateInviteEmail(''), isNotNull);
      expect(validateInviteEmail('   '), isNotNull);
      expect(validateInviteEmail(null), isNotNull);
    });

    test('rejects an obviously malformed e-mail', () {
      expect(validateInviteEmail('not-an-email'), isNotNull);
      expect(validateInviteEmail('missing-domain@'), isNotNull);
    });

    test('accepts a plausible e-mail', () {
      expect(validateInviteEmail('novo.vendedor@vestipro.com.br'), isNull);
      expect(validateInviteEmail('  novo@vestipro.com.br  '), isNull);
    });
  });
}
