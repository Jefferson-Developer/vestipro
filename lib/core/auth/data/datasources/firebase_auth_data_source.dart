import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../environment/app_environment.dart';
import '../../../environment/firebase_emulator_host.dart';
import '../../../environment/firebase_emulator_ports.dart';
import '../../../errors/errors.dart';
import '../dtos/auth_user_dto.dart';
import 'auth_data_source.dart';
import '../mappers/firebase_auth_exception_mapper.dart';

@LazySingleton(as: AuthDataSource)
final class FirebaseAuthDataSource implements AuthDataSource {
  /// Connects [firebaseAuth] to the local Auth Emulator for every non-`prod`
  /// flavor as soon as this datasource exists (ADR-0002), so a
  /// misconfigured flavor never reads/writes real user accounts. Not
  /// awaited: `useAuthEmulator` must run before any other call on
  /// [firebaseAuth], but nothing here can block a lazy DI resolution on a
  /// platform channel round-trip — callers that exercise real sign-in
  /// against the emulator (see the integration test) already run slower
  /// operations first, which gives this call time to land.
  FirebaseAuthDataSource(this._firebaseAuth) {
    if (!AppEnvironment.current.isProduction) {
      unawaited(
        _firebaseAuth.useAuthEmulator(
          resolveFirebaseEmulatorHost(),
          FirebaseEmulatorPorts.auth,
        ),
      );
    }
  }

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUserDto?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_toDto);

  @override
  AuthUserDto? get currentUser => _toDto(_firebaseAuth.currentUser);

  @override
  Future<AuthUserDto> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownException(
          'Firebase returned an empty user after sign-in.',
          code: 'auth_empty_user',
        );
      }
      return _toDto(user)!;
    } on FirebaseAuthException catch (exception, stackTrace) {
      throw mapFirebaseAuthExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (exception, stackTrace) {
      throw mapFirebaseAuthExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (exception, stackTrace) {
      throw mapFirebaseAuthExceptionToAppException(exception, stackTrace);
    }
  }

  AuthUserDto? _toDto(User? user) {
    if (user == null) return null;
    return AuthUserDto(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }
}
