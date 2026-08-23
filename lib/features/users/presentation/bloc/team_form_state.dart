import '../../../../core/errors/errors.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/organization_user.dart';

enum TeamFormLoadStatus { loading, ready, failure }

enum TeamFormSubmissionStatus { idle, submitting, success, failure }

final class TeamFormState {
  const TeamFormState({
    this.loadStatus = TeamFormLoadStatus.loading,
    this.submissionStatus = TeamFormSubmissionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.initialTeam,
    this.users = const <OrganizationUser>[],
    this.name = '',
    this.managerUserId,
    this.memberIds = const <String>{},
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedTeam,
  });

  final TeamFormLoadStatus loadStatus;
  final TeamFormSubmissionStatus submissionStatus;
  final String organizationId;
  final String userId;
  final Team? initialTeam;
  final List<OrganizationUser> users;
  final String name;
  final String? managerUserId;
  final Set<String> memberIds;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Team? savedTeam;

  bool get isEditing => initialTeam != null;
  bool get isSubmitting =>
      submissionStatus == TeamFormSubmissionStatus.submitting;

  List<OrganizationUser> get managers => users
      .where(
        (user) =>
            user.status == MembershipStatus.active &&
            user.roleName == SystemRoleName.salesManager.code,
      )
      .toList(growable: false);

  List<OrganizationUser> get members => users
      .where(
        (user) =>
            user.status == MembershipStatus.active &&
            (user.roleName == SystemRoleName.salesRep.code ||
                user.roleName == SystemRoleName.salesAssistant.code),
      )
      .toList(growable: false);

  TeamFormState copyWith({
    TeamFormLoadStatus? loadStatus,
    TeamFormSubmissionStatus? submissionStatus,
    String? organizationId,
    String? userId,
    Team? initialTeam,
    List<OrganizationUser>? users,
    String? name,
    String? managerUserId,
    Set<String>? memberIds,
    Map<String, String>? fieldErrors,
    Failure? failure,
    Team? savedTeam,
    bool clearManagerUserId = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedTeam = false,
  }) {
    return TeamFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      initialTeam: initialTeam ?? this.initialTeam,
      users: users ?? this.users,
      name: name ?? this.name,
      managerUserId: clearManagerUserId
          ? null
          : managerUserId ?? this.managerUserId,
      memberIds: memberIds ?? this.memberIds,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedTeam: clearSavedTeam ? null : savedTeam ?? this.savedTeam,
    );
  }
}
