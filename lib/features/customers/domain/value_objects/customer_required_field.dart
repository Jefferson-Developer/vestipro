/// Additional customer fields an Organization may require in the customer
/// form. Document + legal/full name are always mandatory and are therefore
/// not configurable here.
enum CustomerRequiredField {
  primaryEmail,
  primaryPhone,
  classification,
  potential,
  responsibleSellerId,
}

extension CustomerRequiredFieldCode on CustomerRequiredField {
  String get code {
    return switch (this) {
      CustomerRequiredField.primaryEmail => 'primaryEmail',
      CustomerRequiredField.primaryPhone => 'primaryPhone',
      CustomerRequiredField.classification => 'classification',
      CustomerRequiredField.potential => 'potential',
      CustomerRequiredField.responsibleSellerId => 'responsibleSellerId',
    };
  }
}

CustomerRequiredField? customerRequiredFieldFromCode(String code) {
  for (final field in CustomerRequiredField.values) {
    if (field.code == code) return field;
  }
  return null;
}
