import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../dashboards/domain/services/representative_dashboard_visibility_service.dart';
import '../entities/daily_rep_summary.dart';
import '../repositories/daily_rep_summary_repository.dart';

/// Requests TASK-188's "resumo diário do vendedor" (EPIC-28) for [sellerId],
/// gated by the exact same visibility rule the "meu dashboard" screen and
/// `GenerateWalletSummaryUseCase` (TASK-186) already enforce
/// (`RepresentativeDashboardVisibilityService`, TASK-140) — a daily summary
/// exposes the same class of sensitive per-seller data (revenue, target
/// risk, named customers) as the wallet summary, so it never gets a looser
/// client-side rule. The server (`getDailyRepSummary`) re-validates this
/// independently regardless of what this check decides — this is UX (fail
/// fast, clear message), never the real authorization boundary.
@injectable
final class LoadDailyRepSummaryUseCase {
  const LoadDailyRepSummaryUseCase(
    this._repository,
    this._visibilityService,
    this._analyticsService,
  );

  final DailyRepSummaryRepository _repository;
  final RepresentativeDashboardVisibilityService _visibilityService;
  final AnalyticsService _analyticsService;

  Future<AppResult<DailyRepSummary>> call({
    required String organizationId,
    required String requesterUserId,
    required String sellerId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedRequesterUserId = requesterUserId.trim();
    final trimmedSellerId = sellerId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedRequesterUserId.isEmpty) {
      fieldErrors['requesterUserId'] = 'RequesterUserId is required.';
    }
    if (trimmedSellerId.isEmpty) {
      fieldErrors['sellerId'] = 'SellerId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<DailyRepSummary>(
        ValidationFailure(
          'Invalid daily rep summary request.',
          fieldErrors: fieldErrors,
          code: 'invalid_daily_rep_summary_request',
        ),
      );
    }

    final visibility = await _visibilityService.canView(
      organizationId: trimmedOrganizationId,
      requesterUserId: trimmedRequesterUserId,
      sellerId: trimmedSellerId,
    );
    if (visibility case AppFailure<bool>(failure: final failure)) {
      return AppFailure<DailyRepSummary>(failure);
    }
    if (!(visibility as AppSuccess<bool>).value) {
      return const AppFailure<DailyRepSummary>(
        PermissionFailure(
          'User cannot view this seller daily summary.',
          code: 'daily_rep_summary_view_denied',
        ),
      );
    }

    final result = await _repository.load(
      organizationId: trimmedOrganizationId,
      sellerId: trimmedSellerId,
    );
    switch (result) {
      case AppSuccess<DailyRepSummary>(value: final summary):
        await _analyticsService.logEvent(
          AnalyticsEvents.dailyRepSummaryViewed,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'seller_id': trimmedSellerId,
            'status': summary.status.name,
          },
        );
      case AppFailure<DailyRepSummary>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.dailyRepSummaryLoadFailed,
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
