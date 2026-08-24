import '../value_objects/customer_required_field.dart';

/// Organization-scoped behavior for `CustomerFormBloc`.
///
/// The minimum identity fields remain hard required by the form/use cases and
/// cannot be disabled by this configuration.
final class CustomerFormConfig {
  const CustomerFormConfig({
    this.additionalRequiredFields = const <CustomerRequiredField>{},
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

  final Set<CustomerRequiredField> additionalRequiredFields;

  bool requires(CustomerRequiredField field) {
    return additionalRequiredFields.contains(field);
  }
}
