import '../entities/customer_portal_models.dart';
import '../repositories/customer_portal_repository.dart';

final class LoadCustomerPortalUseCase {
  const LoadCustomerPortalUseCase(this._repository);
  final CustomerPortalRepository _repository;
  Future<CustomerPortalSnapshot> call(String organizationId) =>
      _repository.load(organizationId);
}

final class RepeatCustomerPortalOrderUseCase {
  const RepeatCustomerPortalOrderUseCase(this._repository);
  final CustomerPortalRepository _repository;
  Future<List<RevalidatedPortalItem>> call({
    required String organizationId,
    required String orderId,
  }) =>
      _repository.repeatOrder(organizationId: organizationId, orderId: orderId);
}

final class ProvisionCustomerPortalAccessUseCase {
  const ProvisionCustomerPortalAccessUseCase(this._repository);
  final CustomerPortalRepository _repository;
  Future<String> call({
    required String organizationId,
    required String customerId,
    required String email,
  }) {
    if (!email.contains('@')) {
      throw ArgumentError.value(email, 'email', 'E-mail inválido');
    }
    return _repository.createInvite(
      organizationId: organizationId,
      customerId: customerId,
      email: email.trim().toLowerCase(),
    );
  }
}
