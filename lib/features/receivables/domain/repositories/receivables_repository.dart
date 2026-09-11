import '../../../../core/utils/utils.dart';
import '../entities/billing_status_check.dart';
import '../entities/receivable.dart';

abstract interface class ReceivablesRepository {
  /// Read-only, masked preview of [customerId]'s (or, when [orderId] is
  /// given, just that pedido's) situação financeira — callable by any active
  /// member; never carries a monetary figure.
  Future<AppResult<BillingStatusCheck>> checkBillingStatus({
    required String organizationId,
    required String customerId,
    String? orderId,
  });

  /// Live, full-detail títulos a receber for [customerId] (optionally scoped
  /// to one [orderId]) — only ever resolves for a caller whose Membership
  /// actually holds `finance.view` (`firestore.rules`'s `receivables` match
  /// block denies the read outright for anyone else, so this stream
  /// fails/stays empty for a seller, it never silently succeeds with
  /// sensitive data).
  Stream<AppResult<List<Receivable>>> watchReceivables({
    required String organizationId,
    required String customerId,
    String? orderId,
  });

  /// Registers one payment/estorno applied to [receivableId] — always a
  /// `finance.manage`-only, server-validated confirmation (never a plain UI
  /// toggle): TASK-213's own "a UI nunca marca fatura como paga sem
  /// confirmação de gateway, ERP ou usuário financeiro autorizado".
  /// [externalReference] is the idempotency key — a retried submission with
  /// the same reference is a safe no-op server-side.
  Future<AppResult<void>> registerPaymentAllocation({
    required String organizationId,
    required String receivableId,
    required double amount,
    required String externalReference,
    String source = 'manual',
    String? note,
  });
}
