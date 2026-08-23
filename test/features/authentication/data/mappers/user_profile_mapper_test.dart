import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/authentication/data/dtos/user_profile_dto.dart';
import 'package:vestipro/features/authentication/data/mappers/user_profile_mapper.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';

void main() {
  group('UserProfileMapper', () {
    const mapper = UserProfileMapper();
    final createdAt = DateTime.utc(2026, 8, 23);

    test('toEntity maps every DTO field, including terms consent', () {
      final dto = UserProfileDto(
        uid: 'user-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
        createdAt: createdAt,
        termsVersion: '2026-08-23',
        termsAcceptedAt: createdAt,
      );

      final entity = mapper.toEntity(dto);

      expect(entity.uid, 'user-1');
      expect(entity.name, 'Ana Souza');
      expect(entity.email, 'ana@vestipro.com.br');
      expect(entity.termsVersion, '2026-08-23');
      expect(entity.termsAcceptedAt, createdAt);
    });

    test('toDto maps every entity field back, including terms consent', () {
      final entity = UserProfile(
        uid: 'user-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
        createdAt: createdAt,
        termsVersion: '2026-08-23',
        termsAcceptedAt: createdAt,
      );

      final dto = mapper.toDto(entity);

      expect(dto.uid, 'user-1');
      expect(dto.name, 'Ana Souza');
      expect(dto.email, 'ana@vestipro.com.br');
      expect(dto.termsVersion, '2026-08-23');
      expect(dto.termsAcceptedAt, createdAt);
    });
  });
}
