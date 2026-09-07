import '../../../../core/utils/utils.dart';
import '../entities/replenishment_decision_result.dart';
import '../entities/replenishment_suggestion_page.dart';
import '../value_objects/replenishment_decision_action.dart';
import '../value_objects/replenishment_suggestion_status.dart';

/// Contract behind reading `ReplenishmentSuggestion`s and deciding one
/// (TASK-184, EPIC-27). Listing/filtering always reads Firestore directly
/// (read-only, already scoped by `firestore.rules`); [decide] always calls
/// the `decideReplenishmentSuggestion` Cloud Function — the only place a
/// suggestion's `status` can ever leave `suggested`/`insufficientData`,
/// never a client-side write.
abstract interface class ReplenishmentRepository {
  Future<AppResult<ReplenishmentSuggestionPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    ReplenishmentSuggestionStatus? status,
    String? warehouseId,
  });

  Future<AppResult<ReplenishmentDecisionResult>> decide({
    required String organizationId,
    required String suggestionId,
    required ReplenishmentDecisionAction action,
    int? adjustedQuantity,
    String? note,
  });
}
