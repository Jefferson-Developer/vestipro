import '../../domain/value_objects/return_reason_category.dart';

enum ReturnRequestFormStatus { idle, submitting, success, failure }

final class ReturnRequestFormState {
  const ReturnRequestFormState({
    this.status = ReturnRequestFormStatus.idle,
    this.selectedQuantities = const <String, int>{},
    this.reasonCategory,
    this.reasonDetails,
    this.evidenceUrls = const <String>[],
    this.isUploadingEvidence = false,
    this.failureMessage,
    this.fieldErrors = const <String, String>{},
  });

  final ReturnRequestFormStatus status;

  /// `orderItemId -> quantidade a devolver` — apenas itens com quantidade
  /// `> 0` são de fato enviados na solicitação.
  final Map<String, int> selectedQuantities;
  final ReturnReasonCategory? reasonCategory;
  final String? reasonDetails;
  final List<String> evidenceUrls;
  final bool isUploadingEvidence;
  final String? failureMessage;
  final Map<String, String> fieldErrors;

  bool get hasAnyItemSelected =>
      selectedQuantities.values.any((quantity) => quantity > 0);

  ReturnRequestFormState copyWith({
    ReturnRequestFormStatus? status,
    Map<String, int>? selectedQuantities,
    ReturnReasonCategory? reasonCategory,
    String? reasonDetails,
    List<String>? evidenceUrls,
    bool? isUploadingEvidence,
    String? failureMessage,
    bool clearFailureMessage = false,
    Map<String, String>? fieldErrors,
  }) {
    return ReturnRequestFormState(
      status: status ?? this.status,
      selectedQuantities: selectedQuantities ?? this.selectedQuantities,
      reasonCategory: reasonCategory ?? this.reasonCategory,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      isUploadingEvidence: isUploadingEvidence ?? this.isUploadingEvidence,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
