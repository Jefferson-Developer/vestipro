// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent every other Orders use case already follows.
import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../pricing/domain/usecases/resolve_price_for_variant_use_case.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/repositories/product_variant_repository.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../../products/domain/value_objects/product_variant_status.dart';
import '../entities/order.dart';
import '../entities/order_duplication_item_issue.dart';
import '../entities/order_duplication_price_change.dart';
import '../entities/order_duplication_result.dart';
import '../entities/order_item.dart';
import '../repositories/order_draft_repository.dart';
import 'add_items_to_order_draft_use_case.dart';
import 'get_order_by_id_use_case.dart';
import 'start_order_draft_for_customer_use_case.dart';

/// "Repetir pedido" (TASK-104): creates a brand new `Order` draft prefilled
/// with [sourceOrderId]'s own cliente and itens (produto + variante +
/// quantidade), always revalidating price and availability instead of ever
/// copying a possibly stale [OrderItem.unitPrice]/estoque as if it were
/// still valid (`tasks.md`'s own rule for this task).
///
/// Deliberately composes the very same building blocks every other EPIC-13
/// task already established instead of reimplementing any of them:
/// [GetOrderByIdUseCase] (RBAC-gated read of the source order, TASK-104),
/// [StartOrderDraftForCustomerUseCase] (the one and only draft-creation
/// entry point, TASK-096 — this is what guarantees the new draft always
/// starts in [OrderStatus.draft] with *current* branch/tabela de preço/
/// condição de pagamento defaults, never the source order's own, possibly
/// outdated ones) and [AddItemsToOrderDraftUseCase] (TASK-097's item
/// persistence, reused so the merge/subtotal rules
/// `OrderItemEditor` already encodes are never duplicated here).
///
/// Per item, revalidates:
/// 1. The variant still exists and is
///    [ProductVariantStatus.active] (`ProductVariantRepository.getById`) —
///    otherwise [OrderDuplicationItemIssueType.discontinued].
/// 2. It is currently sellable (`GetVariantAvailabilityUseCase`) —
///    otherwise [OrderDuplicationItemIssueType.unavailable]. A quantity
///    that exceeds what is actually in stock is *not* checked here: that is
///    `OrderSubmissionValidator`'s own concern (TASK-100), re-run the moment
///    the seller tries to submit the new draft — this use case only ever
///    excludes an item nobody may sell at all right now.
/// 3. Its current price (`ResolvePriceForVariantUseCase`, TASK-088) —
///    missing entirely becomes
///    [OrderDuplicationItemIssueType.priceUnavailable]; a price that simply
///    changed from the source order's own is still carried over (using the
///    *new* price) and reported as an [OrderDuplicationPriceChange] instead.
// Deliberately not `final class`: `OrderDuplicationCubit`'s own tests fake
// this class outright, same precedent every other composing use case in
// this feature already sets.
@injectable
class DuplicateOrderUseCase {
  const DuplicateOrderUseCase(
    this._getOrderById,
    this._startOrderDraftForCustomer,
    this._orderDraftRepository,
    this._addItemsToOrderDraft,
    this._productVariantRepository,
    this._getVariantAvailability,
    this._resolvePriceForVariant,
  );

  final GetOrderByIdUseCase _getOrderById;
  final StartOrderDraftForCustomerUseCase _startOrderDraftForCustomer;
  final OrderDraftRepository _orderDraftRepository;
  final AddItemsToOrderDraftUseCase _addItemsToOrderDraft;
  final ProductVariantRepository _productVariantRepository;
  final GetVariantAvailabilityUseCase _getVariantAvailability;
  final ResolvePriceForVariantUseCase _resolvePriceForVariant;

  final Uuid _uuid = const Uuid();

  Future<AppResult<OrderDuplicationResult>> call({
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String sourceOrderId,
    required String newDraftId,
    DateTime? now,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedSellerId = sellerId.trim();
    final trimmedSourceOrderId = sourceOrderId.trim();
    final trimmedNewDraftId = newDraftId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedSellerId.isEmpty) {
      fieldErrors['sellerId'] = 'SellerId is required.';
    }
    if (trimmedSourceOrderId.isEmpty) {
      fieldErrors['sourceOrderId'] = 'SourceOrderId is required.';
    }
    if (trimmedNewDraftId.isEmpty) {
      fieldErrors['newDraftId'] = 'NewDraftId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<OrderDuplicationResult>(
        ValidationFailure(
          'Invalid order duplication payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_order_duplication_payload',
        ),
      );
    }

