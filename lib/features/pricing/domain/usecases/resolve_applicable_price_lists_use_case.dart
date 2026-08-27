import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/price_list.dart';
import '../repositories/price_list_repository.dart';
import '../value_objects/price_list_scope_type.dart';

/// Resolves which [PriceList]s are vigent AND applicable to a customer/order
/// right now (EPIC-11, TASK-083) — the primitive the future server-side
/// pricing engine (TASK-088) builds on.
///
/// A Price List is included only when it is
/// [PriceList.isApplicableAt] (status `active`, not soft-deleted, inside its
/// own validity window — regardless of what its stored `status` says, see
/// that method's docs) AND [PriceList.matchesCustomerContext] for the given
/// [customerChannel]/[customerSegment]. The result is sorted with the most
/// specific/highest-priority table first: [PriceList.priority] descending,
/// then scope specificity (segment > channel > company-wide) as a
/// tie-breaker, then most recently started, then [PriceList.id] for full
/// determinism. Resolving "which one wins" among the returned tables is
/// this use case's job precisely so no UI/widget ever has to reimplement
/// this precedence itself (AGENTS.md, "Regra de negócio não fica em
/// widget").
@injectable
final class ResolveApplicablePriceListsUseCase {
  const ResolveApplicablePriceListsUseCase(this._repository);

  final PriceListRepository _repository;

  Future<AppResult<List<PriceList>>> call({
    required String organizationId,
    required String companyId,
    String? customerChannel,
    String? customerSegment,
    DateTime? now,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<PriceList>>(
        ValidationFailure(
          'Invalid price list resolution request.',
          code: 'invalid_resolve_price_lists_request',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final listResult = await _repository.listByCompany(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
    );
    if (listResult case AppFailure<List<PriceList>>(failure: final failure)) {
      return AppFailure<List<PriceList>>(failure);
    }
    final priceLists = (listResult as AppSuccess<List<PriceList>>).value;

    final resolvedNow = (now ?? DateTime.now()).toUtc();
    final applicable =
        priceLists
            .where(
              (priceList) =>
                  priceList.organizationId == trimmedOrganizationId &&
                  priceList.companyId == trimmedCompanyId &&
                  priceList.isApplicableAt(resolvedNow) &&
                  priceList.matchesCustomerContext(
                    customerChannel: customerChannel,
                    customerSegment: customerSegment,
                  ),
            )
            .toList()
          ..sort(_compareByApplicability);

    return AppSuccess<List<PriceList>>(applicable);
  }

  int _compareByApplicability(PriceList a, PriceList b) {
    final byPriority = b.priority.compareTo(a.priority);
    if (byPriority != 0) return byPriority;

    final bySpecificity = _scopeSpecificity(
      b.scope,
    ).compareTo(_scopeSpecificity(a.scope));
    if (bySpecificity != 0) return bySpecificity;

    final byValidFrom = b.validFrom.compareTo(a.validFrom);
    if (byValidFrom != 0) return byValidFrom;

    return a.id.compareTo(b.id);
  }

  int _scopeSpecificity(PriceListScopeType scope) {
    return switch (scope) {
      PriceListScopeType.segment => 2,
      PriceListScopeType.channel => 1,
      PriceListScopeType.company => 0,
    };
  }
}
