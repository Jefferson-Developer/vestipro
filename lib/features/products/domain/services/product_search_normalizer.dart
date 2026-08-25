import '../entities/product.dart';

/// Text normalization and prefix indexing for product search.
///
/// Firestore has no native full-text search, so remote search stores
/// precomputed prefixes while the local Drift index stores one normalized
/// search text. Both paths use this same domain service to avoid drift
/// between online and offline matching.
abstract final class ProductSearchNormalizer {
  static const int maxPrefixLength = 32;

  static const Map<String, String> _diacritics = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ā': 'a',
    'ă': 'a',
    'ą': 'a',
    'ç': 'c',
    'ć': 'c',
    'ĉ': 'c',
    'ċ': 'c',
    'č': 'c',
    'ď': 'd',
    'đ': 'd',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'ē': 'e',
    'ĕ': 'e',
    'ė': 'e',
    'ę': 'e',
    'ě': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ī': 'i',
    'ĭ': 'i',
    'į': 'i',
    'ñ': 'n',
    'ń': 'n',
    'ņ': 'n',
    'ň': 'n',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ō': 'o',
    'ŏ': 'o',
    'ő': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ū': 'u',
    'ŭ': 'u',
    'ů': 'u',
    'ű': 'u',
    'ų': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  static final RegExp _nonSearchChars = RegExp(r'[^a-z0-9]+');
  static final RegExp _spaces = RegExp(r'\s+');

  static String normalize(String value) {
    if (value.trim().isEmpty) return '';

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacritics[char] ?? char);
    }

    return buffer
        .toString()
        .replaceAll(_nonSearchChars, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  static List<String> searchableValuesForProduct(Product product) {
    return <String>[
      product.name,
      product.sku.value,
      product.reference,
      if (product.ean != null) product.ean!.digits,
      ...product.tags,
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
  }

  static String searchTextForProduct(Product product) {
    return searchableValuesForProduct(
      product,
    ).map(normalize).where((value) => value.isNotEmpty).join(' ');
  }

  static bool productMatches(Product product, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return false;
    return searchTextForProduct(product).contains(normalizedQuery);
  }

  static Set<String> prefixesForProduct(Product product) {
    return prefixesForValues(searchableValuesForProduct(product));
  }

  static Set<String> prefixesForValues(Iterable<String> values) {
    final prefixes = <String>{};
    for (final value in values) {
      final normalized = normalize(value);
      if (normalized.isEmpty) continue;
      _addPrefixes(prefixes, normalized);
      for (final token in normalized.split(' ')) {
        _addPrefixes(prefixes, token);
      }
    }
    return prefixes;
  }

  static void _addPrefixes(Set<String> prefixes, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final maxLength = normalized.length < maxPrefixLength
        ? normalized.length
        : maxPrefixLength;
    for (var length = 1; length <= maxLength; length += 1) {
      prefixes.add(normalized.substring(0, length));
    }
  }
}