    final sourceResult = await _getOrderById(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      userId: trimmedSellerId,
      orderId: trimmedSourceOrderId,
    );
    if (sourceResult case AppFailure<Order>(failure: final failure)) {
      return AppFailure<OrderDuplicationResult>(failure);
    }
    final source = (sourceResult as AppSuccess<Order>).value;
    if (source.items.isEmpty) {
      return const AppFailure<OrderDuplicationResult>(
        ValidationFailure(
          'Source order has no items to duplicate.',
          code: 'order_duplication_source_has_no_items',
        ),
      );
    }

    final draftResult = await _startOrderDraftForCustomer(
      id: trimmedNewDraftId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      sellerId: trimmedSellerId,
      customerId: source.customerId,
      now: now,
    );
    if (draftResult case AppFailure<Order>(failure: final failure)) {
      return AppFailure<OrderDuplicationResult>(failure);
    }
    final draft = (draftResult as AppSuccess<Order>).value;

    // Purely informative reference back to the source order — never the
    // source's own status/statusHistory, `tasks.md`'s own rule.
    final resolvedNow = (now ?? DateTime.now()).toUtc();
    final tagged = draft.copyWith(
      duplicatedFromOrderId: source.id,
      duplicatedFromOrderNumber: source.orderNumber,
      updatedAt: resolvedNow,
      version: draft.version + 1,
    );
    final tagResult = await _orderDraftRepository.saveDraft(order: tagged);
    if (tagResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<OrderDuplicationResult>(failure);
    }

    final priceChanges = <OrderDuplicationPriceChange>[];
    final issues = <OrderDuplicationItemIssue>[];
    final itemsToAdd = <OrderItem>[];

    for (final item in source.items) {
      final variantResult = await _productVariantRepository.getById(
        organizationId: trimmedOrganizationId,
        id: item.variantId,
      );
      final ProductVariant? variant = switch (variantResult) {
        AppSuccess<ProductVariant>(value: final value) => value,
        AppFailure<ProductVariant>() => null,
      };
      if (variant == null || variant.status != ProductVariantStatus.active) {
        issues.add(
          OrderDuplicationItemIssue(
            productId: item.productId,
            variantId: item.variantId,
            type: OrderDuplicationItemIssueType.discontinued,
            requestedQuantity: item.quantity,
          ),
        );
        continue;
      }

      final availabilityResult = await _getVariantAvailability(
        organizationId: trimmedOrganizationId,
        variantIds: <String>[item.variantId],
      );
      final acceptsQuantity = switch (availabilityResult) {
        AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot) =>
          snapshot.forVariant(item.variantId)?.acceptsQuantity ?? false,
        AppFailure<VariantAvailabilitySnapshot>() => false,
      };
      if (!acceptsQuantity) {
        issues.add(
          OrderDuplicationItemIssue(
            productId: item.productId,
            variantId: item.variantId,
            type: OrderDuplicationItemIssueType.unavailable,
            requestedQuantity: item.quantity,
          ),
        );
        continue;
      }

      final priceResult = await _resolvePriceForVariant(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        productId: item.productId,
        variantId: item.variantId,
      );
      final resolvedPrice = switch (priceResult) {
        AppSuccess<ResolvedVariantPrice>(value: final value) => value,
        AppFailure<ResolvedVariantPrice>() => null,
      };
      if (resolvedPrice == null || !resolvedPrice.hasPrice) {
        issues.add(
          OrderDuplicationItemIssue(
            productId: item.productId,
            variantId: item.variantId,
            type: OrderDuplicationItemIssueType.priceUnavailable,
            requestedQuantity: item.quantity,
          ),
        );
        continue;
      }

      final newPrice = resolvedPrice.price!;
      if (newPrice != item.unitPrice) {
        priceChanges.add(
          OrderDuplicationPriceChange(
            productId: item.productId,
            variantId: item.variantId,
            previousUnitPrice: item.unitPrice,
            newUnitPrice: newPrice,
          ),
        );
      }

      itemsToAdd.add(
        OrderItem(
          id: _uuid.v4(),
          variantId: item.variantId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: newPrice,
          subtotal: item.quantity * newPrice,
        ),
      );
    }

    var finalDraft = tagged;
    if (itemsToAdd.isNotEmpty) {
      final addResult = await _addItemsToOrderDraft(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        draftId: tagged.id,
        items: itemsToAdd,
      );
      if (addResult case AppFailure<Order>(failure: final failure)) {
        return AppFailure<OrderDuplicationResult>(failure);
      }
      finalDraft = (addResult as AppSuccess<Order>).value;
    }

    return AppSuccess<OrderDuplicationResult>(
      OrderDuplicationResult(
        draft: finalDraft,
        sourceOrderId: source.id,
        sourceOrderNumber: source.orderNumber,
        priceChanges: List.unmodifiable(priceChanges),
        issues: List.unmodifiable(issues),
      ),
    );
  }
}
