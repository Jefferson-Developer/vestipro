import 'product_recognition_candidate.dart';

/// The outcome of one `recognizeProductImage` call (TASK-191, EPIC-28).
///
/// [attemptId] identifies this attempt for `submitProductRecognitionFeedback`
/// — every "era este"/"nenhum destes" feedback action must reference it.
///
/// [belowThreshold] is `true` whenever no candidate reached the server's own
/// minimum-confidence bar (including when the organization's catalog has no
/// indexed photo at all yet); [candidates] is always empty in that case. A
/// caller must render this as an explicit "não foi possível identificar com
/// confiança" state, never silently show an empty list
/// (`tasks.md`/TASK-191).
final class ProductRecognitionResult {
  const ProductRecognitionResult({
    required this.attemptId,
    required this.candidates,
    required this.belowThreshold,
    required this.generatedAt,
  });

  final String attemptId;
  final List<ProductRecognitionCandidate> candidates;
  final bool belowThreshold;
  final DateTime generatedAt;
}
