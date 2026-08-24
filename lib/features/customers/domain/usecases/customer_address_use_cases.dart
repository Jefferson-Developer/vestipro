import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../customer_address_contact_rules.dart';
import '../entities/customer.dart';
import '../entities/customer_address.dart';
import '../repositories/customer_repository.dart';
import '../value_objects/customer_address_type.dart';
import '../value_objects/customer_sensitive_field.dart';
import '../value_objects/customer_sync_status.dart';

@injectable
final class AddCustomerAddressUseCase {
  const AddCustomerAddressUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String updatedBy,
    required String addressId,
    required CustomerAddressType type,
    required String street,
    String? number,
    String? complement,
    String? district,
    required String city,
    required String state,
    required String zipCode,
    String country = 'BR',
    bool isPrimary = false,
  }) async {
    try {
      final currentResult = await _repository.getById(
        organizationId: organizationId.trim(),
        id: customerId.trim(),
      );
      return currentResult.fold(
        onSuccess: (customer) {
          final address = buildCustomerAddress(
            id: addressId,
            type: type,
            street: street,
            number: number,
            complement: complement,
            district: district,
            city: _cityFromLocalZip(customer.addresses, zipCode, city),
            state: _stateFromLocalZip(customer.addresses, zipCode, state),
            zipCode: zipCode,
            country: country,
            isPrimary: isPrimary,
          );
          final next = normalizeCustomerAddresses(<CustomerAddress>[
            if (address.isPrimary)
              for (final existing in customer.addresses)
                existing.copyWith(isPrimary: false)
            else
              ...customer.addresses,
            address.copyWith(
              isPrimary: address.isPrimary || customer.addresses.isEmpty,
            ),
          ]);
          return _save(
            _repository,
            customer,
            addresses: next,
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
final class UpdateCustomerAddressUseCase {
  const UpdateCustomerAddressUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String updatedBy,
    required String addressId,
    required CustomerAddressType type,
    required String street,
    String? number,
    String? complement,
    String? district,
    required String city,
    required String state,
    required String zipCode,
    String country = 'BR',
    bool isPrimary = false,
  }) async {
    try {
      final currentResult = await _repository.getById(
        organizationId: organizationId.trim(),
        id: customerId.trim(),
      );
      return currentResult.fold(
        onSuccess: (customer) {
          final index = customer.addresses.indexWhere(
            (address) => address.id == addressId.trim(),
          );
          if (index == -1) {
            return const AppFailure<Customer>(
              NotFoundFailure(
                'Customer address not found.',
                code: 'customer_address_not_found',
              ),
            );
          }
          final updatedAddress = buildCustomerAddress(
            id: addressId,
            type: type,
            street: street,
            number: number,
            complement: complement,
            district: district,
            city: _cityFromLocalZip(customer.addresses, zipCode, city),
            state: _stateFromLocalZip(customer.addresses, zipCode, state),
            zipCode: zipCode,
            country: country,
            isPrimary: isPrimary,
          );
          final next = <CustomerAddress>[
            for (
              var itemIndex = 0;
              itemIndex < customer.addresses.length;
              itemIndex += 1
            )
              itemIndex == index
                  ? updatedAddress
                  : customer.addresses[itemIndex],
          ];
          return _save(
            _repository,
            customer,
            addresses: normalizeCustomerAddresses(next),
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
final class RemoveCustomerAddressUseCase {
  const RemoveCustomerAddressUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String addressId,
    required String updatedBy,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: customerId.trim(),
    );
    return currentResult.fold(
      onSuccess: (customer) {
        final next = customer.addresses
            .where((address) => address.id != addressId.trim())
            .toList(growable: false);
        if (next.length == customer.addresses.length) {
          return const AppFailure<Customer>(
            NotFoundFailure(
              'Customer address not found.',
              code: 'customer_address_not_found',
            ),
          );
        }
        return _save(
          _repository,
          customer,
          addresses: normalizeCustomerAddresses(next),
          updatedBy: updatedBy,
        );
      },
      onFailure: (failure) => AppFailure<Customer>(failure),
    );
  }
}

@injectable
final class SetPrimaryCustomerAddressUseCase {
  const SetPrimaryCustomerAddressUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String customerId,
    required String addressId,
    required String updatedBy,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: customerId.trim(),
    );
    return currentResult.fold(
      onSuccess: (customer) {
        if (!customer.addresses.any(
          (address) => address.id == addressId.trim(),
        )) {
          return const AppFailure<Customer>(
            NotFoundFailure(
              'Customer address not found.',
              code: 'customer_address_not_found',
            ),
          );
        }
        final next = <CustomerAddress>[
          for (final address in customer.addresses)
            address.copyWith(isPrimary: address.id == addressId.trim()),
        ];
        return _save(
          _repository,
          customer,
          addresses: next,
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
  required List<CustomerAddress> addresses,
  required String updatedBy,
}) {
  final now = DateTime.now().toUtc();
  return repository.update(
    customer: customer.copyWith(
      addresses: normalizeCustomerAddresses(addresses),
      updatedAt: now,
      updatedBy: updatedBy.trim(),
      version: customer.version + 1,
      syncStatus: CustomerSyncStatus.pending,
    ),
    sensitiveFieldsToAudit: const <CustomerSensitiveField>{},
  );
}

String _cityFromLocalZip(
  List<CustomerAddress> addresses,
  String zipCode,
  String city,
) {
  final trimmedCity = city.trim();
  if (trimmedCity.isNotEmpty) return city;
  final digits = zipCode.replaceAll(RegExp(r'\D'), '');
  for (final address in addresses) {
    if (address.zipCode.digits == digits) return address.city;
  }
  return city;
}

String _stateFromLocalZip(
  List<CustomerAddress> addresses,
  String zipCode,
  String state,
) {
  final trimmedState = state.trim();
  if (trimmedState.isNotEmpty) return state;
  final digits = zipCode.replaceAll(RegExp(r'\D'), '');
  for (final address in addresses) {
    if (address.zipCode.digits == digits) return address.state;
  }
  return state;
}
