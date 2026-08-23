import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/user_role_update_result.dart';
import '../../domain/user_role_change_policy.dart';

part 'user_role_edit_state.freezed.dart';

enum UserRoleEditLoadStatus { loading, ready }

enum UserRoleEditSubmissionStatus { idle, submitting, success, failure }

@freezed
abstract class UserRoleEditState with _$UserRoleEditState {
  const factory UserRoleEditState({
    @Default(UserRoleEditLoadStatus.loading) UserRoleEditLoadStatus loadStatus,
    @Default('') String organizationId,
    OrganizationUser? user,
    SystemRoleName? currentRole,
    SystemRoleName? selectedRole,
    @Default(<SystemRoleName>[]) List<SystemRoleName> assignableRoles,
    String? roleError,
    @Default(UserRoleEditSubmissionStatus.idle)
    UserRoleEditSubmissionStatus submissionStatus,
    Failure? failure,
    UserRoleUpdateResult? result,
  }) = _UserRoleEditState;

  const UserRoleEditState._();

  bool get canSubmit {
    return loadStatus == UserRoleEditLoadStatus.ready &&
        submissionStatus != UserRoleEditSubmissionStatus.submitting &&
        selectedRole != null &&
        currentRole != null &&
        selectedRole != currentRole &&
        assignableRoles.contains(selectedRole);
  }

  bool get requiresConfirmation {
    final current = currentRole;
    final next = selectedRole;
    if (current == null || next == null || current == next) {
      return false;
    }
    return isSensitiveRoleChange(currentRole: current, nextRole: next);
  }
}
