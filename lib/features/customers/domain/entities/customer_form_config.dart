import '../value_objects/customer_required_field.dart';
import '../value_objects/customer_address_type.dart';
import '../value_objects/customer_contact_type.dart';
import '../../../organizations/domain/value_objects/organization_settings.dart';

/// Organization-scoped behavior for `CustomerFormBloc`.
///
/// The minimum identity fields remain hard required by the form/use cases and
/// cannot be disabled by this configuration.
final class CustomerFormConfig {
  const CustomerFormConfig({
    this.additionalRequiredFields = const <CustomerRequiredField>{},
    this.addressTypes = CustomerAddressType.defaults,
    this.contactTypes = CustomerContactType.defaults,
  });

  factory CustomerFormConfig.fromOrganizationFieldCodes(
    Iterable<String> fieldCodes,
  ) {
    return CustomerFormConfig(
      additionalRequiredFields: fieldCodes
          .map(customerRequiredFieldFromCode)
          .whereType<CustomerRequiredField>()
          .toSet(),
    );
  }

  factory CustomerFormConfig.fromOrganizationSettings(
    OrganizationSettings settings,
  ) {
    return CustomerFormConfig(
      additionalRequiredFields: settings.requiredCustomerFields
          .map(customerRequiredFieldFromCode)
          .whereType<CustomerRequiredField>()
          .toSet(),
      addressTypes: mergeCustomerAddressTypes(settings.customerAddressTypes),
      contactTypes: mergeCustomerContactTypes(settings.customerContactTypes),
    );
  }

  final Set<CustomerRequiredField> additionalRequiredFields;
  final List<CustomerAddressType> addressTypes;
  final List<CustomerContactType> contactTypes;

  bool requires(CustomerRequiredField field) {
    return additionalRequiredFields.contains(field);
  }
}

List<CustomerAddressType> mergeCustomerAddressTypes(Iterable<String> custom) {
  final byCode = <String, CustomerAddressType>{
    for (final type in CustomerAddressType.defaults) type.code: type,
  };
  for (final value in custom) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    final type = CustomerAddressType.custom(trimmed);
    byCode.putIfAbsent(type.code, () => type);
  }
  return List<CustomerAddressType>.unmodifiable(byCode.values);
}

List<CustomerContactType> mergeCustomerContactTypes(Iterable<String> custom) {
  final byCode = <String, CustomerContactType>{
    for (final type in CustomerContactType.defaults) type.code: type,
  };
  for (final value in custom) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    final type = CustomerContactType.custom(trimmed);
    byCode.putIfAbsent(type.code, () => type);
  }
  return List<CustomerContactType>.unmodifiable(byCode.values);
}
