import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:injectable/injectable.dart';

import '../errors/errors.dart';
import 'local_error_log_sink.dart';

abstract interface class LoginErrorLogger {
  Future<void> logFailure({
    required String method,
    required String email,
    required Failure failure,
  });
}

@LazySingleton(as: LoginErrorLogger)
final class FileLoginErrorLogger implements LoginErrorLogger {
  FileLoginErrorLogger() : _sink = const LocalErrorLogSink();

  final LocalErrorLogSink _sink;

  @override
  Future<void> logFailure({
    required String method,
    required String email,
    required Failure failure,
  }) async {
    try {
      final entry = <String, Object?>{
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'event': 'login_failure',
        'method': method,
        'platform': defaultTargetPlatform.name,
        'email': _maskEmail(email),
        'failureType': failure.runtimeType.toString(),
        'failureCode': failure.code,
        'message': failure.message,
        'cause': failure.cause?.toString(),
      };

      final path = await _sink.appendLine(jsonEncode(entry));
      if (path != null) {
        developer.log(
          'Login failure recorded at $path',
          name: 'vestipro.login_error_logger',
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'LoginErrorLogger failed to write the local log.',
        name: 'vestipro.login_error_logger',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

String _maskEmail(String email) {
  final trimmed = email.trim().toLowerCase();
  final atIndex = trimmed.indexOf('@');
  if (atIndex <= 0 || atIndex == trimmed.length - 1) return '<invalid-email>';

  final local = trimmed.substring(0, atIndex);
  final domain = trimmed.substring(atIndex + 1);
  final visibleLocal = local.length <= 2 ? local[0] : local.substring(0, 2);

  return '$visibleLocal***@$domain';
}
