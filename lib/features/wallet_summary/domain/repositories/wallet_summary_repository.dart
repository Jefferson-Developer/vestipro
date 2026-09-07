import '../../../../core/utils/utils.dart';
import '../entities/wallet_summary.dart';

/// Contract for TASK-186's "resumo de carteira" feature (EPIC-28). The only
/// implementation is `CloudFunctionsWalletSummaryRepository` — there is
/// deliberately no local/offline datasource: the underlying data
/// (aggregations, insights) is already server-computed, the LLM call itself
/// requires connectivity, and `tasks.md`/TASK-186 never asks for an offline
/// mode here (unlike, say, pedido em rascunho).
abstract interface class WalletSummaryRepository {
  /// Requests (or reuses a cached) wallet summary for [sellerId]'s current
  /// period, scoped to [organizationId]/[companyId]. Never called with a
  /// [sellerId] other than the caller's own uid unless the caller is a
  /// gestor (OWNER/ADMIN/SALES_MANAGER) — the server re-validates this on
  /// every call regardless of what the UI enforces.
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  });
}
