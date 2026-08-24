import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/cnpj_cpf.dart';
import '../value_objects/customer_status.dart';
import '../value_objects/customer_sync_status.dart';
import '../value_objects/customer_type.dart';

part 'customer.freezed.dart';

/// Customer model for EPIC-06.
///
/// The tenant fields [organizationId] and [companyId] are immutable after
/// creation. Business code must resolve them from the authenticated session or
/// active organization context before calling Customer use cases; they must not
/// be taken from a form field.
@freezed
abstract class Customer with _$Customer {
  const Customer._();

  const factory Customer({
    required String id,
    required String organizationId,
    required String companyId,
    required CustomerType type,
    required CnpjCpf document,
    String? legalName,
    String? tradeName,
    String? fullName,
    String? stateRegistration,
    String? primaryEmail,
    String? primaryPhone,
    required CustomerStatus status,
    String? classification,
    String? potential,
    String? segment,
    String? originChannel,
    String? responsibleSellerId,
    required DateTime registeredAt,
    DateTime? lastPurchaseAt,
    @Default(<String>[]) List<String> tags,
    @Default(<String, Object?>{}) Map<String, Object?> customFields,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    required int version,
    required CustomerSyncStatus syncStatus,
  }) = _Customer;

  String get displayName {
    return switch (type) {
      CustomerType.legalEntity => tradeName ?? legalName ?? document.formatted,
      CustomerType.individual => fullName ?? document.formatted,
    };
  }
}
