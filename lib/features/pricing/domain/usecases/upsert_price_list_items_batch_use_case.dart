import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/price_list_item.dart';
import '../repositories/price_list_item_repository.dart';

final class PriceListItemInput {
  const PriceListItemInput({
    required this.productId,
    required this.price,
    this.variantId,
  });

  final String productId;
  final String? variantId;
  final double price;
}

@injectable
final class UpsertPriceListItemsBatchUseCase {
  const UpsertPriceListItemsBatchUseCase(this._repository);

  final PriceListItemRepository _repository;

  Future<AppResult<List<PriceListItem>>> call({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required String updatedBy,
    required List<PriceListItemInput> items,
    bool confirmOverwrite = false,
    DateTime? now,
  }) async {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (priceListId.trim().isEmpty) {
      fieldErrors['priceListId'] = 'PriceListId is required.';
    }
    if (updatedBy.trim().isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (items.isEmpty) {
      fieldErrors['items'] = 'At least one price row is required.';
    }

    final normalizedItems = <PriceListItem>[];
    final seenIds = <String>{};
    for (final (index, item) in items.indexed) {
      final productId = item.productId.trim();
      final variantId = item.variantId?.trim();
      if (productId.isEmpty) {
        fieldErrors['items[$index].productId'] = 'ProductId is required.';
      }
      if (item.price.isNaN || item.price <= 0) {
        fieldErrors['items[$index].price'] = 'Price must be greater than zero.';
      }
      final id = PriceListItem.composeId(
        priceListId: priceListId.trim(),
        productId: productId,
        variantId: variantId,
      );
      if (!seenIds.add(id)) {
        fieldErrors['items[$index]'] =
            'Duplicated product/variant price row in the same batch.';
      }
      normalizedItems.add(
        PriceListItem(
          id: id,
          organizationId: organizationId.trim(),
          companyId: companyId.trim(),
          priceListId: priceListId.trim(),
          productId: productId,
          variantId: variantId == null || variantId.isEmpty ? null : variantId,
          price: double.parse(item.price.toStringAsFixed(2)),
          updatedAt: (now ?? DateTime.now()).toUtc(),
          updatedBy: updatedBy.trim(),
          syncStatus: 'pending',
        ),
      );
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<PriceListItem>>(
        ValidationFailure(
          'Invalid price list item batch payload.',
          code: 'invalid_price_list_item_batch_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    return _repository.upsertBatch(
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
      priceListId: priceListId.trim(),
      items: normalizedItems,
      confirmOverwrite: confirmOverwrite,
    );
  }
}
