import '../../domain/value_objects/post_sale_event_type.dart';
import '../dtos/post_sale_event_submission_result_dto.dart';

abstract interface class PostSaleEventWriteDataSource {
  Future<PostSaleEventSubmissionResultDto> register({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  });
}
