import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/payment_installment.dart';
import '../../domain/entities/payment_term.dart';
import '../../domain/value_objects/payment_term_status.dart';
import '../../domain/value_objects/payment_term_sync_status.dart';

@injectable
final class PaymentTermLocalMapper {
  const PaymentTermLocalMapper();

  PaymentTermsTableCompanion toRow(PaymentTerm term) {
    return PaymentTermsTableCompanion.insert(
      id: term.id,
      organizationId: term.organizationId,
      companyId: term.companyId,
      name: term.name,
      installmentsJson: jsonEncode(
        term.installments
            .map((installment) => installment.toJson())
            .toList(growable: false),
      ),
      averageTermDays: term.averageTermDays,
      status: term.status.name,
      priceListIdsJson: jsonEncode(term.priceListIds),
      createdAt: term.createdAt,
      createdBy: term.createdBy,
      updatedAt: term.updatedAt,
      updatedBy: term.updatedBy,
      deletedAt: drift.Value(term.deletedAt),
      version: drift.Value(term.version),
      syncStatus: drift.Value(term.syncStatus.name),
    );
  }

  PaymentTerm fromRow(PaymentTermsTableData row) {
    final installments = (jsonDecode(row.installmentsJson) as List<dynamic>)
        .map(
          (item) => PaymentInstallment.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList(growable: false);
    final priceListIds = (jsonDecode(row.priceListIdsJson) as List<dynamic>)
        .map((item) => item as String)
        .toList(growable: false);
    return PaymentTerm(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      name: row.name,
      installments: installments,
      averageTermDays: row.averageTermDays,
      status: PaymentTermStatus.values.byName(row.status),
      priceListIds: priceListIds,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
      version: row.version,
      syncStatus: PaymentTermSyncStatus.values.byName(row.syncStatus),
    );
  }
}
