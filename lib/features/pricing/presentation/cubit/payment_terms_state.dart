import '../../domain/entities/payment_term.dart';
import '../../domain/value_objects/payment_term_status.dart';

enum PaymentTermsLoadStatus { loading, ready, failure }

enum PaymentTermsSaveStatus { idle, editing, submitting, success, failure }

final class PaymentTermsState {
  const PaymentTermsState({
    this.loadStatus = PaymentTermsLoadStatus.loading,
    this.saveStatus = PaymentTermsSaveStatus.idle,
    this.paymentTerms = const <PaymentTerm>[],
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.actorName = '',
    this.editingId,
    this.name = '',
    this.installmentsInput = '',
    this.priceListIdsInput = '',
    this.status = PaymentTermStatus.active,
    this.installmentsTotal = 0,
    this.fieldErrors = const <String, String>{},
    this.failureMessage,
  });

  final PaymentTermsLoadStatus loadStatus;
  final PaymentTermsSaveStatus saveStatus;
  final List<PaymentTerm> paymentTerms;
  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final String? editingId;
  final String name;
  final String installmentsInput;
  final String priceListIdsInput;
  final PaymentTermStatus status;
  final double installmentsTotal;
  final Map<String, String> fieldErrors;
  final String? failureMessage;

  bool get isEditing => editingId != null;
  bool get isBusy =>
      loadStatus == PaymentTermsLoadStatus.loading ||
      saveStatus == PaymentTermsSaveStatus.submitting;

  PaymentTermsState copyWith({
    PaymentTermsLoadStatus? loadStatus,
    PaymentTermsSaveStatus? saveStatus,
    List<PaymentTerm>? paymentTerms,
    String? organizationId,
    String? companyId,
    String? userId,
    String? actorName,
    String? editingId,
    bool clearEditingId = false,
    String? name,
    String? installmentsInput,
    String? priceListIdsInput,
    PaymentTermStatus? status,
    double? installmentsTotal,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PaymentTermsState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      editingId: clearEditingId ? null : (editingId ?? this.editingId),
      name: name ?? this.name,
      installmentsInput: installmentsInput ?? this.installmentsInput,
      priceListIdsInput: priceListIdsInput ?? this.priceListIdsInput,
      status: status ?? this.status,
      installmentsTotal: installmentsTotal ?? this.installmentsTotal,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : (fieldErrors ?? this.fieldErrors),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
