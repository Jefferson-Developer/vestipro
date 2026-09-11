import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/commercial_pack_pricing_policy_type.dart';
import '../value_objects/commercial_pack_status.dart';
import '../value_objects/commercial_pack_stock_policy_type.dart';
import '../value_objects/commercial_pack_sync_status.dart';
import '../value_objects/commercial_pack_type.dart';
import 'assortment_rule.dart';
import 'pack_component.dart';

part 'commercial_pack.freezed.dart';

/// A sellable kit, pack or sortimento (TASK-207, EPIC-32): a
/// vendor-configured grouping of [components] (and, optionally,
/// [assortmentRules]) sold as a single commercial unit for moda B2B.
///
/// [packCode] stays stable across every version of "the same" pack —
/// [id]/[version] change on every revision (see [ReviseCommercialPackUseCase]
/// docs), but [packCode] never does, so an order/report can always group
/// every version of one conceptual pack together. Mirrors the
/// `id`/`version` (but not `packCode`, new to this feature) precedent
/// `Product`/`ProductVariant`/`PriceList` already follow.
///
/// [pricingPolicyType] and its parameters ([fixedPrice],
/// [discountPercentage], [bonusComponentId]) — and [stockPolicyType] and its
/// own parameter ([dedicatedWarehouseId]) — are a **contract only** for the
/// pricing engine (TASK-088) and the order/inventory flow (EPIC-12/EPIC-13)
/// to apply: this entity never computes a final price nor reserves/debits
/// real stock by itself (TASK-207 business rule).
///
/// The tenant field [organizationId] is immutable after creation and must
/// be resolved from the authenticated session/active organization context,
/// never from a form field — same contract every other tenant-scoped entity
/// in this codebase (`Customer`, `Product`, `PriceList`) already follows.
/// [companyId] is optional: a pack scoped to every company of the
/// organization leaves it `null`, same nullable-company precedent
/// `ProductsTable`/`replaceProducts` already use for `Product`.
@freezed
abstract class CommercialPack with _$CommercialPack {
  const CommercialPack._();

  const factory CommercialPack({
    required String id,
    required String organizationId,
    String? companyId,
    required String packCode,
    required int version,
    required String name,
    String? description,
    required CommercialPackType packType,
    required CommercialPackStatus status,
    required CommercialPackPricingPolicyType pricingPolicyType,
    double? fixedPrice,
    double? discountPercentage,
    String? bonusComponentId,
    required CommercialPackStockPolicyType stockPolicyType,
    String? dedicatedWarehouseId,
    String? collectionId,
    String? campaignId,
    String? customerSegment,
    String? channel,
    required DateTime validFrom,
    DateTime? validTo,
    @Default(<PackComponent>[]) List<PackComponent> components,
    @Default(<AssortmentRule>[]) List<AssortmentRule> assortmentRules,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    String? supersededByPackId,
    required CommercialPackSyncStatus syncStatus,
  }) = _CommercialPack;

  /// Whether [instant] falls inside this pack's own [validFrom]/[validTo]
  /// window — independent of [status], same precedent
  /// `PriceList.isWithinValidityWindow` already sets. A pack with no
  /// [validTo] never expires by date alone.
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

  /// Whether this exact pack version can be sold to anyone at [instant]:
  /// not soft-deleted, flagged [CommercialPackStatus.active] AND inside
  /// [isWithinValidityWindow] — a pack out of its own vigency window is
  /// never sellable, even if [status] was never advanced to
  /// [CommercialPackStatus.expired] (same precedent
  /// `PriceList.isApplicableAt` already sets).
  bool isApplicableAt(DateTime instant) {
    return deletedAt == null &&
        status == CommercialPackStatus.active &&
        isWithinValidityWindow(instant);
  }

  /// Whether this pack's optional [customerSegment]/[channel] narrowing
  /// matches a customer described by [candidateSegment]/[candidateChannel].
  /// A `null` [customerSegment]/[channel] on this pack means "applies to
  /// every segment/channel" — unlike `PriceList.scope`, both dimensions can
  /// narrow independently and simultaneously here rather than being a
  /// single mutually-exclusive scope.
  bool matchesCustomerContext({
    String? candidateSegment,
    String? candidateChannel,
  }) {
    if (customerSegment != null && customerSegment != candidateSegment) {
      return false;
    }
    if (channel != null && channel != candidateChannel) {
      return false;
    }
    return true;
  }
}
