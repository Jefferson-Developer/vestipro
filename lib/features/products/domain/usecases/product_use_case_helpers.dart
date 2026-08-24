/// `null`/blank-safe trim helper shared by Product's create/update use
/// cases, mirroring `normalizeCustomerOptional` in `customers/`.
String? normalizeProductOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// De-duplicates and trims tags, dropping blanks — same normalization
/// `normalizeCustomerTags` applies for Customer.
List<String> normalizeProductTags(List<String> tags) {
  final normalized = <String>[];
  for (final tag in tags) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !normalized.contains(trimmed)) {
      normalized.add(trimmed);
    }
  }
  return List<String>.unmodifiable(normalized);
}
