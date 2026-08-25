import 'dart:math' as math;

import 'package:injectable/injectable.dart';

import '../entities/product_color.dart';
import '../value_objects/hex_color.dart';

final class ProductColorSuggestion {
  const ProductColorSuggestion({
    required this.color,
    required this.reason,
    required this.score,
  });

  final ProductColor color;
  final String reason;
  final double score;
}

@lazySingleton
final class ProductColorSimilarityService {
  const ProductColorSimilarityService();

  static const int closeHexDistanceSquared = 900;

  List<ProductColorSuggestion> findSimilar({
    required String name,
    required HexColor hex,
    required List<ProductColor> existingColors,
    String? excludingColorId,
  }) {
    final normalizedName = normalizeName(name);
    final suggestions = <ProductColorSuggestion>[];
    for (final color in existingColors) {
      if (excludingColorId != null && color.id == excludingColorId) continue;
      final nameScore = _nameScore(normalizedName, normalizeName(color.name));
      final hexDistance = hex.distanceTo(color.hex);
      if (nameScore >= 0.86) {
        suggestions.add(
          ProductColorSuggestion(
            color: color,
            reason: 'Nome muito parecido',
            score: nameScore,
          ),
        );
      } else if (hexDistance <= closeHexDistanceSquared) {
        suggestions.add(
          ProductColorSuggestion(
            color: color,
            reason: 'Hexadecimal visualmente próximo',
            score: 1 - (hexDistance / closeHexDistanceSquared),
          ),
        );
      }
    }
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  String normalizeName(String value) {
    const accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'õ': 'o',
      'ô': 'o',
      'ú': 'u',
      'ç': 'c',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  double _nameScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (a.contains(b) || b.contains(a)) return 0.9;
    final distance = _levenshtein(a, b);
    return 1 - distance / math.max(a.length, b.length);
  }

  int _levenshtein(String a, String b) {
    final costs = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i += 1) {
      var previous = costs[0];
      costs[0] = i;
      for (var j = 1; j <= b.length; j += 1) {
        final current = costs[j];
        costs[j] = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1)
            ? previous
            : math.min(math.min(costs[j - 1], costs[j]), previous) + 1;
        previous = current;
      }
    }
    return costs[b.length];
  }
}
