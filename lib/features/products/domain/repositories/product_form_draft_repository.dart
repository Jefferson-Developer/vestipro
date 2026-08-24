import '../../../../core/utils/utils.dart';
import '../entities/product_form_draft.dart';

abstract interface class ProductFormDraftRepository {
  Future<AppResult<ProductFormDraft?>> get({
    required String organizationId,
    required String userId,
  });

  Future<AppResult<void>> save(ProductFormDraft draft);

  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  });
}
