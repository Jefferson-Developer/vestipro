/// Shared field validation for creating/updating a `CatalogCampaign`
/// (TASK-080), so both use cases reject the same invalid payloads — the
/// same "one validation function shared by create/update" precedent
/// `Collection`'s own use cases already set.
Map<String, String> validateCampaignFields({
  required String id,
  required String organizationId,
  required String title,
  required String actorId,
  required String actorField,
  DateTime? startAt,
  DateTime? endAt,
}) {
  final fieldErrors = <String, String>{};
  if (id.isEmpty) fieldErrors['id'] = 'Id is required.';
  if (organizationId.isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (title.isEmpty) {
    fieldErrors['title'] = 'Informe o título da campanha.';
  }
  if (actorId.isEmpty) {
    fieldErrors[actorField] =
        '${actorField[0].toUpperCase()}${actorField.substring(1)} is required.';
  }
  if (startAt != null && endAt != null && endAt.isBefore(startAt)) {
    fieldErrors['endAt'] =
        'A data de término deve ser posterior à data de início.';
  }
  return fieldErrors;
}

/// Normalizes a nullable/optionally-blank text field: trims it and turns an
/// empty result into `null`, mirroring `normalizeProductOptional`.
String? normalizeCampaignOptional(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
