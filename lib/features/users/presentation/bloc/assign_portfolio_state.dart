import '../../../../core/errors/errors.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/commercial_team.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/portfolio_assignment.dart';

enum AssignPortfolioLoadStatus { loading, ready, failure }

enum AssignPortfolioSubmissionStatus { idle, submitting, success, failure }

final class AssignPortfolioState {
  const AssignPortfolioState({
    this.loadStatus = AssignPortfolioLoadStatus.loading,
    this.submissionStatus = AssignPortfolioSubmissionStatus.idle,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.users = const <OrganizationUser>[],
    this.teams = const <CommercialTeam>[],
    this.assignments = const <PortfolioAssignment>[],
    this.selectedUserId,
    this.selectedTeamId,
    this.scopeType = PortfolioAssignmentScopeType.customer,
    this.customerId = '',
    this.region = '',
    this.segment = '',
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedAssignment,
  });

  final AssignPortfolioLoadStatus loadStatus;
  final AssignPortfolioSubmissionStatus submissionStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final List<OrganizationUser> users;
  final List<CommercialTeam> teams;
  final List<PortfolioAssignment> assignments;
  final String? selectedUserId;
  final String? selectedTeamId;
  final PortfolioAssignmentScopeType scopeType;
  final String customerId;
  final String region;
  final String segment;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final PortfolioAssignment? savedAssignment;

  bool get isSubmitting =>
      submissionStatus == AssignPortfolioSubmissionStatus.submitting;

  List<OrganizationUser> get sellers => users
      .where(
        (user) =>
            user.status == MembershipStatus.active &&
            user.roleName == SystemRoleName.salesRep.code,
      )
      .toList(growable: false);

  AssignPortfolioState copyWith({
    AssignPortfolioLoadStatus? loadStatus,
    AssignPortfolioSubmissionStatus? submissionStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    List<OrganizationUser>? users,
    List<CommercialTeam>? teams,
    List<PortfolioAssignment>? assignments,
    String? selectedUserId,
    String? selectedTeamId,
    PortfolioAssignmentScopeType? scopeType,
    String? customerId,
    String? region,
    String? segment,
    Map<String, String>? fieldErrors,
    Failure? failure,
    PortfolioAssignment? savedAssignment,
    bool clearSelectedUserId = false,
    bool clearSelectedTeamId = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedAssignment = false,
  }) {
    return AssignPortfolioState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      users: users ?? this.users,
      teams: teams ?? this.teams,
      assignments: assignments ?? this.assignments,
      selectedUserId: clearSelectedUserId
          ? null
          : selectedUserId ?? this.selectedUserId,
      selectedTeamId: clearSelectedTeamId
          ? null
          : selectedTeamId ?? this.selectedTeamId,
      scopeType: scopeType ?? this.scopeType,
      customerId: customerId ?? this.customerId,
      region: region ?? this.region,
      segment: segment ?? this.segment,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedAssignment: clearSavedAssignment
          ? null
          : savedAssignment ?? this.savedAssignment,
    );
  }
}
