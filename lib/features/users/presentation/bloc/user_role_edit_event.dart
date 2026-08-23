import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/organization_user.dart';

part 'user_role_edit_event.freezed.dart';

@freezed
sealed class UserRoleEditEvent with _$UserRoleEditEvent {
  const factory UserRoleEditEvent.started({
    required String organizationId,
    required OrganizationUser user,
  }) = UserRoleEditStarted;

  const factory UserRoleEditEvent.roleSelected(SystemRoleName role) =
      UserRoleEditRoleSelected;

  const factory UserRoleEditEvent.submitted() = UserRoleEditSubmitted;
}
