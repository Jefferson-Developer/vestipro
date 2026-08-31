import 'dart:convert';

import 'package:drift/drift.dart' show Value;
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_address.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status_history_entry.dart';
import 'order_mapper.dart';

/// Maps `Order` (and its embedded items/status history) to/from the Drift
/// rows backing its offline cache (`OrdersTable`, `OrderItemsTable`,
/// TASK-095).
///
/// Enum<->string conversions delegate to [OrderMapper] so this local store
/// does not reimplement the same `status`/`syncStatus` codes already used
/// for the remote-facing DTO — same precedent [CustomerLocalMapper]/
/// [PriceListLocalMapper] already follow. [OrderAddress]/[attachmentUrls]/
/// [statusHistory] have no dedicated relational shape locally (there is
/// nothing to query them by yet), so — same precedent as
/// `CustomersTable.tagsJson`/`customFieldsJson` — they are stored as encoded
/// JSON text columns on the parent row instead of being flattened out.
@lazySingleton
final class OrderLocalMapper {
  const OrderLocalMapper(this._mapper);

  final OrderMapper _mapper;

  OrdersTableCompanion toOrderRow(Order order) {
    return OrdersTableCompanion.insert(
      id: order.id,
      organizationId: order.organizationId,
      companyId: order.companyId,
      branchId: order.branchId,
      customerId: order.customerId,
      sellerId: order.sellerId,
      orderNumber: Value(order.orderNumber),
      deliveryAddressJson: jsonEncode(_addressToJson(order.deliveryAddress)),
      billingAddressJson: jsonEncode(_addressToJson(order.billingAddress)),
      priceListId: order.priceListId,
      paymentTermId: order.paymentTermId,
      carrierId: Value(order.carrierId),
      collectionId: Value(order.collectionId),
      orderType: Value(order.orderType),
      duplicatedFromOrderId: Value(order.duplicatedFromOrderId),
      duplicatedFromOrderNumber: Value(order.duplicatedFromOrderNumber),
      discountAmount: Value(order.discountAmount),
      surchargeAmount: Value(order.surchargeAmount),
      shippingAmount: Value(order.shippingAmount),
      taxAmount: Value(order.taxAmount),
      notes: Value(order.notes),
      attachmentUrlsJson: Value(
        order.attachmentUrls.isEmpty ? null : jsonEncode(order.attachmentUrls),
      ),
      status: _mapper.statusToDto(order.status),
      statusHistoryJson: Value(
        order.statusHistory.isEmpty
            ? null
            : jsonEncode(order.statusHistory.map(_historyEntryToJson).toList()),
      ),
      approvedBy: Value(order.approvedBy),
      approvedAt: Value(order.approvedAt?.toUtc()),
      rejectionReason: Value(order.rejectionReason),
      createdAt: order.createdAt.toUtc(),
      createdBy: order.createdBy,
      updatedAt: order.updatedAt.toUtc(),
      updatedBy: order.updatedBy,
      deletedAt: Value(order.deletedAt?.toUtc()),
      version: order.version,
      syncStatus: _mapper.syncStatusToDto(order.syncStatus),
    );
  }

  List<OrderItemsTableCompanion> toItemRows(Order order) {
    final items = order.items;
    return <OrderItemsTableCompanion>[
      for (var index = 0; index < items.length; index += 1)
        _toItemRow(order, items[index], position: index),
    ];
  }

  OrderItemsTableCompanion _toItemRow(
    Order order,
    OrderItem item, {
    required int position,
  }) {
    return OrderItemsTableCompanion.insert(
      id: item.id,
      orderId: order.id,
      organizationId: order.organizationId,
      companyId: order.companyId,
      variantId: item.variantId,
      productId: item.productId,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountAmount: Value(item.discountAmount),
      surchargeAmount: Value(item.surchargeAmount),
      subtotal: item.subtotal,
      position: Value(position),
    );
  }

