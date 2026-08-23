import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';
import 'package:vestipro/features/authentication/domain/repositories/user_profile_repository.dart';
import 'package:vestipro/features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  group('CreateAccountWithEmailAndPasswordUseCase', () {
    late _MockAuthRepository authRepository;
    late _MockUserProfileRepository userProfileRepository;
    late CreateAccountWithEmailAndPasswordUseCase useCase;

    const signedUpUser = SessionUser(
      uid: 'user-1',
      email: 'ana@vestipro.com.br',
      displayName: 'Ana Souza',
      emailVerified: false,
    );

    setUpAll(() {
      registerFallbackValue(
        UserProfile(
          uid: 'fallback',
          name: 'fallback',
          email: 'fallback@vestipro.com.br',
          createdAt: DateTime.utc(2026, 1, 1),
          termsVersion: 'fallback',
          termsAcceptedAt: DateTime.utc(2026, 1, 1),
        ),
      );
    });

    setUp(() {
      authRepository = _MockAuthRepository();
      userProfileRepository = _MockUserProfileRepository();
      useCase = CreateAccountWithEmailAndPasswordUseCase(
        authRepository,
        userProfileRepository,
      );
    });

    test(
      'creates the Firebase Auth account, persists the profile with the '
      'terms consent evidence and returns the signed-in SessionUser',
      () async {
        when(
          () => authRepository.createUserWithEmailAndPassword(
            email: 'ana@vestipro.com.br',
            password: 'senha123',
            displayName: 'Ana Souza',
          ),
        ).thenAnswer((_) async => const AppSuccess<SessionUser>(signedUpUser));
        when(
          () => userProfileRepository.createInitialProfile(any()),
        ).thenAnswer((_) async => const AppSuccess<void>(null));

        final result = await useCase(
          name: '  Ana Souza  ',
          email: '  ana@vestipro.com.br  ',
          password: 'senha123',
          termsVersion: '2026-08-23',
        );

        expect(result, isA<AppSuccess<SessionUser>>());
        expect((result as AppSuccess<SessionUser>).value, signedUpUser);

        final createdProfile =
            verify(
                  () =>
                      userProfileRepository.createInitialProfile(captureAny()),
                ).captured.single
                as UserProfile;

        expect(createdProfile.uid, 'user-1');
        expect(createdProfile.name, 'Ana Souza');
        expect(createdProfile.email, 'ana@vestipro.com.br');
        expect(createdProfile.termsVersion, '2026-08-23');
        expect(createdProfile.termsAcceptedAt, isNotNull);
      },
    );

    test('returns the Failure from AuthRepository without creating a profile '
        'when the account already exists (e-mail already in use)', () async {
      when(
        () => authRepository.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer(
        (_) async => const AppFailure<SessionUser>(
          ConflictFailure('Este e-mail já está em uso.'),
        ),
      );

      final result = await useCase(
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
        password: 'senha123',
        termsVersion: '2026-08-23',
      );

      expect(result, isA<AppFailure<SessionUser>>());
      expect(
        (result as AppFailure<SessionUser>).failure,
        isA<ConflictFailure>(),
      );
      verifyNever(() => userProfileRepository.createInitialProfile(any()));
    });

    test('signs the user back out and returns the profile Failure when the '
        'account was created but the profile write fails', () async {
      when(
        () => authRepository.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => const AppSuccess<SessionUser>(signedUpUser));
      when(() => userProfileRepository.createInitialProfile(any())).thenAnswer(
        (_) async => const AppFailure<void>(
          ConnectivityFailure('Sem conexão com a internet.'),
        ),
      );
      when(
        () => authRepository.signOut(),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await useCase(
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
        password: 'senha123',
        termsVersion: '2026-08-23',
      );

      expect(result, isA<AppFailure<SessionUser>>());
      expect(
        (result as AppFailure<SessionUser>).failure,
        isA<ConnectivityFailure>(),
      );
      verify(() => authRepository.signOut()).called(1);
    });
  });
}
