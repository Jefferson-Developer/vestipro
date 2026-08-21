import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/session_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/auth_provider_type.dart';
import '../datasources/auth_data_source.dart';
import '../mappers/auth_user_mapper.dart';

@LazySingleton(as: AuthRepository)
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.dataSource, required this.mapper});

  final AuthDataSource dataSource;
  final AuthUserMapper mapper;

  @override
  Stream<SessionUser?> get authStateChanges => dataSource.authStateChanges.map(
    (dto) => dto == null ? null : mapper.toEntity(dto),
  );

  @override
  SessionUser? get currentUser {
    final dto = dataSource.currentUser;
    return dto == null ? null : mapper.toEntity(dto);
  }

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await dataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AppSuccess<SessionUser>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<SessionUser>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<SessionUser>(
        UnexpectedFailure(
          'Unexpected error signing in.',
          code: 'auth_sign_in_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(
    AuthProviderType provider,
  ) async {
    return AppFailure<SessionUser>(
      UnexpectedFailure(
        'Authentication provider "${provider.name}" is not supported yet.',
        code: 'auth_provider_not_supported',
      ),
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    try {
      await dataSource.signOut();
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error signing out.',
          code: 'auth_sign_out_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await dataSource.sendPasswordResetEmail(email: email);
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error sending password reset email.',
          code: 'auth_password_reset_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
