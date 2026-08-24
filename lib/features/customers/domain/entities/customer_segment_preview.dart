/// Result of previewing how many customers currently match a
/// `CustomerSegmentCriteria`, computed on demand before the segment is saved
/// (TASK-053's "Contagem de clientes... preview antes de salvar").
final class CustomerSegmentPreview {
  const CustomerSegmentPreview({
    required this.matchedCount,
    required this.isAtLeastCount,
  });

  /// Number of matching customers counted, capped at
  /// `PreviewCustomerSegmentCountUseCase.previewLimit`.
  final int matchedCount;

  /// True when there may be more matches than [matchedCount]: the carteira
  /// query returned more results than the preview cap, so [matchedCount] is
  /// a floor, not necessarily the exact total.
  final bool isAtLeastCount;
}
