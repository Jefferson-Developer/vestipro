import 'package:freezed_annotation/freezed_annotation.dart';

part 'completed_sso_login.freezed.dart';

/// The result of a successful `completeSsoLogin` call (TASK-173): the
/// Organization the caller just finished authenticating into, the role
/// their Membership currently holds (either just-in-time provisioned with
/// the connection's `defaultRoleName`, or an already-existing one —
/// [provisioned] tells the two apart), and its name for a friendly
/// "Bem-vindo, {organizationName}" moment.
@freezed
abstract class CompletedSsoLogin with _$CompletedSsoLogin {
  const factory CompletedSsoLogin({
    required String organizationId,
    required String organizationName,
    required String roleName,
    required bool provisioned,
  }) = _CompletedSsoLogin;
}
