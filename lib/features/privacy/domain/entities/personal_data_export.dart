enum PersonalDataExportStatus { requested, processing, ready, expired, failed }

final class PersonalDataExport {
  const PersonalDataExport({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.expiresAt,
    this.fileName,
  });

  final String id;
  final String organizationId;
  final String userId;
  final PersonalDataExportStatus status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? fileName;

  bool get canDownload =>
      status == PersonalDataExportStatus.ready &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());
}

final class PersonalDataExportDownload {
  const PersonalDataExportDownload({
    required this.url,
    required this.fileName,
    required this.expiresAt,
  });

  final Uri url;
  final String fileName;
  final DateTime expiresAt;
}
