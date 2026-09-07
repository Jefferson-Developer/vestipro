import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/sso/data/datasources/sso_data_source.dart';
import 'package:vestipro/features/sso/data/dtos/completed_sso_login_dto.dart';
import 'package:vestipro/features/sso/data/dtos/sso_login_route_dto.dart';
import 'package:vestipro/features/sso/data/mappers/sso_mapper.dart';
import 'package:vestipro/features/sso/data/repositories/sso_repository_impl.dart';
import 'package:vestipro/features/sso/domain/entities/completed_sso_login.dart';
import 'package:vestipro/features/sso/domain/entities/sso_login_route.dart';

class _MockSsoDataSource extends Mock implements SsoDataSource {}

void main() {
  group('SsoRepositoryImpl', () {
    late _MockSsoDataSource dataSource;
    late SsoRepositoryImpl repository;

    setUp(() {
      dataSource = _MockSsoDataSource();
      repository = SsoRepositoryImpl(
        dataSource: dataSource,
        mapper: const SsoMapper(),
      );
    });

    group('resolveConnectionForEmail', () {
      test('returns AppSuccess(null) when no connection is found', () async {
        when(
          () =>
              dataSource.resolveConnectionForEmail(email: any(named: 'email')),
        ).thenAnswer((_) async => const SsoLoginRouteDto(found: false));

        final result = await repository.resolveConnectionForEmail(
          email: 'ana@dominio-desconhecido.com',
        );

        expect(result, isA<AppSuccess<SsoLoginRoute?>>());
        expect((result as AppSuccess<SsoLoginRoute?>).value, isNull);
      });

      test('returns AppSuccess with the mapped route when found', () async {
        when(
          () =>
              dataSource.resolveConnectionForEmail(email: any(named: 'email')),
        ).thenAnswer(
          (_) async => const SsoLoginRouteDto(
            found: true,
            organizationId: 'org-1',
            organizationName: 'Grupo Fashion XPTO',
            protocol: 'oidc',
            providerId: 'oidc.conn-1',
          ),
        );

        final result = await repository.resolveConnectionForEmail(
          email: 'ana@malwee.com.br',
        );

        expect(result, isA<AppSuccess<SsoLoginRoute?>>());
        expect(
          (result as AppSuccess<SsoLoginRoute?>).value!.organizationId,
          'org-1',
        );
      });

      test(
        'maps an AppException from the data source into an AppFailure',
        () async {
          when(
            () => dataSource.resolveConnectionForEmail(
              email: any(named: 'email'),
            ),
          ).thenThrow(const NetworkException('No connectivity.'));

          final result = await repository.resolveConnectionForEmail(
            email: 'ana@malwee.com.br',
          );

          expect(result, isA<AppFailure<SsoLoginRoute?>>());
          expect(
            (result as AppFailure<SsoLoginRoute?>).failure,
            isA<ConnectivityFailure>(),
          );
        },
      );

      test('wraps any other exception as UnexpectedFailure', () async {
        when(
          () =>
              dataSource.resolveConnectionForEmail(email: any(named: 'email')),
        ).thenThrow(Exception('boom'));

        final result = await repository.resolveConnectionForEmail(
          email: 'ana@malwee.com.br',
        );

        expect(result, isA<AppFailure<SsoLoginRoute?>>());
        expect(
          (result as AppFailure<SsoLoginRoute?>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('completeSsoLogin', () {
      test('returns AppSuccess with the mapped completion', () async {
        when(() => dataSource.completeSsoLogin()).thenAnswer(
          (_) async => const CompletedSsoLoginDto(
            organizationId: 'org-1',
            organizationName: 'Grupo Fashion XPTO',
            roleName: 'SALES_REP',
            provisioned: true,
          ),
        );

        final result = await repository.completeSsoLogin();

        expect(result, isA<AppSuccess<CompletedSsoLogin>>());
        expect(
          (result as AppSuccess<CompletedSsoLogin>).value.organizationId,
          'org-1',
        );
      });

      test(
        'maps an AppException from the data source into an AppFailure',
        () async {
          when(
            () => dataSource.completeSsoLogin(),
          ).thenThrow(const UnauthorizedException('Not signed in.'));

          final result = await repository.completeSsoLogin();

          expect(result, isA<AppFailure<CompletedSsoLogin>>());
        },
      );
    });
  });
}
