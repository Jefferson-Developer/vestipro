import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/sso/data/dtos/completed_sso_login_dto.dart';
import 'package:vestipro/features/sso/data/dtos/sso_login_route_dto.dart';
import 'package:vestipro/features/sso/data/mappers/sso_mapper.dart';
import 'package:vestipro/features/sso/domain/value_objects/sso_protocol.dart';

void main() {
  group('SsoMapper', () {
    const mapper = SsoMapper();

    group('toRouteEntityOrNull', () {
      test('returns null when the DTO reports found:false', () {
        const dto = SsoLoginRouteDto(found: false);

        expect(mapper.toRouteEntityOrNull(dto), isNull);
      });

      test(
        'maps a found:true DTO to a SsoLoginRoute, parsing the protocol',
        () {
          const dto = SsoLoginRouteDto(
            found: true,
            organizationId: 'org-1',
            organizationName: 'Grupo Fashion XPTO',
            protocol: 'saml',
            providerId: 'saml.conn-1',
          );

          final route = mapper.toRouteEntityOrNull(dto);

          expect(route, isNotNull);
          expect(route!.organizationId, 'org-1');
          expect(route.organizationName, 'Grupo Fashion XPTO');
          expect(route.protocol, SsoProtocol.saml);
          expect(route.providerId, 'saml.conn-1');
        },
      );

      test('parses "oidc" protocol', () {
        const dto = SsoLoginRouteDto(
          found: true,
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          protocol: 'oidc',
          providerId: 'oidc.conn-1',
        );

        expect(mapper.toRouteEntityOrNull(dto)!.protocol, SsoProtocol.oidc);
      });

      test('throws ValidationException for an unknown protocol code', () {
        const dto = SsoLoginRouteDto(
          found: true,
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          protocol: 'oauth2',
          providerId: 'oauth2.conn-1',
        );

        expect(
          () => mapper.toRouteEntityOrNull(dto),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('toCompletedEntity', () {
      test('maps every field verbatim', () {
        const dto = CompletedSsoLoginDto(
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          roleName: 'SALES_REP',
          provisioned: true,
        );

        final entity = mapper.toCompletedEntity(dto);

        expect(entity.organizationId, 'org-1');
        expect(entity.organizationName, 'Grupo Fashion XPTO');
        expect(entity.roleName, 'SALES_REP');
        expect(entity.provisioned, isTrue);
      });
    });
  });
}
