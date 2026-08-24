import '../../../../core/errors/errors.dart';
import '../value_objects/cnpj_cpf.dart';

CnpjCpf? parseCustomerDocument(
  String document,
  Map<String, String> fieldErrors,
) {
  try {
    return CnpjCpf.parse(document);
  } on ValidationException catch (exception) {
    if (exception.fieldErrors.isEmpty) {
      fieldErrors['document'] = exception.message;
    } else {
      fieldErrors.addAll(exception.fieldErrors);
    }
    return null;
  }
}

String? normalizeCustomerOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<String> normalizeCustomerTags(List<String> tags) {
  final normalized = <String>[];
  for (final tag in tags) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !normalized.contains(trimmed)) {
      normalized.add(trimmed);
    }
  }
  return List<String>.unmodifiable(normalized);
}

Map<String, Object?> normalizeCustomerCustomFields(
  Map<String, Object?> customFields,
) {
  final normalized = <String, Object?>{};
  for (final entry in customFields.entries) {
    final key = entry.key.trim();
    if (key.isNotEmpty) {
      normalized[key] = entry.value;
    }
  }
  return Map<String, Object?>.unmodifiable(normalized);
}
