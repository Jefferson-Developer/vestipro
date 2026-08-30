import 'package:collection/collection.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/customers.dart';
import '../entities/order.dart';
import '../entities/order_address.dart';
import '../entities/order_draft_defaults.dart';
import '../entities/order_status_history_entry.dart';
import '../repositories/order_draft_repository.dart';
import '../value_objects/order_status.dart';
import '../value_objects/order_sync_status.dart';
import 'ensure_customer_in_seller_portfolio_use_case.dart';
import 'resolve_order_draft_defaults_use_case.dart';

/// Starts (and immediately persists, 100% offline) a new `Order` draft for
/// one customer of [sellerId]'s carteira (EPIC-13, TASK-096).
///
/// Composes every business rule the task requires instead of letting the
/// BLoC/UI apply any of them ad hoc:
/// 1. [EnsureCustomerInSellerPortfolioUseCase] — the customer must belong to
///    the seller's carteira (or the seller must have explicit permission).
/// 2. [GetCustomerByIdUseCase] — loads the real `Customer`, never trusting a
///    client-supplied snapshot of it.
/// 3. [ResolveOrderDraftDefaultsUseCase] — pre-fills unidade/tabela de
///    preço/condição de pagamento from the rules already vigent for this
///    customer/company.
/// 4. Copies the customer's primary shipping/billing `CustomerAddress` into
///    the order-owned [OrderAddress] snapshot (`OrderAddress`'s own docs:
///    "which entry point copies a CustomerAddress into an OrderAddress ...
///    is a later EPIC-13 task's concern" — this is that entry point).
/// 5. Persists the resulting `Order` (status [OrderStatus.draft],
///    [OrderSyncStatus.pending]) through [OrderDraftRepository] — no network
///    call happens anywhere in this call graph.
///
/// Deliberately not `final`, mirroring `ListCustomerPortfolioUseCase`'s own
/// precedent for a thin use case a BLoC calls directly: `OrderDraftBloc`'s
/// own tests fake this class outright (`implements
/// StartOrderDraftForCustomerUseCase`) instead of composing every one of its
/// own dependencies with fake repositories every time — those are already
/// covered by this class's own unit tests.
@injectable
class StartOrderDraftForCustomerUseCase {
  const StartOrderDraftForCustomerUseCase(
    this._ensureCustomerInSellerPortfolio,
    this._getCustomerById,
    this._resolveDefaults,
    this._orderDraftRepository,
  );

  final EnsureCustomerInSellerPortfolioUseCase _ensureCustomerInSellerPortfolio;
  final GetCustomerByIdUseCase _getCustomerById;
  final ResolveOrderDraftDefaultsUseCase _resolveDefaults;
  final OrderDraftRepository _orderDraftRepository;

  Future<AppResult<Order>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String customerId,
    DateTime? now,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedSellerId = sellerId.trim();
    final trimmedCustomerId = customerId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedSellerId.isEmpty) {
      fieldErrors['sellerId'] = 'SellerId is required.';
    }
    if (trimmedCustomerId.isEmpty) {
      fieldErrors['customerId'] = 'CustomerId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Order>(
        ValidationFailure(
          'Invalid order draft start payload.',
          code: 'invalid_order_draft_start_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final accessResult = await _ensureCustomerInSellerPortfolio(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      userId: trimmedSellerId,
      customerId: trimmedCustomerId,
    );
    if (accessResult case AppFailure<bool>(failure: final failure)) {
      return AppFailure<Order>(failure);
    }
    final hasAccess = (accessResult as AppSuccess<bool>).value;
    if (!hasAccess) {
      return const AppFailure<Order>(
        PermissionFailure(
          'Customer is outside the seller\'s portfolio.',
          code: 'order_draft_customer_outside_portfolio',
        ),
      );
    }

    final customerResult = await _getCustomerById(
      organizationId: trimmedOrganizationId,
      id: trimmedCustomerId,
    );
    if (customerResult case AppFailure<Customer>(failure: final failure)) {
      return AppFailure<Order>(failure);
    }
    final customer = (customerResult as AppSuccess<Customer>).value;
    if (customer.companyId != trimmedCompanyId) {
      return const AppFailure<Order>(
        PermissionFailure(
          'Customer does not belong to the active company.',
          code: 'order_draft_customer_outside_company',
        ),
      );
    }

    final resolvedNow = (now ?? DateTime.now()).toUtc();
    final defaultsResult = await _resolveDefaults(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      customer: customer,
      now: resolvedNow,
    );
    if (defaultsResult case AppFailure<OrderDraftDefaults>(
      failure: final failure,
    )) {
      return AppFailure<Order>(failure);
    }
    final defaults = (defaultsResult as AppSuccess<OrderDraftDefaults>).value;

    final order = Order(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: customer.companyId,
      branchId: defaults.branch.id,
      customerId: customer.id,
      sellerId: trimmedSellerId,
      deliveryAddress: _resolveOrderAddress(
        customer.addresses,
        preferredType: CustomerAddressType.shipping,
      ),
      billingAddress: _resolveOrderAddress(
        customer.addresses,
        preferredType: CustomerAddressType.billing,
      ),
      priceListId: defaults.priceList.id,
      paymentTermId: defaults.paymentTerm.id,
      status: OrderStatus.draft,
      statusHistory: <OrderStatusHistoryEntry>[
        OrderStatusHistoryEntry(
          newStatus: OrderStatus.draft,
          changedAt: resolvedNow,
          actorId: trimmedSellerId,
        ),
      ],
      createdAt: resolvedNow,
      createdBy: trimmedSellerId,
      updatedAt: resolvedNow,
      updatedBy: trimmedSellerId,
      version: 1,
      syncStatus: OrderSyncStatus.pending,
    );

    final saveResult = await _orderDraftRepository.saveDraft(order: order);
    if (saveResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<Order>(failure);
    }

    return AppSuccess<Order>(order);
  }

  /// Best-effort copy of the customer's primary [preferredType] address into
  /// an order-owned [OrderAddress] snapshot. Falls back to any address of
  /// that type, then to the customer's primary address of any type, then to
  /// an empty (seller-editable later) [OrderAddress] — a customer with no
  /// registered address at all must never block starting a draft.
  OrderAddress _resolveOrderAddress(
    List<CustomerAddress> addresses, {
    required CustomerAddressType preferredType,
  }) {
    final ofPreferredType = addresses
        .where((address) => address.type == preferredType)
        .toList(growable: false);
    final selected =
        ofPreferredType.firstWhereOrNull((address) => address.isPrimary) ??
        ofPreferredType.firstOrNull ??
        addresses.firstWhereOrNull((address) => address.isPrimary) ??
        addresses.firstOrNull;

    if (selected == null) {
      return const OrderAddress(street: '', city: '', state: '', zipCode: '');
    }

    return OrderAddress(
      street: selected.street,
      number: selected.number,
      complement: selected.complement,
      district: selected.district,
      city: selected.city,
      state: selected.state,
      zipCode: selected.zipCode.digits,
      country: selected.country,
    );
  }
}
