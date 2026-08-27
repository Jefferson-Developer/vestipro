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
    if (variantId.trim().isEmpty) {
      fieldErrors['variantId'] = 'VariantId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ResolvedVariantPrice>(
        ValidationFailure(
          'Invalid variant price resolution request.',
          code: 'invalid_resolve_variant_price_request',
          fieldErrors: fieldErrors,
        ),
      );
    }

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
      return AppFailure<ResolvedVariantPrice>(failure);
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
      return AppFailure<ResolvedVariantPrice>(failure);
    }
    final items = (itemsResult as AppSuccess<List<PriceListItem>>).value;

    for (final priceList in applicablePriceLists) {
      final itemForList = items.where(
        (item) => item.priceListId == priceList.id,
      );
      PriceListItem? variantSpecific;
      PriceListItem? productFallback;
      for (final item in itemForList) {
        if (item.variantId == variantId.trim()) {
          variantSpecific = item;
          break;
        }
        if (item.variantId == null) {
          productFallback = item;
        }
      }
      if (variantSpecific != null) {
        return AppSuccess<ResolvedVariantPrice>(
          ResolvedVariantPrice(
            origin: PriceResolutionOrigin.variant,
            applicablePriceLists: List.unmodifiable(applicablePriceLists),
            priceList: priceList,
            matchedItem: variantSpecific,
          ),
        );
      }
      if (productFallback != null) {
        return AppSuccess<ResolvedVariantPrice>(
          ResolvedVariantPrice(
            origin: PriceResolutionOrigin.product,
            applicablePriceLists: List.unmodifiable(applicablePriceLists),
            priceList: priceList,
            matchedItem: productFallback,
          ),
        );
      }
    }

    return AppSuccess<ResolvedVariantPrice>(
      ResolvedVariantPrice(
        origin: PriceResolutionOrigin.missing,
        applicablePriceLists: List.unmodifiable(applicablePriceLists),
      ),
    );
  }
}
