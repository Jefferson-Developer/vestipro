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
final class UpdatePaymentTermUseCase {
  UpdatePaymentTermUseCase(this._repository, this._auditLogRepository);

  final PaymentTermRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<PaymentTerm>> call({
    required String organizationId,
    required String id,
    required String name,
    required List<PaymentInstallment> installments,
    List<String> priceListIds = const <String>[],
    required PaymentTermStatus status,
    required String updatedBy,
    required String actorName,
  }) async {
    final fieldErrors = <String, String>{};
    if (id.trim().isEmpty) {
      fieldErrors['id'] = 'Id is required.';
    }
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (name.trim().isEmpty) {
      fieldErrors['name'] = 'Informe o nome da condicao.';
    }
    if (updatedBy.trim().isEmpty) {
      fieldErrors['updatedBy'] = 'updatedBy is required.';
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
            'O prazo nao pode ser negativo.';
      }
    }
    if ((total - 100).abs() > 0.0001) {
      fieldErrors['installments'] =
          'A soma dos percentuais deve totalizar 100%.';
    }

    final normalizedIds = priceListIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (normalizedIds.length !=
        priceListIds.where((item) => item.trim().isNotEmpty).length) {
      fieldErrors['priceListIds'] =
          'Nao repita a mesma tabela de preco na condicao.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<PaymentTerm>(
        ValidationFailure(
          'Invalid payment term update payload.',
          code: 'invalid_payment_term_update_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
    if (currentResult is AppFailure<PaymentTerm?>) {
      return AppFailure<PaymentTerm>(currentResult.failure);
    }

    final current = (currentResult as AppSuccess<PaymentTerm?>).value;
    if (current == null) {
      return const AppFailure<PaymentTerm>(
        NotFoundFailure(
          'Payment term not found.',
          code: 'payment_term_not_found',
        ),
      );
    }

    final updated = current.copyWith(
      name: name.trim(),
      installments: installments
          .map(
            (installment) => PaymentInstallment(
              percentage: installment.percentage,
              dueInDays: installment.dueInDays,
            ),
          )
          .toList(growable: false),
      averageTermDays: installments.fold<double>(
        0,
        (sum, installment) =>
            sum + (installment.percentage / 100) * installment.dueInDays,
      ),
      status: status,
      priceListIds: normalizedIds.toList(growable: false),
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: current.version + 1,
      syncStatus: PaymentTermSyncStatus.pending,
    );

    final result = await _repository.update(paymentTerm: updated);
    if (result is AppFailure<PaymentTerm>) {
      return result;
    }

    final action =
        current.status == PaymentTermStatus.active &&
            updated.status == PaymentTermStatus.inactive
        ? AuditAction.paymentTermDeactivated
        : AuditAction.paymentTermUpdated;

    final auditEntry = AuditLogEntryFactory.build(
      organizationId: current.organizationId,
      actorUserId: updated.updatedBy,
      actorName: actorName.trim().isEmpty ? updated.updatedBy : actorName,
      action: action,
      entityType: 'paymentTerm',
      entityId: updated.id,
      previousValue: current.toAuditMap(),
      newValue: updated.toAuditMap(),
    );
    final auditResult = await _auditLogRepository.record(auditEntry);
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<PaymentTerm>(auditResult.failure);
    }

    return result;
  }
}
