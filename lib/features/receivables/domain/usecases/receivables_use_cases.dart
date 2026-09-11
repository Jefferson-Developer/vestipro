import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/billing_status_check.dart';
import '../entities/receivable.dart';
import '../repositories/receivables_repository.dart';

/// Masked situação financeira preview — used by the customer 360º/pedido
/// billing section for any caller without `finance.view`.
@injectable
final class CheckBillingStatusUseCase {
  const CheckBillingStatusUseCase(this._repository);
  final ReceivablesRepository _repository;

  Future<AppResult<BillingStatusCheck>> call({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) => _repository.checkBillingStatus(
    organizationId: organizationId,
    customerId: customerId,
    orderId: orderId,
  );
}

/// Live, full-detail títulos a receber — the customer 360º/pedido billing
/// section's financially-authorized (`finance.view`) view.
@injectable
final class WatchReceivablesUseCase {
  const WatchReceivablesUseCase(this._repository);
  final ReceivablesRepository _repository;

  Stream<AppResult<List<Receivable>>> call({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) => _repository.watchReceivables(
    organizationId: organizationId,
    customerId: customerId,
    orderId: orderId,
  );
}

/// Registers a payment/estorno against one título — `finance.manage` only.
@injectable
final class RegisterPaymentAllocationUseCase {
  const RegisterPaymentAllocationUseCase(this._repository);
  final ReceivablesRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String receivableId,
    required double amount,
    required String externalReference,
    String source = 'manual',
    String? note,
  }) => _repository.registerPaymentAllocation(
    organizationId: organizationId,
    receivableId: receivableId,
    amount: amount,
    externalReference: externalReference,
    source: source,
    note: note,
  );
}
