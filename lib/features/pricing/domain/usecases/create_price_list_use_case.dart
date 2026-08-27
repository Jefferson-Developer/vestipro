import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/price_list.dart';
import '../repositories/price_list_repository.dart';
import '../value_objects/price_list_scope_type.dart';
import '../value_objects/price_list_status.dart';
import '../value_objects/price_list_sync_status.dart';

/// Creates a new [PriceList] (EPIC-11, TASK-083).
///
/// Mirrors `CreateCustomerUseCase`/`CreateProductUseCase`: every Price List
/// is born [PriceListStatus.draft] — this use case never accepts a status
/// parameter, so a table can never be created already [active].
@injectable
final class CreatePriceListUseCase {
  const CreatePriceListUseCase(this._repository);

  final PriceListRepository _repository;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');

  Future<AppResult<PriceList>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required String currency,
    required DateTime validFrom,
    DateTime? validTo,
    required PriceListScopeType scope,
    String? scopeValue,
    int priority = 0,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedName = name.trim();
    final trimmedCurrency = currency.trim().toUpperCase();
    final trimmedCreatedBy = createdBy.trim();
    final trimmedScopeValue = scopeValue?.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) {
      fieldErrors['id'] = 'Id is required.';
    }
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Name is required.';
    }
    if (trimmedCurrency.isEmpty) {
      fieldErrors['currency'] = 'Currency is required.';
    } else if (!_currencyPattern.hasMatch(trimmedCurrency)) {
      fieldErrors['currency'] = 'Currency must be a 3-letter ISO 4217 code.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (validTo != null && !validTo.toUtc().isAfter(validFrom.toUtc())) {
      fieldErrors['validTo'] = 'ValidTo must be after validFrom.';
    }
    if (priority < 0) {
      fieldErrors['priority'] = 'Priority must not be negative.';
    }
    if (scope == PriceListScopeType.company) {
      if (trimmedScopeValue != null && trimmedScopeValue.isNotEmpty) {
        fieldErrors['scopeValue'] =
            'ScopeValue must be empty for company scope.';
      }
    } else if (trimmedScopeValue == null || trimmedScopeValue.isEmpty) {
      fieldErrors['scopeValue'] =
          'ScopeValue is required for channel/segment scope.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<PriceList>(
        ValidationFailure(
          'Invalid price list creation payload.',
          code: 'invalid_price_list_create_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final priceList = PriceList(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      name: trimmedName,
      currency: trimmedCurrency,
      validFrom: validFrom.toUtc(),
      validTo: validTo?.toUtc(),
      status: PriceListStatus.draft,
      scope: scope,
      scopeValue: scope == PriceListScopeType.company
          ? null
          : trimmedScopeValue,
      priority: priority,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: PriceListSyncStatus.pending,
    );

    return _repository.create(priceList: priceList);
  }
}
