import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../dashboards/domain/services/representative_dashboard_visibility_service.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_summary_repository.dart';

/// Requests TASK-186's "resumo de carteira" (EPIC-28) for [sellerId], gated
/// by the exact same visibility rule the "meu dashboard" screen already
/// enforces (`RepresentativeDashboardVisibilityService`, TASK-140) — a
/// wallet summary exposes the same class of sensitive per-seller data
/// (revenue, target risk, named customers) as that dashboard, so it never
/// gets a looser client-side rule. The server (`generateWalletSummary`)
/// re-validates this independently regardless of what this check decides —
/// this is UX (fail fast, clear message), never the real authorization
/// boundary.
@injectable
final class GenerateWalletSummaryUseCase {
  const GenerateWalletSummaryUseCase(
    this._repository,
    this._visibilityService,
    this._analyticsService,
  );

  final WalletSummaryRepository _repository;
  final RepresentativeDashboardVisibilityService _visibilityService;
  final AnalyticsService _analyticsService;

  Future<AppResult<WalletSummary>> call({
    required String organizationId,
    required String companyId,
    required String requesterUserId,
    required String sellerId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedRequesterUserId = requesterUserId.trim();
    final trimmedSellerId = sellerId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedRequesterUserId.isEmpty) {
      fieldErrors['requesterUserId'] = 'RequesterUserId is required.';
    }
    if (trimmedSellerId.isEmpty) {
      fieldErrors['sellerId'] = 'SellerId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<WalletSummary>(
        ValidationFailure(
          'Invalid wallet summary request.',
          fieldErrors: fieldErrors,
          code: 'invalid_wallet_summary_request',
        ),
      );
    }

    final visibility = await _visibilityService.canView(
      organizationId: trimmedOrganizationId,
      requesterUserId: trimmedRequesterUserId,
      sellerId: trimmedSellerId,
    );
    if (visibility case AppFailure<bool>(failure: final failure)) {
      return AppFailure<WalletSummary>(failure);
    }
    if (!(visibility as AppSuccess<bool>).value) {
      return const AppFailure<WalletSummary>(
        PermissionFailure(
          'User cannot view this seller wallet summary.',
          code: 'wallet_summary_view_denied',
        ),
      );
    }

    final result = await _repository.generate(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      sellerId: trimmedSellerId,
    );
    switch (result) {
      case AppSuccess<WalletSummary>(value: final summary):
        await _analyticsService.logEvent(
          AnalyticsEvents.walletSummaryGenerated,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'seller_id': trimmedSellerId,
            'from_cache': summary.fromCache,
          },
        );
      case AppFailure<WalletSummary>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.walletSummaryGenerationFailed,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'seller_id': trimmedSellerId,
            'failure_code': failure.code,
          },
        );
    }
    return result;
  }
}
