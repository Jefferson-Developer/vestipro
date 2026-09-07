import '../entities/customer_portal_models.dart';

abstract interface class CustomerPortalRepository {
  Future<CustomerPortalSnapshot> load(String organizationId);
  Future<List<RevalidatedPortalItem>> repeatOrder({
    required String organizationId,
    required String orderId,
  });
  Future<String> createInvite({
    required String organizationId,
    required String customerId,
    required String email,
  });
  Future<void> acceptInvite(String token);
}
