import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../customer_identity_validator.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';
import '../value_objects/customer_status.dart';
import '../value_objects/customer_sync_status.dart';
import '../value_objects/customer_type.dart';
import 'customer_use_case_helpers.dart';

final class CreateCustomerUseCase {
  CreateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required CustomerType type,
    required String document,
    String? legalName,
    String? tradeName,
    String? fullName,
    String? stateRegistration,
    String? primaryEmail,
    String? primaryPhone,
    CustomerStatus status = CustomerStatus.prospect,
    String? classification,
    String? potential,
    String? segment,
    String? originChannel,
    String? responsibleSellerId,
    DateTime? registeredAt,
    DateTime? lastPurchaseAt,
    List<String> tags = const <String>[],
    Map<String, Object?> customFields = const <String, Object?>{},
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
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
          'Invalid customer creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_customer_create_payload',
        ),
      );
    }

    final duplicateResult = await _repository.existsByDocument(
      organizationId: trimmedOrganizationId,
      document: parsedDocument,
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

    final now = DateTime.now().toUtc();
    final customer = Customer(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      type: type,
      document: parsedDocument,
      legalName: type == CustomerType.legalEntity
          ? normalizeCustomerOptional(legalName)
          : null,
      tradeName: type == CustomerType.legalEntity
          ? normalizeCustomerOptional(tradeName)
          : null,
      fullName: type == CustomerType.individual
          ? normalizeCustomerOptional(fullName)
          : null,
      stateRegistration: type == CustomerType.legalEntity
          ? normalizeCustomerOptional(stateRegistration)
          : null,
      primaryEmail: normalizeCustomerOptional(primaryEmail),
      primaryPhone: normalizeCustomerOptional(primaryPhone),
      status: status,
      classification: normalizeCustomerOptional(classification),
      potential: normalizeCustomerOptional(potential),
      segment: normalizeCustomerOptional(segment),
      originChannel: normalizeCustomerOptional(originChannel),
      responsibleSellerId: normalizeCustomerOptional(responsibleSellerId),
      registeredAt: registeredAt?.toUtc() ?? now,
      lastPurchaseAt: lastPurchaseAt?.toUtc(),
      tags: normalizeCustomerTags(tags),
      customFields: normalizeCustomerCustomFields(customFields),
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: CustomerSyncStatus.pending,
    );

    return _repository.create(customer: customer);
  }
}
