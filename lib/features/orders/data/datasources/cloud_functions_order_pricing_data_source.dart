import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/order_pricing_item_request.dart';
import '../dtos/order_pricing_summary_dto.dart';
import 'order_pricing_data_source.dart';

/// [OrderPricingDataSource] backed by [CloudFunctionsService] (TASK-099) —
/// calls `calculatePricing` (TASK-088), never a client-side recomputation of
/// price/desconto/acréscimo/frete/total, same rule every other Cloud-
/// Function-backed data source in this codebase follows
/// (`CloudFunctionsCatalogShareLookupDataSource`,
/// `CloudFunctionsUserAccessDataSource`).
@LazySingleton(as: OrderPricingDataSource)
final class CloudFunctionsOrderPricingDataSource
    implements OrderPricingDataSource {
  const CloudFunctionsOrderPricingDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<OrderPricingSummaryDto> calculate({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String priceListId,
    required String paymentTermId,
    required String idempotencyKey,
    required double shippingAmount,
    required List<OrderPricingItemRequest> items,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'calculatePricing',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerSegment': customerSegment,
        'priceListId': priceListId,
        'paymentTermId': paymentTermId,
        'idempotencyKey': idempotencyKey,
        'shippingAmount': shippingAmount,
        'items': items
            .map(
              (item) => <String, dynamic>{
                'productId': item.productId,
                if (item.variantId != null) 'variantId': item.variantId,
                'quantity': item.quantity,
                if (item.collectionId != null)
                  'collectionId': item.collectionId,
                if (item.categoryId != null) 'categoryId': item.categoryId,
                'manualDiscountPercent': item.manualDiscountPercent,
              },
            )
            .toList(growable: false),
      },
      requireAuth: true,
    );

    return OrderPricingSummaryDto.fromJson(response);
  }
}
