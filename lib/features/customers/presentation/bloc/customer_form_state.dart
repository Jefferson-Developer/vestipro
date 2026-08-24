import '../../../../core/errors/errors.dart';
import '../../../users/users.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_form_config.dart';
import '../../domain/value_objects/customer_required_field.dart';
import '../../domain/value_objects/customer_sync_status.dart';
import '../../domain/value_objects/customer_type.dart';

enum CustomerFormLoadStatus { loading, ready, failure }

enum CustomerFormSubmissionStatus { idle, submitting, success, failure }

enum CustomerFormDraftStatus { idle, saving, saved, failure }

final class CustomerFormState {
  const CustomerFormState({
    this.loadStatus = CustomerFormLoadStatus.loading,
    this.submissionStatus = CustomerFormSubmissionStatus.idle,
    this.draftStatus = CustomerFormDraftStatus.idle,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.initialCustomer,
    this.config = const CustomerFormConfig(),
    this.canChooseResponsibleSeller = false,
    this.responsibleSellers = const <OrganizationUser>[],
    this.type = CustomerType.legalEntity,
    this.document = '',
    this.legalName = '',
    this.tradeName = '',
    this.fullName = '',
    this.stateRegistration = '',
    this.primaryEmail = '',
    this.primaryPhone = '',
    this.classification = '',
    this.potential = '',
    this.responsibleSellerId,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedCustomer,
    this.hasRestoredDraft = false,
  });

  final CustomerFormLoadStatus loadStatus;
  final CustomerFormSubmissionStatus submissionStatus;
  final CustomerFormDraftStatus draftStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final Customer? initialCustomer;
  final CustomerFormConfig config;
  final bool canChooseResponsibleSeller;
  final List<OrganizationUser> responsibleSellers;
  final CustomerType type;
  final String document;
  final String legalName;
  final String tradeName;
  final String fullName;
  final String stateRegistration;
  final String primaryEmail;
  final String primaryPhone;
  final String classification;
  final String potential;
  final String? responsibleSellerId;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Customer? savedCustomer;
  final bool hasRestoredDraft;

  bool get isEditing => initialCustomer != null;
  bool get isSubmitting =>
      submissionStatus == CustomerFormSubmissionStatus.submitting;
  bool get isDraftSaving => draftStatus == CustomerFormDraftStatus.saving;
  bool get wasSavedOffline =>
      savedCustomer?.syncStatus == CustomerSyncStatus.pending;

  bool isRequired(CustomerRequiredField field) {
    return config.requires(field);
  }

  CustomerFormState copyWith({
    CustomerFormLoadStatus? loadStatus,
    CustomerFormSubmissionStatus? submissionStatus,
    CustomerFormDraftStatus? draftStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    Customer? initialCustomer,
    CustomerFormConfig? config,
    bool? canChooseResponsibleSeller,
    List<OrganizationUser>? responsibleSellers,
    CustomerType? type,
    String? document,
    String? legalName,
    String? tradeName,
    String? fullName,
    String? stateRegistration,
    String? primaryEmail,
    String? primaryPhone,
    String? classification,
    String? potential,
    String? responsibleSellerId,
    Map<String, String>? fieldErrors,
    Failure? failure,
    Customer? savedCustomer,
    bool? hasRestoredDraft,
    bool clearResponsibleSellerId = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedCustomer = false,
  }) {
    return CustomerFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      draftStatus: draftStatus ?? this.draftStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      initialCustomer: initialCustomer ?? this.initialCustomer,
      config: config ?? this.config,
      canChooseResponsibleSeller:
          canChooseResponsibleSeller ?? this.canChooseResponsibleSeller,
      responsibleSellers: responsibleSellers ?? this.responsibleSellers,
      type: type ?? this.type,
      document: document ?? this.document,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      fullName: fullName ?? this.fullName,
      stateRegistration: stateRegistration ?? this.stateRegistration,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      classification: classification ?? this.classification,
      potential: potential ?? this.potential,
      responsibleSellerId: clearResponsibleSellerId
          ? null
          : responsibleSellerId ?? this.responsibleSellerId,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedCustomer: clearSavedCustomer
          ? null
          : savedCustomer ?? this.savedCustomer,
      hasRestoredDraft: hasRestoredDraft ?? this.hasRestoredDraft,
    );
  }
}
