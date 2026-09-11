import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import '../../fulfillment/domain/value_objects/shipment_status.dart';
import '../domain/entities/customer_portal_models.dart';
import '../domain/repositories/customer_portal_repository.dart';

@LazySingleton(as: CustomerPortalRepository)
final class CloudFunctionsCustomerPortalRepository
    implements CustomerPortalRepository {
  CloudFunctionsCustomerPortalRepository(this._functions);
  final FirebaseFunctions _functions;

  @override
  Future<CustomerPortalSnapshot> load(String organizationId) async {
    final result = await _functions
        .httpsCallable('loadCustomerPortal')
        .call<Map<String, dynamic>>({'organizationId': organizationId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final branding = Map<String, dynamic>.from(data['branding'] as Map);
    return CustomerPortalSnapshot(
      customerId: data['customerId'] as String,
      branding: CustomerPortalBranding(
        name: branding['name'] as String,
        logoUrl: branding['logoUrl'] as String?,
        primaryColorHex: branding['primaryColorHex'] as String?,
      ),
      products: (data['products'] as List).map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        return CustomerPortalProduct(
          id: item['id'] as String,
          name: item['name'] as String,
          imageUrl: item['imageUrl'] as String?,
        );
      }).toList(),
      orders: (data['orders'] as List).map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        final shipmentStatusCode = item['shipmentStatus'] as String?;
        final estimatedDeliveryDate = item['estimatedDeliveryDate'] as String?;
        return CustomerPortalOrder(
          id: item['id'] as String,
          orderNumber: item['orderNumber'] as String,
          status: item['status'] as String,
          total: (item['total'] as num).toDouble(),
          shipmentStatus: shipmentStatusCode == null
              ? null
              : ShipmentStatus.fromCode(shipmentStatusCode).label,
          hasOpenLogisticsIssue:
              item['hasOpenLogisticsIssue'] as bool? ?? false,
          estimatedDeliveryDate: estimatedDeliveryDate == null
              ? null
              : DateTime.tryParse(estimatedDeliveryDate),
        );
      }).toList(),
    );
  }

  @override
  Future<List<RevalidatedPortalItem>> repeatOrder({
    required String organizationId,
    required String orderId,
  }) async {
    final result = await _functions
        .httpsCallable('repeatCustomerPortalOrder')
        .call<Map<String, dynamic>>({
          'organizationId': organizationId,
          'orderId': orderId,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['items'] as List).map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      return RevalidatedPortalItem(
        productId: item['productId'] as String,
        variantId: item['variantId'] as String,
        quantity: item['quantity'] as int,
        unitPrice: (item['unitPrice'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<String> createInvite({
    required String organizationId,
    required String customerId,
    required String email,
  }) async {
    final result = await _functions
        .httpsCallable('createCustomerPortalInvite')
        .call<Map<String, dynamic>>({
          'organizationId': organizationId,
          'customerId': customerId,
          'email': email,
        });
    return (result.data as Map)['token'] as String;
  }

  @override
  Future<void> acceptInvite(String token) async {
    await _functions.httpsCallable('acceptCustomerPortalInvite').call<void>({
      'token': token,
    });
  }
}
