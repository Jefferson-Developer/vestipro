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
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'submitOrder',
      data: <String, dynamic>{
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
        if (order.carrierId != null) 'carrierId': order.carrierId,
        if (order.collectionId != null) 'collectionId': order.collectionId,
        if (order.orderType != null) 'orderType': order.orderType,
        'items': order.items
            .map((item) => _itemToJson(item, collectionId: order.collectionId))
            .toList(growable: false),
        if (order.notes != null) 'notes': order.notes,
        'attachmentUrls': order.attachmentUrls,
        'shippingAmount': order.shippingAmount,
        'clientOrderTotal': order.itemsSubtotal + order.shippingAmount,
      },
      requireAuth: true,
    );

    return OrderSubmissionResultDto.fromJson(response);
  }

  Map<String, dynamic> _addressToJson(OrderAddress address) {
    return <String, dynamic>{
      'street': address.street,
      if (address.number != null) 'number': address.number,
      if (address.complement != null) 'complement': address.complement,
      if (address.district != null) 'district': address.district,
      'city': address.city,
      'state': address.state,
      'zipCode': address.zipCode,
      'country': address.country,
    };
  }

  Map<String, dynamic> _itemToJson(OrderItem item, {String? collectionId}) {
    return <String, dynamic>{
      'id': item.id,
      'productId': item.productId,
      'variantId': item.variantId,
      'quantity': item.quantity,
      if (collectionId != null) 'collectionId': collectionId,
    };
  }
}
