import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/payment_installment.dart';
import '../entities/payment_term.dart';
import '../repositories/payment_term_repository.dart';
import '../value_objects/payment_term_status.dart';
import '../value_objects/payment_term_sync_status.dart';

@injectable
final class CreatePaymentTermUseCase {
  CreatePaymentTermUseCase(this._repository, this._auditLogRepository);

  final PaymentTermRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<PaymentTerm>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required List<PaymentInstallment> installments,
    List<String> priceListIds = const <String>[],
    PaymentTermStatus status = PaymentTermStatus.active,
    required String createdBy,
    required String actorName,
  }) async {
    final fieldErrors = _validate(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      name: name,
      installments: installments,
      priceListIds: priceListIds,
      userIdKey: 'createdBy',
      userIdValue: createdBy,
    );

    if (fieldErrors.isNotEmpty) {
      return AppFailure<PaymentTerm>(
        ValidationFailure(
          'Invalid payment term creation payload.',
          code: 'invalid_payment_term_create_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final paymentTerm = PaymentTerm(
      id: id.trim(),
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
      name: name.trim(),
      installments: _normalizeInstallments(installments),
      averageTermDays: _averageTermDays(installments),
      status: status,
      priceListIds: _normalizeIds(priceListIds),
      createdAt: now,
      createdBy: createdBy.trim(),
      updatedAt: now,
      updatedBy: createdBy.trim(),
      version: 1,
      syncStatus: PaymentTermSyncStatus.pending,
    );

    final result = await _repository.create(paymentTerm: paymentTerm);
    if (result is AppFailure<PaymentTerm>) return result;

    final auditEntry = AuditLogEntryFactory.build(
      organizationId: paymentTerm.organizationId,
      actorUserId: paymentTerm.createdBy,
      actorName: actorName.trim().isEmpty ? paymentTerm.createdBy : actorName,
      action: AuditAction.paymentTermCreated,
      entityType: 'paymentTerm',
      entityId: paymentTerm.id,
      newValue: paymentTerm.toAuditMap(),
    );
    final auditResult = await _auditLogRepository.record(auditEntry);
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<PaymentTerm>(auditResult.failure);
    }

    return result;
  }
}

Map<String, String> _validate({
  required String id,
  required String organizationId,
  required String companyId,
  required String name,
  required List<PaymentInstallment> installments,
  required List<String> priceListIds,
  required String userIdKey,
  required String userIdValue,
}) {
  final fieldErrors = <String, String>{};
  if (id.trim().isEmpty) fieldErrors['id'] = 'Id is required.';
  if (organizationId.trim().isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (companyId.trim().isEmpty) {
    fieldErrors['companyId'] = 'CompanyId is required.';
  }
  if (name.trim().isEmpty) fieldErrors['name'] = 'Informe o nome da condição.';
  if (userIdValue.trim().isEmpty) {
    fieldErrors[userIdKey] = '$userIdKey is required.';
  }
  if (installments.isEmpty) {
    fieldErrors['installments'] = 'Informe ao menos uma parcela.';
  }

  var total = 0.0;
  for (var index = 0; index < installments.length; index++) {
    final installment = installments[index];
    total += installment.percentage;
    if (installment.percentage <= 0) {
      fieldErrors['installments[$index].percentage'] =
          'O percentual deve ser maior que zero.';
    }
    if (installment.dueInDays < 0) {
      fieldErrors['installments[$index].dueInDays'] =
          'O prazo não pode ser negativo.';
    }
  }
  if ((total - 100).abs() > 0.0001) {
    fieldErrors['installments'] = 'A soma dos percentuais deve totalizar 100%.';
  }

  final normalizedIds = _normalizeIds(priceListIds);
  if (normalizedIds.length !=
      priceListIds.where((id) => id.trim().isNotEmpty).length) {
    fieldErrors['priceListIds'] =
        'Não repita a mesma tabela de preço na condição.';
  }
  return fieldErrors;
}

List<String> _normalizeIds(List<String> ids) => ids
    .map((id) => id.trim())
    .where((id) => id.isNotEmpty)
    .toSet()
    .toList(growable: false);

List<PaymentInstallment> _normalizeInstallments(
  List<PaymentInstallment> installments,
) {
  return installments
      .map(
        (installment) => PaymentInstallment(
          percentage: installment.percentage,
          dueInDays: installment.dueInDays,
        ),
      )
      .toList(growable: false);
}

double _averageTermDays(List<PaymentInstallment> installments) {
  return installments.fold<double>(
    0,
    (sum, installment) =>
        sum + (installment.percentage / 100) * installment.dueInDays,
  );
}
