import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/login_bloc.dart';
import 'package:vestipro/features/authentication/presentation/bloc/login_event.dart';
import 'package:vestipro/features/authentication/presentation/bloc/login_state.dart';

void main() {
  group('LoginBloc', () {
    const validEmail = 'vendedor@vestipro.com.br';
    const validPassword = 'super-secret';
    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    blocTest<LoginBloc, LoginState>(
      'clears the field error and resets a stale failure as soon as the '
      'e-mail changes',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const LoginState(
        emailError: 'Informe um e-mail válido.',
        status: LoginSubmissionStatus.failure,
        failure: AuthenticationFailure('E-mail ou senha inválidos.'),
      ),
      act: (bloc) => bloc.add(const LoginEvent.emailChanged('a@b.com')),
      expect: () => <LoginState>[const LoginState(email: 'a@b.com')],
    );

    blocTest<LoginBloc, LoginState>(
      'toggles password visibility without touching the typed fields',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const LoginState(email: validEmail, password: validPassword),
      act: (bloc) => bloc.add(const LoginEvent.passwordVisibilityToggled()),
      expect: () => <LoginState>[
        const LoginState(
          email: validEmail,
          password: validPassword,
          obscurePassword: false,
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'rejects submit with an empty e-mail and password without calling '
      'the repository',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
        ),
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          emailError: 'Informe seu e-mail.',
          passwordError: 'Informe sua senha.',
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'rejects submit with a malformed e-mail without calling the '
      'repository',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
        ),
        analyticsService: analyticsService,
      ),
      seed: () =>
          const LoginState(email: 'not-an-email', password: validPassword),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          email: 'not-an-email',
          password: validPassword,
          emailError: 'Informe um e-mail válido.',
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'submits successfully, trims the e-mail and logs login_completed '
      'without personal data',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
        ),
        analyticsService: analyticsService,
      ),
      seed: () =>
          const LoginState(email: ' $validEmail ', password: validPassword),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          email: ' $validEmail ',
          password: validPassword,
          status: LoginSubmissionStatus.submitting,
        ),
        const LoginState(
          email: ' $validEmail ',
          password: validPassword,
          status: LoginSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        final event = analyticsService.loggedEvents.single;
        expect(event.name, AnalyticsEvents.loginCompleted);
        expect(event.parameters, containsPair('method', 'email'));
        expect(event.parameters, isNot(contains('email')));
        expect(event.parameters!.values, isNot(contains(validEmail)));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'keeps the typed e-mail/password and shows a generic message on '
      'invalid credentials, never revealing whether the account exists',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            AuthenticationFailure('E-mail ou senha inválidos.'),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () =>
          const LoginState(email: validEmail, password: 'wrong-password'),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          email: validEmail,
          password: 'wrong-password',
          status: LoginSubmissionStatus.submitting,
        ),
        const LoginState(
          email: validEmail,
          password: 'wrong-password',
          status: LoginSubmissionStatus.failure,
          failure: AuthenticationFailure('E-mail ou senha inválidos.'),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'surfaces a connectivity failure without clearing the typed fields',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            ConnectivityFailure('Sem conexão com a internet.'),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const LoginState(email: validEmail, password: validPassword),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.submitting,
        ),
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.failure,
          failure: ConnectivityFailure('Sem conexão com a internet.'),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'surfaces the too-many-requests failure as a ServerFailure',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            ServerFailure(
              'Muitas tentativas de login. Tente novamente mais tarde.',
            ),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const LoginState(email: validEmail, password: validPassword),
      act: (bloc) => bloc.add(const LoginEvent.submitted()),
      expect: () => <LoginState>[
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.submitting,
        ),
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.failure,
          failure: ServerFailure(
            'Muitas tentativas de login. Tente novamente mais tarde.',
          ),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'drops a second submit while one is already in flight (droppable)',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(signedInUser),
          delay: const Duration(milliseconds: 30),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const LoginState(email: validEmail, password: validPassword),
      act: (bloc) {
        bloc
          ..add(const LoginEvent.submitted())
          ..add(const LoginEvent.submitted());
      },
      wait: const Duration(milliseconds: 60),
      expect: () => <LoginState>[
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.submitting,
        ),
        const LoginState(
          email: validEmail,
          password: validPassword,
          status: LoginSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
      },
    );
  });
}

LoginBloc _buildBloc({
  required AuthRepository authRepository,
  required AnalyticsService analyticsService,
}) {
  return LoginBloc(
    signInWithEmailAndPassword: SignInWithEmailAndPasswordUseCase(
      authRepository,
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
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return result;
  }

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> refreshSession() {
    throw UnimplementedError();
  }
}
