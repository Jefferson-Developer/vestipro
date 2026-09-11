import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import 'backorder_write_data_source.dart';

/// [BackorderWriteDataSource] backed by [CloudFunctionsService] (TASK-215) —
/// every mutation goes through the `createBackorderRequest`/
/// `decideBackorderApproval`/`cancelBackorderRequest`/
/// `convertBackorderToOrder` callables, never a direct Firestore write, same
/// contract `CloudFunctionsFulfillmentWriteDataSource` (TASK-214) already
/// follows.
@LazySingleton(as: BackorderWriteDataSource)
final class CloudFunctionsBackorderWriteDataSource
    implements BackorderWriteDataSource {
  const CloudFunctionsBackorderWriteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<void> createBackorderRequest({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required String origin,
    required String priority,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    String? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'createBackorderRequest',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'backorderId': backorderId,
        'customerId': customerId,
        'productId': productId,
        'variantId': variantId,
        'sku': sku,
        'quantity': quantity,
        'origin': origin,
        'priority': priority,
        'sellerId': sellerId,
        'relatedOrderId': relatedOrderId,
        'relatedOrderItemId': relatedOrderItemId,
        'requestedDeliveryDate': requestedDeliveryDate,
        'estimatedUnitPrice': estimatedUnitPrice,
        'notes': notes,
      },
    );
  }

  @override
  Future<void> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'decideBackorderApproval',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'backorderId': backorderId,
        'approve': approve,
        'note': note,
      },
    );
  }

  @override
  Future<void> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'cancelBackorderRequest',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'backorderId': backorderId,
        'reason': reason,
      },
    );
  }

  @override
  Future<void> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'convertBackorderToOrder',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'backorderId': backorderId,
        'orderId': orderId,
      },
    );
  }
}
