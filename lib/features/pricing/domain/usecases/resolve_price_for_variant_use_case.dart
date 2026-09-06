import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/price_list_item.dart';
import '../entities/price_list.dart';
import '../entities/resolved_variant_price.dart';
import '../repositories/price_list_item_repository.dart';
import 'resolve_applicable_price_lists_use_case.dart';

@injectable
final class ResolvePriceForVariantUseCase {
  const ResolvePriceForVariantUseCase(
    this._resolveApplicablePriceLists,
    this._priceListItemRepository,
  );

  final ResolveApplicablePriceListsUseCase _resolveApplicablePriceLists;
  final PriceListItemRepository _priceListItemRepository;

  Future<AppResult<ResolvedVariantPrice>> call({
    required String organizationId,
    required String companyId,
    required String productId,
    required String variantId,
    String? customerChannel,
    String? customerSegment,
    DateTime? now,
  }) async {
    final fieldErrors = _validate(
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      variantId: variantId,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ResolvedVariantPrice>(
        ValidationFailure(
          'Invalid variant price resolution request.',
          code: 'invalid_resolve_variant_price_request',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final contextResult = await _loadPricingContext(
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      customerChannel: customerChannel,
      customerSegment: customerSegment,
      now: now,
    );
    if (contextResult case AppFailure<_PricingContext>(
      failure: final failure,
    )) {
      return AppFailure<ResolvedVariantPrice>(failure);
    }
    final context = (contextResult as AppSuccess<_PricingContext>).value;

    return AppSuccess<ResolvedVariantPrice>(
      _resolveForVariant(context: context, variantId: variantId.trim()),
    );
  }

  /// Same fallback chain as [call] (variant-specific -> product-level in the
  /// same table -> missing), resolved once for every [variantIds] entry of a
  /// single [productId] instead of once per variant.
  ///
  /// [call] itself already fetches the exact same [_resolveApplicablePriceLists]
  /// and `_priceListItemRepository.listByProduct` results for every variant of
  /// the same product — neither depends on `variantId` at all. Calling [call]
  /// in a loop (one per variant, as `ProductGridBloc`/`ProductDetailBloc` used
  /// to do before TASK-164) turns one product's price resolution into
  /// `2 * variantCount` redundant data-layer reads instead of 2, which is
  /// exactly the "client-side over-querying" TASK-164 measured and fixed —
  /// this method is the only entry point catalog screens with more than one
  /// variant per product should use from now on.
  Future<AppResult<Map<String, ResolvedVariantPrice>>> callForProduct({
    required String organizationId,
    required String companyId,
    required String productId,
    required Iterable<String> variantIds,
    String? customerChannel,
    String? customerSegment,
    DateTime? now,
  }) async {
    final ids = variantIds.toList(growable: false);
    final fieldErrors = _validate(
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      variantId: ids.isEmpty ? null : ids.first,
    );
    if (ids.isEmpty) {
      fieldErrors['variantIds'] = 'At least one variantId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Map<String, ResolvedVariantPrice>>(
        ValidationFailure(
          'Invalid variant price resolution request.',
          code: 'invalid_resolve_variant_price_request',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final contextResult = await _loadPricingContext(
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      customerChannel: customerChannel,
      customerSegment: customerSegment,
      now: now,
    );
    if (contextResult case AppFailure<_PricingContext>(
      failure: final failure,
    )) {
      return AppFailure<Map<String, ResolvedVariantPrice>>(failure);
    }
    final context = (contextResult as AppSuccess<_PricingContext>).value;

    return AppSuccess<Map<String, ResolvedVariantPrice>>(
      Map<String, ResolvedVariantPrice>.unmodifiable(
        <String, ResolvedVariantPrice>{
          for (final variantId in ids)
            variantId: _resolveForVariant(
              context: context,
              variantId: variantId.trim(),
            ),
        },
      ),
    );
  }

  Map<String, String> _validate({
    required String organizationId,
    required String companyId,
    required String productId,
    required String? variantId,
  }) {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (productId.trim().isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (variantId != null && variantId.trim().isEmpty) {
      fieldErrors['variantId'] = 'VariantId is required.';
    }
    return fieldErrors;
  }

  /// The two data-layer reads shared by every variant of the same product/
  /// customer context: which price lists apply, and which price-list items
  /// exist for this product. Fetched exactly once per [call]/[callForProduct]
  /// invocation regardless of how many variants are being resolved.
  Future<AppResult<_PricingContext>> _loadPricingContext({
    required String organizationId,
    required String companyId,
    required String productId,
    String? customerChannel,
    String? customerSegment,
    DateTime? now,
  }) async {
    final priceListsResult = await _resolveApplicablePriceLists(
      organizationId: organizationId,
      companyId: companyId,
      customerChannel: customerChannel,
      customerSegment: customerSegment,
      now: now,
    );
    if (priceListsResult case AppFailure<List<PriceList>>(
      failure: final failure,
    )) {
      return AppFailure<_PricingContext>(failure);
    }
    final applicablePriceLists =
        (priceListsResult as AppSuccess<List<PriceList>>).value;

    final itemsResult = await _priceListItemRepository.listByProduct(
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
      productId: productId.trim(),
    );
    if (itemsResult case AppFailure<List<PriceListItem>>(
      failure: final failure,
    )) {
      return AppFailure<_PricingContext>(failure);
    }
    final items = (itemsResult as AppSuccess<List<PriceListItem>>).value;

    return AppSuccess<_PricingContext>(
      _PricingContext(
        applicablePriceLists: List.unmodifiable(applicablePriceLists),
        items: items,
      ),
    );
  }

  /// The single documented fallback chain (TASK-084): variant-specific ->
  /// product-level in the same table -> missing. Pure/in-memory — every
  /// caller ([call], [callForProduct]) already fetched [context] once.
  ResolvedVariantPrice _resolveForVariant({
    required _PricingContext context,
    required String variantId,
  }) {
    for (final priceList in context.applicablePriceLists) {
      final itemsForList = context.items.where(
        (item) => item.priceListId == priceList.id,
      );
      PriceListItem? variantSpecific;
      PriceListItem? productFallback;
      for (final item in itemsForList) {
        if (item.variantId == variantId) {
          variantSpecific = item;
          break;
        }
        if (item.variantId == null) {
          productFallback = item;
        }
      }
      if (variantSpecific != null) {
        return ResolvedVariantPrice(
          origin: PriceResolutionOrigin.variant,
          applicablePriceLists: context.applicablePriceLists,
          priceList: priceList,
          matchedItem: variantSpecific,
        );
      }
      if (productFallback != null) {
        return ResolvedVariantPrice(
          origin: PriceResolutionOrigin.product,
          applicablePriceLists: context.applicablePriceLists,
          priceList: priceList,
          matchedItem: productFallback,
        );
      }
    }

    return ResolvedVariantPrice(
      origin: PriceResolutionOrigin.missing,
      applicablePriceLists: context.applicablePriceLists,
    );
  }
}

/// Internal: the two shared reads behind one product/customer-context price
/// resolution, kept private so no call site is tempted to reach past
/// [ResolvePriceForVariantUseCase.call]/[ResolvePriceForVariantUseCase.callForProduct].
final class _PricingContext {
  const _PricingContext({
    required this.applicablePriceLists,
    required this.items,
  });

  final List<PriceList> applicablePriceLists;
  final List<PriceListItem> items;
}
