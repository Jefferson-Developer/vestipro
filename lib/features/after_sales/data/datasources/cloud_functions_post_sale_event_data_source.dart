import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import '../dtos/post_sale_event_submission_result_dto.dart';
import 'post_sale_event_write_data_source.dart';

/// [PostSaleEventWriteDataSource] backed by [CloudFunctionsService]
/// (TASK-201) — calls `registerPostSaleEvent`, never a client-side write to
/// `organizations/{organizationId}/postSaleEvents`, same rule every other
/// Cloud-Function-backed data source in this codebase follows
/// (`CloudFunctionsReturnRequestDataSource`).
@LazySingleton(as: PostSaleEventWriteDataSource)
final class CloudFunctionsPostSaleEventDataSource
    implements PostSaleEventWriteDataSource {
  const CloudFunctionsPostSaleEventDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<PostSaleEventSubmissionResultDto> register({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'registerPostSaleEvent',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'orderId': orderId,
        'eventId': eventId,
        'type': type.code,
        'description': ?description,
      },
      requireAuth: true,
    );
    return PostSaleEventSubmissionResultDto.fromJson(response);
  }
}
