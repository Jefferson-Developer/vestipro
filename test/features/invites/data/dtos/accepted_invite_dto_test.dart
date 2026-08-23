import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/invites/data/dtos/accepted_invite_dto.dart';

void main() {
  group('AcceptedInviteDto', () {
    test('parses a valid response', () {
      final dto = AcceptedInviteDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'roleName': 'SALES_REP',
        'correlationId': 'correlation-1',
      });

      expect(dto.organizationId, 'org-1');
      expect(dto.organizationName, 'Grupo Fashion XPTO');
      expect(dto.roleName, 'SALES_REP');
    });

    test('throws ServerException when a required field is missing', () {
      expect(
        () => AcceptedInviteDto.fromJson(<String, dynamic>{
          'organizationId': 'org-1',
          'roleName': 'SALES_REP',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when a field has the wrong type', () {
      expect(
        () => AcceptedInviteDto.fromJson(<String, dynamic>{
          'organizationId': 'org-1',
          'organizationName': 'Grupo Fashion XPTO',
          'roleName': 42,
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
