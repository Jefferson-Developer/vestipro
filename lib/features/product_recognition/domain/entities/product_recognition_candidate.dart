/// One ranked candidate product returned by `recognizeProductImage`
/// (TASK-191, EPIC-28). Always part of a list — this entity never appears
/// alone as "the" answer: `ProductRecognitionResult.candidates` is always a
/// ranked list the seller must visually confirm, never a single forced
/// match (`tasks.md`/TASK-191: "sempre sugerindo candidatos... nunca
/// afirmando uma única resposta possivelmente errada").
final class ProductRecognitionCandidate {
  const ProductRecognitionCandidate({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.score,
  });

  final String productId;
  final String productName;
  final String? thumbnailUrl;

  /// Cosine similarity (`0..1`) between the captured photo and this
  /// product's best-matching indexed photo — server-computed, never
  /// recalculated client-side.
  final double score;
}
