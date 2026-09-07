import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/sso/data/dtos/sso_login_route_dto.dart';

void main() {
  group('SsoLoginRouteDto', () {
    test('parses found:false without requiring any other field', () {
      final dto = SsoLoginRouteDto.fromJson(<String, dynamic>{'found': false});

      expect(dto.found, isFalse);
      expect(dto.organizationId, isNull);
      expect(dto.organizationName, isNull);
      expect(dto.protocol, isNull);
      expect(dto.providerId, isNull);
    });

    test('parses a found:true response with every field', () {
      final dto = SsoLoginRouteDto.fromJson(<String, dynamic>{
        'found': true,
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'protocol': 'oidc',
        'providerId': 'oidc.conn-1',
      });

      expect(dto.found, isTrue);
      expect(dto.organizationId, 'org-1');
      expect(dto.organizationName, 'Grupo Fashion XPTO');
      expect(dto.protocol, 'oidc');
      expect(dto.providerId, 'oidc.conn-1');
    });

    test('throws ServerException when found is missing/wrong type', () {
      expect(
        () => SsoLoginRouteDto.fromJson(<String, dynamic>{}),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => SsoLoginRouteDto.fromJson(<String, dynamic>{'found': 'yes'}),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'throws ServerException when found:true is missing a required field',
      () {
        expect(
          () => SsoLoginRouteDto.fromJson(<String, dynamic>{
            'found': true,
            'organizationId': 'org-1',
            'protocol': 'oidc',
            'providerId': 'oidc.conn-1',
          }),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
