import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/customers.dart';
import '../../../organizations/organizations.dart';
import '../../../pricing/pricing.dart';
import '../entities/order_draft_defaults.dart';

/// Resolves the company/unidade/tabela de preço/condição de pagamento a new
/// `Order` draft (TASK-096) is pre-filled with for [customer], reusing the
/// "regras já vigentes" already implemented by earlier EPIC-11/EPIC-03
/// tasks instead of inventing a new precedence rule here:
///
/// - Unidade (Branch): the first [BranchStatus.active] Branch of the
///   company, ordered by name — this codebase has no per-customer/per-seller
///   default-branch assignment yet, so a deterministic, auditable fallback
///   is used until one exists.
/// - Tabela de preço: [ResolveApplicablePriceListsUseCase]'s own
///   highest-priority/most-specific match for the customer's
///   `originChannel`/`segment` (TASK-083 rule).
/// - Condição de pagamento: [ListActivePaymentTermsUseCase]'s own
///   compatibility rule against the resolved Price List
///   (`PaymentTerm.isCompatibleWithPriceList`).
///
/// Fails loudly (never with an invented placeholder id) when the company has
/// no active Branch, no applicable Price List for this customer right now,
/// or no Payment Term compatible with the resolved Price List — `Order`'s
/// `branchId`/`priceListId`/`paymentTermId` are non-nullable, so a seller
/// must not be able to start a draft that secretly carries an empty
/// reference to any of them.
@injectable
final class ResolveOrderDraftDefaultsUseCase {
  const ResolveOrderDraftDefaultsUseCase(
    this._listBranches,
    this._resolveApplicablePriceLists,
    this._listActivePaymentTerms,
  );

  final ListBranchesByCompanyUseCase _listBranches;
  final ResolveApplicablePriceListsUseCase _resolveApplicablePriceLists;
  final ListActivePaymentTermsUseCase _listActivePaymentTerms;

  Future<AppResult<OrderDraftDefaults>> call({
    required String organizationId,
    required String companyId,
    required Customer customer,
    DateTime? now,
  }) async {
    final branchesResult = await _listBranches(
      organizationId: organizationId,
      companyId: companyId,
    );
    if (branchesResult case AppFailure<List<Branch>>(failure: final failure)) {
      return AppFailure<OrderDraftDefaults>(failure);
    }
    final activeBranches =
        (branchesResult as AppSuccess<List<Branch>>).value
            .where((branch) => branch.status == BranchStatus.active)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    if (activeBranches.isEmpty) {
      return const AppFailure<OrderDraftDefaults>(
        ValidationFailure(
          'No active branch configured for this company.',
          code: 'order_draft_no_active_branch',
        ),
      );
    }

    final priceListsResult = await _resolveApplicablePriceLists(
      organizationId: organizationId,
      companyId: companyId,
      customerChannel: customer.originChannel,
      customerSegment: customer.segment,
      now: now,
    );
    if (priceListsResult case AppFailure<List<PriceList>>(
      failure: final failure,
    )) {
      return AppFailure<OrderDraftDefaults>(failure);
    }
    final applicablePriceLists =
        (priceListsResult as AppSuccess<List<PriceList>>).value;
    if (applicablePriceLists.isEmpty) {
      return const AppFailure<OrderDraftDefaults>(
        ValidationFailure(
          'No applicable price list for this customer right now.',
          code: 'order_draft_no_applicable_price_list',
        ),
      );
    }
    final priceList = applicablePriceLists.first;

    final paymentTermsResult = await _listActivePaymentTerms(
      organizationId: organizationId,
      companyId: companyId,
      priceListId: priceList.id,
    );
    if (paymentTermsResult case AppFailure<List<PaymentTerm>>(
      failure: final failure,
    )) {
      return AppFailure<OrderDraftDefaults>(failure);
    }
    final compatiblePaymentTerms =
        (paymentTermsResult as AppSuccess<List<PaymentTerm>>).value;
    if (compatiblePaymentTerms.isEmpty) {
      return const AppFailure<OrderDraftDefaults>(
        ValidationFailure(
          'No active payment term compatible with the resolved price list.',
          code: 'order_draft_no_compatible_payment_term',
        ),
      );
    }

    return AppSuccess<OrderDraftDefaults>(
      OrderDraftDefaults(
        branch: activeBranches.first,
        priceList: priceList,
        paymentTerm: compatiblePaymentTerms.first,
      ),
    );
  }
}
