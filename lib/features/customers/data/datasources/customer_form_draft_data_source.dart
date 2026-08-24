import '../dtos/customer_form_draft_dto.dart';

abstract interface class CustomerFormDraftDataSource {
  Future<CustomerFormDraftDto?> getDraft({
    required String organizationId,
    required String userId,
  });

  Future<void> saveDraft(CustomerFormDraftDto draft);

  Future<void> clearDraft({
    required String organizationId,
    required String userId,
  });
}
