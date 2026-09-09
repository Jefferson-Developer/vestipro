import '../../../../core/utils/utils.dart';
import '../entities/campaign_creation_draft.dart';

/// Contract for TASK-192's "criação assistida de coleção/campanha" feature
/// (EPIC-28). The only implementation is
/// `CloudFunctionsCampaignAssistRepository` — there is deliberately no
/// local/offline datasource: the underlying data (the organization's real
/// products) is already server-computed, the LLM call itself requires
/// connectivity, and `tasks.md`/TASK-192 never asks for an offline mode here
/// (same reasoning as `ApproachSuggestionRepository`, TASK-187).
abstract interface class CampaignAssistRepository {
  /// Requests (or reuses a cached) campaign-creation draft, scoped to
  /// [organizationId]. [productIds] is the admin's currently-selected
  /// related-products list (may be empty — a campaign can be a broad
  /// seasonal narrative with no specific product singled out yet); every id
  /// is independently re-resolved against this organization's own products
  /// server-side, never trusted as-is. Server-side re-validates the
  /// caller's own role (OWNER/ADMIN only, same scope as
  /// `Capability.catalogManage`) on every call regardless of what the UI
  /// enforces.
  Future<AppResult<CampaignCreationDraft>> generate({
    required String organizationId,
    required List<String> productIds,
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  });
}
