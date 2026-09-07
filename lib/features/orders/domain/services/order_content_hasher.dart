import 'dart:convert';

import 'package:crypto/crypto.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent
// `StartOrderDraftForCustomerUseCase` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../entities/order.dart';
import '../entities/order_address.dart';
import '../entities/order_item.dart';

/// Computes a deterministic SHA-256 hash of an `Order`'s own commercial
/// content (EPIC-13, TASK-180) — the evidence `OrderSignature.contentHash`
/// anchors a signature to "this exact pedido, at this exact content", per
/// `tasks.md`'s own "hash do conteúdo do pedido no momento da assinatura"
/// requirement.
///
/// Pure Dart, no Flutter/Firebase dependency (same "domain stays framework-
/// free" rule every other domain service in this codebase already follows)
/// — deliberately re-implemented in TypeScript by the `signOrder` Cloud
/// Function (`functions/src/orders/sign-order.ts`, `buildOrderContentHash`)
/// so the server can independently recompute the very same hash against
/// Firestore's own current order document instead of ever trusting the
/// client's own echoed value; the two implementations are kept in sync
/// manually — same already-accepted risk `firestore.rules`'s own
/// `roleHasCapability` mirror documents for `RolePermissionMatrix`.
///
/// Only the fields that actually define "what was agreed to" are hashed —
/// audit-only fields (`status`, `statusHistory`, `approvedBy`, `syncStatus`,
/// ...) are deliberately excluded: a pedido's own status can legitimately
/// keep advancing (`submitted` → `approved` → `invoiced` → ...) after it is
/// signed without that ever being "the content changed since the
/// signature" — only its commercial substance (customer, itens, valores,
/// condições, endereços) matters here.
@lazySingleton
final class OrderContentHasher {
  const OrderContentHasher();

  /// The signable content's canonical JSON — exposed only so a caller that
  /// already needs the raw payload (e.g. a debugging/audit screen) does not
  /// have to reimplement [_canonicalPayload]; [hash] is what every real
  /// caller (`CaptureOrderSignatureUseCase`) actually wants.
  String canonicalPayload(Order order) => jsonEncode(_canonicalPayload(order));

  /// Hex-encoded SHA-256 of [canonicalPayload].
  String hash(Order order) {
    final bytes = utf8.encode(canonicalPayload(order));
    return sha256.convert(bytes).toString();
  }

  Map<String, Object?> _canonicalPayload(Order order) {
    return <String, Object?>{
      'id': order.id,
      'organizationId': order.organizationId,
      'companyId': order.companyId,
      'branchId': order.branchId,
      'customerId': order.customerId,
      'sellerId': order.sellerId,
      'orderNumber': order.orderNumber,
      'deliveryAddress': _addressPayload(order.deliveryAddress),
      'billingAddress': _addressPayload(order.billingAddress),
      'priceListId': order.priceListId,
      'currency': order.currency,
      'paymentTermId': order.paymentTermId,
      'carrierId': order.carrierId,
      'items': order.items.map(_itemPayload).toList(growable: false),
      'discountAmount': _money(order.discountAmount),
      'surchargeAmount': _money(order.surchargeAmount),
      'shippingAmount': _money(order.shippingAmount),
      'taxAmount': _nullableMoney(order.taxAmount),
      'notes': order.notes,
    };
  }

  Map<String, Object?> _addressPayload(OrderAddress address) {
    return <String, Object?>{
      'street': address.street,
      'number': address.number,
      'complement': address.complement,
      'district': address.district,
      'city': address.city,
      'state': address.state,
      'zipCode': address.zipCode,
      'country': address.country,
    };
  }

  Map<String, Object?> _itemPayload(OrderItem item) {
    return <String, Object?>{
      'id': item.id,
      'variantId': item.variantId,
      'productId': item.productId,
      'quantity': item.quantity,
      'unitPrice': _money(item.unitPrice),
      'discountAmount': _money(item.discountAmount),
      'surchargeAmount': _money(item.surchargeAmount),
      'subtotal': _money(item.subtotal),
    };
  }

  /// Every monetary `double` is hashed as a fixed-2-decimal *string*
  /// (e.g. `"120.00"`), never as a raw JSON number: Dart's `jsonEncode` and
  /// the `signOrder` Cloud Function's own `JSON.stringify` render a whole
  /// double differently (`"120.0"` in Dart vs `"120"` in JavaScript/
  /// TypeScript, which has no separate integer/double numeric type) — a
  /// mismatch that would make the client- and server-computed hashes of the
  /// exact same order content disagree purely because of which language
  /// happened to serialize a whole number. Formatting to a fixed-precision
  /// string first sidesteps that entirely: both implementations hash the
  /// exact same characters.
  String _money(double value) => value.toStringAsFixed(2);

  String? _nullableMoney(double? value) => value == null ? null : _money(value);
}
