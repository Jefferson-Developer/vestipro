import '../../../../core/errors/errors.dart';
import '../../../users/users.dart';
import '../../domain/entities/lead.dart';
import '../../domain/value_objects/lead_source.dart';

enum LeadFormLoadStatus { loading, ready, failure }

enum LeadFormSubmissionStatus { idle, submitting, success, failure }

final class LeadFormState {
  const LeadFormState({
    this.loadStatus = LeadFormLoadStatus.loading,
    this.submissionStatus = LeadFormSubmissionStatus.idle,
    this.organizationId = '',
    this.companyId,
    this.userId = '',
    this.canChooseResponsible = false,
    this.responsibleUsers = const <OrganizationUser>[],
    this.name = '',
    this.document = '',
    this.source = LeadSource.referral,
    this.customSourceLabel = '',
    this.responsibleUserId,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedLead,
  });

  final LeadFormLoadStatus loadStatus;
  final LeadFormSubmissionStatus submissionStatus;
  final String organizationId;
  final String? companyId;
  final String userId;
  final bool canChooseResponsible;
  final List<OrganizationUser> responsibleUsers;
  final String name;
  final String document;
  final LeadSource source;
  final String customSourceLabel;
  final String? responsibleUserId;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Lead? savedLead;

  bool get isSubmitting =>
      submissionStatus == LeadFormSubmissionStatus.submitting;
  bool get isCustomSource => source == LeadSource.other;

  LeadFormState copyWith({
    LeadFormLoadStatus? loadStatus,
    LeadFormSubmissionStatus? submissionStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    bool? canChooseResponsible,
    List<OrganizationUser>? responsibleUsers,
    String? name,
    String? document,
    LeadSource? source,
    String? customSourceLabel,
    String? responsibleUserId,
    bool clearResponsibleUserId = false,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    Failure? failure,
    bool clearFailure = false,
    Lead? savedLead,
    bool clearSavedLead = false,
  }) {
    return LeadFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      canChooseResponsible: canChooseResponsible ?? this.canChooseResponsible,
      responsibleUsers: responsibleUsers ?? this.responsibleUsers,
      name: name ?? this.name,
      document: document ?? this.document,
      source: source ?? this.source,
      customSourceLabel: customSourceLabel ?? this.customSourceLabel,
      responsibleUserId: clearResponsibleUserId
          ? null
          : responsibleUserId ?? this.responsibleUserId,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedLead: clearSavedLead ? null : savedLead ?? this.savedLead,
    );
  }
}
