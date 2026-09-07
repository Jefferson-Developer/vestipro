import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/auth/domain/entities/session_user.dart';

part 'corporate_sso_login_result.freezed.dart';

/// What [SignInWithCorporateSsoUseCase] resolves to on success (TASK-173):
/// the newly-authenticated [sessionUser] plus exactly which Organization
/// `completeSsoLogin` resolved for it — `LoginBloc` never has to separately
/// call `ResolveActiveOrganizationIdUseCase` for the SSO flow the way it
/// does for e-mail/senha, since [organizationId] is already the real,
/// server-confirmed answer.
@freezed
abstract class CorporateSsoLoginResult with _$CorporateSsoLoginResult {
  const factory CorporateSsoLoginResult({
    required SessionUser sessionUser,
    required String organizationId,
    required String organizationName,
  }) = _CorporateSsoLoginResult;
}
