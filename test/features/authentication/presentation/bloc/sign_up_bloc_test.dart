import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';
import 'package:vestipro/features/authentication/domain/repositories/user_profile_repository.dart';
import 'package:vestipro/features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/sign_up_bloc.dart';
import 'package:vestipro/features/authentication/presentation/bloc/sign_up_event.dart';
import 'package:vestipro/features/authentication/presentation/bloc/sign_up_state.dart';

void main() {
  group('SignUpBloc', () {
    const validName = 'Ana Souza';
    const validEmail = 'ana@vestipro.com.br';
    const validPassword = 'senha123';
    const signedUpUser = SessionUser(uid: 'user-1', emailVerified: false);

    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    blocTest<SignUpBloc, SignUpState>(
      'clears the terms error as soon as the checkbox is toggled',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        termsError:
            'É necessário aceitar os Termos de Uso e a Política de '
            'Privacidade.',
      ),
      act: (bloc) => bloc.add(const SignUpEvent.termsAcceptanceToggled()),
      expect: () => <SignUpState>[const SignUpState(termsAccepted: true)],
    );

    blocTest<SignUpBloc, SignUpState>(
      'toggles password/confirmation visibility independently',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc
        ..add(const SignUpEvent.passwordVisibilityToggled())
        ..add(const SignUpEvent.passwordConfirmationVisibilityToggled()),
      expect: () => <SignUpState>[
        const SignUpState(obscurePassword: false),
        const SignUpState(
          obscurePassword: false,
          obscurePasswordConfirmation: false,
        ),
      ],
    );

    blocTest<SignUpBloc, SignUpState>(
      'rejects submit without accepting the terms, without calling the '
      'use case',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: validName,
        email: validEmail,
        password: validPassword,
        passwordConfirmation: validPassword,
      ),
      act: (bloc) => bloc.add(const SignUpEvent.submitted()),
      expect: () => <SignUpState>[
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsError:
              'É necessário aceitar os Termos de Uso e a Política de '
              'Privacidade.',
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'rejects submit with mismatched passwords, without calling the use case',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: validName,
        email: validEmail,
        password: validPassword,
        passwordConfirmation: 'outra-senha1',
        termsAccepted: true,
      ),
      act: (bloc) => bloc.add(const SignUpEvent.submitted()),
      expect: () => <SignUpState>[
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: 'outra-senha1',
          termsAccepted: true,
          passwordConfirmationError: 'As senhas não coincidem.',
        ),
      ],
    );

    blocTest<SignUpBloc, SignUpState>(
      'submits successfully, trims name/e-mail and logs sign_up_completed '
      'without personal data',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: ' $validName ',
        email: ' $validEmail ',
        password: validPassword,
        passwordConfirmation: validPassword,
        termsAccepted: true,
      ),
      act: (bloc) => bloc.add(const SignUpEvent.submitted()),
      expect: () => <SignUpState>[
        const SignUpState(
          name: ' $validName ',
          email: ' $validEmail ',
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.submitting,
        ),
        const SignUpState(
          name: ' $validName ',
          email: ' $validEmail ',
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        final event = analyticsService.loggedEvents.single;
        expect(event.name, AnalyticsEvents.signUpCompleted);
        expect(event.parameters, containsPair('method', 'email'));
        expect(event.parameters, isNot(contains('name')));
        expect(event.parameters, isNot(contains('email')));
        expect(event.parameters!.values, isNot(contains(validName)));
        expect(event.parameters!.values, isNot(contains(validEmail)));
      },
    );

    blocTest<SignUpBloc, SignUpState>(
      'surfaces the e-mail-already-in-use failure without clearing typed '
      'fields',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            ConflictFailure('Este e-mail já está em uso.'),
          ),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: validName,
        email: validEmail,
        password: validPassword,
        passwordConfirmation: validPassword,
        termsAccepted: true,
      ),
      act: (bloc) => bloc.add(const SignUpEvent.submitted()),
      expect: () => <SignUpState>[
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.submitting,
        ),
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.failure,
          failure: ConflictFailure('Este e-mail já está em uso.'),
        ),
      ],
    );

    blocTest<SignUpBloc, SignUpState>(
      'surfaces a connectivity failure without clearing typed fields',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            ConnectivityFailure('Sem conexão com a internet.'),
          ),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: validName,
        email: validEmail,
        password: validPassword,
        passwordConfirmation: validPassword,
        termsAccepted: true,
      ),
      act: (bloc) => bloc.add(const SignUpEvent.submitted()),
      expect: () => <SignUpState>[
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.submitting,
        ),
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.failure,
          failure: ConnectivityFailure('Sem conexão com a internet.'),
        ),
      ],
    );

    blocTest<SignUpBloc, SignUpState>(
      'drops a second submit while one is already in flight (droppable)',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedUpUser),
          delay: const Duration(milliseconds: 30),
        ),
        userProfileRepository: _UserProfileRepositoryStub(),
        analyticsService: analyticsService,
      ),
      seed: () => const SignUpState(
        name: validName,
        email: validEmail,
        password: validPassword,
        passwordConfirmation: validPassword,
        termsAccepted: true,
      ),
      act: (bloc) {
        bloc
          ..add(const SignUpEvent.submitted())
          ..add(const SignUpEvent.submitted());
      },
      wait: const Duration(milliseconds: 60),
      expect: () => <SignUpState>[
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.submitting,
        ),
        const SignUpState(
          name: validName,
          email: validEmail,
          password: validPassword,
          passwordConfirmation: validPassword,
          termsAccepted: true,
          status: SignUpSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
      },
    );
  });
}

SignUpBloc _buildBloc({
  required AuthRepository authRepository,
  required UserProfileRepository userProfileRepository,
  required AnalyticsService analyticsService,
}) {
  return SignUpBloc(
    createAccountWithEmailAndPassword: CreateAccountWithEmailAndPasswordUseCase(
      authRepository,
      userProfileRepository,
    ),
    analyticsService: analyticsService,
  );
}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({required this.result, this.delay = Duration.zero});

  final AppResult<SessionUser> result;
  final Duration delay;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return result;
  }

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> signOut() async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> refreshSession() {
    throw UnimplementedError();
  }
}

final class _UserProfileRepositoryStub implements UserProfileRepository {
  int createInitialProfileCallCount = 0;

  @override
  Future<AppResult<void>> createInitialProfile(UserProfile profile) async {
    createInitialProfileCallCount++;
    return const AppSuccess<void>(null);
  }
}
