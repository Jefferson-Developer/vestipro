// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderDraftBloc`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/functions/functions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_address.dart';
import '../../domain/entities/order_item.dart';
import '../dtos/order_submission_result_dto.dart';
import 'order_submission_data_source.dart';

/// [OrderSubmissionDataSource] backed by [CloudFunctionsService] (TASK-101)
/// — calls `submitOrder`, never a client-side write to
/// `organizations/{organizationId}/orders`, same rule every other Cloud-
/// Function-backed data source in this codebase follows
/// (`CloudFunctionsOrderPricingDataSource`).
@LazySingleton(as: OrderSubmissionDataSource)
final class CloudFunctionsOrderSubmissionDataSource
    implements OrderSubmissionDataSource {
  const CloudFunctionsOrderSubmissionDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<OrderSubmissionResultDto> submit({
    required Order order,
    required String idempotencyKey,
  }) async {
    final data = <String, dynamic>{
      'organizationId': order.organizationId,
      'companyId': order.companyId,
      'orderId': idempotencyKey,
      'branchId': order.branchId,
      'customerId': order.customerId,
      'sellerId': order.sellerId,
      'deliveryAddress': _addressToJson(order.deliveryAddress),
      'billingAddress': _addressToJson(order.billingAddress),
      'priceListId': order.priceListId,
      'paymentTermId': order.paymentTermId,
      'items': order.items
          .map((item) => _itemToJson(item, collectionId: order.collectionId))
          .toList(growable: false),
      'attachmentUrls': order.attachmentUrls,
      'shippingAmount': order.shippingAmount,
      'clientOrderTotal': order.itemsSubtotal + order.shippingAmount,
    };
    if (order.carrierId != null) {
      data['carrierId'] = order.carrierId;
    }
    if (order.collectionId != null) {
      data['collectionId'] = order.collectionId;
    }
    if (order.orderType != null) {
      data['orderType'] = order.orderType;
    }
    if (order.notes != null) {
      data['notes'] = order.notes;
    }

    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'submitOrder',
      data: data,
      requireAuth: true,
    );

    return OrderSubmissionResultDto.fromJson(response);
  }

  Map<String, dynamic> _addressToJson(OrderAddress address) {
    final data = <String, dynamic>{
      'street': address.street,
      'city': address.city,
      'state': address.state,
      'zipCode': address.zipCode,
      'country': address.country,
    };
    if (address.number != null) {
      data['number'] = address.number;
    }
    if (address.complement != null) {
      data['complement'] = address.complement;
    }
    if (address.district != null) {
      data['district'] = address.district;
    }
    return data;
  }

  Map<String, dynamic> _itemToJson(OrderItem item, {String? collectionId}) {
    final data = <String, dynamic>{
      'id': item.id,
      'productId': item.productId,
      'variantId': item.variantId,
      'quantity': item.quantity,
    };
    if (collectionId != null) {
      data['collectionId'] = collectionId;
    }
    return data;
  }
}
