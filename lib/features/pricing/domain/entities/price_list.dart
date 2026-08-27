import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/price_list_scope_type.dart';
import '../value_objects/price_list_status.dart';
import '../value_objects/price_list_sync_status.dart';

part 'price_list.freezed.dart';

/// A Price List / tabela de preço (EPIC-11, TASK-083): the foundation every
/// other pricing concept (price per product/variant, payment terms,
/// discount policy, promotional campaign and the server-side pricing
/// engine) attaches to.
///
/// Multiple Price Lists may be simultaneously [PriceListStatus.active] for
/// the same [organizationId]/[companyId] — e.g. one per sales channel or
/// customer segment (see [scope]/[scopeValue]). [priority] is the
/// tie-breaker `ResolveApplicablePriceListsUseCase` uses when more than one
/// applies to the same customer/order at once: a higher [priority] wins.
///
/// [currency] is immutable once a Price List exists: nothing in this
/// codebase (`CreatePriceListUseCase`, Firestore Security Rules) ever
/// allows changing it after creation — changing the currency of a table
/// already used by an order always means creating a new Price List, never
/// editing the existing one (TASK-083 business rule).
///
/// The tenant fields [organizationId] and [companyId] are immutable after
/// creation and must be resolved from the authenticated session/active
/// organization context, never from a form field — same contract every
/// other tenant-scoped entity in this codebase (`Customer`, `Product`)
/// already follows.
@freezed
abstract class PriceList with _$PriceList {
  const PriceList._();

  const factory PriceList({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required String currency,
    required DateTime validFrom,
    DateTime? validTo,
    required PriceListStatus status,
    required PriceListScopeType scope,
    String? scopeValue,
    @Default(0) int priority,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    required int version,
    required PriceListSyncStatus syncStatus,
  }) = _PriceList;

  /// Whether [instant] falls inside this Price List's own [validFrom]/
  /// [validTo] window — independent of [status], see class docs. A table
  /// with no [validTo] never expires by date alone.
  bool isWithinValidityWindow(DateTime instant) {
    final normalized = instant.toUtc();
    if (normalized.isBefore(validFrom.toUtc())) return false;
    final effectiveValidTo = validTo;
    if (effectiveValidTo != null &&
        normalized.isAfter(effectiveValidTo.toUtc())) {
      return false;
    }
    return true;
  }

  /// Whether this Price List can be returned as applicable to any
  /// customer/order at [instant]: not soft-deleted, flagged
  /// [PriceListStatus.active] AND inside [isWithinValidityWindow] — a table
  /// out of its vigency period is never applicable, even if [status] was
  /// never advanced to [PriceListStatus.expired] (TASK-083 business rule).
  bool isApplicableAt(DateTime instant) {
    return deletedAt == null &&
        status == PriceListStatus.active &&
        isWithinValidityWindow(instant);
  }

  /// Whether this Price List's [scope]/[scopeValue] matches a customer
  /// described by [customerChannel]/[customerSegment].
  bool matchesCustomerContext({
    String? customerChannel,
    String? customerSegment,
  }) {
    return switch (scope) {
      PriceListScopeType.company => true,
      PriceListScopeType.channel =>
        scopeValue != null && scopeValue == customerChannel,
      PriceListScopeType.segment =>
        scopeValue != null && scopeValue == customerSegment,
    };
  }
}
