import 'package:injectable/injectable.dart';

import '../../domain/entities/order_signature_submission_result.dart';
import '../dtos/order_signature_submission_result_dto.dart';

/// Maps [OrderSignatureSubmissionResultDto] (raw `signOrder` JSON response)
/// to the domain-facing [OrderSignatureSubmissionResult] (EPIC-13,
/// TASK-180) — mirrors `OrderSubmissionMapper`'s own shape.
@lazySingleton
final class OrderSignatureSubmissionMapper {
  const OrderSignatureSubmissionMapper();

  OrderSignatureSubmissionResult toEntity(
    OrderSignatureSubmissionResultDto dto,
  ) {
    return OrderSignatureSubmissionResult(
      signatureId: dto.signatureId,
      remoteImageStoragePath: dto.remoteImageStoragePath,
      serverReceivedAt: dto.serverReceivedAt,
      deviceInfo: dto.deviceInfo,
      ipAddress: dto.ipAddress,
    );
  }
}
