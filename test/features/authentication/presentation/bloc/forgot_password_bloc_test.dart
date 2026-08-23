import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/send_password_reset_email_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/forgot_password_bloc.dart';
import 'package:vestipro/features/authentication/presentation/bloc/forgot_password_event.dart';
import 'package:vestipro/features/authentication/presentation/bloc/forgot_password_state.dart';

void main() {
  group('ForgotPasswordBloc', () {
    const validEmail = 'vendedor@vestipro.com.br';

    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'clears the field error and resets a stale failure as soon as the '
      'e-mail changes',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(
        emailError: 'Informe um e-mail válido.',
        status: ForgotPasswordSubmissionStatus.failure,
        failure: ServerFailure(
          'Muitas tentativas. Tente novamente mais tarde.',
        ),
      ),
      act: (bloc) =>
          bloc.add(const ForgotPasswordEvent.emailChanged('a@b.com')),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(email: 'a@b.com'),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'rejects submit with an empty e-mail without calling the use case',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
        ),
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(emailError: 'Informe seu e-mail.'),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'rejects submit with a malformed e-mail without calling the use case',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: 'not-an-email'),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: 'not-an-email',
          emailError: 'Informe um e-mail válido.',
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'submits successfully for an existing account and logs '
      'password_reset_requested without personal data',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: ' $validEmail '),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: ' $validEmail ',
          status: ForgotPasswordSubmissionStatus.submitting,
        ),
        const ForgotPasswordState(
          email: ' $validEmail ',
          status: ForgotPasswordSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        final event = analyticsService.loggedEvents.single;
        expect(event.name, AnalyticsEvents.passwordResetRequested);
        expect(event.parameters, isNot(contains('email')));
        expect(event.parameters!.values, isNot(contains(validEmail)));
      },
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'reaches the exact same success state for a user-not-found account, '
      'never a visible failure',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<void>(
            AuthenticationFailure(
              'E-mail ou senha inválidos.',
              code: 'user-not-found',
            ),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: validEmail),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.submitting,
        ),
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.passwordResetRequested,
        );
      },
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'surfaces a connectivity failure without clearing the typed e-mail',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<void>(
            ConnectivityFailure('Sem conexão com a internet.'),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: validEmail),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.submitting,
        ),
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.failure,
          failure: ConnectivityFailure('Sem conexão com a internet.'),
        ),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'surfaces the too-many-requests failure as a ServerFailure',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppFailure<void>(
            ServerFailure('Muitas tentativas. Tente novamente mais tarde.'),
          ),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: validEmail),
      act: (bloc) => bloc.add(const ForgotPasswordEvent.submitted()),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.submitting,
        ),
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.failure,
          failure: ServerFailure(
            'Muitas tentativas. Tente novamente mais tarde.',
          ),
        ),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'drops a second submit while one is already in flight (droppable)',
      build: () => _buildBloc(
        authRepository: _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
          delay: const Duration(milliseconds: 30),
        ),
        analyticsService: analyticsService,
      ),
      seed: () => const ForgotPasswordState(email: validEmail),
      act: (bloc) {
        bloc
          ..add(const ForgotPasswordEvent.submitted())
          ..add(const ForgotPasswordEvent.submitted());
      },
      wait: const Duration(milliseconds: 60),
      expect: () => <ForgotPasswordState>[
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.submitting,
        ),
        const ForgotPasswordState(
          email: validEmail,
          status: ForgotPasswordSubmissionStatus.success,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
      },
    );
  });
}

ForgotPasswordBloc _buildBloc({
  required AuthRepository authRepository,
  required AnalyticsService analyticsService,
}) {
  return ForgotPasswordBloc(
    sendPasswordResetEmail: SendPasswordResetEmailUseCase(authRepository),
    analyticsService: analyticsService,
  );
}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({required this.result, this.delay = Duration.zero});

  final AppResult<void> result;
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
  }) {
    throw UnimplementedError();
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
  Future<AppResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return result;
  }
}
