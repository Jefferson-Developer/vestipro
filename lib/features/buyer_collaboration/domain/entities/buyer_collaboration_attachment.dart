/// A file the seller or buyer attached to one comment (a photo, a PDF quote
/// counter-proposal, etc.) — always an already-uploaded, https link; this
/// feature never uploads to Storage itself (`AGENTS.md`: "UI não acessa
/// Storage diretamente" — uploading is the caller's own concern, e.g. the
/// same Storage picker other features already use).
final class BuyerCollaborationAttachment {
  const BuyerCollaborationAttachment({
    required this.name,
    required this.url,
    required this.contentType,
  });

  final String name;
  final String url;
  final String contentType;
}
