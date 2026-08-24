import '../dtos/product_form_draft_dto.dart';

abstract interface class ProductFormDraftDataSource {
  Future<ProductFormDraftDto?> getDraft({
    required String organizationId,
    required String userId,
  });

  Future<void> saveDraft(ProductFormDraftDto draft);

  Future<void> clearDraft({
    required String organizationId,
    required String userId,
  });
}
