import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/completed_sso_login_dto.dart';
import '../dtos/sso_login_route_dto.dart';
import 'sso_data_source.dart';

/// [SsoDataSource] backed by [CloudFunctionsService] (TASK-173) — never
/// talks to `cloud_firestore` directly, same rationale as
/// `CloudFunctionsInviteAcceptanceDataSource`.
@LazySingleton(as: SsoDataSource)
final class CloudFunctionsSsoDataSource implements SsoDataSource {
  const CloudFunctionsSsoDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<SsoLoginRouteDto> resolveConnectionForEmail({
    required String email,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'resolveSsoForEmail',
      data: <String, dynamic>{'email': email},
      // Deliberately `false`: the whole point of `resolveSsoForEmail` is
      // being safe to call *before* anyone is signed in, so `LoginBloc` can
      // decide which `providerId` to hand `signInWithFederatedProvider`
      // next.
      requireAuth: false,
    );
    return SsoLoginRouteDto.fromJson(response);
  }

  @override
  Future<CompletedSsoLoginDto> completeSsoLogin() async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'completeSsoLogin',
      requireAuth: true,
    );
    return CompletedSsoLoginDto.fromJson(response);
  }
}
