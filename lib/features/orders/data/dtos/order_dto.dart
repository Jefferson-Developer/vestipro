import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import 'order_address_dto.dart';
import 'order_item_dto.dart';
import 'order_status_history_entry_dto.dart';

/// Firestore document shape for an Order scoped by organization (TASK-095),
/// modeling `organizations/{organizationId}/orders/{orderId}`.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] and [companyId] remain duplicated in the
/// payload so Security Rules and queries can validate tenant scope without
/// trusting a client value — same contract [CustomerDto]/[PriceListDto]
/// already follow.
final class OrderDto {
  const OrderDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.branchId,
    required this.customerId,
    required this.sellerId,
    this.orderNumber,
    required this.deliveryAddress,
    required this.billingAddress,
    required this.priceListId,
    required this.paymentTermId,
    this.carrierId,
    this.collectionId,
    this.orderType,
    this.items = const <OrderItemDto>[],
    required this.discountAmount,
    required this.surchargeAmount,
    required this.shippingAmount,
    this.taxAmount,
    this.notes,
    this.attachmentUrls = const <String>[],
    required this.status,
    this.statusHistory = const <OrderStatusHistoryEntryDto>[],
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final branchId = json['branchId'];
    final customerId = json['customerId'];
    final sellerId = json['sellerId'];
    final orderNumber = json['orderNumber'];
    final deliveryAddress = json['deliveryAddress'];
    final billingAddress = json['billingAddress'];
    final priceListId = json['priceListId'];
    final paymentTermId = json['paymentTermId'];
    final carrierId = json['carrierId'];
    final collectionId = json['collectionId'];
    final orderType = json['orderType'];
    final rawItems = json['items'];
    final discountAmount = json['discountAmount'];
    final surchargeAmount = json['surchargeAmount'];
    final shippingAmount = json['shippingAmount'];
    final taxAmount = json['taxAmount'];
    final notes = json['notes'];
    final rawAttachmentUrls = json['attachmentUrls'];
    final status = json['status'];
    final rawStatusHistory = json['statusHistory'];
    final approvedBy = json['approvedBy'];
    final approvedAt = json['approvedAt'];
    final rejectionReason = json['rejectionReason'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        companyId is! String ||
        branchId is! String ||
        customerId is! String ||
        sellerId is! String ||
        deliveryAddress is! Map<String, dynamic> ||
        billingAddress is! Map<String, dynamic> ||
        priceListId is! String ||
        paymentTermId is! String ||
        (orderNumber != null && orderNumber is! String) ||
        (carrierId != null && carrierId is! String) ||
        (collectionId != null && collectionId is! String) ||
        (orderType != null && orderType is! String) ||
        discountAmount is! num ||
        surchargeAmount is! num ||
        shippingAmount is! num ||
        (taxAmount != null && taxAmount is! num) ||
        (notes != null && notes is! String) ||
        status is! String ||
        (approvedBy != null && approvedBy is! String) ||
        (approvedAt != null && approvedAt is! Timestamp) ||
        (rejectionReason != null && rejectionReason is! String) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid order payload.',
        code: 'invalid_order_payload',
      );
    }

    return OrderDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      branchId: branchId,
      customerId: customerId,
      sellerId: sellerId,
      orderNumber: orderNumber as String?,
      deliveryAddress: OrderAddressDto.fromJson(deliveryAddress),
      billingAddress: OrderAddressDto.fromJson(billingAddress),
      priceListId: priceListId,
      paymentTermId: paymentTermId,
      carrierId: carrierId as String?,
      collectionId: collectionId as String?,
      orderType: orderType as String?,
      items: _itemDtosFromJson(rawItems),
      discountAmount: discountAmount.toDouble(),
      surchargeAmount: surchargeAmount.toDouble(),
      shippingAmount: shippingAmount.toDouble(),
      taxAmount: (taxAmount as num?)?.toDouble(),
      notes: notes as String?,
      attachmentUrls: _attachmentUrlsFromJson(rawAttachmentUrls),
      status: status,
      statusHistory: _statusHistoryDtosFromJson(rawStatusHistory),
      approvedBy: approvedBy as String?,
      approvedAt: (approvedAt as Timestamp?)?.toDate(),
      rejectionReason: rejectionReason as String?,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String branchId;
  final String customerId;
  final String sellerId;
  final String? orderNumber;
  final OrderAddressDto deliveryAddress;
  final OrderAddressDto billingAddress;
  final String priceListId;
  final String paymentTermId;
  final String? carrierId;
  final String? collectionId;
  final String? orderType;
  final List<OrderItemDto> items;
  final double discountAmount;
  final double surchargeAmount;
  final double shippingAmount;
  final double? taxAmount;
  final String? notes;
  final List<String> attachmentUrls;
  final String status;
  final List<OrderStatusHistoryEntryDto> statusHistory;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'branchId': branchId,
      'customerId': customerId,
      'sellerId': sellerId,
      'orderNumber': orderNumber,
      'deliveryAddress': deliveryAddress.toJson(),
      'billingAddress': billingAddress.toJson(),
      'priceListId': priceListId,
      'paymentTermId': paymentTermId,
      'carrierId': carrierId,
      'collectionId': collectionId,
      'orderType': orderType,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'discountAmount': discountAmount,
      'surchargeAmount': surchargeAmount,
      'shippingAmount': shippingAmount,
      'taxAmount': taxAmount,
      'notes': notes,
      'attachmentUrls': attachmentUrls,
      'status': status,
      'statusHistory': statusHistory
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}

List<OrderItemDto> _itemDtosFromJson(Object? value) {
  if (value == null) return const <OrderItemDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid order items payload.',
      code: 'invalid_order_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid order item payload.',
            code: 'invalid_order_payload',
          );
        }
        return OrderItemDto.fromJson(item);
      })
      .toList(growable: false);
}

List<OrderStatusHistoryEntryDto> _statusHistoryDtosFromJson(Object? value) {
  if (value == null) return const <OrderStatusHistoryEntryDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid order status history payload.',
      code: 'invalid_order_payload',
    );
  }
  return value
      .map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid order status history entry payload.',
            code: 'invalid_order_payload',
          );
        }
        return OrderStatusHistoryEntryDto.fromJson(entry);
      })
      .toList(growable: false);
}

List<String> _attachmentUrlsFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid order attachment urls payload.',
      code: 'invalid_order_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}
