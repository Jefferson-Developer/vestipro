import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../customer_address_contact_rules.dart';
import '../entities/customer.dart';
import '../entities/customer_contact.dart';
import '../repositories/customer_repository.dart';
import '../value_objects/customer_contact_type.dart';
import '../value_objects/customer_sensitive_field.dart';
import '../value_objects/customer_sync_status.dart';

@injectable
final class AddCustomerContactUseCase {
  const AddCustomerContactUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String updatedBy,
    required String contactId,
    required CustomerContactType type,
    required String name,
    String? role,
    String? phone,
    String? email,
    bool isPrimary = false,
  }) async {
    try {
      final contact = buildCustomerContact(
        id: contactId,
        type: type,
        name: name,
        role: role,
        phone: phone,
        email: email,
        isPrimary: isPrimary,
      );
      final currentResult = await _repository.getById(
        organizationId: organizationId.trim(),
        id: customerId.trim(),
      );
      return currentResult.fold(
        onSuccess: (customer) {
          final next = normalizeCustomerContacts(<CustomerContact>[
            if (contact.isPrimary)
              for (final existing in customer.contacts)
                existing.copyWith(isPrimary: false)
            else
              ...customer.contacts,
            contact.copyWith(
              isPrimary: contact.isPrimary || customer.contacts.isEmpty,
            ),
          ]);
          return _save(
            _repository,
            customer,
            contacts: next,
            updatedBy: updatedBy,
          );
        },
        onFailure: (failure) => AppFailure<Customer>(failure),
      );
    } on ValidationException catch (exception) {
      return AppFailure<Customer>(mapAppExceptionToFailure(exception));
    }
  }
}

@injectable
final class UpdateCustomerContactUseCase {
  const UpdateCustomerContactUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String updatedBy,
    required String contactId,
    required CustomerContactType type,
    required String name,
    String? role,
    String? phone,
    String? email,
    bool isPrimary = false,
  }) async {
    try {
      final updatedContact = buildCustomerContact(
        id: contactId,
        type: type,
        name: name,
        role: role,
        phone: phone,
        email: email,
        isPrimary: isPrimary,
      );
      final currentResult = await _repository.getById(
        organizationId: organizationId.trim(),
        id: customerId.trim(),
      );
      return currentResult.fold(
        onSuccess: (customer) {
          final index = customer.contacts.indexWhere(
            (contact) => contact.id == contactId.trim(),
          );
          if (index == -1) {
            return const AppFailure<Customer>(
              NotFoundFailure(
                'Customer contact not found.',
                code: 'customer_contact_not_found',
              ),
            );
          }
          final next = <CustomerContact>[
            for (
              var itemIndex = 0;
              itemIndex < customer.contacts.length;
              itemIndex += 1
            )
              itemIndex == index
                  ? updatedContact
                  : customer.contacts[itemIndex],
          ];
          return _save(
            _repository,
            customer,
            contacts: normalizeCustomerContacts(next),
            updatedBy: updatedBy,
          );
        },
        onFailure: (failure) => AppFailure<Customer>(failure),
      );
    } on ValidationException catch (exception) {
      return AppFailure<Customer>(mapAppExceptionToFailure(exception));
    }
  }
}

@injectable
final class RemoveCustomerContactUseCase {
  const RemoveCustomerContactUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String contactId,
    required String updatedBy,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: customerId.trim(),
    );
    return currentResult.fold(
      onSuccess: (customer) {
        final next = customer.contacts
            .where((contact) => contact.id != contactId.trim())
            .toList(growable: false);
        if (next.length == customer.contacts.length) {
          return const AppFailure<Customer>(
            NotFoundFailure(
              'Customer contact not found.',
              code: 'customer_contact_not_found',
            ),
          );
        }
        return _save(
          _repository,
          customer,
          contacts: normalizeCustomerContacts(next),
          updatedBy: updatedBy,
        );
      },
      onFailure: (failure) => AppFailure<Customer>(failure),
    );
  }
}

@injectable
final class SetPrimaryCustomerContactUseCase {
  const SetPrimaryCustomerContactUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String contactId,
    required String updatedBy,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: customerId.trim(),
    );
    return currentResult.fold(
      onSuccess: (customer) {
        if (!customer.contacts.any(
          (contact) => contact.id == contactId.trim(),
        )) {
          return const AppFailure<Customer>(
            NotFoundFailure(
              'Customer contact not found.',
              code: 'customer_contact_not_found',
            ),
          );
        }
        final next = <CustomerContact>[
          for (final contact in customer.contacts)
            contact.copyWith(isPrimary: contact.id == contactId.trim()),
        ];
        return _save(
          _repository,
          customer,
          contacts: next,
          updatedBy: updatedBy,
        );
      },
      onFailure: (failure) => AppFailure<Customer>(failure),
    );
  }
}

Future<AppResult<Customer>> _save(
  CustomerRepository repository,
  Customer customer, {
  required List<CustomerContact> contacts,
  required String updatedBy,
}) {
  final now = DateTime.now().toUtc();
  final normalizedContacts = normalizeCustomerContacts(contacts);
  final primary = primaryCustomerContact(normalizedContacts);
  return repository.update(
    customer: customer.copyWith(
      contacts: normalizedContacts,
      primaryEmail: primary?.email ?? customer.primaryEmail,
      primaryPhone: primary?.phone ?? customer.primaryPhone,
      updatedAt: now,
      updatedBy: updatedBy.trim(),
      version: customer.version + 1,
      syncStatus: CustomerSyncStatus.pending,
    ),
    sensitiveFieldsToAudit: const <CustomerSensitiveField>{},
  );
}