  Order fromRow(OrderWithItemsRow row) {
    final orderRow = row.order;
    return Order(
      id: orderRow.id,
      organizationId: orderRow.organizationId,
      companyId: orderRow.companyId,
      branchId: orderRow.branchId,
      customerId: orderRow.customerId,
      sellerId: orderRow.sellerId,
      orderNumber: orderRow.orderNumber,
      deliveryAddress: _addressFromJson(orderRow.deliveryAddressJson),
      billingAddress: _addressFromJson(orderRow.billingAddressJson),
      priceListId: orderRow.priceListId,
      paymentTermId: orderRow.paymentTermId,
      carrierId: orderRow.carrierId,
      collectionId: orderRow.collectionId,
      orderType: orderRow.orderType,
      duplicatedFromOrderId: orderRow.duplicatedFromOrderId,
      duplicatedFromOrderNumber: orderRow.duplicatedFromOrderNumber,
      items: row.items.map(_itemFromRow).toList(growable: false),
      discountAmount: orderRow.discountAmount,
      surchargeAmount: orderRow.surchargeAmount,
      shippingAmount: orderRow.shippingAmount,
      taxAmount: orderRow.taxAmount,
      notes: orderRow.notes,
      attachmentUrls: _stringListFromJson(orderRow.attachmentUrlsJson),
      status: _mapper.statusToEntity(orderRow.status),
      statusHistory: _historyFromJson(orderRow.statusHistoryJson),
      approvedBy: orderRow.approvedBy,
      approvedAt: orderRow.approvedAt?.toUtc(),
      rejectionReason: orderRow.rejectionReason,
      createdAt: orderRow.createdAt.toUtc(),
      createdBy: orderRow.createdBy,
      updatedAt: orderRow.updatedAt.toUtc(),
      updatedBy: orderRow.updatedBy,
      deletedAt: orderRow.deletedAt?.toUtc(),
      version: orderRow.version,
      syncStatus: _mapper.syncStatusToEntity(orderRow.syncStatus),
    );
  }

  OrderItem _itemFromRow(OrderItemsTableData row) {
    return OrderItem(
      id: row.id,
      variantId: row.variantId,
      productId: row.productId,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      discountAmount: row.discountAmount,
      surchargeAmount: row.surchargeAmount,
      subtotal: row.subtotal,
    );
  }

  Map<String, Object?> _addressToJson(OrderAddress address) {
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

  OrderAddress _addressFromJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationException(
        'Invalid local order address payload.',
        code: 'invalid_order_local_payload',
      );
    }
    return OrderAddress(
      street: decoded['street'] as String,
      number: decoded['number'] as String?,
      complement: decoded['complement'] as String?,
      district: decoded['district'] as String?,
      city: decoded['city'] as String,
      state: decoded['state'] as String,
      zipCode: decoded['zipCode'] as String,
      country: decoded['country'] as String,
    );
  }

  Map<String, Object?> _historyEntryToJson(OrderStatusHistoryEntry entry) {
    return <String, Object?>{
      'previousStatus': entry.previousStatus == null
          ? null
          : _mapper.statusToDto(entry.previousStatus!),
      'newStatus': _mapper.statusToDto(entry.newStatus),
      'changedAt': entry.changedAt.toUtc().toIso8601String(),
      'actorId': entry.actorId,
      'reason': entry.reason,
    };
  }

  List<OrderStatusHistoryEntry> _historyFromJson(String? raw) {
    if (raw == null) return const <OrderStatusHistoryEntry>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local order status history payload.',
        code: 'invalid_order_local_payload',
      );
    }
    return decoded
        .map((rawEntry) {
          if (rawEntry is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local order status history entry payload.',
              code: 'invalid_order_local_payload',
            );
          }
          final previousStatus = rawEntry['previousStatus'] as String?;
          return OrderStatusHistoryEntry(
            previousStatus: previousStatus == null
                ? null
                : _mapper.statusToEntity(previousStatus),
            newStatus: _mapper.statusToEntity(rawEntry['newStatus'] as String),
            changedAt: DateTime.parse(rawEntry['changedAt'] as String).toUtc(),
            actorId: rawEntry['actorId'] as String,
            reason: rawEntry['reason'] as String?,
          );
        })
        .toList(growable: false);
  }

  List<String> _stringListFromJson(String? raw) {
    if (raw == null) return const <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic> || decoded.any((item) => item is! String)) {
      throw const ValidationException(
        'Invalid local order attachment urls payload.',
        code: 'invalid_order_local_payload',
      );
    }
    return List<String>.unmodifiable(decoded.cast<String>());
  }
}
