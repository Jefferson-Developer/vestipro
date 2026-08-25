import '../../../../core/utils/utils.dart';
import '../entities/commercial_size_grid_draft.dart';

abstract interface class CommercialSizeGridDraftRepository {
  Future<AppResult<CommercialSizeGridDraft?>> getDraft({
    required String organizationId,
    required String productId,
  });

  Future<AppResult<CommercialSizeGridDraft>> saveDraft({
    required CommercialSizeGridDraft draft,
  });
}
