import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/sso/domain/entities/completed_sso_login.dart';
import 'package:vestipro/features/sso/domain/entities/corporate_sso_login_result.dart';
import 'package:vestipro/features/sso/domain/entities/sso_login_route.dart';
import 'package:vestipro/features/sso/domain/repositories/sso_repository.dart';
import 'package:vestipro/features/sso/domain/usecases/sign_in_with_corporate_sso_use_case.dart';
import 'package:vestipro/features/sso/domain/value_objects/sso_protocol.dart';

class _MockSsoRepository extends Mock implements SsoRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignInWithCorporateSsoUseCase', () {
    late _MockSsoRepository ssoRepository;
    late _MockAuthRepository authRepository;
    late SignInWithCorporateSsoUseCase useCase;

    const route = SsoLoginRoute(
      organizationId: 'org-1',
      organizationName: 'Grupo Fashion XPTO',
      protocol: SsoProtocol.oidc,
      providerId: 'oidc.conn-1',
    );

    const sessionUser = SessionUser(
      uid: 'user-1',
      email: 'ana@malwee.com.br',
      displayName: 'Ana Souza',
      emailVerified: true,
    );

    const completion = CompletedSsoLogin(
      organizationId: 'org-1',
      organizationName: 'Grupo Fashion XPTO',
      roleName: 'SALES_REP',
      provisioned: true,
    );

    setUp(() {
      ssoRepository = _MockSsoRepository();
      authRepository = _MockAuthRepository();
      useCase = SignInWithCorporateSsoUseCase(ssoRepository, authRepository);
    });

    test('returns a ValidationFailure without calling any repository when '
        'the e-mail is blank', () async {
      final result = await useCase.call(email: '   ');

      expect(result, isA<AppFailure<CorporateSsoLoginResult>>());
      expect(
        (result as AppFailure<CorporateSsoLoginResult>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () =>
            ssoRepository.resolveConnectionForEmail(email: any(named: 'email')),
      );
      verifyNever(
        () => authRepository.signInWithFederatedProvider(
          providerId: any(named: 'providerId'),
          isSaml: any(named: 'isSaml'),
        ),
      );
    });

    test('returns a NotFoundFailure without ever authenticating when no '
        'connection is resolved for the e-mail', () async {
      when(
        () =>
            ssoRepository.resolveConnectionForEmail(email: any(named: 'email')),
      ).thenAnswer((_) async => const AppSuccess<SsoLoginRoute?>(null));

      final result = await useCase.call(email: 'ana@dominio-pessoal.com');

      expect(result, isA<AppFailure<CorporateSsoLoginResult>>());
      expect(
        (result as AppFailure<CorporateSsoLoginResult>).failure,
        isA<NotFoundFailure>(),
      );
      verifyNever(
        () => authRepository.signInWithFederatedProvider(
          providerId: any(named: 'providerId'),
          isSaml: any(named: 'isSaml'),
        ),
      );
    });

    test(
      'propagates a resolve failure (network/server) without authenticating',
      () async {
        when(
          () => ssoRepository.resolveConnectionForEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer(
          (_) async => AppFailure<SsoLoginRoute?>(
            const ConnectivityFailure('No connectivity.'),
          ),
        );

        final result = await useCase.call(email: 'ana@malwee.com.br');

        expect(result, isA<AppFailure<CorporateSsoLoginResult>>());
        expect(
          (result as AppFailure<CorporateSsoLoginResult>).failure,
          isA<ConnectivityFailure>(),
        );
      },
    );

    test('signs in with the resolved providerId/protocol, then completes the '
        'JIT login, returning the sessionUser and organization', () async {
      when(
        () =>
            ssoRepository.resolveConnectionForEmail(email: any(named: 'email')),
      ).thenAnswer((_) async => const AppSuccess<SsoLoginRoute?>(route));
      when(
        () => authRepository.signInWithFederatedProvider(
          providerId: 'oidc.conn-1',
          isSaml: false,
        ),
      ).thenAnswer((_) async => const AppSuccess<SessionUser>(sessionUser));
      when(() => ssoRepository.completeSsoLogin()).thenAnswer(
        (_) async => const AppSuccess<CompletedSsoLogin>(completion),
      );

      final result = await useCase.call(email: '  Ana@Malwee.com.br  ');

      expect(result, isA<AppSuccess<CorporateSsoLoginResult>>());
      final value = (result as AppSuccess<CorporateSsoLoginResult>).value;
      expect(value.sessionUser.uid, 'user-1');
      expect(value.organizationId, 'org-1');
      expect(value.organizationName, 'Grupo Fashion XPTO');
      verify(
        () =>
            ssoRepository.resolveConnectionForEmail(email: 'Ana@Malwee.com.br'),
      ).called(1);
    });

    test(
      'builds a SAML provider when the resolved connection is SAML',
      () async {
        const samlRoute = SsoLoginRoute(
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          protocol: SsoProtocol.saml,
          providerId: 'saml.conn-1',
        );
        when(
          () => ssoRepository.resolveConnectionForEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const AppSuccess<SsoLoginRoute?>(samlRoute));
        when(
          () => authRepository.signInWithFederatedProvider(
            providerId: 'saml.conn-1',
            isSaml: true,
          ),
        ).thenAnswer((_) async => const AppSuccess<SessionUser>(sessionUser));
        when(() => ssoRepository.completeSsoLogin()).thenAnswer(
          (_) async => const AppSuccess<CompletedSsoLogin>(completion),
        );

        final result = await useCase.call(email: 'ana@malwee.com.br');

        expect(result, isA<AppSuccess<CorporateSsoLoginResult>>());
        verify(
          () => authRepository.signInWithFederatedProvider(
            providerId: 'saml.conn-1',
            isSaml: true,
          ),
        ).called(1);
      },
    );

    test(
      'propagates a sign-in failure (e.g. account-exists-with-different-credential) '
      'without ever calling completeSsoLogin',
      () async {
        when(
          () => ssoRepository.resolveConnectionForEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const AppSuccess<SsoLoginRoute?>(route));
        when(
          () => authRepository.signInWithFederatedProvider(
            providerId: any(named: 'providerId'),
            isSaml: any(named: 'isSaml'),
          ),
        ).thenAnswer(
          (_) async => AppFailure<SessionUser>(
            const ConflictFailure('Já existe uma conta com este e-mail.'),
          ),
        );

        final result = await useCase.call(email: 'ana@malwee.com.br');

        expect(result, isA<AppFailure<CorporateSsoLoginResult>>());
        expect(
          (result as AppFailure<CorporateSsoLoginResult>).failure,
          isA<ConflictFailure>(),
        );
        verifyNever(() => ssoRepository.completeSsoLogin());
      },
    );

    test(
      'propagates a completeSsoLogin failure even after a successful federated sign-in',
      () async {
        when(
          () => ssoRepository.resolveConnectionForEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => const AppSuccess<SsoLoginRoute?>(route));
        when(
          () => authRepository.signInWithFederatedProvider(
            providerId: any(named: 'providerId'),
            isSaml: any(named: 'isSaml'),
          ),
        ).thenAnswer((_) async => const AppSuccess<SessionUser>(sessionUser));
        when(() => ssoRepository.completeSsoLogin()).thenAnswer(
          (_) async => AppFailure<CompletedSsoLogin>(
            const PermissionFailure('Este provedor de SSO está desativado.'),
          ),
        );

        final result = await useCase.call(email: 'ana@malwee.com.br');

        expect(result, isA<AppFailure<CorporateSsoLoginResult>>());
        expect(
          (result as AppFailure<CorporateSsoLoginResult>).failure,
          isA<PermissionFailure>(),
        );
      },
    );
  });
}
