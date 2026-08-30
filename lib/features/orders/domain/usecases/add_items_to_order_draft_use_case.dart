// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../repositories/order_draft_repository.dart';
import '../services/order_item_editor.dart';

/// Adds [items] (already resolved against the pricing engine and the
/// variant/size selection the seller made in the catalog — TASK-097) to the
/// `Order` draft [draftId], fully offline.
///
/// Unlike `OrderDraftBloc`'s own quantity/removal handlers — which edit the
/// `Order` already held in that bloc's in-memory state — this use case is
/// the entry point for the catalog picking flow, a *different* route/bloc
/// instance than the one showing the draft summary: it reloads the draft
/// fresh from [OrderDraftRepository], merges [items] via [OrderItemEditor]
/// and persists the result, so the seller can add products from the catalog
/// and come back to the draft screen (which reloads via
/// `OrderDraftStarted(draftId: ...)`) and see them there — no shared
/// in-memory bloc state required across that navigation.
@injectable
class AddItemsToOrderDraftUseCase {
  const AddItemsToOrderDraftUseCase(this._repository);

  final OrderDraftRepository _repository;

  Future<AppResult<Order>> call({
    required String organizationId,
    required String companyId,
    required String draftId,
    required List<OrderItem> items,
  }) async {
    final fieldErrors = <String, String>{};
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedDraftId = draftId.trim();
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedDraftId.isEmpty) {
      fieldErrors['draftId'] = 'DraftId is required.';
    }
    if (items.isEmpty) {
      fieldErrors['items'] = 'At least one item is required.';
    }
    for (final item in items) {
      if (item.variantId.trim().isEmpty || item.productId.trim().isEmpty) {
        fieldErrors['items'] = 'Every item must carry a variant and product.';
      }
      if (item.quantity <= 0) {
        fieldErrors['items'] = 'Every item quantity must be greater than zero.';
      }
      if (item.unitPrice < 0) {
        fieldErrors['items'] = 'Every item unit price must not be negative.';
      }
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Order>(
        ValidationFailure(
          'Invalid order draft item addition request.',
          code: 'invalid_add_order_draft_items_request',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final draftResult = await _repository.getDraftById(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      id: trimmedDraftId,
    );
    if (draftResult case AppFailure<Order?>(failure: final failure)) {
      return AppFailure<Order>(failure);
    }
    final order = (draftResult as AppSuccess<Order?>).value;
    if (order == null) {
      return AppFailure<Order>(
        const NotFoundFailure(
          'Order draft not found.',
          code: 'order_draft_not_found',
        ),
      );
    }

    final updated = order.copyWith(
      items: OrderItemEditor.withAddedItems(order.items, items),
      updatedAt: DateTime.now().toUtc(),
      version: order.version + 1,
    );

    final saveResult = await _repository.saveDraft(order: updated);
    return switch (saveResult) {
      AppSuccess<void>() => AppSuccess<Order>(updated),
      AppFailure<void>(failure: final failure) => AppFailure<Order>(failure),
    };
  }
}
