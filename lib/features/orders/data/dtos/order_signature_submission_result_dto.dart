/// Raw JSON shape `signOrder` (the Cloud Function) responds with (EPIC-13,
/// TASK-180) — mirrors `OrderSubmissionResultDto`'s own "thin JSON parsing,
/// no business rule" shape for `submitOrder`.
final class OrderSignatureSubmissionResultDto {
  const OrderSignatureSubmissionResultDto({
    required this.signatureId,
    required this.remoteImageStoragePath,
    required this.serverReceivedAt,
    this.deviceInfo,
    this.ipAddress,
  });

  factory OrderSignatureSubmissionResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrderSignatureSubmissionResultDto(
      signatureId: json['signatureId'] as String,
      remoteImageStoragePath: json['remoteImageStoragePath'] as String,
      serverReceivedAt: DateTime.parse(
        json['serverReceivedAt'] as String,
      ).toUtc(),
      deviceInfo: json['deviceInfo'] as String?,
      ipAddress: json['ipAddress'] as String?,
    );
  }

  final String signatureId;
  final String remoteImageStoragePath;
  final DateTime serverReceivedAt;
  final String? deviceInfo;
  final String? ipAddress;
}
