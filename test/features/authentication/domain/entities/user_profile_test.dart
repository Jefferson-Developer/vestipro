import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    final createdAt = DateTime.utc(2026, 8, 23);

    UserProfile buildProfile({String uid = 'user-1'}) {
      return UserProfile(
        uid: uid,
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
        createdAt: createdAt,
        termsVersion: '2026-08-23',
        termsAcceptedAt: createdAt,
      );
    }

    test('two profiles with the same field values are equal', () {
      expect(buildProfile(), buildProfile());
    });

    test('profiles with different uids are not equal', () {
      expect(buildProfile(uid: 'user-1'), isNot(buildProfile(uid: 'user-2')));
    });

    test('copyWith produces a new instance without mutating the original', () {
      final original = buildProfile();
      final copy = original.copyWith(name: 'Novo Nome');

      expect(original.name, 'Ana Souza');
      expect(copy.name, 'Novo Nome');
      expect(original, isNot(copy));
    });

    test('keeps the terms consent evidence (version and timestamp)', () {
      final profile = buildProfile();

      expect(profile.termsVersion, '2026-08-23');
      expect(profile.termsAcceptedAt, createdAt);
    });
  });
}
