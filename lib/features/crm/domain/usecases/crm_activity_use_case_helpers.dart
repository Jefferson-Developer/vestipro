String? normalizeCrmOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<String> normalizeCrmAttachments(List<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
