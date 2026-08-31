// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_address.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status_history_entry.dart';
import '../../domain/value_objects/order_status.dart';
import '../../domain/value_objects/order_sync_status.dart';
import '../dtos/order_address_dto.dart';
import '../dtos/order_dto.dart';
import '../dtos/order_item_dto.dart';
import '../dtos/order_status_history_entry_dto.dart';

/// Maps [Order] to/from [OrderDto] (EPIC-13, TASK-095), the only place
/// enum<->string codes for `status`/`syncStatus` are decided, so no other
/// layer reimplements them.
@lazySingleton
final class OrderMapper {
  const OrderMapper();

  Order toEntity(OrderDto dto) {
    return Order(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      branchId: dto.branchId,
      customerId: dto.customerId,
      sellerId: dto.sellerId,
      orderNumber: dto.orderNumber,
      deliveryAddress: addressToEntity(dto.deliveryAddress),
      billingAddress: addressToEntity(dto.billingAddress),
      priceListId: dto.priceListId,
      paymentTermId: dto.paymentTermId,
      carrierId: dto.carrierId,
      collectionId: dto.collectionId,
      orderType: dto.orderType,
      items: dto.items.map(itemToEntity).toList(growable: false),
      discountAmount: dto.discountAmount,
      surchargeAmount: dto.surchargeAmount,
      shippingAmount: dto.shippingAmount,
      taxAmount: dto.taxAmount,
      notes: dto.notes,
      attachmentUrls: dto.attachmentUrls,
      status: statusToEntity(dto.status),
      statusHistory: dto.statusHistory
          .map(historyEntryToEntity)
          .toList(growable: false),
      approvedBy: dto.approvedBy,
      approvedAt: dto.approvedAt,
      rejectionReason: dto.rejectionReason,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  OrderDto toDto(Order entity) {
    return OrderDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      branchId: entity.branchId,
      customerId: entity.customerId,
      sellerId: entity.sellerId,
      orderNumber: entity.orderNumber,
      deliveryAddress: addressToDto(entity.deliveryAddress),
      billingAddress: addressToDto(entity.billingAddress),
      priceListId: entity.priceListId,
      paymentTermId: entity.paymentTermId,
      carrierId: entity.carrierId,
      collectionId: entity.collectionId,
      orderType: entity.orderType,
      items: entity.items.map(itemToDto).toList(growable: false),
      discountAmount: entity.discountAmount,
      surchargeAmount: entity.surchargeAmount,
      shippingAmount: entity.shippingAmount,
      taxAmount: entity.taxAmount,
      notes: entity.notes,
      attachmentUrls: entity.attachmentUrls,
      status: statusToDto(entity.status),
      statusHistory: entity.statusHistory
          .map(historyEntryToDto)
          .toList(growable: false),
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      rejectionReason: entity.rejectionReason,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  OrderAddress addressToEntity(OrderAddressDto dto) {
    return OrderAddress(
      street: dto.street,
      number: dto.number,
      complement: dto.complement,
      district: dto.district,
      city: dto.city,
      state: dto.state,
      zipCode: dto.zipCode,
      country: dto.country,
    );
  }

  OrderAddressDto addressToDto(OrderAddress address) {
    return OrderAddressDto(
      street: address.street,
      number: address.number,
      complement: address.complement,
      district: address.district,
      city: address.city,
      state: address.state,
      zipCode: address.zipCode,
      country: address.country,
    );
  }

  OrderItem itemToEntity(OrderItemDto dto) {
    return OrderItem(
      id: dto.id,
      variantId: dto.variantId,
      productId: dto.productId,
      quantity: dto.quantity,
      unitPrice: dto.unitPrice,
      discountAmount: dto.discountAmount,
      surchargeAmount: dto.surchargeAmount,
      subtotal: dto.subtotal,
    );
  }

  OrderItemDto itemToDto(OrderItem item) {
    return OrderItemDto(
      id: item.id,
      variantId: item.variantId,
      productId: item.productId,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountAmount: item.discountAmount,
      surchargeAmount: item.surchargeAmount,
      subtotal: item.subtotal,
    );
  }

  OrderStatusHistoryEntry historyEntryToEntity(OrderStatusHistoryEntryDto dto) {
    return OrderStatusHistoryEntry(
      previousStatus: dto.previousStatus == null
          ? null
          : statusToEntity(dto.previousStatus!),
      newStatus: statusToEntity(dto.newStatus),
      changedAt: dto.changedAt,
      actorId: dto.actorId,
      reason: dto.reason,
    );
  }

  OrderStatusHistoryEntryDto historyEntryToDto(OrderStatusHistoryEntry entry) {
    return OrderStatusHistoryEntryDto(
      previousStatus: entry.previousStatus == null
          ? null
          : statusToDto(entry.previousStatus!),
      newStatus: statusToDto(entry.newStatus),
      changedAt: entry.changedAt,
      actorId: entry.actorId,
      reason: entry.reason,
    );
  }

  OrderStatus statusToEntity(String raw) {
    return switch (raw) {
      'draft' => OrderStatus.draft,
      'pending_sync' => OrderStatus.pendingSync,
      'submitted' => OrderStatus.submitted,
      'under_review' => OrderStatus.underReview,
      'approved' => OrderStatus.approved,
      'rejected' => OrderStatus.rejected,
      'processing' => OrderStatus.processing,
      'invoiced' => OrderStatus.invoiced,
      'partially_invoiced' => OrderStatus.partiallyInvoiced,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => throw ValidationException(
        'Invalid order status "$raw".',
        code: 'invalid_order_status',
      ),
    };
  }

  String statusToDto(OrderStatus status) {
    return switch (status) {
      OrderStatus.draft => 'draft',
      OrderStatus.pendingSync => 'pending_sync',
      OrderStatus.submitted => 'submitted',
      OrderStatus.underReview => 'under_review',
      OrderStatus.approved => 'approved',
      OrderStatus.rejected => 'rejected',
      OrderStatus.processing => 'processing',
      OrderStatus.invoiced => 'invoiced',
      OrderStatus.partiallyInvoiced => 'partially_invoiced',
      OrderStatus.shipped => 'shipped',
      OrderStatus.delivered => 'delivered',
      OrderStatus.cancelled => 'cancelled',
    };
  }

  OrderSyncStatus syncStatusToEntity(String raw) {
    return switch (raw) {
      'pending' => OrderSyncStatus.pending,
      'syncing' => OrderSyncStatus.syncing,
      'synced' => OrderSyncStatus.synced,
      'failed' => OrderSyncStatus.failed,
      'conflict' => OrderSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid order syncStatus "$raw".',
        code: 'invalid_order_sync_status',
      ),
    };
  }

  String syncStatusToDto(OrderSyncStatus syncStatus) {
    return switch (syncStatus) {
      OrderSyncStatus.pending => 'pending',
      OrderSyncStatus.syncing => 'syncing',
      OrderSyncStatus.synced => 'synced',
      OrderSyncStatus.failed => 'failed',
      OrderSyncStatus.conflict => 'conflict',
    };
  }
}
