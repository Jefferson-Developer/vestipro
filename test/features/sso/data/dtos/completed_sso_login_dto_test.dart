import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/sso/data/dtos/completed_sso_login_dto.dart';

void main() {
  group('CompletedSsoLoginDto', () {
    test('parses a valid response', () {
      final dto = CompletedSsoLoginDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'roleName': 'SALES_REP',
        'provisioned': true,
        'correlationId': 'correlation-1',
      });

      expect(dto.organizationId, 'org-1');
      expect(dto.organizationName, 'Grupo Fashion XPTO');
      expect(dto.roleName, 'SALES_REP');
      expect(dto.provisioned, isTrue);
    });

    test('throws ServerException when a required field is missing', () {
      expect(
        () => CompletedSsoLoginDto.fromJson(<String, dynamic>{
          'organizationId': 'org-1',
          'roleName': 'SALES_REP',
          'provisioned': false,
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when a field has the wrong type', () {
      expect(
        () => CompletedSsoLoginDto.fromJson(<String, dynamic>{
          'organizationId': 'org-1',
          'organizationName': 'Grupo Fashion XPTO',
          'roleName': 'SALES_REP',
          'provisioned': 'yes',
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
