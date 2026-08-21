import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/auth/data/dtos/auth_user_dto.dart';
import 'package:vestipro/core/auth/data/mappers/auth_user_mapper.dart';

void main() {
  group('AuthUserMapper', () {
    test('maps every field from the DTO to the entity', () {
      const mapper = AuthUserMapper();
      const dto = AuthUserDto(
        uid: 'user-1',
        email: 'rep@vestipro.com.br',
        displayName: 'Vendedor VestiPro',
        emailVerified: true,
      );

      final entity = mapper.toEntity(dto);

      expect(entity.uid, 'user-1');
      expect(entity.email, 'rep@vestipro.com.br');
      expect(entity.displayName, 'Vendedor VestiPro');
      expect(entity.emailVerified, isTrue);
    });

    test('preserves null email and displayName', () {
      const mapper = AuthUserMapper();
      const dto = AuthUserDto(
        uid: 'user-2',
        email: null,
        displayName: null,
        emailVerified: false,
      );

      final entity = mapper.toEntity(dto);

      expect(entity.email, isNull);
      expect(entity.displayName, isNull);
      expect(entity.emailVerified, isFalse);
    });
  });
}
