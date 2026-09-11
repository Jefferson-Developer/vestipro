import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/backorder_request.dart';
import '../repositories/backorder_repository.dart';
import '../value_objects/backorder_origin.dart';
import '../value_objects/backorder_priority.dart';

@injectable
final class WatchBackorderQueueUseCase {
  const WatchBackorderQueueUseCase(this._repository);
  final BackorderRepository _repository;

  Stream<AppResult<List<BackorderRequest>>> call({
    required String organizationId,
  }) => _repository.watchQueue(organizationId: organizationId);
}

@injectable
final class WatchBackordersAwaitingApprovalUseCase {
  const WatchBackordersAwaitingApprovalUseCase(this._repository);
  final BackorderRepository _repository;

  Stream<AppResult<List<BackorderRequest>>> call({
    required String organizationId,
  }) => _repository.watchAwaitingApproval(organizationId: organizationId);
}

@injectable
final class WatchBackordersForCustomerUseCase {
  const WatchBackordersForCustomerUseCase(this._repository);
  final BackorderRepository _repository;

  Stream<AppResult<List<BackorderRequest>>> call({
    required String organizationId,
    required String customerId,
  }) => _repository.watchForCustomer(
    organizationId: organizationId,
    customerId: customerId,
  );
}

@injectable
final class CreateBackorderRequestUseCase {
  const CreateBackorderRequestUseCase(this._repository);
  final BackorderRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required BackorderOrigin origin,
    BackorderPriority priority = BackorderPriority.normal,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    DateTime? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  }) => _repository.createBackorderRequest(
    organizationId: organizationId,
    companyId: companyId,
    backorderId: backorderId,
    customerId: customerId,
    productId: productId,
    variantId: variantId,
    sku: sku,
    quantity: quantity,
    origin: origin,
    priority: priority,
    sellerId: sellerId,
    relatedOrderId: relatedOrderId,
    relatedOrderItemId: relatedOrderItemId,
    requestedDeliveryDate: requestedDeliveryDate,
    estimatedUnitPrice: estimatedUnitPrice,
    notes: notes,
  );
}

@injectable
final class DecideBackorderApprovalUseCase {
  const DecideBackorderApprovalUseCase(this._repository);
  final BackorderRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  }) => _repository.decideBackorderApproval(
    organizationId: organizationId,
    backorderId: backorderId,
    approve: approve,
    note: note,
  );
}

@injectable
final class CancelBackorderRequestUseCase {
  const CancelBackorderRequestUseCase(this._repository);
  final BackorderRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String backorderId,
    String? reason,
  }) => _repository.cancelBackorderRequest(
    organizationId: organizationId,
    backorderId: backorderId,
    reason: reason,
  );
}

@injectable
final class ConvertBackorderToOrderUseCase {
  const ConvertBackorderToOrderUseCase(this._repository);
  final BackorderRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String backorderId,
    required String orderId,
  }) => _repository.convertBackorderToOrder(
    organizationId: organizationId,
    backorderId: backorderId,
    orderId: orderId,
  );
}
