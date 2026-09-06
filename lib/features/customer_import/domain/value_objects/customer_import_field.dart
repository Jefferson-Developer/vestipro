/// Every `Customer` (`lib/features/customers/domain/entities/customer.dart`,
/// TASK-048) field a spreadsheet column can be mapped to during a customer
/// import (TASK-167). Deliberately a closed set — a gestor maps a column to
/// one of these, never to an arbitrary free-text key, so both the client
/// preview and the `processCustomerImportJob` Cloud Function agree on
/// exactly what each mapped column means.
///
/// [ignored] is not a `Customer` field: it marks a spreadsheet column the
/// gestor chose not to import (e.g. an internal legacy id), so
/// `CustomerImportMapping` can represent "every column has a decision"
/// without forcing every column to map to something.
enum CustomerImportField {
  document,
  legalName,
  tradeName,
  fullName,
  stateRegistration,
  primaryEmail,
  primaryPhone,
  classification,
  potential,
  segment,
  originChannel,
  addressStreet,
  addressNumber,
  addressComplement,
  addressDistrict,
  addressCity,
  addressState,
  addressZipCode,
  ignored,
}

extension CustomerImportFieldCode on CustomerImportField {
  /// Stable identifier persisted in `CustomerImportMapping`/
  /// `CustomerImportTemplate` (Firestore) and sent to the
  /// `startCustomerImportJob` Cloud Function — never the enum index, which
  /// would silently shift meaning if a value were reordered.
  String get code {
    return switch (this) {
      CustomerImportField.document => 'document',
      CustomerImportField.legalName => 'legalName',
      CustomerImportField.tradeName => 'tradeName',
      CustomerImportField.fullName => 'fullName',
      CustomerImportField.stateRegistration => 'stateRegistration',
      CustomerImportField.primaryEmail => 'primaryEmail',
      CustomerImportField.primaryPhone => 'primaryPhone',
      CustomerImportField.classification => 'classification',
      CustomerImportField.potential => 'potential',
      CustomerImportField.segment => 'segment',
      CustomerImportField.originChannel => 'originChannel',
      CustomerImportField.addressStreet => 'addressStreet',
      CustomerImportField.addressNumber => 'addressNumber',
      CustomerImportField.addressComplement => 'addressComplement',
      CustomerImportField.addressDistrict => 'addressDistrict',
      CustomerImportField.addressCity => 'addressCity',
      CustomerImportField.addressState => 'addressState',
      CustomerImportField.addressZipCode => 'addressZipCode',
      CustomerImportField.ignored => 'ignored',
    };
  }

  /// Portuguese label shown in the column-mapping step
  /// (`CustomerImportMappingStep`) — never hardcoded again at the call
  /// site.
  String get label {
    return switch (this) {
      CustomerImportField.document => 'CNPJ/CPF',
      CustomerImportField.legalName => 'Razão social',
      CustomerImportField.tradeName => 'Nome fantasia',
      CustomerImportField.fullName => 'Nome completo',
      CustomerImportField.stateRegistration => 'Inscrição estadual',
      CustomerImportField.primaryEmail => 'E-mail',
      CustomerImportField.primaryPhone => 'Telefone',
      CustomerImportField.classification => 'Classificação',
      CustomerImportField.potential => 'Potencial',
      CustomerImportField.segment => 'Segmento',
      CustomerImportField.originChannel => 'Canal de origem',
      CustomerImportField.addressStreet => 'Endereço (rua)',
      CustomerImportField.addressNumber => 'Endereço (número)',
      CustomerImportField.addressComplement => 'Endereço (complemento)',
      CustomerImportField.addressDistrict => 'Endereço (bairro)',
      CustomerImportField.addressCity => 'Endereço (cidade)',
      CustomerImportField.addressState => 'Endereço (UF)',
      CustomerImportField.addressZipCode => 'Endereço (CEP)',
      CustomerImportField.ignored => 'Não importar',
    };
  }

  static CustomerImportField? fromCode(String code) {
    for (final field in CustomerImportField.values) {
      if (field.code == code) return field;
    }
    return null;
  }
}

/// Every [CustomerImportField] a mapping must assign to a column before an
/// import can start — enforced by `validateCustomerImportMapping`.
/// [CustomerImportField.document] is always required because duplicate
/// detection and `Customer.document` itself depend on it
/// (`AGENTS.md`/TASK-167: "Duplicidade é sempre verificada por documento
/// normalizado"). At least one of [CustomerImportField.legalName],
/// [CustomerImportField.tradeName] or [CustomerImportField.fullName] must
/// also be mapped — checked separately since it is an "at least one of"
/// rule, not "every field in this set".
const Set<CustomerImportField> kRequiredCustomerImportFields =
    <CustomerImportField>{CustomerImportField.document};
