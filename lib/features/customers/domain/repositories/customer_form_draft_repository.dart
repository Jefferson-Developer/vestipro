import '../../../../core/utils/utils.dart';
import '../entities/customer_form_draft.dart';

abstract interface class CustomerFormDraftRepository {
  Future<AppResult<CustomerFormDraft?>> get({
    required String organizationId,
    required String userId,
  });

  Future<AppResult<void>> save(CustomerFormDraft draft);

  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  });
}
