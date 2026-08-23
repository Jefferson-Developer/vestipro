import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/accepted_invite_dto.dart';
import '../dtos/invite_preview_dto.dart';
import 'invite_acceptance_data_source.dart';

/// [InviteAcceptanceDataSource] backed by [CloudFunctionsService] (TASK-040)
/// — never talks to `cloud_firestore` directly, same rationale as
/// `FirestoreInviteDataSource.create`/`resend`/`revoke`.
@LazySingleton(as: InviteAcceptanceDataSource)
final class CloudFunctionsInviteAcceptanceDataSource
    implements InviteAcceptanceDataSource {
  const CloudFunctionsInviteAcceptanceDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<InvitePreviewDto> validate({required String token}) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'validateInvite',
      data: <String, dynamic>{'token': token},
      // Deliberately `false`: the whole point of `validateInvite` is being
      // safe to call *before* anyone is signed in, so `AcceptInvitePage`
      // can decide whether to show a "create account" or a "confirm" flow
      // next.
      requireAuth: false,
    );
    return InvitePreviewDto.fromJson(response);
  }

  @override
  Future<AcceptedInviteDto> accept({required String token}) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'acceptInvite',
      data: <String, dynamic>{'token': token},
      requireAuth: true,
    );
    return AcceptedInviteDto.fromJson(response);
  }
}
