import '../value_objects/shipment_status.dart';
import 'shipment_package.dart';

/// A romaneio/expedição de um pedido (TASK-214, EPIC-32) — always vinculado a
/// um pedido faturado ([orderId]), com volumes/itens congelados no momento da
/// criação ([packages]) e um histórico completo de `TrackingEvent`s (lido à
/// parte via `FulfillmentRepository.watchTrackingEvents`).
///
/// Exclusively written by `createShipment`/`registerTrackingEvent`/
/// `handleShipmentTrackingWebhook` (Cloud Functions) — the UI never mutates
/// one directly (`AGENTS.md`: UI nunca acessa Firestore diretamente); this
/// entity is only ever read back through
/// [FulfillmentRepository.watchShipmentsForOrder].
final class Shipment {
  const Shipment({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    this.carrierName,
    this.carrierTrackingCode,
    required this.status,
    required this.hasOpenIssue,
    required this.packages,
    required this.deliveredQuantities,
    this.estimatedDeliveryDate,
    this.shippedAt,
    this.deliveredAt,
    this.lastEventAt,
    required this.createdAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String? carrierName;
  final String? carrierTrackingCode;
  final ShipmentStatus status;
  final bool hasOpenIssue;
  final List<ShipmentPackage> packages;

  /// Cumulative quantity actually confirmed delivered so far, keyed by
  /// `orderItemId` — never trusted from a single event's own label, always
  /// the server's own accumulated ledger (`resolveDeliveryStatus`).
  final Map<String, int> deliveredQuantities;
  final DateTime? estimatedDeliveryDate;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? lastEventAt;
  final DateTime createdAt;

  int get totalQuantity =>
      packages.fold(0, (sum, package) => sum + package.totalQuantity);

  int get totalDeliveredQuantity =>
      deliveredQuantities.values.fold(0, (sum, quantity) => sum + quantity);

  bool get isFullyDelivered =>
      status == ShipmentStatus.delivered && totalQuantity > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shipment &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.companyId == companyId &&
          other.orderId == orderId &&
          other.orderNumber == orderNumber &&
          other.customerId == customerId &&
          other.sellerId == sellerId &&
          other.carrierName == carrierName &&
          other.carrierTrackingCode == carrierTrackingCode &&
          other.status == status &&
          other.hasOpenIssue == hasOpenIssue &&
          _listEquals(other.packages, packages) &&
          _mapEquals(other.deliveredQuantities, deliveredQuantities) &&
          other.estimatedDeliveryDate == estimatedDeliveryDate &&
          other.shippedAt == shippedAt &&
          other.deliveredAt == deliveredAt &&
          other.lastEventAt == lastEventAt &&
          other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(
    Object.hash(
      id,
      organizationId,
      companyId,
      orderId,
      orderNumber,
      customerId,
      sellerId,
      carrierName,
      carrierTrackingCode,
      status,
    ),
    hasOpenIssue,
    Object.hashAll(packages),
    Object.hashAllUnordered(
      deliveredQuantities.entries.map((e) => '${e.key}:${e.value}'),
    ),
    estimatedDeliveryDate,
    shippedAt,
    deliveredAt,
    lastEventAt,
    createdAt,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
