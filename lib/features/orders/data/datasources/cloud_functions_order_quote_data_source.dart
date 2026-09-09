import '../../../../core/functions/functions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_address.dart';
import '../../domain/entities/order_item.dart';
import '../dtos/quote_conversion_result_dto.dart';
import '../dtos/quote_dto.dart';
import 'order_quote_data_source.dart';

final class CloudFunctionsOrderQuoteDataSource implements OrderQuoteDataSource {
  const CloudFunctionsOrderQuoteDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<QuoteDto> generate({
    required Order order,
    required Duration validity,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'generateQuote',
      data: <String, dynamic>{
        'organizationId': order.organizationId,
        'companyId': order.companyId,
        'quoteId': '${order.id}-quote',
        'orderDraftId': order.id,
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
        'shippingAmount': order.shippingAmount,
        'validityDays': validity.inDays,
        if (order.carrierId != null) 'carrierId': order.carrierId,
        if (order.collectionId != null) 'collectionId': order.collectionId,
        if (order.orderType != null) 'orderType': order.orderType,
        if (order.notes != null) 'notes': order.notes,
      },
      requireAuth: true,
    );
    return QuoteDto.fromJson(response);
  }

  @override
  Future<QuoteConversionResultDto> convertToOrder({
    required String organizationId,
    required String quoteId,
    required String orderId,
    required bool acceptChanges,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'convertQuoteToOrder',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'quoteId': quoteId,
        'orderId': orderId,
        'acceptChanges': acceptChanges,
      },
      requireAuth: true,
    );
    return QuoteConversionResultDto.fromJson(response);
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
      ..._optionalString('collectionId', collectionId),
    };
  }

  Map<String, String> _optionalString(String key, String? value) {
    return value == null
        ? const <String, String>{}
        : <String, String>{key: value};
  }
}
