import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/system_role_name.dart';

part 'accepted_invite.freezed.dart';

/// The result of a successful `acceptInvite` call (TASK-040): the
/// Organization the caller just joined, and the exact role they were
/// granted (always the invite's own `roleName`, never one they chose).
@freezed
abstract class AcceptedInvite with _$AcceptedInvite {
  const factory AcceptedInvite({
    required String organizationId,
    required String organizationName,
    required SystemRoleName roleName,
  }) = _AcceptedInvite;
}
