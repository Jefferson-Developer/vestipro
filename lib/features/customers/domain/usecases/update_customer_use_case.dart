import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../customer_address_contact_rules.dart';
import '../customer_identity_validator.dart';
import '../entities/customer.dart';
import '../entities/customer_address.dart';
import '../entities/customer_contact.dart';
import '../repositories/customer_repository.dart';
import '../value_objects/customer_sensitive_field.dart';
import '../value_objects/customer_status.dart';
import '../value_objects/customer_sync_status.dart';
import '../value_objects/customer_type.dart';
import 'customer_use_case_helpers.dart';

@injectable
final class UpdateCustomerUseCase {
  UpdateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String id,
    required CustomerType type,
    required String document,
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
    DateTime? registeredAt,
    DateTime? lastPurchaseAt,
    List<CustomerAddress>? addresses,
    List<CustomerContact>? contacts,
    List<String> tags = const <String>[],
    Map<String, Object?> customFields = const <String, Object?>{},
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    final parsedDocument = parseCustomerDocument(document, fieldErrors);
    if (parsedDocument != null) {
      fieldErrors.addAll(
        validateCustomerIdentity(
          type: type,
          document: parsedDocument,
          legalName: legalName,
          fullName: fullName,
          stateRegistration: stateRegistration,
        ),
      );
    }

    if (fieldErrors.isNotEmpty || parsedDocument == null) {
      return AppFailure<Customer>(
        ValidationFailure(
          'Invalid customer update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_customer_update_payload',
        ),
      );
    }

    final duplicateResult = await _repository.existsByDocument(
      organizationId: trimmedOrganizationId,
      document: parsedDocument,
      excludingCustomerId: trimmedId,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<Customer>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return AppFailure<Customer>(
        const ConflictFailure(
          'Customer document already exists in this organization.',
          code: 'customer_document_already_exists',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<Customer>) {
      return currentResult;
    }
    final current = (currentResult as AppSuccess<Customer>).value;
    final normalizedLegalName = type == CustomerType.legalEntity
        ? normalizeCustomerOptional(legalName)
        : null;
    final sensitiveFieldsToAudit = <CustomerSensitiveField>{};
    if (current.document != parsedDocument) {
      sensitiveFieldsToAudit.add(CustomerSensitiveField.document);
    }
    if (current.legalName != normalizedLegalName) {
      sensitiveFieldsToAudit.add(CustomerSensitiveField.legalName);
    }
    final normalizedAddresses = normalizeCustomerAddresses(
      addresses ?? current.addresses,
    );
    final normalizedContacts = normalizeCustomerContacts(
      contacts ?? current.contacts,
    );
    final primaryContact = primaryCustomerContact(normalizedContacts);

    final updated = current.copyWith(
      type: type,
      document: parsedDocument,
      legalName: normalizedLegalName,
      tradeName: type == CustomerType.legalEntity
          ? normalizeCustomerOptional(tradeName)
          : null,
      fullName: type == CustomerType.individual
          ? normalizeCustomerOptional(fullName)
          : null,
      stateRegistration: type == CustomerType.legalEntity
          ? normalizeCustomerOptional(stateRegistration)
          : null,
      primaryEmail:
          normalizeCustomerOptional(primaryContact?.email) ??
          normalizeCustomerOptional(primaryEmail),
      primaryPhone:
          normalizeCustomerOptional(primaryContact?.phone) ??
          normalizeCustomerOptional(primaryPhone),
      status: status,
      classification: normalizeCustomerOptional(classification),
      potential: normalizeCustomerOptional(potential),
      segment: normalizeCustomerOptional(segment),
      originChannel: normalizeCustomerOptional(originChannel),
      responsibleSellerId: normalizeCustomerOptional(responsibleSellerId),
      registeredAt: registeredAt?.toUtc() ?? current.registeredAt,
      lastPurchaseAt: lastPurchaseAt?.toUtc(),
      addresses: normalizedAddresses,
      contacts: normalizedContacts,
      tags: normalizeCustomerTags(tags),
      customFields: normalizeCustomerCustomFields(customFields),
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: current.version + 1,
      syncStatus: CustomerSyncStatus.pending,
    );

    return _repository.update(
      customer: updated,
      sensitiveFieldsToAudit: sensitiveFieldsToAudit,
    );
  }
}
