import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_portfolio_page_result.dart';
import '../entities/customer_segment_criteria.dart';
import '../entities/customer_segment_preview.dart';
import 'list_customer_portfolio_use_case.dart';

/// Previews how many customers currently match a [CustomerSegmentCriteria],
/// before the segment is saved (TASK-053).
///
/// Deliberately reuses [ListCustomerPortfolioUseCase] instead of duplicating
/// its RBAC visibility resolution (role/team/own-customers scoping): the
/// preview must only ever count customers the requesting user could already
/// see in the carteira.
@injectable
final class PreviewCustomerSegmentCountUseCase {
  const PreviewCustomerSegmentCountUseCase(this._listCustomerPortfolio);

  final ListCustomerPortfolioUseCase _listCustomerPortfolio;

  /// Maximum customers counted per preview call. This is meant as a quick
  /// "about how many customers match" signal before saving, not an exact
  /// count for very large portfolios: when the real count would be at or
  /// above this cap, [CustomerSegmentPreview.isAtLeastCount] is true.
  static const previewLimit = 100;

  Future<AppResult<CustomerSegmentPreview>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required CustomerSegmentCriteria criteria,
    DateTime? now,
  }) async {
    final result = await _listCustomerPortfolio(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      filters: criteria.toPortfolioFilters(),
      limit: previewLimit,
      now: now,
    );
    return switch (result) {
      AppSuccess<CustomerPortfolioPageResult>(value: final page) =>
        AppSuccess<CustomerSegmentPreview>(
          CustomerSegmentPreview(
            matchedCount: page.customers.length,
            isAtLeastCount: page.hasMore,
          ),
        ),
      AppFailure<CustomerPortfolioPageResult>(failure: final failure) =>
        AppFailure<CustomerSegmentPreview>(failure),
    };
  }
}
