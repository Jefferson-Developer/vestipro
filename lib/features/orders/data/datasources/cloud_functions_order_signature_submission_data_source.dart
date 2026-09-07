import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/order_signature.dart';
import '../dtos/order_signature_submission_result_dto.dart';
import '../mappers/order_signature_codec.dart';
import 'order_signature_submission_data_source.dart';

/// [OrderSignatureSubmissionDataSource] backed by [CloudFunctionsService]
/// (EPIC-13, TASK-180) — calls `signOrder`, never a client-side write to
/// `organizations/{organizationId}/orders/{orderId}/signatures` or Cloud
/// Storage, same rule every other Cloud-Function-backed data source in this
/// codebase follows (`CloudFunctionsOrderSubmissionDataSource`).
///
/// [OrderSignature.imageBytes] travels as a base64 string inside the
/// callable payload (never a direct client upload to Storage): the
/// signature image path in Cloud Storage is written exclusively by
/// `signOrder` itself (Admin SDK), which is what lets the Function be the
/// one and only place that ever writes the immutable evidence — the same
/// reason `storage.rules`'s own
/// `organizations/{organizationId}/orders/{orderId}/signatures/{fileName}`
/// match is `allow write: if false` unconditionally.
@LazySingleton(as: OrderSignatureSubmissionDataSource)
final class CloudFunctionsOrderSignatureSubmissionDataSource
    implements OrderSignatureSubmissionDataSource {
  const CloudFunctionsOrderSignatureSubmissionDataSource(
    this._cloudFunctionsService,
    this._codec,
  );

  final CloudFunctionsService _cloudFunctionsService;
  final OrderSignatureCodec _codec;

  @override
  Future<OrderSignatureSubmissionResultDto> submit({
    required OrderSignature signature,
  }) async {
    final data = <String, dynamic>{
      'organizationId': signature.organizationId,
      'companyId': signature.companyId,
      'orderId': signature.orderId,
      'signatureId': signature.id,
      'signerRole': _codec.signerRoleToCode(signature.signerRole),
      'signedByName': signature.signedByName,
      'method': _codec.methodToCode(signature.method),
      'imageBase64': base64Encode(signature.imageBytes),
      'contentHash': signature.contentHash,
      'orderVersionAtSignature': signature.orderVersionAtSignature,
      'signedAt': signature.signedAt.toUtc().toIso8601String(),
    };

    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'signOrder',
      data: data,
      requireAuth: true,
    );

    return OrderSignatureSubmissionResultDto.fromJson(response);
  }
}
