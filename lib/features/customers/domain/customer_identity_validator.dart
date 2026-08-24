import 'value_objects/cnpj_cpf.dart';
import 'value_objects/customer_type.dart';

Map<String, String> validateCustomerIdentity({
  required CustomerType type,
  required CnpjCpf document,
  String? legalName,
  String? fullName,
  String? stateRegistration,
}) {
  final fieldErrors = <String, String>{};

  switch (type) {
    case CustomerType.legalEntity:
      if (!document.isCnpj) {
        fieldErrors['document'] = 'Legal entities require a valid CNPJ.';
      }
      if (legalName == null || legalName.trim().isEmpty) {
        fieldErrors['legalName'] = 'Legal name is required for legal entities.';
      }
    case CustomerType.individual:
      if (!document.isCpf) {
        fieldErrors['document'] = 'Individuals require a valid CPF.';
      }
      if (fullName == null || fullName.trim().isEmpty) {
        fieldErrors['fullName'] = 'Full name is required for individuals.';
      }
      if (stateRegistration != null && stateRegistration.trim().isNotEmpty) {
        fieldErrors['stateRegistration'] =
            'State registration applies only to legal entities.';
      }
  }

  return fieldErrors;
}
