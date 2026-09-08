import '../../../../core/utils/utils.dart';
import '../entities/approach_suggestion.dart';

/// Contract for TASK-187's "sugestão de abordagem comercial" feature
/// (EPIC-28). The only implementation is
/// `CloudFunctionsApproachSuggestionRepository` — there is deliberately no
/// local/offline datasource: the underlying data (orders, CRM activities,
/// insights) is already server-computed, the LLM call itself requires
/// connectivity, and `tasks.md`/TASK-187 never asks for an offline mode
/// here (same reasoning as `WalletSummaryRepository`, TASK-186).
abstract interface class ApproachSuggestionRepository {
  /// Requests (or reuses a cached) approach-suggestion draft for
  /// [customerId], scoped to [organizationId]/[companyId]. Never called for
  /// a customer outside the caller's own carteira unless the caller is a
  /// gestor (OWNER/ADMIN/SALES_MANAGER) — the server re-validates this on
  /// every call regardless of what the UI enforces.
  Future<AppResult<ApproachSuggestion>> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  });
}
