import '../../../../core/errors/errors.dart';

/// Response shape of the `checkBillingStatus` callable (TASK-213) — mirrors
/// `CheckBillingStatusResponse` (`functions/src/receivables/check-billing-status.ts`).
/// Deliberately ignores the response's own `sensitive` field: a
/// financially-authorized caller always uses `WatchReceivablesUseCase`'s live
/// Firestore stream for full detail instead (same "masked check is only ever
/// called by a caller without finance.view" precedent
/// `CustomerCreditCubit.loadMaskedStatus` already sets for TASK-212).
final class BillingStatusCheckDto {
  const BillingStatusCheckDto({required this.status, required this.message});

  factory BillingStatusCheckDto.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final message = json['message'];
    if (status is! String || message is! String) {
      throw const ValidationException(
        'Invalid billing status check payload.',
        code: 'invalid_billing_status_check_payload',
      );
    }
    return BillingStatusCheckDto(status: status, message: message);
  }

  final String status;
  final String message;
}
