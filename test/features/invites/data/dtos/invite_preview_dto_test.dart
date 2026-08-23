import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/invites/data/dtos/invite_preview_dto.dart';

void main() {
  group('InvitePreviewDto', () {
    test('parses a full valid-outcome response', () {
      final dto = InvitePreviewDto.fromJson(<String, dynamic>{
        'outcome': 'valid',
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'email': 'convidado@vestipro.com.br',
        'roleName': 'SALES_REP',
        'correlationId': 'correlation-1',
      });

      expect(dto.outcome, 'valid');
      expect(dto.organizationId, 'org-1');
      expect(dto.organizationName, 'Grupo Fashion XPTO');
      expect(dto.email, 'convidado@vestipro.com.br');
      expect(dto.roleName, 'SALES_REP');
    });

    test('parses a notFound response with every context field null', () {
      final dto = InvitePreviewDto.fromJson(<String, dynamic>{
        'outcome': 'notFound',
        'organizationId': null,
        'organizationName': null,
        'email': null,
        'roleName': null,
        'correlationId': 'correlation-1',
      });

      expect(dto.outcome, 'notFound');
      expect(dto.organizationId, isNull);
      expect(dto.organizationName, isNull);
      expect(dto.email, isNull);
      expect(dto.roleName, isNull);
    });

    test('throws ServerException when outcome is missing/malformed', () {
      expect(
        () => InvitePreviewDto.fromJson(<String, dynamic>{
          'organizationId': null,
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when a context field has the wrong type', () {
      expect(
        () => InvitePreviewDto.fromJson(<String, dynamic>{
          'outcome': 'valid',
          'roleName': 123,
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
